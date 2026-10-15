/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionReaperScytheRush.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 REAPER_SPELL_FAMILY = 36;
constexpr uint32 SPELL_REAPER_SCYTHE_RUSH = 500359;

constexpr float REAPER_SCYTHE_RUSH_SPEED = 200.0f;
}

void ApplyAscensionReaperScytheRushContracts(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->Id != SPELL_REAPER_SCYTHE_RUSH ||
        spellInfo->SpellFamilyName != REAPER_SPELL_FAMILY ||
        spellInfo->SpellFamilyFlags != flag96(0, 512, 0))
        return;

    SpellEffectInfo const& charge = spellInfo->Effects[EFFECT_0];
    if (charge.Effect != SPELL_EFFECT_CHARGE || charge.TargetA.GetTarget() != TARGET_UNIT_TARGET_ENEMY ||
        spellInfo->Effects[EFFECT_1].Effect || spellInfo->Effects[EFFECT_2].Effect)
        return;

    if (!spellInfo->Speed)
        spellInfo->Speed = REAPER_SCYTHE_RUSH_SPEED;
}
