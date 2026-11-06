/*
 * Where Bazaar Tokens come from.
 *
 * The shop is only half the economy. Ascension sold tokens for real money and
 * let players buy them off the auction house; with the shop gone, the only way
 * left is to play. The rule the server owner asked for: a little from
 * everything, more from harder content.
 *
 *   quest turned in     0 to 6
 *   creature killed     0 to 2
 *   dungeon boss        6 to 12
 *   raid boss          30 to 40
 *
 * A percentage from BonusLevel on can multiply every amount; by default it
 * is 100, so there is no bonus.
 *
 * The zero in the lower two ranges is deliberate: most kills and some quests
 * give nothing at all, so tokens stay something one notices.
 *
 * A kill pays everyone the native kill credit rewards: whoever tapped the
 * creature, and every member of a tapping group in reward range, whether they
 * attacked, healed or watched. Each member rolls their own amount.
 *
 * A kill far below the player's own level pays nothing, so outlevelled mobs
 * are not a token farm. Each member is judged on their own level; see KillPays.
 */

#include "EtherealBazaar.h"

#include "AscensionBazaarTokenCap.h"
#include "CoATestZoneBonus.h"
#include "Configuration/Config.h"
#include "Creature.h"
#include "DataMap.h"
#include "Formulas.h"
#include "KillRewarder.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QuestDef.h"
#include "Mail.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "StringConvert.h"
#include "StringFormat.h"
#include "WorldScript.h"
#include <algorithm>
#include <atomic>
#include <limits>
#include <memory>
#include <string>
#include <utility>

namespace
{
    std::string const PendingTokensKey = "ethereal_bazaar_pending_tokens";
    constexpr uint32 KillPayoutMinimumMs = 1000;
    constexpr uint32 KillPayoutSpreadMs = 1000;

    struct RewardRange
    {
        uint32 Min;
        uint32 Max;

        uint32 Roll() const { return urand(Min, Max); }
    };

    struct TokenSettings
    {
        bool Enabled = true;
        bool Announce = false;
        RewardRange Quest{0, 6};
        RewardRange Creature{0, 2};
        RewardRange DungeonBoss{6, 12};
        RewardRange RaidBoss{30, 40};
        uint32 MaxLevel = 60;
        Optional<uint32> LevelingGap;
        Optional<uint32> MaxLevelGap = 5;
        uint32 BonusLevel = 60;
        uint32 BonusPercent = 100;
    };

    std::atomic<std::shared_ptr<TokenSettings const>> Settings{std::make_shared<TokenSettings>()};

    struct PendingTokens final : DataMap::Base
    {
        uint32 Amount = 0;
        bool Scheduled = false;
    };

    RewardRange LoadRange(char const* name, RewardRange defaults)
    {
        uint32 const min = sConfigMgr->GetOption<uint32>(
            Acore::StringFormat("EtherealBazaar.Tokens.{}.Min", name), defaults.Min);
        uint32 const max = sConfigMgr->GetOption<uint32>(
            Acore::StringFormat("EtherealBazaar.Tokens.{}.Max", name), defaults.Max);
        return {min, std::max(min, max)};
    }

    // The setting is a number of levels, or "grey" for the XP rule: anything grey
    // to this player pays nothing. Creatures above the player always pay.
    //
    // Every character is judged on the level they are shown: a creature scaled
    // to them has that level's health and armor, so it pays like one. A scaled
    // dungeon holds its creatures inside the dungeon's band, so a low dungeon
    // stays below a maximum-level character.
    bool KillPays(Player* player, Creature const* killed, TokenSettings const& settings)
    {
        uint32 const level = player->GetLevel();
        Optional<uint32> const& levelsAbove = level >= settings.MaxLevel ? settings.MaxLevelGap : settings.LevelingGap;
        uint32 const killedLevel = killed->getLevelForTarget(player);
        if (levelsAbove)
            return killedLevel >= level || level - killedLevel <= *levelsAbove;

        return killedLevel > Acore::XP::GetGrayLevel(level);
    }

    // The multiplier is a percentage so the config can hold a whole number.
    uint32 CalculateReward(Player* player, uint32 amount, TokenSettings const& settings)
    {
        if (!amount)
            return 0;

        if (player->GetLevel() >= settings.BonusLevel)
            amount = uint32(std::clamp<uint64>(uint64(amount) * settings.BonusPercent / 100,
                1, std::numeric_limits<uint32>::max()));
        return TestZoneBonus::Apply(player, TestZoneBonus::Reward::BazaarTokens, amount);
    }

    void Deliver(Player* player, uint32 amount, bool announce)
    {
        if (!amount)
            return;

        ItemTemplate const* token = sObjectMgr->GetItemTemplate(BAZAAR_TOKEN_ITEM);
        if (!token)
            return;
        amount = AscensionBazaarTokenCap::Claim(player, amount);
        if (!amount)
            return;

        uint32 remaining = amount;
        ItemPosCountVec dest;
        player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, BAZAAR_TOKEN_ITEM, amount);
        if (!dest.empty())
        {
            if (Item* item = player->StoreNewItem(dest, BAZAAR_TOKEN_ITEM, true))
            {
                for (ItemPosCount const& position : dest)
                    remaining -= position.count;
                if (announce)
                    player->SendNewItem(item, amount - remaining, true, false);
            }
        }

