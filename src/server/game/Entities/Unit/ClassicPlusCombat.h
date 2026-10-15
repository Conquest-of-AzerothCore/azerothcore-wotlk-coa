/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef AC_CLASSIC_PLUS_COMBAT_H
#define AC_CLASSIC_PLUS_COMBAT_H

#include "Define.h"
#include <algorithm>
#include <array>

namespace ClassicPlusCombat
{
constexpr uint32 MaxPlayerLevel = 60;
constexpr uint32 MaxCreatureLevel = 63;

constexpr float CreatureBaseAvoidance = 5.0f;
constexpr int32 MaxCreatureBlockChance = 500;
constexpr int32 MaxGlancingChance = 4000;
constexpr float MaxResistChance = 0.75f;
constexpr float DotResistChanceFactor = 0.1f;
constexpr float EnergyThreatPerPoint = 5.0f;
constexpr float DazeChancePerSkillPoint = 0.2f;

struct Combatant
{
    uint32 Level;
    bool PlayerControlled;
};

constexpr bool IsVanillaLevel(Combatant unit)
{
    return unit.Level <= (unit.PlayerControlled ? MaxPlayerLevel : MaxCreatureLevel);
}

constexpr bool IsClassicContext(Combatant attacker, Combatant victim)
{
    return IsVanillaLevel(attacker) && IsVanillaLevel(victim);
}

constexpr float LowLevelAvoidanceFactor(uint32 creatureLevel)
{
    return creatureLevel < 10 ? float(creatureLevel) / 10.0f : 1.0f;
}

enum class Avoidance
{
    Dodge,
    Parry,
    Block
};

constexpr int32 CreatureAvoidanceChance(Avoidance avoidance, int32 chance, int32 weaponSkill, int32 attackerMaxSkill,
    int32 victimMaxSkill, uint32 victimLevel)
{
    int32 const skillDiff = weaponSkill - victimMaxSkill;
    int32 const cappedSkillDiff = std::min(weaponSkill, attackerMaxSkill) - victimMaxSkill;
    switch (avoidance)
    {
        case Avoidance::Dodge:
            chance -= 10 * skillDiff;
            break;
        case Avoidance::Parry:
            chance -= (cappedSkillDiff < -10 ? 60 : 20) * cappedSkillDiff;
            break;
        case Avoidance::Block:
            chance = std::min(chance - 10 * skillDiff, MaxCreatureBlockChance);
            break;
    }
    return int32(float(chance) * LowLevelAvoidanceFactor(victimLevel));
}

constexpr float CreatureMissChance(float baseMissChance, int32 defenseGap, uint32 victimLevel)
{
    float const perPoint = defenseGap > 10 ? 0.2f : 0.1f;
    return (baseMissChance + float(defenseGap) * perPoint) * LowLevelAvoidanceFactor(victimLevel);
}

constexpr float IgnoredHitChance(float hitChance, int32 defenseGap)
{
    return defenseGap > 10 && hitChance > 0.0f ? std::min(hitChance, 1.0f) : 0.0f;
}

constexpr float CreatureVictimCritModifier(int32 weaponSkill, int32 attackerMaxSkill, int32 victimDefense)
{
    int32 const skillDiff = weaponSkill - victimDefense;
    if (skillDiff > 0)
        return float(skillDiff) * 0.04f;
    return float(std::min(weaponSkill, attackerMaxSkill) - victimDefense) * 0.2f;
}

constexpr int32 GlancingChance(int32 victimDefense, int32 weaponSkill, int32 attackerMaxSkill)
{
    int32 const skill = std::min(weaponSkill, attackerMaxSkill);
    return std::clamp((10 + 2 * (victimDefense - skill)) * 100, 0, MaxGlancingChance);
}

struct DamageRange
{
    float Low;
    float High;
};

constexpr DamageRange GlancingDamageRange(int32 victimDefense, int32 weaponSkill, bool caster)
{
    float const gap = float(victimDefense - weaponSkill);
    float low = 1.3f - 0.05f * gap;
    float high = 1.2f - 0.03f * gap;
    float lowCap = 0.91f;
    if (caster)
    {
        low -= 0.7f;
        high -= 0.3f;
        lowCap = 0.6f;
    }
    return { std::clamp(low, 0.01f, lowCap), std::clamp(high, 0.2f, 0.99f) };
}

constexpr float WotlkGlancingDamageMultiplier(int32 levelDiff)
{
    return 1.0f - 0.1f * float(std::clamp(levelDiff, 0, 3));
}

constexpr float ArmorConstant(uint32 attackerLevel)
{
    return 85.0f * float(attackerLevel) + 400.0f;
}

constexpr float SpellResistChance(float resistance, int32 levelDiff, uint32 casterLevel, bool levelBased)
{
    float const level = float(std::max<uint32>(casterLevel, 1));
    if (levelBased)
        resistance += float(int32(8.0f * float(levelDiff) * level / 63.0f));
    return std::clamp(resistance * 0.15f / level, 0.0f, MaxResistChance);
}

constexpr int32 BinaryResistChance(int32 missAndResistChance, float resistChance)
{
    return int32(float(std::max(0, 10000 - missAndResistChance)) * resistChance);
}

enum DirectlyResistedDot : uint32
{
    VaelastraszFlameBreath = 23461,
    NightmareDragonNoxiousBreath = 24818,
    LordKriToxicVolley = 25812,
    SapphironFrostAura = 28531
};

constexpr bool ResistsDotAsDirectDamage(uint32 spellId)
{
    switch (spellId)
    {
        case VaelastraszFlameBreath:
        case NightmareDragonNoxiousBreath:
        case LordKriToxicVolley:
        case SapphironFrostAura:
            return true;
        default:
            return false;
    }
}

struct PartialResistRow
{
    float Chance;
    float Resist100;
    float Resist75;
    float Resist50;
    float Resist25;
};

// Vanilla partial-resist distribution by average resist chance (%), as tabled by vmangos and Turtle WoW 1.12.
inline constexpr std::array<PartialResistRow, 31> PartialResistTable =
{{
    { 0, 0, 0, 0, 0 }, { 3, 0, 0, 2, 6 }, { 5, 0, 1, 4, 12 }, { 8, 0, 1, 5, 18 }, { 10, 0, 1, 7, 23 },
    { 13, 0, 2, 9, 28 }, { 15, 0, 2, 11, 33 }, { 18, 0, 2, 13, 37 }, { 20, 0, 3, 15, 41 }, { 23, 1, 3, 17, 46 },
    { 25, 1, 4, 19, 47 }, { 28, 1, 5, 21, 48 }, { 30, 1, 6, 24, 49 }, { 33, 1, 8, 28, 47 }, { 35, 1, 9, 33, 43 },
    { 38, 1, 11, 37, 39 }, { 40, 1, 13, 41, 35 }, { 43, 1, 16, 45, 30 }, { 45, 1, 18, 48, 26 },
    { 48, 2, 20, 48, 24 }, { 50, 4, 23, 48, 21 }, { 53, 5, 25, 47, 19 }, { 55, 7, 28, 45, 17 },
    { 58, 9, 31, 43, 16 }, { 60, 11, 34, 40, 14 }, { 62, 13, 37, 37, 12 }, { 65, 15, 41, 33, 10 },
    { 68, 18, 44, 29, 8 }, { 70, 20, 48, 25, 7 }, { 73, 23, 51, 20, 5 }, { 75, 25, 55, 16, 3 }
}};

struct PartialResistChances
{
    float Resist75;
    float Resist50;
    float Resist25;
};

constexpr PartialResistChances PartialResistDistribution(float resistChance)
{
    float const percent = std::clamp(resistChance * 100.0f, 0.0f, MaxResistChance * 100.0f);
    std::size_t next = 1;
    while (next + 1 < PartialResistTable.size() && PartialResistTable[next].Chance < percent)
        ++next;

    PartialResistRow const& low = PartialResistTable[next - 1];
    PartialResistRow const& high = PartialResistTable[next];
    float const t = (percent - low.Chance) / (high.Chance - low.Chance);
    auto const lerp = [t](float from, float to) { return from + (to - from) * t; };
    return { lerp(low.Resist100 + low.Resist75, high.Resist100 + high.Resist75), lerp(low.Resist50, high.Resist50),
        lerp(low.Resist25, high.Resist25) };
}

constexpr float PartialResistMultiplier(PartialResistChances chances, float rollPercent)
{
    if (rollPercent < chances.Resist75)
        return 0.75f;
    if (rollPercent < chances.Resist75 + chances.Resist50)
        return 0.5f;
    if (rollPercent < chances.Resist75 + chances.Resist50 + chances.Resist25)
        return 0.25f;
    return 0.0f;
}
}

#endif
