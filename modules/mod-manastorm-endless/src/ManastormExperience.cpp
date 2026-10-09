#include "ManastormExperience.h"
#include "ManastormRun.h"
#include "LFGMgr.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QuestDef.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "World.h"
#include "WorldSession.h"
#include <algorithm>
#include <cmath>
#include <limits>

namespace
{
constexpr char const* LOG_FILTER = "module.manastorm.endless";

uint32 ClampXP(double value)
{
    if (!std::isfinite(value) || value <= 0.0)
        return 0;

    return static_cast<uint32>(std::min(value, double(std::numeric_limits<uint32>::max())));
}
}

ManastormExperience& ManastormExperience::Instance()
{
    static ManastormExperience instance;
    return instance;
}

bool ManastormExperience::Load()
{
    _loaded = false;
    PreparedQueryResult result = WorldDatabase.Query(
        WorldDatabase.GetPreparedStatement(WORLD_SEL_MANASTORM_FLOOR_XP));
    if (!result)
    {
        LOG_ERROR(LOG_FILTER, "Manastorm floor XP policy is missing. Apply world SQL 83.");
        return false;
    }

    Field* fields = result->Fetch();
    _enabled = fields[0].Get<bool>();
    _dungeonId = fields[1].Get<uint32>();
    _multiplier = fields[2].Get<double>();
    if (!std::isfinite(_multiplier) || _multiplier < 0.0)
    {
        LOG_ERROR(LOG_FILTER, "Invalid Manastorm floor XP multiplier: {}.", _multiplier);
        return false;
    }

    if (_enabled && _multiplier > 0.0)
    {
        for (uint32 level = 10; level < sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL); ++level)
        {
            lfg::LfgReward const* reward = sLFGMgr->GetRandomDungeonReward(_dungeonId, uint8(level));
            if (!reward || !sObjectMgr->GetQuestTemplate(reward->otherQuest))
            {
                LOG_ERROR(LOG_FILTER, "Manastorm floor XP RDF {} has no repeatable quest for level {}.",
                    _dungeonId, level);
                return false;
            }
        }
    }

    _loaded = true;
    LOG_INFO(LOG_FILTER, "Loaded Manastorm floor XP: enabled={} RDF={} multiplier={}.",
        _enabled, _dungeonId, _multiplier);
    return true;
}

bool ManastormExperience::PrepareCompletion(ManastormRun const& run,
    CharacterDatabaseTransaction const& transaction, std::string& error) const
{
    if (!_loaded)
    {
        error = "Manastorm floor XP policy is not loaded.";
        return false;
    }

    if (!_enabled || _multiplier == 0.0)
        return true;

    for (ObjectGuid::LowType guid : run.GetMembers())
    {
        Player* player = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
        uint8 level = 0;
        if (player)
        {
            if (player->HasPlayerFlag(PLAYER_FLAGS_NO_XP_GAIN) || player->HasPlayerFlag(PLAYER_FLAGS_NO_PLAY_TIME))
                continue;

            level = player->GetLevel();
            sScriptMgr->OnPlayerBeforeGetLevelForXPGain(player, level);
        }
        else
        {
            CharacterDatabasePreparedStatement* statement =
                CharacterDatabase.GetPreparedStatement(CHAR_SEL_MANASTORM_XP_LEVEL);
            statement->SetData(0, guid);
            PreparedQueryResult result = CharacterDatabase.Query(statement);
            if (!result)
            {
                error = "Unable to read an offline Manastorm member's level for floor XP.";
                return false;
            }

            Field* fields = result->Fetch();
            if (fields[1].Get<uint32>() & (PLAYER_FLAGS_NO_XP_GAIN | PLAYER_FLAGS_NO_PLAY_TIME))
                continue;

            level = fields[0].Get<uint8>();
        }

        if (level >= sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL))
            continue;

        lfg::LfgReward const* reward = sLFGMgr->GetRandomDungeonReward(_dungeonId, level);
        Quest const* quest = reward ? sObjectMgr->GetQuestTemplate(reward->otherQuest) : nullptr;
        if (!quest)
        {
            error = "No repeatable RDF quest exists for the configured Manastorm XP dungeon and level.";
            return false;
        }

        uint32 const baseXP = ClampXP(double(quest->XPValue(level)) * _multiplier);
        if (!baseXP)
            continue;

        CharacterDatabasePreparedStatement* statement =
            CharacterDatabase.GetPreparedStatement(CHAR_ADD_MANASTORM_FLOOR_XP);
        statement->SetData(0, guid);
        statement->SetData(1, baseXP);
        transaction->Append(statement);
    }

    return true;
}

void ManastormExperience::Settle(Player* player)
{
    if (!_loaded || !player || !player->GetSession())
        return;

    ObjectGuid::LowType const guid = player->GetGUID().GetCounter();
    if (!player->IsInWorld() || !player->FindMap() || player->IsBeingTeleportedFar())
    {
        _deferredClaims.insert(guid);
        return;
    }

    _deferredClaims.erase(guid);
    if (_failedClaims.count(guid) || player->HasPlayerFlag(PLAYER_FLAGS_NO_XP_GAIN)
        || player->HasPlayerFlag(PLAYER_FLAGS_NO_PLAY_TIME))
        return;

    CharacterDatabasePreparedStatement* statement =
        CharacterDatabase.GetPreparedStatement(CHAR_SEL_MANASTORM_FLOOR_XP);
    statement->SetData(0, guid);
    PreparedQueryResult result = CharacterDatabase.Query(statement);
    if (!result)
        return;

    uint64 const pending = result->Fetch()[0].Get<uint64>();
    uint32 const claimed = static_cast<uint32>(std::min(pending, uint64(std::numeric_limits<uint32>::max())));
    if (!claimed)
        return;

    // Use the core's RDF quest rate and quest XP auras, including its RAF exclusion.
    bool const recruitAFriend = player->GetsRecruitAFriendBonus(true);
    double const auraMultiplier = player->GetTotalAuraMultiplier(SPELL_AURA_MOD_XP_QUEST_PCT,
        [recruitAFriend](AuraEffect const* effect)
        {
            return effect->GetId() != 818059 || !recruitAFriend;
        });
    uint32 amount = ClampXP(double(ClampXP(double(claimed) * player->GetQuestRate(true))) * auraMultiplier);
    sScriptMgr->OnPlayerGiveXP(player, amount, nullptr, PlayerXPSource::XPSOURCE_QUEST_DF);
    player->GiveXP(amount, nullptr, 1.0f, true);

    // Persist the resulting level/XP and debit together, following the native XP claim contract.
    CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
    player->SaveToDB(transaction, false, false);
    statement = CharacterDatabase.GetPreparedStatement(CHAR_CLAIM_MANASTORM_FLOOR_XP);
    statement->SetData(0, claimed);
    statement->SetData(1, guid);
    transaction->Append(statement);
    if (!CharacterDatabase.AsyncCommitTransaction(transaction).m_future.get())
    {
        // Do not replay a grant already applied to this live Player after a database failure.
        _failedClaims.insert(guid);
        LOG_ERROR(LOG_FILTER, "Manastorm floor XP claim failed for guid {}. XP claims blocked until restart; "
            "reconcile character XP and pending XP before restarting.", guid);
    }
}

void ManastormExperience::OnMapEntry(Player* player)
{
    // Most map changes have no pending claim and require no database query.
    if (player && _deferredClaims.count(player->GetGUID().GetCounter()))
        Settle(player);
}
