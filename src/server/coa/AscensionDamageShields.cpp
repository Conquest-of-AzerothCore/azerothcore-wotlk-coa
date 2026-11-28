/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include <algorithm>

class aura_ascension_damage_shield_single_bonus : public AuraScript
{
    PrepareAuraScript(aura_ascension_damage_shield_single_bonus);

    void KeepBaseAmount(AuraEffect const* effect, int32& amount, bool&)
    {
        amount = effect->GetOldAmount() / std::max<int32>(1, GetStackAmount());
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_damage_shield_single_bonus::KeepBaseAmount,
            EFFECT_ALL, SPELL_AURA_DAMAGE_SHIELD);
    }
};

void AddSC_AscensionDamageShields()
{
    RegisterSpellScript(aura_ascension_damage_shield_single_bonus);
}
