/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionNightmareDamageTaken.h"
#include "AscensionNightmareDamageTakenPolicy.h"
#include "SpellInfo.h"

void ApplyAscensionNightmareDamageTakenContracts(SpellInfo* spellInfo)
{
    if (!spellInfo || !NightmareDamageTaken::IsLevelScaledAura(spellInfo->Id))
        return;

    for (SpellEffectInfo& effect : spellInfo->Effects)
    {
        if (effect.ApplyAuraName != SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN)
            continue;

        NightmareDamageTaken::DamageTakenEffect const current{
            effect.BasePoints, effect.RealPointsPerLevel, effect.MiscValue };
        if (std::optional<std::int32_t> flat = NightmareDamageTaken::FlatBasePoints(spellInfo->Id, current))
        {
            effect.BasePoints = *flat;
            effect.RealPointsPerLevel = 0.0f;
        }
    }
}
