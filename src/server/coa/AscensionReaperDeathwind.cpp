/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionReaperDeathwind.h"
#include "SpellInfo.h"
#include <array>

namespace
{
constexpr uint32 REAPER_SPELL_FAMILY = 36;

struct DeathwindRank
{
    uint32 Id;
    uint32 SpellLevel;
    uint32 MaxLevel;
};

constexpr std::array<DeathwindRank, 7> DEATHWIND_RANKS =
{{
    {800174, 16, 22},
    {502989, 24, 29},
    {502990, 31, 36},
    {502991, 38, 43},
    {502992, 45, 50},
    {502993, 52, 57},
    {502994, 59, 64}
}};
}

void ApplyAscensionReaperDeathwindContracts(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != REAPER_SPELL_FAMILY ||
        spellInfo->SpellFamilyFlags != flag96(0, 536870912, 0))
        return;

    SpellEffectInfo const& leech = spellInfo->Effects[EFFECT_0];
    if (leech.Effect != SPELL_EFFECT_PERSISTENT_AREA_AURA || leech.ApplyAuraName != SPELL_AURA_PERIODIC_LEECH ||
        leech.Amplitude != 2000 || leech.TargetA.GetTarget() != TARGET_UNIT_DEST_AREA_ENEMY ||
        leech.TargetB.GetTarget() || leech.RealPointsPerLevel || leech.TriggerSpell)
        return;

    for (DeathwindRank const& rank : DEATHWIND_RANKS)
    {
        if (spellInfo->Id != rank.Id)
            continue;

        if (spellInfo->SpellLevel == rank.SpellLevel && spellInfo->BaseLevel == rank.SpellLevel &&
            spellInfo->MaxLevel == rank.MaxLevel)
            spellInfo->IgnoreSpellLevelPenalty = true;
        return;
    }
}
