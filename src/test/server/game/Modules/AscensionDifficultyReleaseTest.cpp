/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDifficultyRelease.h"
#include "gtest/gtest.h"

TEST(AscensionDifficultyRelease, ActiveEventMatchesTheClientGameEventInfoLayout)
{
    WorldPacket data = AscensionDifficultyRelease::BuildActiveEvent(728);

    EXPECT_EQ(data.GetOpcode(), 0x09BD);
    ASSERT_EQ(data.size(), 52u);
    EXPECT_EQ(data.read<uint16>(), 728u);
    EXPECT_EQ(data.read<uint8>(), 0u);
    EXPECT_EQ(data.read<uint64>(), 0u);
    EXPECT_EQ(data.read<uint64>(), 0u);
    EXPECT_EQ(data.read<uint8>(), 1u);
    EXPECT_EQ(data.read<uint32>(), 0u);
    while (data.rpos() < data.size())
        EXPECT_EQ(data.read<uint8>(), 0u) << data.rpos();
}

TEST(AscensionDifficultyRelease, ReleasedEventsFollowTheReleaseLadder)
{
    using AscensionDifficultyRelease::HeroicDungeonEvents;
    using AscensionDifficultyRelease::MythicDungeonEvents;
    std::vector<uint16> const heroic(HeroicDungeonEvents.begin(), HeroicDungeonEvents.end());
    std::vector<uint16> both = heroic;
    both.insert(both.end(), MythicDungeonEvents.begin(), MythicDungeonEvents.end());

    EXPECT_TRUE(AscensionDifficultyRelease::ReleasedEvents(0).empty());
    EXPECT_EQ(AscensionDifficultyRelease::ReleasedEvents(1), heroic);
    EXPECT_EQ(AscensionDifficultyRelease::ReleasedEvents(2), both);
    EXPECT_EQ(AscensionDifficultyRelease::ReleasedEvents(8), both);
}
