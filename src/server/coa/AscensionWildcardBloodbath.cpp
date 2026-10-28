/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"

namespace
{
class aura_ascension_wildcard_bloodbath_damage : public AuraScript
{
    PrepareAuraScript(aura_ascension_wildcard_bloodbath_damage);

    void SpreadDamage(AuraEffect const* effect, int32& amount, bool& canBeRecalculated)
    {
        int32 const ticks = effect->GetTotalTicks();
        if (ticks > 0)
            amount /= ticks;
        canBeRecalculated = false;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_wildcard_bloodbath_damage::SpreadDamage,
            EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
    }
};
}

void AddSC_AscensionWildcardBloodbath()
{
    RegisterSpellScript(aura_ascension_wildcard_bloodbath_damage);
}
