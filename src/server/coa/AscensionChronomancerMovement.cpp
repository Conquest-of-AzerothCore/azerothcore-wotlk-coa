/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "CellImpl.h"
#include "Creature.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "MotionMaster.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <cmath>

namespace
{
enum ChronomancerMovement : uint32
{
    InfiniteClone = 50071,
    UnstableChronoglassNpc = 506015,
    UnstableChronoglassMagnet = 506638,
    CloneAppearance = 45204,
    InfiniteCloneAura = 704154,
    Rewind = 801294,
    RewindSlow = 572883,
    Backtrack = 706973,
    Displacement = 806727,
    WavesOfTimeKnockback = 802600
};

bool CanRecordPosition(Unit* unit)
{
    return unit && unit->IsAlive() && unit->IsInWorld() && !unit->GetTransport() && !unit->GetVehicle() &&
        !unit->IsInFlight() && (!unit->IsPlayer() || !unit->ToPlayer()->IsBeingTeleported());
}

struct npc_ascension_infinite_clone : ScriptedAI
{
    explicit npc_ascension_infinite_clone(Creature* creature) : ScriptedAI(creature) { }

    ObjectGuid owner;
    Position origin;
    uint32 health = 0;
    uint32 mana = 0;
    bool recorded = false;

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = summoner ? summoner->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_CHRONOMANCER || !CanRecordPosition(player))
            return;
        owner = player->GetGUID();
        origin = player->GetPosition();
        health = player->GetHealth();
        mana = player->GetPower(POWER_MANA);
        recorded = true;
        me->SetReactState(REACT_PASSIVE);
        me->SetUnitFlag(UNIT_FLAG_DISABLE_MOVE);
        player->CastSpell(me, CloneAppearance, true);
        player->CastSpell(player, InfiniteCloneAura, true);

        std::list<Creature*> previous;
        player->GetAllMinionsByEntry(previous, InfiniteClone);
        for (Creature* clone : previous)
            if (clone != me)
                clone->ToTempSummon()->UnSummon();
    }

    void UpdateAI(uint32) override { }
};

Creature* FindClone(Player* player)
{
    if (!player)
        return nullptr;
    std::list<Creature*> clones;
    player->GetAllMinionsByEntry(clones, InfiniteClone);
    for (Creature* clone : clones)
        if (clone->IsAlive() && clone->IsInWorld() && clone->GetMap() == player->GetMap() &&
            clone->InSamePhase(player))
            if (auto* ai = dynamic_cast<npc_ascension_infinite_clone*>(clone->AI());
                ai && ai->recorded && ai->owner == player->GetGUID())
                return clone;
    return nullptr;
}

class spell_ascension_rewind : public SpellScript
{
    PrepareSpellScript(spell_ascension_rewind);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({RewindSlow, CloneAppearance, InfiniteCloneAura});
    }

    SpellCastResult CheckClone()
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == CLASS_CHRONOMANCER && CanRecordPosition(player) && FindClone(player)
            ? SPELL_CAST_OK : SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
    }

    void Restore(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        Creature* clone = FindClone(player);
        if (!clone || !CanRecordPosition(player))
            return;
        auto* ai = dynamic_cast<npc_ascension_infinite_clone*>(clone->AI());
        Position origin = ai->origin;
        uint32 health = std::min(ai->health, player->GetMaxHealth());
        uint32 mana = std::min(ai->mana, player->GetMaxPower(POWER_MANA));
        player->CastSpell(player, RewindSlow, true);
        player->RemoveAurasDueToSpell(InfiniteCloneAura, player->GetGUID());
        clone->ToTempSummon()->UnSummon();
        player->NearTeleportTo(origin, true);
        player->SetHealth(health);
        player->SetPower(POWER_MANA, mana);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_rewind::CheckClone);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_rewind::Restore, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class aura_ascension_backtrack : public AuraScript
{
    PrepareAuraScript(aura_ascension_backtrack);

    Position origin;
    uint32 mapId = 0;
    uint32 instanceId = 0;
    bool recorded = false;

    void Record(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* target = GetTarget();
        recorded = CanRecordPosition(target);
        if (recorded)
        {
            origin = target->GetPosition();
            mapId = target->GetMapId();
            instanceId = target->GetInstanceId();
        }
    }

    void Return(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* target = GetTarget();
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE && recorded &&
            CanRecordPosition(target) && target->GetMapId() == mapId && target->GetInstanceId() == instanceId)
            target->NearTeleportTo(origin);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_backtrack::Record,
            EFFECT_1, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_backtrack::Return,
            EFFECT_1, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_displacement : public SpellScript
{
    PrepareSpellScript(spell_ascension_displacement);

    void Displace(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target || target == caster || target->IsImmuneToForcedMovement())
            return;
        Position destination = caster->GetNearPosition(2.0f, 0.0f);
        target->NearTeleportTo(destination, true);
        target->RemoveMovementImpairingAuras(true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_displacement::Displace, EFFECT_2, SPELL_EFFECT_DUMMY);
    }
};

class spell_ascension_waves_of_time : public SpellScript
{
    PrepareSpellScript(spell_ascension_waves_of_time);

    void Knock()
    {
        Unit* caster = GetCaster();
        if (caster)
            caster->CastSpell(caster, WavesOfTimeKnockback, true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_waves_of_time::Knock);
    }
};

class chronomancer_movement_contracts : public GlobalScript
{
public:
    chronomancer_movement_contracts() : GlobalScript("chronomancer_movement_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info || info->SpellFamilyName != 28)
            return;
        if (info->Id == Backtrack)
        {
            info->Effects[EFFECT_0].Effect = 0;
            info->_InitializeExplicitTargetMask();
        }
        if (info->Id == Displacement)
        {
            info->Effects[EFFECT_2].Effect = SPELL_EFFECT_DUMMY;
            info->_InitializeExplicitTargetMask();
        }
    }
};

