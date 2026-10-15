/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchHunterTargeting.h"
#include "DBCStores.h"
#include "SharedDefines.h"
#include "SpellInfo.h"

void ApplyAscensionWitchHunterTargetingContracts(SpellInfo* spellInfo)
{
    if (!spellInfo || (spellInfo->Id != 802140 && (spellInfo->Id < 803366 || spellInfo->Id > 803369)))
        return;

    SpellEffectInfo& effect = spellInfo->Effects[EFFECT_0];
    if (spellInfo->SpellFamilyName != uint32(CLASS_WITCH_HUNTER) + 6 ||
        spellInfo->SpellFamilyFlags != flag96(0, 0, 131072) || spellInfo->SchoolMask != SPELL_SCHOOL_MASK_FIRE ||
        spellInfo->DmgClass != SPELL_DAMAGE_CLASS_MELEE || spellInfo->MaxAffectedTargets ||
        effect.Effect != SPELL_EFFECT_SCHOOL_DAMAGE || effect.TargetA.GetTarget() != TARGET_UNIT_TARGET_ENEMY ||
        effect.TargetB.GetTarget() || effect.RadiusEntry || spellInfo->Effects[EFFECT_1].Effect ||
        spellInfo->Effects[EFFECT_2].Effect)
        return;

    SpellRadiusEntry const* radius = sSpellRadiusStore.LookupEntry(8);
    if (!radius || radius->RadiusMin != 5.0f || radius->RadiusPerLevel != 0.0f || radius->RadiusMax != 5.0f)
        return;

    effect.TargetA = SpellImplicitTargetInfo(TARGET_DEST_TARGET_ENEMY);
    effect.TargetB = SpellImplicitTargetInfo(TARGET_UNIT_DEST_AREA_ENEMY);
    effect.RadiusEntry = radius;
    spellInfo->_InitializeExplicitTargetMask();
}
