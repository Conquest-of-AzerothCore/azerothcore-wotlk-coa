/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <algorithm>

namespace
{
enum ChronomancerMovement : uint32
{
    InfiniteClone = 50071,
    CloneAppearance = 45204,
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
        return ValidateSpellInfo({RewindSlow, CloneAppearance});
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
}

void AddSC_AscensionChronomancerMovement()
{
    new chronomancer_movement_contracts();
    RegisterCreatureAI(npc_ascension_infinite_clone);
    RegisterSpellScript(spell_ascension_rewind);
    RegisterSpellScript(aura_ascension_backtrack);
    RegisterSpellScript(spell_ascension_displacement);
    RegisterSpellScript(spell_ascension_waves_of_time);
}
