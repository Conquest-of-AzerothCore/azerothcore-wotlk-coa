#include "AscensionCrowsCachePolicy.h"
#include <gtest/gtest.h>

TEST(CrowsCache, OnlyLivingHighRiskLevelSixtyPlayersCanClaim)
{
    EXPECT_TRUE(CrowsCache::Eligible(60, true, true));
    EXPECT_FALSE(CrowsCache::Eligible(59, true, true));
    EXPECT_FALSE(CrowsCache::Eligible(61, true, true));
    EXPECT_FALSE(CrowsCache::Eligible(60, false, true));
    EXPECT_FALSE(CrowsCache::Eligible(60, true, false));
}

TEST(CrowsCache, OriginalChestRequiresCompletedCastButDeathDropIsInstant)
{
    using CrowsCache::Phase;
    EXPECT_FALSE(CrowsCache::CanClaim(Phase::Warning, true));
    EXPECT_FALSE(CrowsCache::CanClaim(Phase::Available, false));
    EXPECT_TRUE(CrowsCache::CanClaim(Phase::Available, true));
    EXPECT_TRUE(CrowsCache::CanClaim(Phase::Dropped, false));
    EXPECT_FALSE(CrowsCache::CanClaim(Phase::Carried, true));
}

TEST(CrowsCache, MovementOrAnyDamageInterruptsOpening)
{
    EXPECT_TRUE(CrowsCache::InterruptOpening(true, 0));
    EXPECT_TRUE(CrowsCache::InterruptOpening(false, 1));
    EXPECT_FALSE(CrowsCache::InterruptOpening(false, 0));
}

TEST(CrowsCache, SafetyRequiresTrackedCacheAndCorrectArea)
{
    EXPECT_FALSE(CrowsCache::CanOpen(true, true, CrowsCache::AbyssalSands, false));
    EXPECT_FALSE(CrowsCache::CanOpen(false, true, CrowsCache::Gadgetzan, false));
    EXPECT_FALSE(CrowsCache::CanOpen(true, false, CrowsCache::Gadgetzan, false));
    EXPECT_FALSE(CrowsCache::CanOpen(true, true, CrowsCache::Gadgetzan, true));
    EXPECT_TRUE(CrowsCache::CanOpen(true, true, CrowsCache::Gadgetzan, false));
    EXPECT_TRUE(CrowsCache::CarrySlow(true, CrowsCache::AbyssalSands));
    EXPECT_FALSE(CrowsCache::CarrySlow(true, CrowsCache::Gadgetzan));
    EXPECT_FALSE(CrowsCache::CarrySlow(false, CrowsCache::AbyssalSands));
}

TEST(CrowsCache, WarningsFireAtThirtyFifteenFiveAndOneMinute)
{
    using namespace CrowsCache;
    EXPECT_EQ(DueWarning(0, 1801), WarningCount);
    EXPECT_EQ(DueWarning(0, 1800), 0u);
    EXPECT_EQ(DueWarning(1, 1799), WarningCount);
    EXPECT_EQ(DueWarning(1, 900), 1u);
    EXPECT_EQ(DueWarning(3, 899), WarningCount);
    EXPECT_EQ(DueWarning(3, 300), 2u);
    EXPECT_EQ(DueWarning(7, 60), 3u);
    EXPECT_EQ(DueWarning(15, 59), WarningCount);
    EXPECT_EQ(DueWarning(1, 50), 3u);
    EXPECT_EQ(PassedWarnings(1800), 0u);
    EXPECT_EQ(PassedWarnings(300), 3u);
    EXPECT_EQ(PassedWarnings(10), 15u);
}

TEST(CrowsCache, AppearanceCadenceSurvivesLateUpdates)
{
    EXPECT_EQ(CrowsCache::NextAppearance(10800, 9000, 10800), 10800u);
    EXPECT_EQ(CrowsCache::NextAppearance(10800, 10800, 10800), 21600u);
    EXPECT_EQ(CrowsCache::NextAppearance(10800, 32401, 10800), 43200u);
}

TEST(CrowsCache, BothDeliveryTownsAllowSafeOpening)
{
    EXPECT_TRUE(CrowsCache::CanOpen(true, true, CrowsCache::CenarionHold, false));
    EXPECT_FALSE(CrowsCache::CanOpen(true, true, CrowsCache::CenarionHold, true));
    EXPECT_FALSE(CrowsCache::CanOpen(true, true, CrowsCache::Silithus, false));
    EXPECT_FALSE(CrowsCache::CarrySlow(true, CrowsCache::CenarionHold));
    EXPECT_TRUE(CrowsCache::CarrySlow(true, CrowsCache::Silithus));
}
