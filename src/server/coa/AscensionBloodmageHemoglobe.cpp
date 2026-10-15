/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBloodmageHemoglobe.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 BLOODMAGE_SPELL_FAMILY = 26;
constexpr uint32 HEMOPULSE = 524906;
}

void ApplyAscensionBloodmageHemoglobeContract(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->Id != HEMOPULSE || spellInfo->SpellFamilyName != BLOODMAGE_SPELL_FAMILY ||
        spellInfo->SpellLevel != 35 || spellInfo->BaseLevel != 35 || spellInfo->MaxLevel != 60)
        return;

    SpellEffectInfo const& heal = spellInfo->Effects[EFFECT_0];
    if (heal.Effect != SPELL_EFFECT_HEAL)
        return;

    spellInfo->IgnoreSpellLevelPenalty = true;
}
