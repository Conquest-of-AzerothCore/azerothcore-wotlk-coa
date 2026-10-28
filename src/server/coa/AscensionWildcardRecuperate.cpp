/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "DBCStructure.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 SPELL_RECUPERATE = 965425;
constexpr SpellDurationEntry RecuperateDuration = {37, {0, 0, 15000}};

class wildcard_recuperate_duration : public GlobalScript
{
public:
    wildcard_recuperate_duration() : GlobalScript("wildcard_recuperate_duration",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id != SPELL_RECUPERATE || info->SpellFamilyName != SPELLFAMILY_ROGUE || !info->NeedsComboPoints() ||
            !info->DurationEntry || info->DurationEntry->ID != RecuperateDuration.ID ||
            info->GetDuration() != 1 || info->GetMaxDuration() != 1 ||
            !info->Effects[EFFECT_0].IsAura(SPELL_AURA_OBS_MOD_HEALTH) ||
            info->Effects[EFFECT_0].Amplitude != 3000)
            return;
        info->DurationEntry = &RecuperateDuration;
    }
};
}

void AddSC_AscensionWildcardRecuperate()
{
    new wildcard_recuperate_duration();
}