        uint32 const mailLimit = uint32(std::min<uint64>(
            uint64(token->GetMaxStackSize()) * MAX_MAIL_ITEMS, std::numeric_limits<uint32>::max()));
        while (remaining)
        {
            uint32 const count = std::min(remaining, mailLimit);
            player->SendItemRetrievalMail(BAZAAR_TOKEN_ITEM, count);
            remaining -= count;
        }
    }

    void FlushPending(Player* player)
    {
        if (PendingTokens* pending = player->CustomData.Get<PendingTokens>(PendingTokensKey))
            Deliver(player, std::exchange(pending->Amount, 0), Settings.load()->Announce);
    }

    void QueueKillReward(Player* player, uint32 amount)
    {
        if (!amount)
            return;

        PendingTokens* pending = player->CustomData.GetDefault<PendingTokens>(PendingTokensKey);
        if (amount > std::numeric_limits<uint32>::max() - pending->Amount)
            FlushPending(player);
        pending->Amount += amount;
        if (pending->Scheduled)
            return;

        pending->Scheduled = true;
        player->m_Events.AddEventAtOffset([guid = player->GetGUID()]
        {
            Player* current = ObjectAccessor::FindConnectedPlayer(guid);
            if (!current)
                return;
            if (PendingTokens* batch = current->CustomData.Get<PendingTokens>(PendingTokensKey))
            {
                batch->Scheduled = false;
                FlushPending(current);
            }
        }, Milliseconds(KillPayoutMinimumMs + player->GetGUID().GetRawValue() % KillPayoutSpreadMs));
    }
}

class ethereal_bazaar_token_config final : public WorldScript
{
public:
    ethereal_bazaar_token_config() : WorldScript("ethereal_bazaar_token_config", {WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnAfterConfigLoad(bool) override
    {
        auto settings = std::make_shared<TokenSettings>();
        settings->Enabled = sConfigMgr->GetOption<bool>("EtherealBazaar.Tokens.Enable", true);
        settings->Announce = sConfigMgr->GetOption<bool>("EtherealBazaar.Tokens.Announce", false);
        settings->Quest = LoadRange("Quest", settings->Quest);
        settings->Creature = LoadRange("Creature", settings->Creature);
        settings->DungeonBoss = LoadRange("DungeonBoss", settings->DungeonBoss);
        settings->RaidBoss = LoadRange("RaidBoss", settings->RaidBoss);
        settings->MaxLevel = sConfigMgr->GetOption<uint32>("EtherealBazaar.Tokens.MaxLevel", 60);
        settings->LevelingGap = Acore::StringTo<uint32>(
            sConfigMgr->GetOption<std::string>("EtherealBazaar.Tokens.MaxLevelsAboveMob.WhileLeveling", "grey"));
        settings->MaxLevelGap = Acore::StringTo<uint32>(
            sConfigMgr->GetOption<std::string>("EtherealBazaar.Tokens.MaxLevelsAboveMob.AtMaxLevel", "5"));
        settings->BonusLevel = sConfigMgr->GetOption<uint32>("EtherealBazaar.Tokens.BonusLevel", 60);
        settings->BonusPercent = sConfigMgr->GetOption<uint32>("EtherealBazaar.Tokens.BonusPercent", 100);
        Settings.store(std::move(settings));
    }
};

class ethereal_bazaar_tokens : public PlayerScript
{
public:
    ethereal_bazaar_tokens() : PlayerScript("ethereal_bazaar_tokens",
        {PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST, PLAYERHOOK_ON_REWARD_KILL_REWARDER, PLAYERHOOK_ON_BEFORE_LOGOUT}) { }

    void OnPlayerBeforeLogout(Player* player) override
    {
        FlushPending(player);
    }

    void OnPlayerCompleteQuest(Player* player, Quest const* quest) override
    {
        auto const settings = Settings.load();
        if (!settings->Enabled || !player || !quest)
            return;

        FlushPending(player);
        Deliver(player, CalculateReward(player, settings->Quest.Roll(), *settings), settings->Announce);
    }

    void OnPlayerRewardKillRewarder(Player* player, KillRewarder* rewarder, bool, float&) override
    {
        Creature* killed = rewarder && rewarder->GetVictim() ? rewarder->GetVictim()->ToCreature() : nullptr;
        if (!player || !killed)
            return;

        // Nothing for what a player made themselves, and nothing for the
        // harmless: a totem farm should not be a token farm.
        if (killed->IsSummon() || killed->IsCritter() || killed->IsTotem())
            return;

        auto const settings = Settings.load();
        if (!settings->Enabled)
            return;

        // Bosses are worth a real amount, and a raid boss more than a dungeon
        // one. IsDungeonBoss covers the flagged encounters; the world bosses
        // outside an instance are deliberately left with the ordinary rate.
        bool const boss = killed->IsDungeonBoss();
        Map const* map = boss ? killed->GetMap() : nullptr;
        RewardRange const& range = !boss ? settings->Creature
            : (map && map->IsRaid() ? settings->RaidBoss : settings->DungeonBoss);
        uint32 const roll = range.Roll();
        if (!roll || !KillPays(player, killed, *settings))
            return;

        uint32 const amount = CalculateReward(player, roll, *settings);
        if (boss)
        {
            FlushPending(player);
            Deliver(player, amount, settings->Announce);
            return;
        }

        QueueKillReward(player, amount);
    }
};

void AddEtherealBazaarTokenScripts()
{
    new ethereal_bazaar_token_config();
    new ethereal_bazaar_tokens();
}
