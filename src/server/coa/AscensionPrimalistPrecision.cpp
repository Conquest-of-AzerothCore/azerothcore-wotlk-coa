/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 EarthmotherPrecisionDebuff = 555724;

class primalist_precision_metadata : public GlobalScript
{
public:
    primalist_precision_metadata() : GlobalScript("primalist_precision_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == EarthmotherPrecisionDebuff && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_ATTACKER_SPELL_HIT_CHANCE))
            info->Effects[EFFECT_0].MiscValue = SPELL_SCHOOL_MASK_ALL;
    }
};
}

void AddSC_AscensionPrimalistPrecision()
{
    new primalist_precision_metadata();
}
