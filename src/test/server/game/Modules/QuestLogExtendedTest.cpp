/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "QuestLogExtended.h"
#include "gtest/gtest.h"

#include <vector>

namespace
{
std::vector<uint8> Bytes(WorldPacket const& packet)
{
    return { packet.contents(), packet.contents() + packet.size() };
}

std::pair<uint32, uint32> NoLevelOrXp(uint32)
{
    return { 0, 0 };
}

WorldPacket Hello(uint8 version, uint8 maxSlots)
{
    WorldPacket packet(QuestLogExtended::HelloOpcode, 2);
    packet << version << maxSlots;
    return packet;
}
}

TEST(QuestLogExtended, BuildStateLayout)
{
    QuestLogExtended::Entry entry{ 40, 777, 3, { 1, 2, 3, 4 }, 0, 21, 1350 };

    WorldPacket packet = QuestLogExtended::BuildState({ entry }, 64, true);

    std::vector<uint8> const expected = {
        0x01, 0x01, 0x40, 0x01,
        0x28,
        0x09, 0x03, 0x00, 0x00,
        0x03, 0x00, 0x00, 0x00,
        0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x04, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x15, 0x00, 0x00, 0x00,
        0x46, 0x05, 0x00, 0x00 };
    EXPECT_EQ(packet.GetOpcode(), QuestLogExtended::StateOpcode);
    EXPECT_EQ(packet.size(), 33u);
    EXPECT_EQ(Bytes(packet), expected);
}

TEST(QuestLogExtended, BuildStateDeltaClearsSlot)
{
    QuestLogExtended::Entry entry{ 40, 0, 0, {}, 0, 0, 0 };

    std::vector<uint8> const bytes = Bytes(QuestLogExtended::BuildState({ entry }, 64, false));

    EXPECT_EQ(bytes[1], 0);
    EXPECT_EQ(bytes[3], 1);
    EXPECT_EQ(bytes[4], 40);
    EXPECT_EQ(bytes[5] | bytes[6] | bytes[7] | bytes[8], 0);
}

TEST(QuestLogExtended, SnapshotSkipsNativeAndEmpty)
{
    QuestLogSlots slots;
    slots[3].QuestId = 1000;
    slots[30].QuestId = 2000;
    slots[63].QuestId = 3000;

    auto const entries = QuestLogExtended::Snapshot(slots, NoLevelOrXp);

    ASSERT_EQ(entries.size(), 2u);
    EXPECT_EQ(entries[0].Slot, 30);
    EXPECT_EQ(entries[0].QuestId, 2000u);
    EXPECT_EQ(entries[1].Slot, 63);
    EXPECT_EQ(entries[1].QuestId, 3000u);
}

TEST(QuestLogExtended, SnapshotSplitsCountersAndAppliesLevelAndXp)
{
    QuestLogSlots slots;
    slots[30].QuestId = 2000;
    slots[30].State = 3;
    slots[30].Time = 99;
    slots[30].Counters = 0x0004000300020001ull;

    auto const entries = QuestLogExtended::Snapshot(slots, [](uint32 questId)
    {
        return std::pair<uint32, uint32>{ questId / 100, questId * 2 };
    });

    ASSERT_EQ(entries.size(), 1u);
    EXPECT_EQ(entries[0].State, 3u);
    EXPECT_EQ(entries[0].Time, 99u);
    EXPECT_EQ(entries[0].Level, 20u);
    EXPECT_EQ(entries[0].RewardXP, 4000u);
    for (uint16 i = 0; i < 4; ++i)
        EXPECT_EQ(entries[0].Counters[i], i + 1);
}

TEST(QuestLogExtended, SnapshotIncludesSlotsAboveLogSize)
{
    QuestLogSlots slots;
    slots[60].QuestId = 4000;

    auto const entries = QuestLogExtended::Snapshot(slots, NoLevelOrXp);
    ASSERT_EQ(entries.size(), 1u);
    EXPECT_EQ(entries[0].Slot, 60);

    std::vector<uint8> const bytes = Bytes(QuestLogExtended::BuildState(entries, 30, true));
    EXPECT_EQ(bytes[3], 1);
    EXPECT_EQ(bytes[4], 60);
}

TEST(QuestLogExtended, ParseHelloAcceptsVersion1)
{
    auto const hello = QuestLogExtended::ParseHello(Hello(1, 64));

    ASSERT_TRUE(hello.has_value());
    EXPECT_EQ(hello->Version, 1);
    EXPECT_EQ(hello->ClientMaxSlots, 64);
}

TEST(QuestLogExtended, ParseHelloRejectsVersion2AndShort)
{
    EXPECT_FALSE(QuestLogExtended::ParseHello(Hello(2, 64)).has_value());
    EXPECT_FALSE(QuestLogExtended::ParseHello(Hello(1, 24)).has_value());

    WorldPacket shortPacket(QuestLogExtended::HelloOpcode, 1);
    shortPacket << uint8(1);
    EXPECT_FALSE(QuestLogExtended::ParseHello(shortPacket).has_value());
}
