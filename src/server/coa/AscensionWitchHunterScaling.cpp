/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchHunterScaling.h"
#include "SharedDefines.h"
#include "SpellAuraDefines.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 SPELL_CINDER_AND_ASHES = 707317;
constexpr int32 PRIVATE_SPELL_POWER_COEFFICIENT = 41;
}

void ApplyAscensionWitchHunterScalingContracts(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->Id != SPELL_CINDER_AND_ASHES ||
        spellInfo->SpellFamilyName != uint32(CLASS_WITCH_HUNTER) + 6 || spellInfo->SpellFamilyFlags)
        return;

    SpellEffectInfo& effect = spellInfo->Effects[EFFECT_0];
    if (!effect.IsAura(SPELL_AURA_ADD_FLAT_MODIFIER) || effect.MiscValue != PRIVATE_SPELL_POWER_COEFFICIENT ||
        effect.SpellClassMask != flag96(0, 0, 131200) || effect.BasePoints != 24 || effect.DieSides != 1 ||
        effect.TargetA.GetTarget() != TARGET_UNIT_CASTER || effect.TargetB.GetTarget() ||
        spellInfo->Effects[EFFECT_1].Effect || spellInfo->Effects[EFFECT_2].Effect)
        return;

    effect.ApplyAuraName = SPELL_AURA_OVERRIDE_CLASS_SCRIPTS;
    effect.MiscValue = ASCENSION_SPELL_POWER_COEFFICIENT_FLAT;
}
