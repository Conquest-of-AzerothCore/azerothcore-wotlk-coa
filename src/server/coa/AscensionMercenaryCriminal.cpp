/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionMercenary.h"
#include "BattlegroundMgr.h"
#include "BattlegroundQueue.h"
#include "Chat.h"
#include "DBCStores.h"
#include "DataMap.h"
#include "Group.h"
#include "LFGMgr.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ReputationMgr.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "WorldSession.h"
#include <array>
#include <unordered_set>
#include <vector>

namespace
{
constexpr uint32 SPELL_CRIMINAL = 9930873;
constexpr int32 CRIMINAL_HIT_DURATION = 3 * MINUTE * IN_MILLISECONDS;
constexpr int32 CRIMINAL_KILL_DURATION = 8 * MINUTE * IN_MILLISECONDS;
constexpr char NoRetreatMessage[] = "You cannot escape while the No Retreat debuff is active!";
constexpr char const* AggressionKey = "ascension_mercenary_criminal_aggression";

struct Aggression final : DataMap::Base
{
    std::unordered_set<ObjectGuid> Victims;
};

Player* MercenaryStriking(Unit* attacker, Unit* victim, Player*& innocent)
{
    Player* mercenary = attacker ? attacker->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
    innocent = victim ? victim->ToPlayer() : nullptr;
    if (!mercenary || !innocent || mercenary == innocent || !AscensionMercenary::Active(mercenary) ||
        AscensionMercenary::Active(innocent) || mercenary->GetTeamId() != innocent->GetTeamId())
        return nullptr;
    return mercenary;
}

void MarkCriminal(Player* player, int32 duration)
{
    Aura* aura = player->GetAura(SPELL_CRIMINAL);
    if (!aura)
    {
        player->CastSpell(player, SPELL_CRIMINAL, true);
        aura = player->GetAura(SPELL_CRIMINAL);
        if (!aura)
            return;
    }
    else if (aura->GetDuration() >= duration)
        return;

    aura->SetMaxDuration(duration);
    aura->SetDuration(duration);
}

void StrikeInnocent(Unit* attacker, Unit* victim)
{
    Player* innocent = nullptr;
    Player* mercenary = MercenaryStriking(attacker, victim, innocent);
    if (!mercenary || AscensionMercenary::StruckFirst(innocent, mercenary))
        return;

    mercenary->CustomData.GetDefault<Aggression>(AggressionKey)->Victims.insert(innocent->GetGUID());
    MarkCriminal(mercenary, CRIMINAL_HIT_DURATION);
}

void KillInnocent(Unit* killer, Unit* victim)
{
    Player* innocent = nullptr;
    Player* mercenary = MercenaryStriking(killer, victim, innocent);
    if (!mercenary)
        return;

    Aggression* state = mercenary->CustomData.Get<Aggression>(AggressionKey);
    if (state && state->Victims.erase(innocent->GetGUID()))
        MarkCriminal(mercenary, CRIMINAL_KILL_DURATION);
}

void ForgetAggressionOnceOutOfCombat(Player* player)
{
    if (!player->CustomData.Get<Aggression>(AggressionKey))
        return;

    ObjectGuid const guid = player->GetGUID();
    player->m_Events.AddEventAtOffset([guid]()
    {
        Player* player = ObjectAccessor::FindPlayer(guid);
        if (!player || player->IsInCombat())
            return;
        if (Aggression* state = player->CustomData.Get<Aggression>(AggressionKey))
            state->Victims.clear();
    }, 0ms);
}

std::vector<uint32> CapitalFactionsOf(Team team)
{
    std::vector<uint32> factions;
    for (uint32 id = 0; id < sFactionStore.GetNumRows(); ++id)
        if (FactionEntry const* faction = sFactionStore.LookupEntry(id))
            if (faction->team == uint32(team) && faction->CanHaveReputation())
                factions.push_back(faction->ID);
    return factions;
}

std::vector<uint32> const& CapitalFactions(TeamId team)
{
    static std::array<std::vector<uint32>, 2> const factions = {CapitalFactionsOf(ALLIANCE), CapitalFactionsOf(HORDE)};
    return factions[team == TEAM_ALLIANCE ? 0 : 1];
}

void SetOutlawed(Player* player, bool outlawed)
{
    for (uint32 faction : CapitalFactions(player->GetTeamId()))
        player->GetReputationMgr().ApplyForceReaction(faction, REP_HOSTILE, outlawed);
    if (player->IsInWorld())
        player->GetReputationMgr().SendForceReactions();
}

bool IsCriminal(Player const* player)
{
    return player && player->HasAura(SPELL_CRIMINAL);
}

bool TravelsCasterAway(SpellInfo const* info)
{
    for (SpellEffectInfo const& effect : info->Effects)
        if (effect.Effect == SPELL_EFFECT_TELEPORT_UNITS && effect.TargetA.GetTarget() == TARGET_UNIT_CASTER &&
            (effect.TargetB.GetTarget() == TARGET_DEST_DB || effect.TargetB.GetTarget() == TARGET_DEST_HOME))
            return true;
    return false;
}

void RefuseRetreat(Player* player)
{
    ChatHandler(player->GetSession()).SendNotification(NoRetreatMessage);
}

bool SummonedByPlayer(Player const* player, Unit const* summoner)
{
    Player const* other = summoner ? summoner->ToPlayer() : nullptr;
    return other && other != player && other->GetSession()->GetSecurity() == SEC_PLAYER;
}

bool GroupHasCriminal(Player* player)
{
    if (IsCriminal(player))
        return true;
    if (Group* group = player->GetGroup())
        for (GroupReference* member = group->GetFirstMember(); member; member = member->next())
            if (IsCriminal(member->GetSource()))
                return true;
    return false;
}

void LeaveEveryQueue(Player* player)
{
    for (uint8 slot = 0; slot < PLAYER_MAX_BATTLEGROUND_QUEUES; ++slot)
    {
        BattlegroundQueueTypeId const queue = player->GetBattlegroundQueueTypeId(slot);
        if (queue == BATTLEGROUND_QUEUE_NONE)
            continue;

        sBattlegroundMgr->GetBattlegroundQueue(queue).RemovePlayer(player->GetGUID(), true);
        player->RemoveBattlegroundQueueId(queue);
        if (Battleground* bg = sBattlegroundMgr->GetBattlegroundTemplate(BattlegroundMgr::BGTemplateId(queue)))
        {
            WorldPacket data;
            sBattlegroundMgr->BuildBattlegroundStatusPacket(&data, bg, slot, STATUS_NONE, 0, 0, 0, TEAM_NEUTRAL);
            player->SendDirectMessage(&data);
        }
    }

    Group* group = player->GetGroup();
    sLFGMgr->LeaveAllLfgQueues(player->GetGUID(), true, group ? group->GetGUID() : ObjectGuid::Empty);
}

void TurnCriminal(Player* player)
{
    SetOutlawed(player, true);
    if (!player->IsInWorld())
        return;
    if (player->GetTradeData())
        player->TradeCancel(true);
    LeaveEveryQueue(player);
}

class ascension_mercenary_criminal_acts : public UnitScript
{
public:
    ascension_mercenary_criminal_acts()
        : UnitScript("ascension_mercenary_criminal_acts", true,
                     {UNITHOOK_ON_DAMAGE, UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_UNIT_DEATH,
                      UNITHOOK_ON_UNIT_EXIT_COMBAT}) { }

