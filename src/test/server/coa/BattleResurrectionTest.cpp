#include "AscensionBattleResurrection.h"
#include <gtest/gtest.h>

using namespace Ascension::BattleResurrection;

TEST(BattleResurrectionCharges, RaidsUpToFifteenPlayersGetTwo)
{
    EXPECT_EQ(RaidCharges(1), 2u);
    EXPECT_EQ(RaidCharges(10), 2u);
    EXPECT_EQ(RaidCharges(15), 2u);
}

TEST(BattleResurrectionCharges, RaidsAboveFifteenPlayersGetThree)
{
    EXPECT_EQ(RaidCharges(16), 3u);
    EXPECT_EQ(RaidCharges(20), 3u);
    EXPECT_EQ(RaidCharges(25), 3u);
    EXPECT_EQ(RaidCharges(40), 3u);
}

TEST(BattleResurrectionCharges, MythicPlusRunGetsOne)
{
    EXPECT_EQ(MythicPlusCharges, 1u);
}

TEST(BattleResurrectionBudget, EmptyUntilStarted)
{
    Budget budget;
    EXPECT_FALSE(budget.Available());
    EXPECT_FALSE(budget.Consume());
    EXPECT_EQ(budget.Remaining(), 0u);
}

TEST(BattleResurrectionBudget, RefusesAfterTheLastCharge)
{
    Budget budget;
    budget.Start(2);
    EXPECT_TRUE(budget.Consume());
    EXPECT_EQ(budget.Remaining(), 1u);
    EXPECT_TRUE(budget.Consume());
    EXPECT_FALSE(budget.Available());
    EXPECT_FALSE(budget.Consume());
    EXPECT_EQ(budget.Remaining(), 0u);
    EXPECT_EQ(budget.Total(), 2u);
}

TEST(BattleResurrectionBudget, NewFightRestoresTheCharges)
{
    Budget budget;
    budget.Start(2);
    budget.Consume();
    budget.Consume();
    budget.Start(3);
    EXPECT_EQ(budget.Remaining(), 3u);
    EXPECT_EQ(budget.Total(), 3u);
}
