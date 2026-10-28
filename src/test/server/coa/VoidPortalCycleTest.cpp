#include "AscensionVoidPortalCycle.h"
#include <gtest/gtest.h>

using namespace Ascension::VoidPortal;

TEST(VoidPortalSelection, ExcludesThePreviousGroupWhenAnotherExists)
{
    Selection selection({ { 100, {} }, { 200, {} }, { 300, {} } });
    std::mt19937 rng(7);
    for (int i = 0; i < 200; ++i)
    {
        auto chosen = selection.ChooseGroup(200, rng);
        ASSERT_TRUE(chosen.has_value());
        EXPECT_NE(*chosen, 200u);
    }
}

TEST(VoidPortalSelection, UsesTheOnlyGroup)
{
    Selection selection({ { 100, {} } });
    std::mt19937 rng(7);
    EXPECT_EQ(selection.ChooseGroup(100, rng), 100u);
}

TEST(VoidPortalSelection, ExcludesTheCurrentPoint)
{
    SpawnGroup group{ 100, { { 1, 0, 0, 0, 0, 0 }, { 2, 0, 0, 0, 0, 0 } } };
    Selection selection({ group });
    std::mt19937 rng(7);
    for (int i = 0; i < 50; ++i)
    {
        auto chosen = selection.ChoosePoint(group, 1, rng);
        ASSERT_TRUE(chosen.has_value());
        EXPECT_EQ(chosen->spawnId, 2u);
    }
}

TEST(VoidPortalSelection, UsesTheOnlyPoint)
{
    SpawnGroup group{ 100, { { 5, 0, 0, 0, 0, 0 } } };
    Selection selection({ group });
    std::mt19937 rng(7);
    EXPECT_EQ(selection.ChoosePoint(group, 5, rng)->spawnId, 5u);
}

TEST(VoidPortalSchedule, SetsPointAndGroupExpiry)
{
    Schedule schedule;
    schedule.StartPoint(1000);
    schedule.StartGroup(1000);
    EXPECT_EQ(schedule.PointExpiry(), 1000 + PointLifetimeMs);
    EXPECT_EQ(schedule.GroupExpiry(), 1000 + GroupLifetimeMs);
}

TEST(VoidPortalProximity, SucceedsAtHalfOrBelow)
{
    for (std::uint32_t roll = 1; roll <= 50; ++roll)
        EXPECT_TRUE(Selection::ProximityRollSucceeds(roll));
    for (std::uint32_t roll = 51; roll <= 100; ++roll)
        EXPECT_FALSE(Selection::ProximityRollSucceeds(roll));
}
