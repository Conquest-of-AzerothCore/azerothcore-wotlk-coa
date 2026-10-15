/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace
{
enum DreamslipSpells : uint32
{
    Dreamslip = 805867,
    RapidRegeneration = 804315
};

class primalist_dreamslip_metadata : public GlobalScript
{
public:
    primalist_dreamslip_metadata() : GlobalScript("primalist_dreamslip_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == Dreamslip && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_1].IsAura(SPELL_AURA_PERIODIC_TRIGGER_SPELL) &&
            info->Effects[EFFECT_1].TriggerSpell == RapidRegeneration)
            info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_PACIFY_SILENCE;
    }
};

class aura_ascension_dreamslip : public AuraScript
{
    PrepareAuraScript(aura_ascension_dreamslip);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({RapidRegeneration}); }

    void Periodic(AuraEffect const*, bool& periodic, int32& amplitude)
    {
        periodic = true;
        amplitude = GetSpellInfo()->Effects[EFFECT_1].Amplitude;
    }

    void Recover(AuraEffect const* effect)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), RapidRegeneration, TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_ascension_dreamslip::Periodic,
            EFFECT_1, SPELL_AURA_MOD_PACIFY_SILENCE);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_dreamslip::Recover,
            EFFECT_1, SPELL_AURA_MOD_PACIFY_SILENCE);
    }
};
}

void AddSC_AscensionPrimalistDreamslip()
{
    new primalist_dreamslip_metadata();
    RegisterSpellScript(aura_ascension_dreamslip);
}