    void OnDamage(Unit* attacker, Unit* victim, uint32&) override { StrikeInnocent(attacker, victim); }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Unit* caster = aura->GetCaster();
        if (caster != unit && !aura->GetSpellInfo()->IsPositive())
            StrikeInnocent(caster, unit);
    }

    void OnUnitDeath(Unit* unit, Unit* killer) override { KillInnocent(killer, unit); }

    void OnUnitExitCombat(Unit* unit) override
    {
        if (Player* player = unit->ToPlayer())
            ForgetAggressionOnceOutOfCombat(player);
    }
};

class ascension_mercenary_criminal_outlaw : public UnitScript
{
public:
    ascension_mercenary_criminal_outlaw()
        : UnitScript("ascension_mercenary_criminal_outlaw", true, {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (Player* player = unit->ToPlayer(); player && aura->GetId() == SPELL_CRIMINAL)
            TurnCriminal(player);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        if (Player* player = unit->ToPlayer(); player && application->GetBase()->GetId() == SPELL_CRIMINAL)
            SetOutlawed(player, false);
    }
};

class ascension_mercenary_criminal_no_retreat_spells : public AllSpellScript
{
public:
    ascension_mercenary_criminal_no_retreat_spells()
        : AllSpellScript("ascension_mercenary_criminal_no_retreat_spells", {ALLSPELLHOOK_ON_SPELL_CHECK_CAST}) { }

