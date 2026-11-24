#include "Engine/Rng.h"
#include "PetBattleData.h"
#include <gtest/gtest.h>

using namespace CoAPetBattles;

namespace
{
    DataSet const& Data()
    {
        static DataSet const data = []
        {
            DataSet set;
            set.zones[12] = { 12, "Elwynn Forest", 1, 2, 1, 10 };
            set.zones[3483] = { 3483, "Hellfire Peninsula", 17, 18, 56, 68 };
            return set;
        }();
        return data;
    }
}

TEST(CoAPetBattlesWildRules, PetLevelFollowsTheZoneCurve)
{
    EXPECT_EQ(PetLevel(Data(), 25, 1, 12), 1);
    EXPECT_EQ(PetLevel(Data(), 25, 5, 12), 1);
    EXPECT_EQ(PetLevel(Data(), 25, 6, 12), 2);
    EXPECT_EQ(PetLevel(Data(), 25, 10, 12), 2);
    EXPECT_EQ(PetLevel(Data(), 25, 40, 12), 2);
    EXPECT_EQ(PetLevel(Data(), 25, 56, 3483), 17);
    EXPECT_EQ(PetLevel(Data(), 25, 62, 3483), 17);
    EXPECT_EQ(PetLevel(Data(), 25, 63, 3483), 18);
    EXPECT_EQ(PetLevel(Data(), 25, 1, 3483), 17);
}

TEST(CoAPetBattlesWildRules, PetLevelWithoutZoneIsProportional)
{
    EXPECT_EQ(PetLevel(Data(), 25, 80, 0), 25);
    EXPECT_EQ(PetLevel(Data(), 25, 1, 0), 1);
    EXPECT_EQ(PetLevel(Data(), 25, 40, 0), 13);
}

TEST(CoAPetBattlesWildRules, SettingsDefaultToUpstream)
{
    WildSettings const wild;
    EXPECT_TRUE(wild.enabled);
    EXPECT_EQ(wild.tickMs, 5000u);
    EXPECT_EQ(wild.blipMs, 1000u);
    EXPECT_FLOAT_EQ(wild.search, 60.0f);
    EXPECT_FLOAT_EQ(wild.spacing, 90.0f);
    EXPECT_EQ(wild.maxArea, 3u);
    EXPECT_EQ(wild.cooldownSeconds, 90u);
    EXPECT_EQ(wild.lifetimeSeconds, 600u);
    EXPECT_FLOAT_EQ(wild.leave, 90.0f);
    EXPECT_EQ(wild.awayGraceSeconds, 60u);
    EXPECT_FLOAT_EQ(wild.moveRescan, 25.0f);
    EXPECT_EQ(wild.rescanIdleSeconds, 45u);
    EXPECT_FLOAT_EQ(wild.talkRange, 12.0f);
    EXPECT_EQ(wild.soloMaxLevel, 2);
    EXPECT_FLOAT_EQ(wild.spotMin, 5.0f);
    EXPECT_FLOAT_EQ(wild.spotMax, 50.0f);
    EXPECT_FLOAT_EQ(wild.maxHeightDifference, 2.5f);
    EXPECT_EQ(wild.tries, 8u);
    EXPECT_FLOAT_EQ(wild.fallbackDistance, 3.0f);
    EXPECT_FLOAT_EQ(wild.wander, 3.0f);
}

TEST(CoAPetBattlesWildRules, ReplayRngServesFractions)
{
    Engine::RecordedRoll fraction;
    fraction.fraction = true;
    fraction.real = 0.25;
    Engine::ReplayRng rng({ { 1, 3, 2 }, fraction });
    EXPECT_EQ(rng.Roll(1, 3), 2);
    EXPECT_DOUBLE_EQ(rng.Fraction(), 0.25);
    EXPECT_TRUE(rng.Divergence().empty());
    EXPECT_TRUE(rng.Exhausted());

    Engine::ReplayRng mismatched({ { 1, 3, 2 } });
    mismatched.Fraction();
    EXPECT_FALSE(mismatched.Divergence().empty());
}

TEST(CoAPetBattlesWildRules, SeededFractionsStayBelowOne)
{
    Engine::SeededRng rng(11);
    for (int i = 0; i < 1000; ++i)
    {
        double const value = rng.Fraction();
        EXPECT_GE(value, 0.0);
        EXPECT_LT(value, 1.0);
    }
}
