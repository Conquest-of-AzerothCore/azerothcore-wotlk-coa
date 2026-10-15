/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 RideTheWaveSpeed = 300868;

class primalist_ride_wave_metadata : public GlobalScript
{
public:
    primalist_ride_wave_metadata() : GlobalScript("primalist_ride_wave_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == RideTheWaveSpeed && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_INCREASE_SPEED))
        {
            info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
            info->Effects[EFFECT_0].TargetB = SpellImplicitTargetInfo(0);
        }
    }
};
}

void AddSC_AscensionPrimalistRideWave()
{
    new primalist_ride_wave_metadata();
}
