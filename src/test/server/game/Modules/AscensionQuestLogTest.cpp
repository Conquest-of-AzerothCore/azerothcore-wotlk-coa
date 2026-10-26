/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionQuestLog.h"
#include "UpdateFieldFlags.h"
#include "gtest/gtest.h"

namespace
{
void ExpectAddonField(WorldPacket data, ObjectGuid guid, uint32 field, uint32 value)
{
    EXPECT_EQ(data.GetOpcode(), 0x0578);
    ASSERT_EQ(data.size(), 16u);
    EXPECT_EQ(data.read<uint64>(), guid.GetRawValue());
    EXPECT_EQ(data.read<uint32>(), field);
    EXPECT_EQ(data.read<uint32>(), value);
}
}

TEST(AscensionQuestLog, LevelOfFirstSlotIsAddonField100)
{
    ObjectGuid const guid = ObjectGuid::Create<HighGuid::Player>(4242);
    ExpectAddonField(AscensionQuestLog::BuildLevel(guid, 0, 12), guid, 100, 12);
}

TEST(AscensionQuestLog, RewardXPOfFirstSlotIsAddonField36)
{
    ObjectGuid const guid = ObjectGuid::Create<HighGuid::Player>(4242);
    ExpectAddonField(AscensionQuestLog::BuildRewardXP(guid, 0, 1450), guid, 36, 1450);
}

TEST(AscensionQuestLog, LastSlotStaysInsideItsFieldRange)
{
    ObjectGuid const guid = ObjectGuid::Create<HighGuid::Player>(7);
    ExpectAddonField(AscensionQuestLog::BuildRewardXP(guid, 63, 90), guid, 99, 90);
    ExpectAddonField(AscensionQuestLog::BuildLevel(guid, 63, 80), guid, 163, 80);
}

TEST(AscensionQuestLog, All64SlotsHavePrivateStateAndPartyQuestIds)
{
    ASSERT_EQ(MAX_QUEST_LOG_SIZE, 64);
    ASSERT_EQ(PLAYER_VISIBLE_ITEM_1_ENTRYID, PLAYER_QUEST_LOG_1_1 + 64 * 5);
    ASSERT_EQ(PLAYER_QUEST_LOG_64_5 + 1, PLAYER_VISIBLE_ITEM_1_ENTRYID);
    for (uint32 slot = 0; slot < 64; ++slot)
    {
        uint32 const first = PLAYER_QUEST_LOG_1_1 + slot * 5;
        EXPECT_EQ(UnitUpdateFieldFlags[first], uint32(UF_FLAG_PARTY_MEMBER));
        for (uint32 field = 1; field < 5; ++field)
            EXPECT_EQ(UnitUpdateFieldFlags[first + field], uint32(UF_FLAG_PRIVATE));
    }
    EXPECT_EQ(UnitUpdateFieldFlags[PLAYER_VISIBLE_ITEM_1_ENTRYID], uint32(UF_FLAG_PUBLIC));
    EXPECT_EQ(UnitUpdateFieldFlags[PLAYER_PET_SPELL_POWER], uint32(UF_FLAG_PRIVATE));
}

TEST(AscensionQuestLog, AddonRewardAndLevelRangesDoNotOverlap)
{
    EXPECT_EQ(AscensionQuestLog::RewardXPField + MAX_QUEST_LOG_SIZE, AscensionQuestLog::LevelField);
    EXPECT_LT(AscensionQuestLog::RewardXPField + MAX_QUEST_LOG_SIZE - 1, AscensionQuestLog::LevelField);
}
