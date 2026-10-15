/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "DBCStores.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 SPELL_KEEPERS_SCROLL_STEADFAST = 91770;
constexpr uint32 STEADFAST_DURATION_ONE_HOUR = 42;

class ascension_keepers_scroll_steadfast : public GlobalScript
{
public:
    ascension_keepers_scroll_steadfast()
        : GlobalScript("ascension_keepers_scroll_steadfast", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info || info->Id != SPELL_KEEPERS_SCROLL_STEADFAST)
            return;

        SpellEffectInfo& effect = info->Effects[EFFECT_0];
        if (effect.Effect != SPELL_EFFECT_DUMMY)
            return;

        effect.Effect = SPELL_EFFECT_APPLY_AURA;
        effect.ApplyAuraName = SPELL_AURA_MOD_MOUNTED_SPEED_NOT_STACK;
        effect.BasePoints = 24;
        effect.DieSides = 1;
        info->DurationEntry = sSpellDurationStore.LookupEntry(STEADFAST_DURATION_ONE_HOUR);
    }
};
}

void AddSC_AscensionKeepersScrollSteadfast()
{
    new ascension_keepers_scroll_steadfast();
}
