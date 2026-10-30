/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionHonorableCombatPolicy.h"
#include "DataMap.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <set>

namespace
{
using namespace HonorableCombat;

enum HonorableRulesetSpells : uint32
{
    SPELL_HIGH_RISK = 1004019,
    SPELL_WAR_MODE = 1004119,
    SPELL_PVE = 9931032
};

constexpr char const* HonorableStateKey = "ascension_honorable_combat";

struct HonorableState final : DataMap::Base
{
    ObjectGuid Partner;
    std::set<ObjectGuid> StartedAgainst;
    bool CreditingWin = false;
};

bool IsPvPRuleset(Unit const* unit)
{
    return unit->HasAura(SPELL_HIGH_RISK) || (unit->HasAura(SPELL_WAR_MODE) && !unit->HasAura(SPELL_PVE));
}

bool IsRulesetAura(uint32 spellId)
{
    return spellId == SPELL_HIGH_RISK || spellId == SPELL_WAR_MODE || spellId == SPELL_PVE;
}

HonorableState const* FindState(Player const* player)
{
    return player->CustomData.Get<HonorableState>(HonorableStateKey);
}

HonorableState& State(Player* player)
{
    return *player->CustomData.GetDefault<HonorableState>(HonorableStateKey);
}

ObjectGuid PartnerOf(Player const* player)
{
    HonorableState const* state = FindState(player);
    return state ? state->Partner : ObjectGuid::Empty;
}

bool Initiated(Player const* player)
{
    HonorableState const* state = FindState(player);
    return state && !state->StartedAgainst.empty();
}

bool StartedAgainst(Player const* player, Player const* target)
{
    HonorableState const* state = FindState(player);
    return state && state->StartedAgainst.count(target->GetGUID());
}

Player* OwnerPlayer(Unit const* unit)
{
    return unit ? unit->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
}

bool Dueling(Player const* first, Player const* second)
{
    return first->duel && first->duel->Opponent == second;
}

bool Engageable(Player const* attacker, Player const* target)
{
    return Dueling(attacker, target) || CanEngage(attacker->GetGUID().GetRawValue(),
        PartnerOf(attacker).GetRawValue(), target->GetGUID().GetRawValue(), PartnerOf(target).GetRawValue());
}

bool AssistBlocked(Unit const* first, Unit const* second)
{
    Player const* firstPlayer = OwnerPlayer(first);
    Player const* secondPlayer = OwnerPlayer(second);
    return firstPlayer && secondPlayer && BlocksAssist(firstPlayer->GetGUID().GetRawValue(),
        PartnerOf(firstPlayer).GetRawValue(), secondPlayer->GetGUID().GetRawValue(),
        PartnerOf(secondPlayer).GetRawValue());
}

void SendHonorableZones(Player* player)
{
    WorldPacket packet(uint16(ZonesOpcode), 4 + 4 * Zones.size());
    packet << uint32(Zones.size());
    for (uint32 zone : Zones)
        packet << zone;
    player->GetSession()->SendPacket(&packet);
}

void ClearLock(Player* player)
{
    if (HonorableState* state = player->CustomData.Get<HonorableState>(HonorableStateKey))
        state->Partner.Clear();
    player->RemoveAurasDueToSpell(CombatAura);
}

void EndLock(Player* player)
{
    ObjectGuid partner = PartnerOf(player);
    if (partner.IsEmpty())
        return;

    ClearLock(player);
    if (Player* other = ObjectAccessor::GetPlayer(*player, partner))
        if (PartnerOf(other) == player->GetGUID())
            ClearLock(other);
}

void StartLock(Player* attacker, Player* target)
{
    State(attacker).Partner = target->GetGUID();
    State(target).Partner = attacker->GetGUID();
    attacker->AddAura(CombatAura, attacker);
    target->AddAura(CombatAura, target);
}

void SyncHonorable(Player* player)
{
    if (!player->IsInWorld())
        return;

    bool eligible = Eligible(player->GetZoneId(), IsPvPRuleset(player));
    bool honorable = player->HasAura(HonorableAura);
    if (eligible && !honorable)
        player->AddAura(HonorableAura, player);
    else if (!eligible && honorable)
        player->RemoveAurasDueToSpell(HonorableAura);
}

void OnHostileAction(Player* attacker, Player* target)
{
    if (!IsHonorableZone(attacker->GetZoneId()) && !IsHonorableZone(target->GetZoneId()))
        return;

    if (Dueling(attacker, target) || PartnerOf(attacker) == target->GetGUID())
        return;

    bool attackerLocked = !PartnerOf(attacker).IsEmpty();
    if (StartsLock(target->HasAura(HonorableAura), Initiated(target), attackerLocked, !PartnerOf(target).IsEmpty()))
    {
        StartLock(attacker, target);
        return;
    }

    if (IsInitiation(attackerLocked, StartedAgainst(target, attacker)))
        State(attacker).StartedAgainst.insert(target->GetGUID());
}

void CreditWin(Player* winner, uint32 zone)
{
    HonorableState& state = State(winner);
    state.CreditingWin = true;
    winner->UpdateAchievementCriteria(ACHIEVEMENT_CRITERIA_TYPE_HONORABLE_KILL_AT_AREA, zone);
    state.CreditingWin = false;
}

class AscensionHonorableCombatUnit final : public UnitScript
{
public:
    AscensionHonorableCombatUnit() : UnitScript("AscensionHonorableCombatUnit", true,
        {UNITHOOK_ON_DAMAGE, UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE, UNITHOOK_CAN_UNIT_ATTACK,
         UNITHOOK_ON_UNIT_EXIT_COMBAT, UNITHOOK_ON_UNIT_DEATH, UNITHOOK_MODIFY_HEAL_RECEIVED}) { }

