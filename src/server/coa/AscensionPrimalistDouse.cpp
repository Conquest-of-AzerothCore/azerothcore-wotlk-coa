/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
enum DouseSpells : uint32
{
    DouseDamage = 807559,
    Doused = 803514
};

class primalist_douse_metadata : public GlobalScript
{
public:
    primalist_douse_metadata() : GlobalScript("primalist_douse_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == DouseDamage && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
        {
            info->Effects[EFFECT_0].BasePoints = -1;
            info->Effects[EFFECT_0].DieSides = 1;
        }
        if (info->Id == Doused && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_1].IsAura(SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN))
            info->Effects[EFFECT_1].BasePoints = 1;
    }
};
}

void AddSC_AscensionPrimalistDouse()
{
    new primalist_douse_metadata();
}
