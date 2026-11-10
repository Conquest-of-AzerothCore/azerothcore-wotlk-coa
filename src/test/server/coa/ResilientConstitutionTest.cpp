#include "AscensionResilientConstitution.h"
#include <gtest/gtest.h>

using ResilientConstitution::Apply;

TEST(ResilientConstitution, DefaultsHalveHitsAndTakeAFurtherFifthFromCriticals)
{
    EXPECT_EQ(Apply(1000, false, 50, 20, 100), 500);
    EXPECT_EQ(Apply(1000, true, 50, 20, 100), 400);
}

TEST(ResilientConstitution, PetsReceiveTheirShareOfBothReductions)
{
    EXPECT_EQ(Apply(1000, false, 50, 20, 85), 575);
    EXPECT_EQ(Apply(1000, true, 50, 20, 85), 477);
}

TEST(ResilientConstitution, PreviousTenPercentPolicyIsReproducible)
{
    EXPECT_EQ(Apply(1000, false, 10, 20, 100), 900);
    EXPECT_EQ(Apply(1000, true, 10, 20, 100), 720);
}

TEST(ResilientConstitution, PercentagesAboveOneHundredAreCapped)
{
    EXPECT_EQ(Apply(1000, false, 150, 20, 100), 0);
    EXPECT_EQ(Apply(1000, false, 50, 20, 250), 500);
}

TEST(ResilientConstitution, NonPositiveDamageIsUnchanged)
{
    EXPECT_EQ(Apply(0, true, 50, 20, 100), 0);
    EXPECT_EQ(Apply(-5, true, 50, 20, 100), -5);
}

TEST(ResilientConstitution, LargeHitsDoNotOverflow)
{
    EXPECT_EQ(Apply(2000000000, true, 50, 20, 100), 800000000);
}

TEST(ResilientConstitution, ConfiguredValuesDriveReduce)
{
    ResilientConstitution::damageReductionPct = 30;
    ResilientConstitution::criticalReductionPct = 0;
    ResilientConstitution::petSharePct = 50;
    EXPECT_EQ(ResilientConstitution::Reduce(1000, true, false), 700);
    EXPECT_EQ(ResilientConstitution::Reduce(1000, true, true), 850);
    ResilientConstitution::damageReductionPct = ResilientConstitution::DefaultDamageReductionPct;
    ResilientConstitution::criticalReductionPct = ResilientConstitution::DefaultCriticalReductionPct;
    ResilientConstitution::petSharePct = ResilientConstitution::DefaultPetSharePct;
}
