/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 WildCarnageBuff = 800041;

class primalist_wild_carnage_metadata : public GlobalScript
{
public:
    primalist_wild_carnage_metadata() : GlobalScript("primalist_wild_carnage_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == WildCarnageBuff && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_ADD_FLAT_MODIFIER) &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_JUMP_TARGETS)
            info->Effects[EFFECT_0].BasePoints = 3;
    }
};
}

void AddSC_AscensionPrimalistWildCarnage()
{
    new primalist_wild_carnage_metadata();
}
