#include "ManastormExperienceFormula.h"

#include <cmath>
#include <gtest/gtest.h>

TEST(ManastormExperienceFormulaTest, SoloPlayersReceiveUnpenalizedFullCurve)
{
    for (uint32 depth : { 1u, 10u, 50u, 100u, 250u, 1000u, 5000u })
    {
        EXPECT_EQ(ManastormExperienceFormula::EffectiveDepth(depth, false, 0), depth);
        EXPECT_DOUBLE_EQ(ManastormExperienceFormula::FloorGroupEffortFactor(1, 0.0), 1.0);
        EXPECT_DOUBLE_EQ(ManastormExperienceFormula::RaidSizeFactor(1), 1.0);
        EXPECT_DOUBLE_EQ(ManastormExperienceFormula::LevelGapFactor(35, 35, 60), 1.0);
        EXPECT_DOUBLE_EQ(ManastormExperienceFormula::KillGroupLevelShareCap(false, 55, 19.0), 1.0);
        EXPECT_DOUBLE_EQ(
            ManastormExperienceFormula::CombatContributionFactor(1, 0, 0, 0, 0, true, false), 1.0);
    }

    EXPECT_DOUBLE_EQ(ManastormExperienceFormula::DepthBonusFraction(1), 0.0);
    EXPECT_NEAR(ManastormExperienceFormula::DepthBonusFraction(50), 49.0 / 149.0, 1e-9);
    EXPECT_DOUBLE_EQ(ManastormExperienceFormula::DepthBonusFraction(101), 0.5);
    EXPECT_LT(ManastormExperienceFormula::DepthBonusFraction(16384), 1.0);
    EXPECT_GT(ManastormExperienceFormula::DepthBonusFraction(16384), 0.99);
}

TEST(ManastormExperienceFormulaTest, PersonalEffectiveDepthPreventsLeaderCarryBoost)
{
    EXPECT_EQ(ManastormExperienceFormula::EffectiveDepth(1000, true, 0), 5u);
    EXPECT_EQ(ManastormExperienceFormula::EffectiveDepth(1000, true, 20), 25u);
    EXPECT_EQ(ManastormExperienceFormula::EffectiveDepth(20, true, 25), 20u);
}

TEST(ManastormExperienceFormulaTest, DepthBonusStacksAdditivelyWithPrestigeAndAuras)
{
    double const external = 3.0 * 1.5;
    uint32 const depth = 1001;
    double const bonus = ManastormExperienceFormula::DepthBonusFraction(depth);
    double const mult = ManastormExperienceFormula::AdditiveDepthMultiplier(depth, external);
    EXPECT_NEAR(external * mult, external + bonus, 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::AdditiveDepthMultiplier(depth, 0.5), 1.0 + bonus, 1e-9);
}

TEST(ManastormExperienceFormulaTest, GroupEffortAndRaidPenaltiesNormalizeThroughput)
{
    EXPECT_NEAR(ManastormExperienceFormula::FloorGroupEffortFactor(2, 1.6), 0.80, 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::FloorGroupEffortFactor(3, 2.2), 2.2 / 3.0, 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::FloorGroupEffortFactor(4, 2.8), 0.70, 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::FloorGroupEffortFactor(5, 3.4), 0.68, 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::FloorGroupEffortFactor(15, 0.0), 9.4 / 15.0, 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::FloorGroupEffortFactor(15, 1.0), 1.0 / 15.0, 1e-9);

    EXPECT_DOUBLE_EQ(ManastormExperienceFormula::RaidSizeFactor(5), 1.0);
    EXPECT_NEAR(ManastormExperienceFormula::RaidSizeFactor(6), 25.0 / 36.0, 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::RaidSizeFactor(10), 0.25, 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::RaidSizeFactor(15), 1.0 / 9.0, 1e-9);
}

TEST(ManastormExperienceFormulaTest, LevelGapAllowsMixedPlayWhileCrushingTwinkAndMaxLevelCarries)
{
    EXPECT_DOUBLE_EQ(ManastormExperienceFormula::LevelGapFactor(39, 59, 60), 1.0);
    EXPECT_NEAR(ManastormExperienceFormula::LevelGapFactor(34, 59, 60), std::pow(25.0 / 30.0, 1.5), 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::LevelGapFactor(29, 59, 60), std::pow(20.0 / 30.0, 1.5), 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::LevelGapFactor(24, 59, 60), std::pow(15.0 / 30.0, 1.5), 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::LevelGapFactor(19, 59, 60), std::pow(10.0 / 30.0, 1.5), 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::LevelGapFactor(14, 59, 60), std::pow(5.0 / 30.0, 1.5), 1e-9);
    EXPECT_DOUBLE_EQ(ManastormExperienceFormula::LevelGapFactor(9, 59, 60), 0.0);
    EXPECT_DOUBLE_EQ(ManastormExperienceFormula::LevelGapFactor(59, 60, 60), 0.0);
    EXPECT_DOUBLE_EQ(ManastormExperienceFormula::LevelGapFactor(10, 60, 60), 0.0);
}

TEST(ManastormExperienceFormulaTest, KillGroupLevelShareCapBlocksReverseBoostWithoutHurtingLowLevels)
{
    EXPECT_DOUBLE_EQ(ManastormExperienceFormula::KillGroupLevelShareCap(true, 30, 30.0), 1.0);
    EXPECT_DOUBLE_EQ(ManastormExperienceFormula::KillGroupLevelShareCap(true, 15, 42.4), 1.0);
    EXPECT_NEAR(ManastormExperienceFormula::KillGroupLevelShareCap(true, 50, 42.4), 42.4 / 50.0, 1e-9);
    EXPECT_NEAR(ManastormExperienceFormula::KillGroupLevelShareCap(true, 55, 19.0), 19.0 / 55.0, 1e-9);
}

TEST(ManastormExperienceFormulaTest, DualPoolContributionPreventsDpsStarvationAndPokeLeeching)
{
    EXPECT_DOUBLE_EQ(
        ManastormExperienceFormula::CombatContributionFactor(5, 3000, 10000, 0, 500000, false, true), 1.0);
    EXPECT_DOUBLE_EQ(
        ManastormExperienceFormula::CombatContributionFactor(5, 0, 500000, 10000, 10000, false, true), 1.0);
    EXPECT_NEAR(
        ManastormExperienceFormula::CombatContributionFactor(5, 0, 500000, 500, 500, false, true), 0.625, 1e-9);
    EXPECT_DOUBLE_EQ(
        ManastormExperienceFormula::CombatContributionFactor(5, 10000, 10000, 0, 0, true, false), 0.0);
    EXPECT_DOUBLE_EQ(
        ManastormExperienceFormula::CombatContributionFactor(5, 0, 5000, 0, 0, true, true), 1.0);
    EXPECT_DOUBLE_EQ(
        ManastormExperienceFormula::CombatContributionFactor(5, 0, 20000, 0, 0, false, true), 0.10);
    EXPECT_EQ(ManastormExperienceFormula::CombatRealDamagePoints(50000, 500), 500u);
    EXPECT_EQ(ManastormExperienceFormula::CombatHealthBasisPoints(50000, 1000), 10000u);
}
