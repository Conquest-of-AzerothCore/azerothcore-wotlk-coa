/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 RushOfTheHunt = 300691;

class primalist_rush_hunt_metadata : public GlobalScript
{
public:
    primalist_rush_hunt_metadata() : GlobalScript("primalist_rush_hunt_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id != RushOfTheHunt || info->SpellFamilyName != 37)
            return;
        SpellEffectInfo& effect = info->Effects[EFFECT_0];
        if (effect.IsAura(SPELL_AURA_OVERRIDE_CLASS_SCRIPTS) &&
            effect.MiscValue == ASCENSION_CLASSMASK_AURASTATE_DAMAGE &&
            effect.MiscValueB == AURA_STATE_BLEEDING && effect.SpellClassMask == flag96(1, 0, 64))
        {
            effect.ApplyAuraName = SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE;
            effect.MiscValue = AURA_STATE_BLEEDING;
            effect.MiscValueB = ASCENSION_CLASSMASK_AURASTATE_DAMAGE;
        }
    }
};
}

void AddSC_AscensionPrimalistRushHunt()
{
    new primalist_rush_hunt_metadata();
}
