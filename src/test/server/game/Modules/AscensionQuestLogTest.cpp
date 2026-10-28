/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionQuestLog.h"
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

TEST(AscensionQuestLog, LevelOfFirstSlotIsAddonField61)
{
    ObjectGuid const guid = ObjectGuid::Create<HighGuid::Player>(4242);
    ExpectAddonField(AscensionQuestLog::BuildLevel(guid, 0, 12), guid, 61, 12);
}

TEST(AscensionQuestLog, RewardXPOfFirstSlotIsAddonField36)
{
    ObjectGuid const guid = ObjectGuid::Create<HighGuid::Player>(4242);
    ExpectAddonField(AscensionQuestLog::BuildRewardXP(guid, 0, 1450), guid, 36, 1450);
}

TEST(AscensionQuestLog, LastSlotStaysInsideItsFieldRange)
{
    ObjectGuid const guid = ObjectGuid::Create<HighGuid::Player>(7);
    ExpectAddonField(AscensionQuestLog::BuildRewardXP(guid, 24, 90), guid, 60, 90);
    ExpectAddonField(AscensionQuestLog::BuildLevel(guid, 24, 80), guid, 85, 80);
}
