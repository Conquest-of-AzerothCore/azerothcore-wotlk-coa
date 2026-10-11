/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum DarkIntentSpells : uint32
{
    DarkIntentCrit = 275496,
    DarkIntentNonCrit = 275503
};

class aura_wildcard_dark_intent : public AuraScript
{
    PrepareAuraScript(aura_wildcard_dark_intent);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({DarkIntentCrit, DarkIntentNonCrit});
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        return eventInfo.GetActionTarget() && damage && damage->GetDamage();
    }

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        bool const critical = eventInfo.GetHitMask() & PROC_HIT_CRITICAL;
        GetTarget()->CastSpell(eventInfo.GetActionTarget(), critical ? DarkIntentCrit : DarkIntentNonCrit, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_dark_intent::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_dark_intent::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
}

void AddSC_AscensionWildcardDarkIntent()
{
    RegisterSpellScript(aura_wildcard_dark_intent);
}
