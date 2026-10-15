/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"

#include <algorithm>
#include <limits>

namespace
{
enum SacredGroveSpells : uint32
{
    SacredGrove = 800180,
    GroveRecovery = 800179
};

class primalist_sacred_grove_metadata : public GlobalScript
{
public:
    primalist_sacred_grove_metadata() : GlobalScript("primalist_sacred_grove_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 37)
            return;
        if (info->Id == SacredGrove)
        {
            SpellEffectInfo& periodic = info->Effects[EFFECT_1];
            periodic.ApplyAuraName = SPELL_AURA_PERIODIC_TRIGGER_SPELL;
            periodic.TriggerSpell = GroveRecovery;
            periodic.Amplitude = 2000;
            periodic.TargetB = SpellImplicitTargetInfo(TARGET_DEST_DYNOBJ_ALLY);
            SpellEffectInfo& healing = info->Effects[EFFECT_2];
            healing.Effect = SPELL_EFFECT_PERSISTENT_AREA_AURA;
            healing.ApplyAuraName = SPELL_AURA_MOD_HEALING_PCT;
            healing.BasePoints = 24;
            healing.DieSides = 1;
            healing.TargetA = periodic.TargetA;
            healing.TargetB = periodic.TargetB;
            healing.RadiusEntry = periodic.RadiusEntry;
            healing.MiscValue = SPELL_SCHOOL_MASK_ALL;
        }
        else if (info->Id == GroveRecovery)
        {
            for (SpellEffectInfo& effect : info->Effects)
            {
                if (effect.Effect == SPELL_EFFECT_HEAL_PCT)
                    effect.Effect = SPELL_EFFECT_HEAL;
                else if (effect.Effect == SPELL_EFFECT_ENERGIZE_PCT)
                    effect.Effect = SPELL_EFFECT_ENERGIZE;
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
            }
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
        }
    }
};

class aura_ascension_sacred_grove : public AuraScript
{
    PrepareAuraScript(aura_ascension_sacred_grove);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({GroveRecovery}); }

    bool Check(Unit* target)
    {
        return GetAura()->GetApplicationOfTarget(target->GetGUID()) ||
            GetAura()->GetApplicationMap().size() < GetSpellInfo()->MaxAffectedTargets;
    }

    void Recover(AuraEffect const* effect)
    {
        PreventDefaultAction();
        if (Unit* caster = GetCaster())
            caster->CastSpell(GetTarget(), GroveRecovery, TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoCheckAreaTarget += AuraCheckAreaTargetFn(aura_ascension_sacred_grove::Check);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_sacred_grove::Recover,
            EFFECT_1, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

class spell_ascension_sacred_grove_recovery : public SpellScript
{
    PrepareSpellScript(spell_ascension_sacred_grove_recovery);

    void Amount(SpellEffIndex index)
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        bool health = index == EFFECT_0;
        Powers power = index == EFFECT_1 ? POWER_MANA : POWER_RAGE;
        uint64 maximum = health ? target->GetMaxHealth() : target->GetMaxPower(power);
        uint64 current = health ? target->GetHealth() : target->GetPower(power);
        uint64 amount = (maximum - std::min(current, maximum)) * std::clamp(GetEffectValue(), 0, 100) / 100;
        SetEffectValue(int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_sacred_grove_recovery::Amount,
            EFFECT_0, SPELL_EFFECT_HEAL);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_sacred_grove_recovery::Amount,
            EFFECT_1, SPELL_EFFECT_ENERGIZE);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_sacred_grove_recovery::Amount,
            EFFECT_2, SPELL_EFFECT_ENERGIZE);
    }
};
}

void AddSC_AscensionPrimalistSacredGrove()
{
    new primalist_sacred_grove_metadata();
    RegisterSpellScript(aura_ascension_sacred_grove);
    RegisterSpellScript(spell_ascension_sacred_grove_recovery);
}
