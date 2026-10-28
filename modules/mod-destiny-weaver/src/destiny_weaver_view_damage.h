/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef DESTINY_WEAVER_VIEW_DAMAGE_H
#define DESTINY_WEAVER_VIEW_DAMAGE_H

#include "Define.h"
#include <algorithm>
#include <cmath>

namespace DestinyWeaver
{
    /// Creature::SelectLevel gives a creature the weapon range `base .. base * 1.5`.
    constexpr double CREATURE_MAX_WEAPON_DAMAGE_FACTOR = 1.5;

    /// The average of the melee range Creature::CalculateMinMaxDamage builds from one row of
    /// `creature_classlevelstats`, before the template, rank and aura modifiers that do not depend on level.
    inline double AverageCreatureMeleeHit(float baseDamage, uint32 attackPower, float variance, uint32 attackTimeMs)
    {
        double const averageWeaponDamage = double(baseDamage) * (1.0 + CREATURE_MAX_WEAPON_DAMAGE_FACTOR) / 2.0;
        double const attackPowerDamage = double(attackPower) / 14.0 * double(variance);
        return (averageWeaponDamage + attackPowerDamage) * double(attackTimeMs) / 1000.0;
    }

    /// One end of that range from one row: `weaponFactor` 1 gives the bottom, CREATURE_MAX_WEAPON_DAMAGE_FACTOR the
    /// top. The attack time and the template, rank and aura multipliers are the same at every level.
    inline double CreatureSwingEnd(float baseDamage, uint32 attackPower, float variance, double weaponFactor)
    {
        return double(baseDamage) * weaponFactor + double(attackPower) / 14.0 * double(variance);
    }

    /// What one of the creature's blows is worth in the viewer's version of the fight.
    inline double ViewDamageTakenFactor(double viewAverageHit, double ownAverageHit)
    {
        return ownAverageHit > 0.0 ? viewAverageHit / ownAverageHit : 1.0;
    }

    /// Unit::CalculateDamage rolls a creature's blow as `urand(uint32(min), uint32(max))`, so a blow from a
    /// 1.5 - 2.3 range is 1 or 2 and nothing between, and a view factor of 20 turns those into two flat values.
    /// This puts the blow back at `spot` (0 <= spot < 1) inside its whole-number bucket and lands it on the same
    /// place of the viewer's range, whose bottom and top are the real ones scaled by their own ratios: a low
    /// creature's range is nearly flat (attack power dominates), the view level's is not. A number the roll cannot
    /// have produced (an aura already changed it) keeps its place in the real range, or the average factor when
    /// the range has no width.
    inline double ViewBlow(uint32 rolled, float minDamage, float maxDamage, double lowFactor, double highFactor,
                           double averageFactor, double spot)
    {
        double const blow = double(rolled);
        double const low = std::floor(double(minDamage));
        double const high = std::floor(double(maxDamage));
        if (minDamage >= 0.0f && maxDamage > 0.0f && blow >= low && blow <= high)
        {
            double const position = std::clamp((blow - low + spot) / (high - low + 1.0), 0.0, 1.0);
            double const viewLow = double(minDamage) * lowFactor;
            double const viewHigh = double(maxDamage) * highFactor;
            return viewLow + position * (viewHigh - viewLow);
        }

        if (maxDamage > minDamage)
        {
            double const position = std::clamp((blow - double(minDamage)) / double(maxDamage - minDamage), 0.0, 1.0);
            return blow * (lowFactor + position * (highFactor - lowFactor));
        }

        return blow * averageFactor;
    }

    /// A scaled blow as whole damage: its fraction is added with that probability (`chance`, 0 <= chance < 1), so
    /// many blows add up to the scaled amount, and a blow that landed never does less than 1.
    inline uint32 WholeDamage(double damage, double chance)
    {
        uint32 const whole = uint32(std::max(0.0, damage));
        uint32 const roundedUp = chance < damage - double(whole) ? 1 : 0;
        return std::max<uint32>(1, whole + roundedUp);
    }
}

#endif
