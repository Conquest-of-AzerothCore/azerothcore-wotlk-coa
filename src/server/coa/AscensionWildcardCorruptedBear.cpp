/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum CorruptedBearSpells : uint32
{
    CorruptedBear = 271403,
    CorruptedBearVisualAndPenalty = 271408
};

bool IsBear(Unit const* target)
{
    return target->GetShapeshiftForm() == FORM_BEAR || target->GetShapeshiftForm() == FORM_DIREBEAR;
}

void SynchronizeBear(Unit* target)
{
    if (IsBear(target) && target->HasAura(CorruptedBear))
    {
        if (!target->HasAura(CorruptedBearVisualAndPenalty, target->GetGUID()))
            target->CastSpell(target, CorruptedBearVisualAndPenalty, TRIGGERED_FULL_MASK);
    }
    else
        target->RemoveAurasDueToSpell(CorruptedBearVisualAndPenalty, target->GetGUID());
}

class aura_ascension_wildcard_corrupted_bear : public AuraScript
{
    PrepareAuraScript(aura_ascension_wildcard_corrupted_bear);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({CorruptedBearVisualAndPenalty}); }

    bool CheckProc(ProcEventInfo& event)
    {
        DamageInfo const* damage = event.GetDamageInfo();
        return IsBear(GetTarget()) && event.GetActor() == GetTarget() && damage && damage->GetDamage();
    }

    void Synchronize(AuraEffect const*, AuraEffectHandleModes)
    {
        SynchronizeBear(GetTarget());
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(CorruptedBearVisualAndPenalty, GetTarget()->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_wildcard_corrupted_bear::CheckProc);
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_wildcard_corrupted_bear::Synchronize,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_wildcard_corrupted_bear::Remove,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_wildcard_corrupted_bear_form : public AuraScript
{
    PrepareAuraScript(aura_ascension_wildcard_corrupted_bear_form);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({CorruptedBear, CorruptedBearVisualAndPenalty});
    }

    void Synchronize(AuraEffect const*, AuraEffectHandleModes)
    {
        SynchronizeBear(GetTarget());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_wildcard_corrupted_bear_form::Synchronize,
            EFFECT_0, SPELL_AURA_MOD_SHAPESHIFT, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_wildcard_corrupted_bear_form::Synchronize,
            EFFECT_0, SPELL_AURA_MOD_SHAPESHIFT, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionWildcardCorruptedBear()
{
    RegisterSpellScript(aura_ascension_wildcard_corrupted_bear);
    RegisterSpellScript(aura_ascension_wildcard_corrupted_bear_form);
}
