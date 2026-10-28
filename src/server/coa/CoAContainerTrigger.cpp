/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Item.h"
#include "Player.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "WorldSession.h"

namespace
{
constexpr uint32 SPELL_CONTAINER_TRIGGER = 93461;

class spell_coa_container_trigger : public SpellScript
{
    PrepareSpellScript(spell_coa_container_trigger);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_CONTAINER_TRIGGER && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_DUMMY;
    }

    void RefreshOpenableTemplate(SpellEffIndex effect)
    {
        PreventHitDefaultEffect(effect);
        Player* player = GetCaster()->ToPlayer();
        Item* container = GetCastItem();
        if (player && container && container->GetTemplate()->HasFlag(ITEM_FLAG_HAS_LOOT))
            player->GetSession()->SendItemQuerySingleResponse(container->GetEntry());
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_coa_container_trigger::RefreshOpenableTemplate, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};
}

void AddCoAContainerTriggerScripts()
{
    RegisterSpellScript(spell_coa_container_trigger);
}
