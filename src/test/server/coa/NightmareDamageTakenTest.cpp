/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionNightmareDamageTakenPolicy.h"
#include <gtest/gtest.h>

using namespace NightmareDamageTaken;

namespace
{
constexpr DamageTakenEffect ScaledPhysical{ 150, 3.75f, PhysicalSchoolMask };
constexpr DamageTakenEffect ScaledMagic{ 250, 6.25f, MagicSchoolMask };
constexpr std::int32_t DieSides = 1;
constexpr std::int32_t MaxLevel = 10;
constexpr std::int32_t BaseLevel = 1;

std::int32_t PercentAtLevel(DamageTakenEffect const& effect, std::int32_t level)
{
    std::int32_t const scaledLevel = std::min(level, MaxLevel) - BaseLevel;
    return effect.basePoints + std::int32_t(scaledLevel * effect.realPointsPerLevel) + DieSides;
}

DamageTakenEffect Flattened(std::uint32_t spellId, DamageTakenEffect effect)
{
    if (std::optional<std::int32_t> flat = FlatBasePoints(spellId, effect))
        return { *flat, 0.0f, effect.schoolMask };
    return effect;
}
}

TEST(NightmareDamageTaken, LevelScaledAurasStopAtTheLevelTenCap)
{
    EXPECT_EQ(PercentAtLevel(ScaledPhysical, 60), 184);
    EXPECT_EQ(PercentAtLevel(ScaledMagic, 60), 307);
}

TEST(NightmareDamageTaken, EveryLevelScaledAuraBecomesThreeHundredAndFiveHundredPercent)
{
    for (std::uint32_t spellId : LevelScaledAuras)
    {
        for (std::int32_t level : { 1, 10, 60 })
        {
            EXPECT_EQ(PercentAtLevel(Flattened(spellId, ScaledPhysical), level), 300) << spellId << " L" << level;
            EXPECT_EQ(PercentAtLevel(Flattened(spellId, ScaledMagic), level), 500) << spellId << " L" << level;
        }
    }
}

TEST(NightmareDamageTaken, AurasThatAlreadyMatchTheTrialTextAreUntouched)
{
    DamageTakenEffect const flatPhysical{ 299, 0.0f, PhysicalSchoolMask };
    EXPECT_FALSE(FlatBasePoints(93134, ScaledPhysical));
    EXPECT_FALSE(FlatBasePoints(93179, ScaledMagic));
    EXPECT_FALSE(FlatBasePoints(93132, flatPhysical));
}

TEST(NightmareDamageTaken, OtherSchoolsAreUntouched)
{
    EXPECT_FALSE(FlatBasePoints(93132, DamageTakenEffect{ 150, 3.75f, 4 }));
}

TEST(NightmareDamageTaken, OnlyTheEightLevelScaledNightmareAurasAreListed)
{
    EXPECT_EQ(LevelScaledAuras.size(), 8u);
    EXPECT_TRUE(IsLevelScaledAura(93136));
    EXPECT_TRUE(IsLevelScaledAura(900930));
    EXPECT_FALSE(IsLevelScaledAura(93178));
}
