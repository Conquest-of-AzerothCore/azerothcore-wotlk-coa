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
