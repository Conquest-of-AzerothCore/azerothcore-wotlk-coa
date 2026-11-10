/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionSpellProgressionData.h"
#include "Player.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"

namespace
{
constexpr uint32 SPELL_CONJURE_THUNDERALE = 807850;
constexpr uint32 SPELL_CONJURE_THUNDER_ALE = 804763;

uint32 ThunderAleForLevel(uint8 level)
{
    uint32 spellId = SPELL_CONJURE_THUNDER_ALE;
    uint8 bestLevel = 0;
    for (AscensionProgression::Rank const& rank : AscensionProgression::Ranks)
    {
        if (rank.FirstSpellId != SPELL_CONJURE_THUNDER_ALE || rank.RequiredLevel > level || rank.RequiredLevel < bestLevel)
            continue;
        bestLevel = rank.RequiredLevel;
        spellId = rank.SpellId;
    }
    SpellInfo const* ale = sSpellMgr->GetSpellInfo(spellId);
    return ale ? ale->Effects[EFFECT_0].ItemType : 0;
}

class spell_ascension_thunderkeg_ale : public SpellScript
{
    PrepareSpellScript(spell_ascension_thunderkeg_ale);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_CONJURE_THUNDERALE && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_CREATE_ITEM;
    }

    void CreateRankedAle(SpellEffIndex effect)
    {
        Player* player = GetHitPlayer();
        if (!player)
            return;
        uint32 itemId = ThunderAleForLevel(player->GetLevel());
        if (!itemId)
            return;
        PreventHitDefaultEffect(effect);
        CreateItem(effect, itemId);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_thunderkeg_ale::CreateRankedAle, EFFECT_0, SPELL_EFFECT_CREATE_ITEM);
    }
};
}

void AddAscensionThunderkegScripts()
{
    RegisterSpellScript(spell_ascension_thunderkeg_ale);
}
