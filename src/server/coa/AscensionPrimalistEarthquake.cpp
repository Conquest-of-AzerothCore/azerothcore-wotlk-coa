/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionPrimalistEarthquake.h"
#include "Player.h"
#include "SpellAuraDefines.h"
#include "SpellMgr.h"
#include <array>

namespace
{
constexpr uint32 PRIMALIST_FAMILY = uint32(CLASS_WILDWALKER) + 6;
constexpr std::array<uint32, 6> EARTHQUAKE_RANKS =
    {520412, 520741, 520742, 520743, 520744, 520745};
}

void ApplyAscensionPrimalistEarthquakeContract(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != PRIMALIST_FAMILY)
        return;

    bool isEarthquakeRank = false;
    for (uint32 rankId : EARTHQUAKE_RANKS)
        if (spellInfo->Id == rankId)
        {
            isEarthquakeRank = true;
            break;
        }
    if (!isEarthquakeRank)
        return;

    if (spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_PERSISTENT_AREA_AURA &&
        spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE &&
        spellInfo->Effects[EFFECT_1].Effect == SPELL_EFFECT_PERSISTENT_AREA_AURA &&
        spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL)
        spellInfo->AttributesCu &= ~SPELL_ATTR0_CU_BINARY_SPELL;
}
