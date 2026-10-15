/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAGameplayIsolation.h"
#include "ObjectMgr.h"
#include "SharedDefines.h"
#include "WorldMock.h"
#include "gtest/gtest.h"
#include <algorithm>
#include <cctype>
#include <stdexcept>
#include <unordered_set>
#include <vector>

using namespace CoAGameplay;

namespace
{
constexpr uint32 NameSampleSize = 100000;

std::string Lower(std::string text)
{
    std::transform(text.begin(), text.end(), text.begin(), [](unsigned char c) { return char(std::tolower(c)); });
    return text;
}

bool IsVowel(char c)
{
    return std::string_view("aeiou").find(c) != std::string_view::npos;
}

std::vector<std::string> AllocatedNames(uint32 count)
{
    NameAllocator allocator;
    std::vector<std::string> names;
    names.reserve(count);
    for (uint32 index = 0; index < count; ++index)
        names.push_back(allocator.Next());
    return names;
}

class CoAGameplayNameTest : public ::testing::Test
{
protected:
    void SetUp() override
    {
        previousWorld = std::move(sWorld);
        world = new ::testing::NiceMock<WorldMock>();
        ON_CALL(*world, getIntConfig(::testing::_)).WillByDefault(::testing::Return(0));
        ON_CALL(*world, getIntConfig(CONFIG_MIN_PLAYER_NAME)).WillByDefault(::testing::Return(2));
        sWorld.reset(world);
    }

    void TearDown() override
    {
        sWorld = std::move(previousWorld);
    }

    void UseStrictPlayerNames(uint32 mask)
    {
        ON_CALL(*world, getIntConfig(CONFIG_STRICT_PLAYER_NAMES)).WillByDefault(::testing::Return(mask));
    }

    ::testing::NiceMock<WorldMock>* world = nullptr;
    std::unique_ptr<IWorld> previousWorld;
};
}

TEST(CoAGameplayIsolationTest, FirstLaneKeepsTheFixturePhase)
{
    EXPECT_EQ(LanePhase(0), 1u << 30);
    EXPECT_EQ(LanePhase(0), FixturePhaseMask);
    EXPECT_EQ(LanePhases(1), FixturePhaseMask);
}

TEST(CoAGameplayIsolationTest, ConcurrentLanesUseBitsSixteenToTwentyNine)
{
    uint32 seen = 0;
    for (uint32 lane = 1; lane < MaxLanes; ++lane)
    {
        EXPECT_EQ(LanePhase(lane), 1u << (15 + lane)) << lane;
        EXPECT_EQ(seen & LanePhase(lane), 0u) << lane;
        seen |= LanePhase(lane);
    }
    EXPECT_EQ(seen, 0x3FFF0000u);
    EXPECT_EQ(LanePhases(MaxLanes), 0x7FFF0000u);
    EXPECT_EQ(LanePhases(3), (1u << 30) | (1u << 16) | (1u << 17));
    EXPECT_EQ(LanePhases(0), 0u);
    EXPECT_EQ(LanePhases(MaxLanes) & 0x8000FFFFu, 0u);
}

TEST(CoAGameplayIsolationTest, RejectsLanesBeyondTheLimit)
{
    EXPECT_EQ(MaxLanes, 15u);
    EXPECT_THROW(LanePhase(MaxLanes), std::out_of_range);
    EXPECT_THROW(LanePhase(31), std::out_of_range);
    EXPECT_THROW(LanePhases(MaxLanes + 1), std::out_of_range);
}

TEST(CoAGameplayIsolationTest, GeneratedNamesFollowAFixedPattern)
{
    EXPECT_EQ(GeneratedName(0), "Hababababa");
    EXPECT_EQ(GeneratedName(1), "Hababababe");
    EXPECT_EQ(GeneratedName(2), "Hababababi");
    EXPECT_EQ(GeneratedName(5), "Habababaca");
    EXPECT_EQ(GeneratedNameCapacity, 500000000u);
    EXPECT_EQ(GeneratedName(GeneratedNameCapacity - 1), "Huzuzuzuzu");
    EXPECT_THROW(GeneratedName(GeneratedNameCapacity), std::out_of_range);

    NameAllocator allocator;
    for (uint64 index = 0; index < 64; ++index)
        EXPECT_EQ(allocator.Next(), GeneratedName(index));
}

TEST_F(CoAGameplayNameTest, AllocatedNamesAreUniqueValidCharacterNames)
{
    std::vector<std::string> const names = AllocatedNames(NameSampleSize);
    std::unordered_set<std::string> unique;
    for (std::string const& name : names)
    {
        ASSERT_EQ(name.size(), GeneratedNameLength) << name;
        ASSERT_EQ(name.front(), 'H') << name;
        for (std::size_t position = 1; position < name.size(); ++position)
        {
            ASSERT_TRUE(name[position] >= 'a' && name[position] <= 'z') << name;
            ASSERT_EQ(IsVowel(name[position]), position % 2 == 1) << name;
            if (position >= 2)
                ASSERT_FALSE(name[position] == name[position - 1] && name[position] == name[position - 2]) << name;
        }

        std::string normalized = name;
        ASSERT_TRUE(normalizePlayerName(normalized)) << name;
        ASSERT_EQ(normalized, name);
        ASSERT_EQ(ObjectMgr::CheckPlayerName(name, true), CHAR_NAME_SUCCESS) << name;
        ASSERT_TRUE(unique.insert(Lower(name)).second) << name;
    }
}

