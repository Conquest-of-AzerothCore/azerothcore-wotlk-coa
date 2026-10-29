/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWarcraftRebornHunter.h"
#include "AscensionWarcraftRebornRules.h"
#include "SpellInfo.h"
#include <algorithm>
#include <array>
#include <cmath>

namespace AscensionWarcraftReborn
{
namespace
{
constexpr std::array<uint32, 5> MORTAL_SHOTS = { 1119485, 1119487, 1119488, 1119489, 1119490 };
constexpr std::array<uint32, 3> HAWK_EYE = { 1119498, 1119499, 1119500 };
constexpr uint32 IMPROVED_STEADY_SHOT_RANK_3 = 1153224;
constexpr uint32 IMPROVED_STEADY_SHOT_BUFF = 1153220;
constexpr uint32 AUTO_SHOT_FLAG = 0x00000001;
constexpr uint32 KILL_SHOT_FLAG = 0x00800000;

constexpr std::array<uint32, 8> CARVE = { 1101500, 1101501, 1101502, 1101503, 1101504, 1101505, 1101506, 1101507 };
constexpr uint32 CARVE_FLAG2 = 0x10000000;

template <std::size_t N>
bool IsOneOf(std::array<uint32, N> const& spells, uint32 spellId)
{
    return std::find(spells.begin(), spells.end(), spellId) != spells.end();
}

bool IsFlatWeaponBonus(uint32 effect)
{
    return effect == SPELL_EFFECT_WEAPON_DAMAGE || effect == SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL ||
        effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG;
}

void KeepFlatBonusOutsideWeaponPercent(SpellInfo* spellInfo)
{
    for (uint8 bonus = 0; bonus < MAX_SPELL_EFFECTS; ++bonus)
    {
        if (!IsFlatWeaponBonus(spellInfo->Effects[bonus].Effect))
            continue;
        for (uint8 percent = bonus + 1; percent < MAX_SPELL_EFFECTS; ++percent)
        {
            SpellEffectInfo const& weaponPercent = spellInfo->Effects[percent];
            if (weaponPercent.Effect != SPELL_EFFECT_WEAPON_PERCENT_DAMAGE || weaponPercent.BasePoints + 1 <= 0)
                continue;
            SpellEffectInfo& flat = spellInfo->Effects[bonus];
            flat.BasePoints = int32(std::lround((flat.BasePoints + 1) * 100.0 / (weaponPercent.BasePoints + 1))) - 1;
            flat.RealPointsPerLevel = flat.RealPointsPerLevel * 100.0f / float(weaponPercent.BasePoints + 1);
            return;
        }
    }
}
}
}

void ApplyAscensionWarcraftRebornHunterContracts(SpellInfo* spellInfo)
{
    using namespace AscensionWarcraftReborn;
    if (!spellInfo || spellInfo->Id < REBORN_SPELL_OFFSET || spellInfo->SpellFamilyName != SPELLFAMILY_HUNTER)
        return;

    KeepFlatBonusOutsideWeaponPercent(spellInfo);

    if (IsOneOf(MORTAL_SHOTS, spellInfo->Id) &&
        spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER &&
        spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER)
    {
        spellInfo->Effects[EFFECT_0].SpellClassMask[0] |= AUTO_SHOT_FLAG;
        spellInfo->Effects[EFFECT_1].BasePoints = spellInfo->Effects[EFFECT_0].BasePoints;
    }

    if (IsOneOf(CARVE, spellInfo->Id) && !spellInfo->SpellFamilyFlags)
        spellInfo->SpellFamilyFlags[2] |= CARVE_FLAG2;

    if (IsOneOf(HAWK_EYE, spellInfo->Id) && spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER)
        spellInfo->Effects[EFFECT_0].SpellClassMask[1] |= KILL_SHOT_FLAG;

    if (spellInfo->Id == IMPROVED_STEADY_SHOT_RANK_3 &&
        spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL)
    {
        spellInfo->ProcChance = uint32(spellInfo->Effects[EFFECT_0].BasePoints + 1);
        spellInfo->Effects[EFFECT_0].TriggerSpell = IMPROVED_STEADY_SHOT_BUFF;
    }
}
