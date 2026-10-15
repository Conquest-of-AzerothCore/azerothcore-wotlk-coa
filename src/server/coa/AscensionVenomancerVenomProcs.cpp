/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionVenomancerVenomProcs.h"
#include "AscensionVenomancerVenomData.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"

namespace
{
using AscensionVenomancerVenomData::Activation;

Activation const* FindActivation(uint32 id)
{
    for (Activation const& entry : AscensionVenomancerVenomData::ACTIVATIONS)
        if (entry.Id == id)
            return &entry;

    return nullptr;
}

bool IsActivation(SpellInfo const* info)
{
    Activation const* entry = info ? FindActivation(info->Id) : nullptr;
    if (!entry || info->SpellFamilyName != uint32(CLASS_PROPHET) + 6 ||
        info->SpellFamilyFlags != flag96(0, entry->FamilyMask1, 268435456) ||
        info->GetDuration() != 7200000 || info->ProcFlags || info->ProcCharges ||
        info->ProcChance != entry->Chance || info->StackAmount != entry->Stacks ||
        info->Effects[EFFECT_2].Effect)
        return false;

    SpellEffectInfo const& effect = info->Effects[EFFECT_0];
    return effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL &&
        effect.TriggerSpell == entry->Helper && !effect.BasePoints && !effect.DieSides &&
        !effect.RealPointsPerLevel && !effect.Amplitude && !effect.MiscValue && !effect.MiscValueB &&
        !effect.SpellClassMask && effect.TargetA.GetTarget() == TARGET_UNIT_CASTER &&
        !effect.TargetB.GetTarget();
}

bool IsHelper(SpellInfo const* info, uint32 id)
{
    if (!info || info->Id != id || info->SpellFamilyName != uint32(CLASS_PROPHET) + 6 ||
        info->SpellFamilyFlags[0] || info->SpellFamilyFlags[1] != 32768 || info->Effects[EFFECT_2].Effect)
        return false;

    SpellEffectInfo const& effect = info->Effects[EFFECT_0];
    if (effect.Effect != SPELL_EFFECT_APPLY_AURA || effect.TriggerSpell)
        return false;

    switch (id)
    {
        case 630869:
            return effect.ApplyAuraName == SPELL_AURA_PERIODIC_HEAL && effect.Amplitude == 2000 &&
                effect.TargetA.GetTarget() == TARGET_UNIT_DEST_AREA_ALLY && !effect.TargetB.GetTarget() &&
                info->MaxAffectedTargets == 1 && info->GetDuration() == 6000;
        case 805894:
            return effect.ApplyAuraName == SPELL_AURA_MOD_MELEE_RANGED_HASTE &&
                effect.TargetA.GetTarget() == TARGET_UNIT_CASTER && !effect.TargetB.GetTarget() &&
                info->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_HASTE_SPELLS &&
                info->GetDuration() == 6000 && info->StackAmount == 3;
        case 805895:
            return effect.ApplyAuraName == SPELL_AURA_MOD_DECREASE_SPEED &&
                effect.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY &&
                effect.TargetB.GetTarget() == TARGET_UNIT_DEST_AREA_ENEMY && info->GetDuration() == 8000;
        case 805896:
            return effect.ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE && effect.Amplitude == 1000 &&
                effect.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY && !effect.TargetB.GetTarget() &&
                info->GetDuration() == 6000;
        case 805897:
            return effect.ApplyAuraName == SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK &&
                effect.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY && !effect.TargetB.GetTarget() &&
                info->GetDuration() == 8000;
        case 706000:
            return effect.ApplyAuraName == SPELL_AURA_ASCENSION_MOD_ATTACK_POWER_FLAT &&
                effect.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY && !effect.TargetB.GetTarget() &&
                info->Effects[EFFECT_1].Effect == SPELL_EFFECT_SCHOOL_DAMAGE && info->GetDuration() == 8000;
        default:
            return false;
    }
}

bool IsEnemy(Player* owner, Unit* target, SpellInfo const* helper)
{
    return target && target != owner && target->IsInWorld() && target->IsAlive() &&
        owner->IsInMap(target) && owner->IsValidAttackTarget(target, helper);
}

Unit* SelectEnemy(Player* owner, Spell const* source, SpellInfo const* helper)
{
    Unit* explicitTarget = source->m_targets.GetUnitTarget();
    if (IsEnemy(owner, explicitTarget, helper))
        return explicitTarget;

    Unit* chosen = nullptr;
    uint32 eligible = 0;
    for (TargetInfo const& entry : *source->GetUniqueTargetInfo())
    {
        Unit* target = ObjectAccessor::GetUnit(*owner, entry.targetGUID);
        if (entry.effectMask && IsEnemy(owner, target, helper) && urand(1, ++eligible) == 1)
            chosen = target;
    }

    return chosen;
}

class aura_ascension_venomancer_venom_proc : public AuraScript
{
    PrepareAuraScript(aura_ascension_venomancer_venom_proc);

    bool Validate(SpellInfo const* info) override
    {
        Activation const* entry = info ? FindActivation(info->Id) : nullptr;
        return entry && IsActivation(info) && ValidateSpellInfo({entry->Helper});
    }

    bool CheckCast(ProcEventInfo& event)
    {
        Player* owner = GetTarget() ? GetTarget()->ToPlayer() : nullptr;
        Spell const* source = event.GetProcSpell();
        return owner && owner->getClass() == CLASS_PROPHET && GetCasterGUID() == owner->GetGUID() &&
            GetUnitOwner() == owner && !GetAura()->IsRemoved() && !GetAura()->IsExpired() &&
            IsActivation(GetSpellInfo()) && event.GetActor() == owner && source && !source->IsTriggered() &&
            source->GetCaster() == owner && source->GetOriginalCaster() == owner &&
            event.GetSpellPhaseMask() == PROC_SPELL_PHASE_CAST && !event.GetDamageInfo() && !event.GetHealInfo() &&
            (GetId() != 805776 || !source->GetSpellInfo()->IsPositive());
    }

    void Trigger(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (!CheckCast(event))
            return;

        Player* owner = GetTarget()->ToPlayer();
        Activation const* entry = FindActivation(GetId());
        SpellInfo const* helper = sSpellMgr->GetSpellInfo(entry->Helper);
        if (!IsHelper(helper, entry->Helper))
            return;

        Spell const* source = event.GetProcSpell();
        SpellCastTargets targets;
        if (entry->Helper == 805894)
            targets.SetUnitTarget(owner);
        else if (entry->Helper == 630869)
        {
            if (Unit* center = source->m_targets.GetUnitTarget())
                targets.SetDst(*center);
            else if (source->m_targets.HasDst())
                targets.SetDst(source->m_targets);
            else
                targets.SetDst(*owner);
        }
        else
        {
            Unit* enemy = SelectEnemy(owner, source, helper);
            if (!IsEnemy(owner, enemy, helper))
                return;

            targets.SetUnitTarget(enemy);
            if (entry->Helper == 805895)
                targets.SetDst(*enemy);
        }

        owner->CastSpell(targets, helper, nullptr, TRIGGERED_FULL_MASK, nullptr, effect, owner->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_venomancer_venom_proc::CheckCast);
        OnEffectProc += AuraEffectProcFn(aura_ascension_venomancer_venom_proc::Trigger,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
}

void AddAscensionVenomancerVenomProcScripts()
{
    RegisterSpellScript(aura_ascension_venomancer_venom_proc);
}