    void OnSpellCheckCast(Spell* spell, bool strict, SpellCastResult& result) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (result != SPELL_CAST_OK || !IsCriminal(player) || !TravelsCasterAway(spell->GetSpellInfo()))
            return;

        result = SPELL_FAILED_DONT_REPORT;
        if (strict)
            RefuseRetreat(player);
    }
};

class ascension_mercenary_criminal_no_retreat : public PlayerScript
{
public:
    ascension_mercenary_criminal_no_retreat()
        : PlayerScript("ascension_mercenary_criminal_no_retreat",
                       {PLAYERHOOK_ON_BEFORE_TELEPORT, PLAYERHOOK_CAN_LFG_TELEPORT}) { }

    bool OnPlayerBeforeTeleport(Player* player, uint32, float, float, float, float, uint32, Unit* target) override
    {
        if (!IsCriminal(player) || !SummonedByPlayer(player, target))
            return true;

        RefuseRetreat(player);
        return false;
    }

    bool OnPlayerCanLfgTeleport(Player* player) override { return !IsCriminal(player); }
};

class ascension_mercenary_criminal_outcast : public PlayerScript
{
public:
    ascension_mercenary_criminal_outcast()
        : PlayerScript("ascension_mercenary_criminal_outcast",
                       {PLAYERHOOK_CAN_INIT_TRADE, PLAYERHOOK_CAN_JOIN_IN_BATTLEGROUND_QUEUE,
                        PLAYERHOOK_CAN_JOIN_IN_ARENA_QUEUE, PLAYERHOOK_CAN_JOIN_LFG}) { }

    bool OnPlayerCanInitTrade(Player* player, Player* target) override
    {
        return !IsCriminal(player) && !IsCriminal(target);
    }

    bool OnPlayerCanJoinInBattlegroundQueue(Player* player, ObjectGuid, BattlegroundTypeId, uint8,
                                            GroupJoinBattlegroundResult& err) override
    {
        return Admit(player, err);
    }

    bool OnPlayerCanJoinInArenaQueue(Player* player, ObjectGuid, uint8, BattlegroundTypeId, uint8, uint8,
                                     GroupJoinBattlegroundResult& err) override
    {
        return Admit(player, err);
    }

    bool OnPlayerCanJoinLfg(Player* player, uint8, std::set<uint32>&, std::string const&) override
    {
        return !GroupHasCriminal(player);
    }

private:
    static bool Admit(Player* player, GroupJoinBattlegroundResult& err)
    {
        if (!GroupHasCriminal(player))
            return true;
        err = ERR_GROUP_JOIN_BATTLEGROUND_FAIL;
        return false;
    }
};
}

void AddSC_AscensionMercenaryCriminal()
{
    new ascension_mercenary_criminal_acts();
    new ascension_mercenary_criminal_outlaw();
    new ascension_mercenary_criminal_no_retreat_spells();
    new ascension_mercenary_criminal_no_retreat();
    new ascension_mercenary_criminal_outcast();
}
