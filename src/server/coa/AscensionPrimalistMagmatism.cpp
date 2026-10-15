/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
enum MagmatismSpells : uint32
{
    Magmatism = 706174
};

class primalist_magmatism : public GlobalScript
{
public:
    primalist_magmatism() : GlobalScript("primalist_magmatism",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id != Magmatism || info->SpellFamilyName != 37)
            return;
        SpellEffectInfo& effect = info->Effects[EFFECT_1];
        if (!effect.IsAura(SPELL_AURA_OVERRIDE_CLASS_SCRIPTS) ||
            effect.MiscValue != ASCENSION_CLASSMASK_AURASTATE_DAMAGE || effect.MiscValueB != 10 ||
            effect.BasePoints != 29 || effect.DieSides != 1 || effect.SpellClassMask != flag96(0, 0, 128))
            return;

        effect.ApplyAuraName = SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE;
        effect.MiscValue = AURA_STATE_HEALTH_ABOVE_75_PERCENT;
        effect.MiscValueB = ASCENSION_CLASSMASK_AURASTATE_DAMAGE;
    }
};
}

void AddSC_AscensionPrimalistMagmatism()
{
    new primalist_magmatism();
}
