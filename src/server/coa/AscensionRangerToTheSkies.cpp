/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Log.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 SPELL_TO_THE_SKIES = 301365;
constexpr uint32 RANGER_FAMILY = 27;
constexpr uint32 BUSHCRAFT_GLIDER_FLAG = 1073741824;
constexpr int32 GLIDER_COOLDOWN_REDUCTION_MS = -30000;

bool IsGliderCooldownReduction(SpellInfo const* info, SpellEffectInfo const& cooldown)
{
    bool const spellModifier = cooldown.ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER ||
        cooldown.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER;
    return info->SpellFamilyName == RANGER_FAMILY && cooldown.Effect == SPELL_EFFECT_APPLY_AURA && spellModifier &&
        cooldown.MiscValue == SPELLMOD_COOLDOWN && cooldown.CalcValue() == GLIDER_COOLDOWN_REDUCTION_MS &&
        cooldown.SpellClassMask == flag96(0, 0, BUSHCRAFT_GLIDER_FLAG);
}

class ranger_to_the_skies_contract : public GlobalScript
{
public:
    ranger_to_the_skies_contract() : GlobalScript("ranger_to_the_skies_contract",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info || info->Id != SPELL_TO_THE_SKIES)
            return;
        SpellEffectInfo& cooldown = info->Effects[EFFECT_0];
        if (IsGliderCooldownReduction(info, cooldown))
            cooldown.ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
        else
            LOG_ERROR("coa", "Skipped unexpected To The Skies! record {}", info->Id);
    }
};
}

void AddSC_AscensionRangerToTheSkies()
{
    new ranger_to_the_skies_contract();
}
