/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 EarthmotherWarden = 707514;

class primalist_earthmother_warden_metadata : public GlobalScript
{
public:
    primalist_earthmother_warden_metadata() : GlobalScript("primalist_earthmother_warden_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == EarthmotherWarden && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_ADD_FLAT_MODIFIER) &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_COOLDOWN)
            info->Effects[EFFECT_0].SpellClassMask[0] |= 64;
    }
};
}

void AddSC_AscensionPrimalistEarthmotherWarden()
{
    new primalist_earthmother_warden_metadata();
}
