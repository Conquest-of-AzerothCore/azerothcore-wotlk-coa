/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
enum ValkyrieSpells : uint32
{
    SPELL_ARBITER_OF_GRACE = 301313,
    SPELL_GLORIOUS_EXECUTION_MANA_PASSIVE = 807451,
    SPELL_ARBITER_OF_LIGHT = 302914,
    SPELL_GAVEL_OF_LIGHT_PASSIVE = 707521,
};

class sun_cleric_valkyrie_metadata : public GlobalScript
{
public:
    sun_cleric_valkyrie_metadata() : GlobalScript("sun_cleric_valkyrie_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 33)
            return;
        if (info->Id == SPELL_ARBITER_OF_GRACE)
            info->Effects[EFFECT_0].BasePoints = 14;
        if (info->Id == SPELL_ARBITER_OF_LIGHT)
            info->Effects[EFFECT_0].BasePoints = 99;
    }
};
}

void AddSC_AscensionSunClericValkyrie()
{
    new sun_cleric_valkyrie_metadata();
}