struct npc_ascension_unstable_chronoglass : ScriptedAI
{
    explicit npc_ascension_unstable_chronoglass(Creature* creature) : ScriptedAI(creature) { }

    uint32 remainingRedirects = 3;

    void IsSummonedBy(WorldObject* summoner) override
    {
        SpellInfo const* magnet = sSpellMgr->GetSpellInfo(UnstableChronoglassMagnet);
        remainingRedirects = magnet && magnet->ProcCharges ? magnet->ProcCharges : 3;
        me->SetReactState(REACT_PASSIVE);
        me->SetUnitFlag(UNIT_FLAG_DISABLE_MOVE);
        me->SetControlled(true, UNIT_STATE_ROOT);
        me->GetMotionMaster()->Clear(false);
        me->GetMotionMaster()->MoveIdle();

        Player* player = summoner ? summoner->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_CHRONOMANCER)
            return;

        std::list<Creature*> previous;
        player->GetAllMinionsByEntry(previous, UnstableChronoglassNpc);
        for (Creature* glass : previous)
            if (glass != me)
                glass->ToTempSummon()->UnSummon();
    }

    void DamageTaken(Unit*, uint32& damage, DamageEffectType damagetype, SpellSchoolMask) override
    {
        if (remainingRedirects > 0 && damagetype != DIRECT_DAMAGE && damage >= me->GetHealth())
            damage = me->GetHealth() > 1 ? me->GetHealth() - 1 : 0;
    }

    bool ConsumeRedirect(Unit const* attacker, SpellInfo const* info)
    {
        if (!remainingRedirects)
            return false;
        --remainingRedirects;
        if (!remainingRedirects)
        {
            uint32 delayMs = 250;
            if (info && info->Speed > 0.0f && attacker)
            {
                float dist = std::max(5.0f, attacker->GetDistance(me));
                delayMs = uint32(std::floor(dist / info->Speed * 1000.0f)) + 250;
            }
            me->DespawnOrUnsummon(Milliseconds(delayMs));
        }
        return true;
    }

    void UpdateAI(uint32) override
    {
        if (me->GetMotionMaster()->GetCurrentMovementGeneratorType() != IDLE_MOTION_TYPE)
        {
            me->GetMotionMaster()->Clear(false);
            me->GetMotionMaster()->MoveIdle();
        }
    }
};

class chronomancer_chronoglass_magnet : public UnitScript
{
public:
    chronomancer_chronoglass_magnet() : UnitScript("chronomancer_chronoglass_magnet", true,
        {UNITHOOK_SPELL_MAGNET_TARGET}) { }

    Unit* SpellMagnetTarget(Unit* attacker, Unit* victim, SpellInfo const* info, bool& ignoreM2Los) override
    {
        if (!attacker || !victim || !info || info->IsPositive() || victim->GetEntry() == UnstableChronoglassNpc)
            return nullptr;
        SpellInfo const* magnet = sSpellMgr->GetSpellInfo(UnstableChronoglassMagnet);
        float radius = magnet ? magnet->Effects[EFFECT_0].CalcRadius() : 30.0f;
        if (radius <= 0.0f)
            radius = 30.0f;

        std::list<Unit*> units;
        Acore::AnyUnitInObjectRangeCheck check(victim, radius);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(victim, units, check);
        Cell::VisitObjects(victim, search, radius);
        units.sort([victim](Unit const* left, Unit const* right)
        {
            float d1 = victim->GetExactDist(left);
            float d2 = victim->GetExactDist(right);
            return d1 == d2 ? left->GetGUID() < right->GetGUID() : d1 < d2;
        });

        for (Unit* unit : units)
        {
            Creature* glass = unit->ToCreature();
            if (!glass || glass->GetEntry() != UnstableChronoglassNpc || !glass->IsAlive() || !glass->IsAIEnabled)
                continue;
            Unit* ownerUnit = glass->GetOwner();
            if (!ownerUnit)
                if (TempSummon* summon = glass->ToTempSummon())
                    ownerUnit = summon->GetSummonerUnit();
            Player* owner = ownerUnit ? ownerUnit->ToPlayer() : nullptr;
            if (!owner || owner->getClass() != CLASS_CHRONOMANCER)
                continue;
            if (victim != owner && (!owner->IsFriendlyTo(victim) || !owner->IsInRaidWith(victim)))
                continue;
            if (!attacker->IsInMap(glass) || !attacker->InSamePhase(glass))
                continue;
            if (info->CheckExplicitTarget(attacker, glass) != SPELL_CAST_OK ||
                !attacker->IsValidAttackTarget(glass, info) ||
                !glass->IsWithinLOSInMap(victim, VMAP::ModelIgnoreFlags::M2) ||
                !attacker->IsWithinLOSInMap(glass, VMAP::ModelIgnoreFlags::M2))
                continue;
            if (auto* ai = dynamic_cast<npc_ascension_unstable_chronoglass*>(glass->AI());
                ai && ai->ConsumeRedirect(attacker, info))
            {
                ignoreM2Los = true;
                return glass;
            }
        }
        return nullptr;
    }
};
}

void AddSC_AscensionChronomancerMovement()
{
    new chronomancer_movement_contracts();
    new chronomancer_chronoglass_magnet();
    RegisterCreatureAI(npc_ascension_infinite_clone);
    RegisterCreatureAI(npc_ascension_unstable_chronoglass);
    RegisterSpellScript(spell_ascension_rewind);
    RegisterSpellScript(aura_ascension_backtrack);
    RegisterSpellScript(spell_ascension_displacement);
    RegisterSpellScript(spell_ascension_waves_of_time);
}
