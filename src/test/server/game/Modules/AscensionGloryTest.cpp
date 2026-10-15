/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionGlory.h"
#include "BattlegroundScore.h"
#include "gtest/gtest.h"
#include <limits>

TEST(AscensionGlory, KillingBlowsReachRankTwoAfter250Kills)
{
    uint32 glory = 0;
    for (int kill = 0; kill < 249; ++kill)
        glory = AscensionGlory::Accrue(glory, AscensionGlory::KillingBlowGlory);

    EXPECT_EQ(glory, 249u);
    EXPECT_EQ(AscensionGlory::Accrue(glory, AscensionGlory::KillingBlowGlory), 250u);
}

TEST(AscensionGlory, ObjectivesAwardFiveGloryEach)
{
    for (uint32 type : {SCORE_FLAG_CAPTURES, SCORE_BASES_ASSAULTED, SCORE_BASES_DEFENDED, SCORE_GRAVEYARDS_ASSAULTED,
        SCORE_GRAVEYARDS_DEFENDED, SCORE_TOWERS_ASSAULTED, SCORE_TOWERS_DEFENDED, SCORE_MINES_CAPTURED})
    {
        EXPECT_EQ(AscensionGlory::ObjectiveReward(type, 1), 5u) << type;
        EXPECT_EQ(AscensionGlory::ObjectiveReward(type, 2), 10u) << type;
    }
}

TEST(AscensionGlory, OtherScoresAwardNoObjectiveGlory)
{
    for (uint32 type : {SCORE_KILLING_BLOWS, SCORE_DEATHS, SCORE_HONORABLE_KILLS, SCORE_BONUS_HONOR, SCORE_DAMAGE_DONE,
        SCORE_HEALING_DONE, SCORE_FLAG_RETURNS, SCORE_DESTROYED_DEMOLISHER, SCORE_DESTROYED_WALL})
        EXPECT_EQ(AscensionGlory::ObjectiveReward(type, 1), 0u) << type;
}

TEST(AscensionGlory, SaturatesInsteadOfWrapping)
{
    uint32 const max = std::numeric_limits<uint32>::max();
    EXPECT_EQ(AscensionGlory::Accrue(max - 5, 10), max);
    EXPECT_EQ(AscensionGlory::Accrue(max, max), max);
    EXPECT_EQ(AscensionGlory::ObjectiveReward(SCORE_FLAG_CAPTURES, max), max);
}

TEST(AscensionGlory, UpdateCarriesGuidAndGloryInAddonField35)
{
    ObjectGuid const guid = ObjectGuid::Create<HighGuid::Player>(4242);
    WorldPacket data = AscensionGlory::BuildUpdate(guid, 15000);

    EXPECT_EQ(data.GetOpcode(), 0x0578);
    ASSERT_EQ(data.size(), 16u);
    EXPECT_EQ(data.read<uint64>(), guid.GetRawValue());
    EXPECT_EQ(data.read<uint32>(), 35u);
    EXPECT_EQ(data.read<uint32>(), 15000u);
}
