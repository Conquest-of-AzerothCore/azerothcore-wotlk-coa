/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <array>

namespace
{
constexpr std::array<uint32, 4> CatFormAbilityAuras = {9726361, 9726362, 9726363, 9726364};

class aura_hero_cat_form_abilities : public AuraScript
{
    PrepareAuraScript(aura_hero_cat_form_abilities);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo(CatFormAbilityAuras);
    }

    void AddAbilityAuras(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || player->getClass() != CLASS_HERO)
            return;

        for (uint32 aura : CatFormAbilityAuras)
            player->CastSpell(player, aura, true);
    }

    void RemoveAbilityAuras(AuraEffect const*, AuraEffectHandleModes)
    {
        for (uint32 aura : CatFormAbilityAuras)
            GetTarget()->RemoveAurasDueToSpell(aura);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_hero_cat_form_abilities::AddAbilityAuras, EFFECT_0,
            SPELL_AURA_MOD_SHAPESHIFT, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_hero_cat_form_abilities::RemoveAbilityAuras, EFFECT_0,
            SPELL_AURA_MOD_SHAPESHIFT, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionHeroCatFormAbilities()
{
    RegisterSpellScript(aura_hero_cat_form_abilities);
}
