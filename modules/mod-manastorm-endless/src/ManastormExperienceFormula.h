#ifndef MANASTORM_EXPERIENCE_FORMULA_H
#define MANASTORM_EXPERIENCE_FORMULA_H

#include "Define.h"
#include <algorithm>
#include <cmath>

namespace ManastormExperienceFormula
{
    inline constexpr double MaxDepthBonus = 1.0;
    inline constexpr double DepthHalfSaturation = 100.0;
    inline constexpr uint32 PersonalDepthGrace = 5;
    inline constexpr uint32 RaidThreshold = 5;
    inline constexpr uint32 LevelGapPenaltyStart = 5;
    inline constexpr uint32 LevelGapZeroAt = 10;
    inline constexpr double ContributionFullShareRatio = 0.40;
    inline constexpr double MinGroupContributionFactor = 0.10;
    inline constexpr uint64 FullHealthBarBasisPoints = 10000;
    inline constexpr float KillContributionRangeYards = 100.0f;

    inline uint32 EffectiveDepth(uint32 runDepth, bool isGroupRun, uint32 personalBestDepth) noexcept
    {
        if (!runDepth)
            return 1;

        if (!isGroupRun)
            return runDepth;

        uint64 const cap = uint64(personalBestDepth) + PersonalDepthGrace;
        return uint32(std::min<uint64>(runDepth, std::max<uint64>(1, cap)));
    }

    inline double DepthBonusFraction(uint32 effectiveDepth) noexcept
    {
        if (effectiveDepth <= 1)
            return 0.0;

        double const extra = double(effectiveDepth - 1);
        return MaxDepthBonus * extra / (extra + DepthHalfSaturation);
    }

    inline uint64 DepthBonusTenths(uint32 effectiveDepth) noexcept
    {
        double const tenths = DepthBonusFraction(effectiveDepth) * 1000.0;
        return tenths <= 0.0 ? 0 : uint64(std::llround(tenths));
    }

    inline double AdditiveDepthMultiplier(uint32 effectiveDepth, double externalMultiplier) noexcept
    {
        double const bonus = DepthBonusFraction(effectiveDepth);
        if (bonus <= 0.0)
            return 1.0;

        double const safeExternal = std::isfinite(externalMultiplier) && externalMultiplier > 1.0
            ? externalMultiplier
            : 1.0;
        return 1.0 + (bonus / safeExternal);
    }

    inline double GroupHealthMultiplierFallback(uint32 memberCount) noexcept
    {
        if (memberCount <= 1)
            return 1.0;

        return 1.0 + (0.6 * double(memberCount - 1));
    }

    inline double FloorGroupEffortFactor(uint32 memberCount, double configuredGroupHealthMultiplier) noexcept
    {
        if (memberCount <= 1)
            return 1.0;

        double const hpMultiplier =
            std::isfinite(configuredGroupHealthMultiplier) && configuredGroupHealthMultiplier > 0.0
            ? configuredGroupHealthMultiplier
            : GroupHealthMultiplierFallback(memberCount);
        return std::clamp(hpMultiplier / double(memberCount), 0.0, 1.0);
    }

    inline double RaidSizeFactor(uint32 memberCount) noexcept
    {
        if (memberCount <= RaidThreshold)
            return 1.0;

        double const ratio = double(RaidThreshold) / double(memberCount);
        return ratio * ratio;
    }

    inline double LevelGapFactor(uint8 playerLevel, uint8 highestMemberLevel, uint32 maxPlayerLevel) noexcept
    {
        if (maxPlayerLevel && highestMemberLevel >= maxPlayerLevel)
            return 0.0;

        if (highestMemberLevel <= playerLevel)
            return 1.0;

        uint32 const gap = uint32(highestMemberLevel) - uint32(playerLevel);
        if (gap <= LevelGapPenaltyStart)
            return 1.0;

        if (gap >= LevelGapZeroAt)
            return 0.0;

        return double(LevelGapZeroAt - gap) / double(LevelGapZeroAt - LevelGapPenaltyStart);
    }

    inline double CombatContributionFactor(
        uint32 memberCount,
        uint64 memberDamage,
        uint64 totalDamage,
        uint64 memberCreditedHeal,
        uint64 totalCreditedHeal,
        bool allowWarmup = false,
        bool withinKillRange = true) noexcept
    {
        if (memberCount <= 1)
            return 1.0;

        if (!withinKillRange)
            return 0.0;

        if (!totalDamage && !totalCreditedHeal)
            return 1.0;

        if (allowWarmup)
            return 1.0;

        double const damageShare = totalDamage ? double(memberDamage) / double(totalDamage) : 0.0;
        double const healScale = std::min(1.0, double(totalCreditedHeal) / double(FullHealthBarBasisPoints));
        double const healShare = totalCreditedHeal
            ? (double(memberCreditedHeal) / double(totalCreditedHeal)) * healScale
            : 0.0;
        double const bestShare = std::max(damageShare, healShare);
        double const targetShare = ContributionFullShareRatio / double(memberCount);
        return std::clamp(bestShare / targetShare, MinGroupContributionFactor, 1.0);
    }

    inline uint64 CombatRealDamagePoints(uint32 damage, uint32 currentHealth) noexcept
    {
        return uint64(std::min(damage, currentHealth));
    }

    inline uint64 CombatHealthBasisPoints(uint32 amount, uint32 maxHealth) noexcept
    {
        uint32 const safeMax = std::max(1u, maxHealth);
        uint32 const clamped = std::min(amount, safeMax);
        if (!clamped)
            return 0;

        return uint64(clamped) * FullHealthBarBasisPoints / uint64(safeMax);
    }
}

#endif
