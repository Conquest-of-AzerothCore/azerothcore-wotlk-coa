/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 GroveGuardianAllies = 505208;

class primalist_grove_metadata : public GlobalScript
{
public:
    primalist_grove_metadata() : GlobalScript("primalist_grove_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id != GroveGuardianAllies || info->SpellFamilyName != 37)
            return;
        for (SpellEffectInfo& effect : info->Effects)
            if (effect.Effect == SPELL_EFFECT_PERSISTENT_AREA_AURA &&
                effect.TargetA.GetTarget() == TARGET_UNIT_DEST_AREA_ALLY && effect.TargetB.GetTarget() == 0)
                effect.TargetB = SpellImplicitTargetInfo(TARGET_UNIT_DEST_AREA_ALLY);
        info->_InitializeExplicitTargetMask();
    }
};
}

void AddSC_AscensionPrimalistGrove()
{
    new primalist_grove_metadata();
}
