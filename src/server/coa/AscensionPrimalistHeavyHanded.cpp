/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
enum HeavyHandedSpells : uint32
{
    HeavyHandedBuff = 706345
};

class primalist_heavy_handed : public GlobalScript
{
public:
    primalist_heavy_handed() : GlobalScript("primalist_heavy_handed",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id != HeavyHandedBuff || info->SpellFamilyName != 37)
            return;

        info->Effects[EFFECT_0].TargetB = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        info->Effects[EFFECT_1].Effect = 0;
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_NONE;
    }
};
}

void AddSC_AscensionPrimalistHeavyHanded()
{
    new primalist_heavy_handed();
}
