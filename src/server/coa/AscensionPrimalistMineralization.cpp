/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 MineralizationBuff = 520465;

class primalist_mineralization_metadata : public GlobalScript
{
public:
    primalist_mineralization_metadata() : GlobalScript("primalist_mineralization_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == MineralizationBuff && info->CasterAuraState == AURA_STATE_HEALTHLESS_35_PERCENT)
            info->CasterAuraState = 0;
    }
};
}

void AddSC_AscensionPrimalistMineralization()
{
    new primalist_mineralization_metadata();
}
