/*
 * mod-coa-challenges: host-side unit tests for the pure parsing helpers in
 * CoAChallengeParse.h. Registered with the core unit_tests target through
 * ACORE_MODULE_TEST_SOURCES (see mod-coa-challenges.cmake).
 */
#include "CoAChallengeParse.h"

#include <gtest/gtest.h>

using namespace CoAParse;

TEST(CoAParse, SplitDropsEmptyFields)
{
    std::vector<std::string> out = Split("a;b;c", ';');
    ASSERT_EQ(out.size(), 3u);
    EXPECT_EQ(out[0], "a");
    EXPECT_EQ(out[1], "b");
    EXPECT_EQ(out[2], "c");

    EXPECT_TRUE(Split("", ';').empty());
    EXPECT_EQ(Split("a;", ';').size(), 1u);
    EXPECT_EQ(Split("a;;b", ';').size(), 2u); // empty middle dropped
}

TEST(CoAParse, SplitKeepEmptyPreservesSlots)
{
    std::vector<std::string> out = SplitKeepEmpty("1//3", '/');
    ASSERT_EQ(out.size(), 3u);
    EXPECT_EQ(out[0], "1");
    EXPECT_EQ(out[1], "");
    EXPECT_EQ(out[2], "3");

    out = SplitKeepEmpty("/5", '/');
    ASSERT_EQ(out.size(), 2u);
    EXPECT_EQ(out[0], "");
    EXPECT_EQ(out[1], "5");
}

TEST(CoAParse, LootObjectiveTargetsItemAndGatesOnThirdValue)
{
    std::vector<Entry> objectives = ParseEntries(
        "CHALLENGE_REQUIREMENT_TYPE_LOOT_ITEM_BEFORE_LEVEL:1/6294/15;"
        "CHALLENGE_REQUIREMENT_TYPE_KILL_CREATURE_BEFORE_LEVEL:639/21/0;"
        "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_QUEST_BEFORE_LEVEL:208/40/0");
    ASSERT_EQ(objectives.size(), 3u);

    EXPECT_EQ(ObjectiveTarget(objectives[0]), 6294u);
    EXPECT_EQ(ObjectiveGateLevel(objectives[0]), 15u);
    EXPECT_EQ(ObjectiveTarget(objectives[1]), 639u);
    EXPECT_EQ(ObjectiveGateLevel(objectives[1]), 21u);
    EXPECT_EQ(ObjectiveTarget(objectives[2]), 208u);
    EXPECT_EQ(ObjectiveGateLevel(objectives[2]), 40u);
}

TEST(CoAParse, PlayerLevelScalingRuleBlocksCreatureAndQuestScaling)
{
    EXPECT_EQ(LevelScalingBlockBits("CHALLENGE_RULES_TYPE_NO_CREATURE_LEVEL_SCALING"), LevelScalingBlockCreature);
    EXPECT_EQ(LevelScalingBlockBits("CHALLENGE_RULES_TYPE_NO_QUEST_LEVEL_SCALING"), LevelScalingBlockQuest);
    EXPECT_EQ(LevelScalingBlockBits("CHALLENGE_RULES_TYPE_NO_PLAYER_LEVEL_SCALING"),
        LevelScalingBlockCreature | LevelScalingBlockQuest);
    EXPECT_EQ(LevelScalingBlockBits("CHALLENGE_RULES_TYPE_NO_PORTALS"), 0u);

    bool tracked = false;
    for (char const* rule : LevelScalingRules)
        tracked |= std::string(rule) == "CHALLENGE_RULES_TYPE_NO_PLAYER_LEVEL_SCALING";
    EXPECT_TRUE(tracked);
}

TEST(CoAParse, ToU32IsStrict)
{
    EXPECT_EQ(ToU32("0"), 0u);
    EXPECT_EQ(ToU32("12345"), 12345u);
    EXPECT_EQ(ToU32(""), 0u);
    // Sign, partial and overflow must not be silently accepted.
    EXPECT_EQ(ToU32("-1"), 0u);
    EXPECT_EQ(ToU32("+7"), 0u);
    EXPECT_EQ(ToU32("12abc"), 0u);
    EXPECT_EQ(ToU32("99999999999"), 0u);
    EXPECT_EQ(ToU32("4294967295"), 0xFFFFFFFFu);
    EXPECT_EQ(ToU32("4294967296"), 0u);
}

TEST(CoAParse, ParseEntriesReadsValues)
{
    std::vector<Entry> out = ParseEntries(
        "CHALLENGE_REQUIREMENT_TYPE_KILL_CREATURE_BEFORE_LEVEL:1234/9;"
        "CHALLENGE_REQUIREMENT_TYPE_DUO");
    ASSERT_EQ(out.size(), 2u);
    EXPECT_EQ(out[0].type, "CHALLENGE_REQUIREMENT_TYPE_KILL_CREATURE_BEFORE_LEVEL");
    EXPECT_EQ(out[0].v1, 1234u);
    EXPECT_EQ(out[0].v2, 9u);
    EXPECT_EQ(out[0].v3, 0u);
    EXPECT_EQ(out[0].key, "CHALLENGE_REQUIREMENT_TYPE_KILL_CREATURE_BEFORE_LEVEL:1234/9");
    EXPECT_EQ(out[1].type, "CHALLENGE_REQUIREMENT_TYPE_DUO");
    EXPECT_EQ(out[1].v1, 0u);
}

TEST(CoAParse, ParseEntriesKeepsEmptySlotsAligned)
{
    std::vector<Entry> out = ParseEntries("T:/5");
    ASSERT_EQ(out.size(), 1u);
    EXPECT_EQ(out[0].v1, 0u);
    EXPECT_EQ(out[0].v2, 5u);

    out = ParseEntries("T:1//3");
    ASSERT_EQ(out.size(), 1u);
    EXPECT_EQ(out[0].v1, 1u);
    EXPECT_EQ(out[0].v2, 0u);
    EXPECT_EQ(out[0].v3, 3u);
}

TEST(CoAParse, ListContainsIsExact)
{
    EXPECT_TRUE(ListContains("A;B;C", "B"));
    EXPECT_FALSE(ListContains("A;BC;C", "B"));
    EXPECT_FALSE(ListContains("", "B"));
}

TEST(CoAParse, IsTrackedObjectiveMatchesKnownTypes)
{
    EXPECT_TRUE(IsTrackedObjective("CHALLENGE_REQUIREMENT_TYPE_KILL_CREATURE_BEFORE_LEVEL"));
    EXPECT_TRUE(IsTrackedObjective("CHALLENGE_REQUIREMENT_TYPE_DUO"));
    EXPECT_FALSE(IsTrackedObjective("CHALLENGE_REQUIREMENT_TYPE_NONE"));
    EXPECT_FALSE(IsTrackedObjective(""));
}

TEST(CoAParse, RequirementTypeIndexOrder)
{
    EXPECT_EQ(RequirementTypeIndex("CHALLENGE_REQUIREMENT_TYPE_COMPLETE_QUEST_BEFORE_LEVEL"), 1u);
    EXPECT_EQ(RequirementTypeIndex("CHALLENGE_REQUIREMENT_TYPE_KILL_CREATURE_BEFORE_LEVEL"), 6u);
    EXPECT_EQ(RequirementTypeIndex("CHALLENGE_REQUIREMENT_TYPE_REACH_REPUTATION_WITHIN_TIME"), 22u);
    // Unknown -> NONE (0).
    EXPECT_EQ(RequirementTypeIndex("NOT_A_REAL_TYPE"), 0u);
}
