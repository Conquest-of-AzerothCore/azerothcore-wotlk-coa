/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionGlory.h"
#include "BattlegroundScore.h"
#include "gtest/gtest.h"
#include <limits>

TEST(AscensionGlory, KillerEarnsTenAndHelpersFive)
{
    EXPECT_EQ(AscensionGlory::HonorableKillGlory, 5u);
    EXPECT_EQ(AscensionGlory::HonorableKillGlory + AscensionGlory::KillingBlowBonusGlory, 10u);
    EXPECT_EQ(AscensionGlory::BattlegroundWinGlory, 50u);
    EXPECT_EQ(AscensionGlory::NodeCaptureGlory, 50u);
}

TEST(AscensionGlory, WarsongFlagCapturesAwardThirtyThree)
{
    EXPECT_EQ(AscensionGlory::ObjectiveReward(BATTLEGROUND_WS, SCORE_FLAG_CAPTURES, 1), 33u);
    EXPECT_EQ(AscensionGlory::ObjectiveReward(BATTLEGROUND_WS, SCORE_FLAG_CAPTURES, 2), 66u);
    EXPECT_EQ(AscensionGlory::ObjectiveReward(BATTLEGROUND_EY, SCORE_FLAG_CAPTURES, 1), 5u);
}

TEST(AscensionGlory, ObjectivesAwardFiveGloryEach)
{
    for (uint32 type : {SCORE_BASES_ASSAULTED, SCORE_BASES_DEFENDED, SCORE_MINES_CAPTURED})
    {
        EXPECT_EQ(AscensionGlory::ObjectiveReward(BATTLEGROUND_AB, type, 1), 5u) << type;
        EXPECT_EQ(AscensionGlory::ObjectiveReward(BATTLEGROUND_AB, type, 2), 10u) << type;
    }

    for (uint32 type : {SCORE_GRAVEYARDS_ASSAULTED, SCORE_GRAVEYARDS_DEFENDED, SCORE_TOWERS_ASSAULTED,
        SCORE_TOWERS_DEFENDED})
    {
        EXPECT_EQ(AscensionGlory::ObjectiveReward(BATTLEGROUND_AV, type, 1), 5u) << type;
        EXPECT_EQ(AscensionGlory::ObjectiveReward(BATTLEGROUND_AV, type, 2), 10u) << type;
    }
}

TEST(AscensionGlory, OtherScoresAwardNoObjectiveGlory)
{
    for (uint32 type : {SCORE_KILLING_BLOWS, SCORE_DEATHS, SCORE_HONORABLE_KILLS, SCORE_BONUS_HONOR, SCORE_DAMAGE_DONE,
        SCORE_HEALING_DONE, SCORE_FLAG_RETURNS, SCORE_DESTROYED_DEMOLISHER, SCORE_DESTROYED_WALL})
        EXPECT_EQ(AscensionGlory::ObjectiveReward(BATTLEGROUND_WS, type, 1), 0u) << type;
}

TEST(AscensionGlory, SaturatesInsteadOfWrapping)
{
    uint32 const max = std::numeric_limits<uint32>::max();
    EXPECT_EQ(AscensionGlory::Accrue(max - 5, 10), max);
    EXPECT_EQ(AscensionGlory::Accrue(max, max), max);
    EXPECT_EQ(AscensionGlory::ObjectiveReward(BATTLEGROUND_WS, SCORE_FLAG_CAPTURES, max), max);
    EXPECT_EQ(AscensionGlory::ObjectiveReward(BATTLEGROUND_AB, SCORE_BASES_ASSAULTED, max), max);
}

TEST(AscensionGlory, GloryToNextRankFollowsTheClientTable)
{
    EXPECT_EQ(AscensionGlory::GloryToNextRank(0), 250u);
    EXPECT_EQ(AscensionGlory::GloryToNextRank(249), 1u);
    EXPECT_EQ(AscensionGlory::GloryToNextRank(250), 250u);
    EXPECT_EQ(AscensionGlory::GloryToNextRank(6094), 1906u);
    EXPECT_EQ(AscensionGlory::GloryToNextRank(249999), 1u);
    EXPECT_EQ(AscensionGlory::GloryToNextRank(250000), 0u);
    EXPECT_EQ(AscensionGlory::GloryToNextRank(std::numeric_limits<uint32>::max()), 0u);
}

TEST(AscensionGlory, GainMessageMatchesLive)
{
    EXPECT_EQ(AscensionGlory::GainMessage(50, 6094), "You gained 50 Glory. 1906 Glory needed to reach the next rank.");
    EXPECT_EQ(AscensionGlory::GainMessage(5, 250000), "You gained 5 Glory.");
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