TEST_F(CoAGameplayNameTest, NamesStayValidUnderBasicLatinNameRules)
{
    UseStrictPlayerNames(1);
    for (uint64 index = 0; index < GeneratedNameCapacity; index += GeneratedNameCapacity / 997)
        EXPECT_EQ(ObjectMgr::CheckPlayerName(GeneratedName(index), true), CHAR_NAME_SUCCESS) << index;
}

TEST(CoAGameplayIsolationTest, NoGeneratedNameContainsAnotherOrALegacyName)
{
    std::vector<std::string> sample = AllocatedNames(1500);
    for (uint64 index = 1; index < 500; ++index)
        sample.push_back(GeneratedName(index * (GeneratedNameCapacity / 500) + index));
    for (std::string& name : sample)
        name = Lower(name);

    for (std::size_t outer = 0; outer < sample.size(); ++outer)
    {
        for (char actor = 'a'; actor <= 'h'; ++actor)
            ASSERT_EQ(sample[outer].find(std::string("harness") + actor), std::string::npos) << sample[outer];
        for (std::size_t inner = 0; inner < sample.size(); ++inner)
            if (outer != inner)
                ASSERT_EQ(sample[outer].find(sample[inner]), std::string::npos)
                    << sample[outer] << " contains " << sample[inner];
    }
}

TEST(CoAGameplayIsolationTest, SubstitutesWholeLegacyNames)
{
    std::map<char, std::string> const names{{'a', "Hababababa"}, {'b', "Hababababe"}, {'h', "Hababababi"}};
    EXPECT_EQ(SubstituteLegacyNames("pinfo Harnessa", names), "pinfo Hababababa");
    EXPECT_EQ(SubstituteLegacyNames("Harnessa", names), "Hababababa");
    EXPECT_EQ(SubstituteLegacyNames(".send money Harnessa \"Tithe\" \"\" 5", names),
        ".send money Hababababa \"Tithe\" \"\" 5");
    EXPECT_EQ(SubstituteLegacyNames("Harnessa gives Harnessb to Harnessh", names),
        "Hababababa gives Hababababe to Hababababi");
    EXPECT_EQ(SubstituteLegacyNames("Harnessa,Harnessb", names), "Hababababa,Hababababe");
    EXPECT_EQ(SubstituteLegacyNames("(Harnessa) Harnessb's -Harnessh.", names),
        "(Hababababa) Hababababe's -Hababababi.");
}

TEST(CoAGameplayIsolationTest, LeavesPartialAndUnknownLegacyNamesUnchanged)
{
    std::map<char, std::string> const names{{'a', "Hababababa"}, {'i', "Hababababo"}};
    for (std::string_view text : {"Harnessab", "xHarnessa", "Harnessa1", "Harnessa_", "_Harnessa", "9Harnessa",
        "harnessa", "HARNESSA", "HarnessA", "Harness", "Harness a", "Harnessi", "Harnessc", "", "HarnessHarnessab"})
        EXPECT_EQ(SubstituteLegacyNames(text, names), std::string(text)) << text;
    EXPECT_EQ(SubstituteLegacyNames("Harnessab Harnessa", names), "Harnessab Hababababa");
    EXPECT_EQ(SubstituteLegacyNames("Harnessa", {}), "Harnessa");
}

TEST(CoAGameplayIsolationTest, NonAsciiPunctuationAndSpacesBoundLegacyNames)
{
    std::map<char, std::string> const names{{'a', "Hababababa"}, {'b', "Hababababe"}};
    EXPECT_EQ(SubstituteLegacyNames("Harnessa\xE2\x80\x99s", names), "Hababababa\xE2\x80\x99s");
    EXPECT_EQ(SubstituteLegacyNames("\xC2\xABHarnessa\xC2\xBB", names), "\xC2\xABHababababa\xC2\xBB");
    EXPECT_EQ(SubstituteLegacyNames("tele name Harnessa\xC2\xA0" "Deathknell", names),
        "tele name Hababababa\xC2\xA0" "Deathknell");
    EXPECT_EQ(SubstituteLegacyNames("\xC2\xA0Harnessa\xE2\x80\xA6", names), "\xC2\xA0Hababababa\xE2\x80\xA6");
    EXPECT_EQ(SubstituteLegacyNames("\xE3\x80\x8CHarnessa\xE3\x80\x8D", names),
        "\xE3\x80\x8CHababababa\xE3\x80\x8D");
    EXPECT_EQ(SubstituteLegacyNames("Harnessa\xF0\x9F\x98\x80Harnessb", names),
        "Hababababa\xF0\x9F\x98\x80Hababababe");
}

TEST(CoAGameplayIsolationTest, NonAsciiLettersAndMalformedBytesExtendLegacyNames)
{
    std::map<char, std::string> const names{{'a', "Hababababa"}};
    for (std::string_view text : {"\xC3\xA9Harnessa", "Harnessa\xC3\xA9", "Harnessa\xD0\xB6", "\xE4\xB8\xADHarnessa",
        "Harnessa\xCC\x81", "\xA9Harnessa", "Harnessa\xC3", "\xC3\xA9\xA9Harnessa", "Harnessa\xFF"})
        EXPECT_EQ(SubstituteLegacyNames(text, names), std::string(text)) << text;
}
