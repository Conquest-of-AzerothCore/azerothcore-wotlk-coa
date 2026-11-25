/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDifficultyRelease.h"
#include "gtest/gtest.h"
#include <algorithm>

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

TEST(AscensionDifficultyRelease, BurningCrusadeEventsFollowTheirDifficulty)
{
    std::vector<uint16> const burningCrusadeHeroic = { 339, 400, 401, 402, 403, 404 };
    std::vector<uint16> const burningCrusadeMythic = { 365, 221, 222, 223, 224, 225 };
    std::vector<uint16> const heroicStage = AscensionDifficultyRelease::ReleasedEvents(1);
    std::vector<uint16> const mythicStage = AscensionDifficultyRelease::ReleasedEvents(2);
    auto released = [](std::vector<uint16> const& events, uint16 event)
    {
        return std::ranges::find(events, event) != events.end();
    };

    for (uint16 event : burningCrusadeHeroic)
    {
        EXPECT_TRUE(released(heroicStage, event)) << event;
        EXPECT_TRUE(released(mythicStage, event)) << event;
    }
    for (uint16 event : burningCrusadeMythic)
    {
        EXPECT_FALSE(released(heroicStage, event)) << event;
        EXPECT_TRUE(released(mythicStage, event)) << event;
    }
}
