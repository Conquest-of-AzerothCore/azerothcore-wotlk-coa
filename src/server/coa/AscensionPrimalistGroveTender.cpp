/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
enum GroveTenderSpells : uint32
{
    GroveTender = 706148
};

class primalist_grove_tender_metadata : public GlobalScript
{
public:
    primalist_grove_tender_metadata() : GlobalScript("primalist_grove_tender_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == GroveTender && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_ADD_PCT_MODIFIER) &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_COOLDOWN)
            info->Effects[EFFECT_0].SpellClassMask[0] |= 64;
    }
};

}

void AddSC_AscensionPrimalistGroveTender()
{
    new primalist_grove_tender_metadata();
}
