/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 StoneTosser = 680862;

class primalist_stone_tosser : public GlobalScript
{
public:
    primalist_stone_tosser() : GlobalScript("primalist_stone_tosser", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == StoneTosser && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER &&
            info->Effects[EFFECT_0].MiscValue == 41)
            info->Effects[EFFECT_0].MiscValue = SPELLMOD_BONUS_MULTIPLIER;
    }
};
}

void AddSC_AscensionPrimalistStoneTosser()
{
    new primalist_stone_tosser();
}