    void ModifyHealReceived(Unit* first, Unit* second, uint32& heal, SpellInfo const*) override
    {
        if (AssistBlocked(first, second))
            heal = 0;
    }

    bool CanUnitAttack(Unit const* attacker, Unit const* target, SpellInfo const*) override
    {
        Player const* attackerPlayer = OwnerPlayer(attacker);
        Player const* targetPlayer = OwnerPlayer(target);
        return !attackerPlayer || !targetPlayer || attackerPlayer == targetPlayer
            || Engageable(attackerPlayer, targetPlayer);
    }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        Player* attackerPlayer = OwnerPlayer(attacker);
        Player* victimPlayer = OwnerPlayer(victim);
        if (!attackerPlayer || !victimPlayer || attackerPlayer == victimPlayer
            || attackerPlayer->IsFriendlyTo(victimPlayer))
            return;

        if (!Engageable(attackerPlayer, victimPlayer))
        {
            damage = 0;
            return;
        }

        OnHostileAction(attackerPlayer, victimPlayer);
    }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (IsRulesetAura(aura->GetId()))
        {
            if (Player* player = unit->ToPlayer())
                SyncHonorable(player);
            return;
        }

        if (aura->GetSpellInfo()->IsPositive())
            return;

        Unit* caster = aura->GetCaster();
        Player* casterPlayer = OwnerPlayer(caster);
        Player* targetPlayer = OwnerPlayer(unit);
        if (casterPlayer && targetPlayer && casterPlayer != targetPlayer && !casterPlayer->IsFriendlyTo(targetPlayer))
            OnHostileAction(casterPlayer, targetPlayer);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* aurApp, AuraRemoveMode) override
    {
        Player* player = unit->ToPlayer();
        if (!player)
            return;

        uint32 spellId = aurApp->GetBase()->GetId();
        if (spellId == HonorableAura)
            EndLock(player);
        else if (IsRulesetAura(spellId))
            SyncHonorable(player);
    }

    void OnUnitExitCombat(Unit* unit) override
    {
        Player* player = unit->ToPlayer();
        if (!player)
            return;

        if (HonorableState* state = player->CustomData.Get<HonorableState>(HonorableStateKey))
            state->StartedAgainst.clear();

        ObjectGuid partner = PartnerOf(player);
        if (partner.IsEmpty() || !player->IsAlive())
            return;

        if (Player* other = ObjectAccessor::GetPlayer(*player, partner))
            if (!other->IsAlive())
                return;

        EndLock(player);
    }

    void OnUnitDeath(Unit* victim, Unit* killer) override
    {
        Player* loser = victim->ToPlayer();
        if (!loser)
            return;

        ObjectGuid partner = PartnerOf(loser);
        if (partner.IsEmpty())
            return;

        if (Player* winner = OwnerPlayer(killer))
            if (IsWin(winner->GetGUID().GetRawValue(), partner.GetRawValue(), loser->GetZoneId()))
                CreditWin(winner, loser->GetZoneId());

        EndLock(loser);
    }
};

class AscensionHonorableCombatSpells final : public AllSpellScript
{
public:
    AscensionHonorableCombatSpells() : AllSpellScript("AscensionHonorableCombatSpells",
        {ALLSPELLHOOK_ON_SPELL_CHECK_CAST}) { }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        Unit* target = spell->m_targets.GetUnitTarget();
        if (result == SPELL_CAST_OK && target && spell->GetSpellInfo()->IsPositive()
            && AssistBlocked(spell->GetCaster(), target))
            result = SPELL_FAILED_BAD_TARGETS;
    }
};

class AscensionHonorableCombatPlayer final : public PlayerScript
{
public:
    AscensionHonorableCombatPlayer() : PlayerScript("AscensionHonorableCombatPlayer",
        {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_UPDATE_ZONE,
         PLAYERHOOK_ON_BEFORE_CRITERIA_PROGRESS}) { }

    void OnPlayerLogin(Player* player) override
    {
        SendHonorableZones(player);
        SyncHonorable(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        EndLock(player);
    }

    void OnPlayerUpdateZone(Player* player, uint32, uint32) override
    {
        SyncHonorable(player);
    }

    bool OnPlayerBeforeCriteriaProgress(Player* player, AchievementCriteriaEntry const* criteria) override
    {
        if (!IsWinCriteria(criteria->ID))
            return true;

        HonorableState const* state = FindState(player);
        return state && state->CreditingWin;
    }
};
}

void AddSC_AscensionHonorableCombat()
{
    new AscensionHonorableCombatUnit();
    new AscensionHonorableCombatSpells();
    new AscensionHonorableCombatPlayer();
}
