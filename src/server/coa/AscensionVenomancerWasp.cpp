/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum WaspFormSpells : uint32
{
    SPELL_WASP_FORM = 805141,
    SPELL_WASP_FORM_FLIGHT = 805142
};

class aura_ascension_venomancer_wasp_form : public AuraScript
{
    PrepareAuraScript(aura_ascension_venomancer_wasp_form);

public:
    explicit aura_ascension_venomancer_wasp_form(uint32 flight = SPELL_WASP_FORM_FLIGHT) : _flight(flight) { }

private:
    uint32 const _flight;

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({_flight});
    }

    void GrantFlight(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* target = GetTarget();
        if (!target->HasAura(_flight))
            target->CastSpell(target, _flight, true);
    }

    void RemoveFlight(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(_flight);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_venomancer_wasp_form::GrantFlight, EFFECT_0,
            SPELL_AURA_MOD_SHAPESHIFT, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_venomancer_wasp_form::RemoveFlight, EFFECT_0,
            SPELL_AURA_MOD_SHAPESHIFT, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionVenomancerWasp()
{
    RegisterSpellScript(aura_ascension_venomancer_wasp_form);
    RegisterSpellScriptWithArgs(aura_ascension_venomancer_wasp_form,
        "aura_ascension_venomancer_venomwing", 520330);
}
