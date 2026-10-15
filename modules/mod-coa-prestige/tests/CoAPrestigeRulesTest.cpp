/*
 * mod-coa-prestige: host-side unit tests for CoAPrestigeRules.h. Registered with the core
 * unit_tests target through ACORE_MODULE_TEST_SOURCES (see mod-coa-prestige.cmake).
 */
#include "CoAPrestigeRules.h"

#include <gtest/gtest.h>

#include <limits>
#include <map>

using namespace CoAPrestige;

TEST(CoAPrestige, GossipOptionsMatchTheClientWindow)
{
    // PrestigeModeUI.MSGS.GOSSIP_OPTION_* in AscensionUI/Gossips/PrestigeMode.lua.
    EXPECT_EQ(OptionActivate, "I would like to prestige!");
    EXPECT_EQ(OptionRewards, "I would like to purchase Prestige items!");
    EXPECT_EQ(OptionExperienceItems, "GOSSIP_ACTION_EXPERIENCE_ITEMS");
    EXPECT_EQ(ChromieEntry, 178081u);
    EXPECT_EQ(PrestigedAura, 9930831u);
}

TEST(CoAPrestige, LoginCatchesUpThePrestigeAchievementsALevelIsMissing)
{
    EXPECT_EQ(MissingPrestigeCredits(0, 0), 0u);
    EXPECT_EQ(MissingPrestigeCredits(1, 0), 1u);
    EXPECT_EQ(MissingPrestigeCredits(3, 1), 2u);
    EXPECT_EQ(MissingPrestigeCredits(3, 3), 0u);
    EXPECT_EQ(MissingPrestigeCredits(12, 4), 6u);
    EXPECT_EQ(MissingPrestigeCredits(12, 10), 0u);
}

TEST(CoAPrestige, StateRoundTripsThroughTheSetting)
{
    State const state{ 3, true, 25 };
    EXPECT_EQ(EncodeState(state), (std::vector<uint32_t>{ 3, 1, 25 }));
    EXPECT_EQ(DecodeState(EncodeState(state)), state);

    EXPECT_EQ(DecodeState({}), State{});
    EXPECT_EQ(DecodeState({ 7 }), (State{ 7, false, 0 }));
    EXPECT_EQ(DecodeState({ 2, 0, 31 }), (State{ 2, false, 31 }));
}

TEST(CoAPrestige, ActivationNeedsTheLevelAClassAndASpecialization)
{
    ActivationFacts ready;
    ready.level = 60;
    ready.specialization = 25;
    EXPECT_EQ(CheckActivation(ready), Refusal::None);

    ActivationFacts facts = ready;
    facts.level = 59;
    EXPECT_EQ(CheckActivation(facts), Refusal::BelowLevel);

    facts = ready;
    facts.level = 61;
    EXPECT_EQ(CheckActivation(facts), Refusal::None);

    facts = ready;
    facts.enabled = false;
    EXPECT_EQ(CheckActivation(facts), Refusal::Disabled);

    facts = ready;
    facts.customClass = false;
    EXPECT_EQ(CheckActivation(facts), Refusal::NotCustomClass);

    facts = ready;
    facts.active = true;
    EXPECT_EQ(CheckActivation(facts), Refusal::InProgress);

    facts = ready;
    facts.specialization = 0;
    EXPECT_EQ(CheckActivation(facts), Refusal::NoSpecialization);
}

TEST(CoAPrestige, ActivationNeedsAQuietMomentInTheOpenWorld)
{
    ActivationFacts ready;
    ready.level = 60;
    ready.specialization = 25;

    ActivationFacts facts = ready;
    facts.alive = false;
    EXPECT_EQ(CheckActivation(facts), Refusal::Dead);

    facts = ready;
    facts.inCombat = true;
    EXPECT_EQ(CheckActivation(facts), Refusal::InCombat);

    facts = ready;
    facts.travelling = true;
    EXPECT_EQ(CheckActivation(facts), Refusal::Travelling);

    facts = ready;
    facts.inInstance = true;
    EXPECT_EQ(CheckActivation(facts), Refusal::NotInOpenWorld);
}

TEST(CoAPrestige, RefusalsExplainThemselves)
{
    // PRESTIGE_UI_ERROR_LEVEL, the client's own wording for the same refusal.
    EXPECT_EQ(RefusalMessage(Refusal::BelowLevel, 60),
        "You must be level 60 or higher to participate in Prestige Mode");
    EXPECT_TRUE(RefusalMessage(Refusal::None, 60).empty());
    for (Refusal refusal : { Refusal::Disabled, Refusal::NotCustomClass, Refusal::InProgress, Refusal::NoSpecialization,
             Refusal::Dead, Refusal::InCombat, Refusal::Travelling, Refusal::NotInOpenWorld })
        EXPECT_FALSE(RefusalMessage(refusal, 60).empty());
}

TEST(CoAPrestige, TheSpecializationStaysLockedWhilePrestiging)
{
    State const prestiging{ 1, true, 25 };
    EXPECT_FALSE(IsSpecializationSwitchAllowed(prestiging, 26));
    EXPECT_TRUE(IsSpecializationSwitchAllowed(prestiging, 25));

    State const finished{ 1, false, 25 };
    EXPECT_TRUE(IsSpecializationSwitchAllowed(finished, 26));
    EXPECT_TRUE(IsSpecializationSwitchAllowed(State{}, 26));
    EXPECT_EQ(SpecializationLockedMessage(60),
        "Your active specialization is prestige locked until you reach level 60.");
}

TEST(CoAPrestige, CompletedPrestigeKeepsOnlySignatureRestorationPending)
{
    State const pending{ 1, false, 17, true };
    EXPECT_EQ(EncodeState(pending), (std::vector<uint32_t>{ 1, 0, 17, 1 }));
    EXPECT_EQ(DecodeState(EncodeState(pending)), pending);
    EXPECT_TRUE(IsSpecializationSwitchAllowed(DecodeState(EncodeState(pending)), 18));

    EXPECT_FALSE(DecodeState({ 1, 0, 17 }).signaturePending);
    EXPECT_FALSE(DecodeState({ 1, 0, 17, 0 }).signaturePending);
}

TEST(CoAPrestige, OnlyLevellingZoneAndDungeonQuestsAreReplayed)
{
    QuestTraits const zoneQuest{ 12, 20, QuestTypeNormal, false };
    EXPECT_TRUE(IsReplayableQuest(zoneQuest, 60));

    QuestTraits quest = zoneQuest;
    quest.type = QuestTypeGroup;
    EXPECT_TRUE(IsReplayableQuest(quest, 60));
    quest.type = QuestTypeEscort;
    EXPECT_TRUE(IsReplayableQuest(quest, 60));

    quest.type = QuestTypeDungeon;
    EXPECT_TRUE(IsReplayableQuest(quest, 60)) << "dungeon";

    quest = zoneQuest;
    quest.type = 62;
    EXPECT_FALSE(IsReplayableQuest(quest, 60)) << "raid";
    quest.type = 41;
    EXPECT_FALSE(IsReplayableQuest(quest, 60)) << "PvP";

    quest = zoneQuest;
    quest.zoneOrSort = -161;
    EXPECT_FALSE(IsReplayableQuest(quest, 60)) << "class quest";
    quest.zoneOrSort = -182;
    EXPECT_FALSE(IsReplayableQuest(quest, 60)) << "profession quest";

    quest = zoneQuest;
    quest.repeatable = true;
    EXPECT_FALSE(IsReplayableQuest(quest, 60));

    quest = zoneQuest;
    quest.level = 61;
    EXPECT_FALSE(IsReplayableQuest(quest, 60));
    quest.level = 60;
    EXPECT_TRUE(IsReplayableQuest(quest, 60));
    quest.level = 0;
    EXPECT_FALSE(IsReplayableQuest(quest, 60));

    quest = zoneQuest;
    quest.level = ScaledQuestLevel;
    quest.minLevel = 3;
    EXPECT_TRUE(IsReplayableQuest(quest, 60)) << "scales with the player";
    quest.minLevel = 61;
    EXPECT_FALSE(IsReplayableQuest(quest, 60)) << "scales, but opens above the Prestige level";
    quest.minLevel = 3;
    quest.zoneOrSort = -161;
    EXPECT_FALSE(IsReplayableQuest(quest, 60)) << "scaled class quest";
}

TEST(CoAPrestige, RewardsParseAsItemCountPairs)
{
    std::optional<std::vector<RewardItem>> rewards = ParseRewards("1287330:1 375250:100000 90004:100");
    ASSERT_TRUE(rewards);
    EXPECT_EQ(*rewards, (std::vector<RewardItem>{ { 1287330, 1 }, { 375250, 100000 }, { 90004, 100 } }));

    rewards = ParseRewards(" 97304:1,375250:100000 ");
    ASSERT_TRUE(rewards);
    EXPECT_EQ(*rewards, (std::vector<RewardItem>{ { 97304, 1 }, { 375250, 100000 } }));

    rewards = ParseRewards("");
    ASSERT_TRUE(rewards);
    EXPECT_TRUE(rewards->empty());

    EXPECT_FALSE(ParseRewards("1287330"));
    EXPECT_FALSE(ParseRewards("1287330:"));
    EXPECT_FALSE(ParseRewards("1287330:0"));
    EXPECT_FALSE(ParseRewards("0:1"));
    EXPECT_FALSE(ParseRewards("cache:1"));
    EXPECT_FALSE(ParseRewards("1287330:1x"));
}

TEST(CoAPrestige, ExperienceBonusMultipliesAndSaturates)
{
    EXPECT_EQ(ApplyExperienceBonus(456, 150), 1140u);
    EXPECT_EQ(ApplyExperienceBonus(146, 150), 365u);
    EXPECT_EQ(ApplyExperienceBonus(100, 0), 100u);
    EXPECT_EQ(ApplyExperienceBonus(0, 150), 0u);
    EXPECT_EQ(ApplyExperienceBonus(std::numeric_limits<uint32_t>::max(), 150), std::numeric_limits<uint32_t>::max());
}

TEST(CoAPrestige, TheActionBarRoundTripsThroughTheSetting)
{
    std::vector<BarSlot> const bar = { { 0, 500125 }, { 11, 681078 }, { 72, 92112 } };
    std::vector<uint32_t> const values = EncodeBar(bar);
    EXPECT_EQ(values, (std::vector<uint32_t>{ 3, 0, 500125, 11, 681078, 72, 92112 }));
    EXPECT_EQ(DecodeBar(values), bar);

    EXPECT_TRUE(DecodeBar({}).empty());
    EXPECT_TRUE(DecodeBar({ 0, 5, 100 }).empty()) << "a count of 0 is an empty bar";
    EXPECT_EQ(DecodeBar({ 5, 1, 100 }), (std::vector<BarSlot>{ { 1, 100 } })) << "a count past the data is cut";
    EXPECT_EQ(DecodeBar({ 2, 1, 0, 2, 200 }), (std::vector<BarSlot>{ { 2, 200 } })) << "a claimed slot is skipped";
}

TEST(CoAPrestige, ALearnedRankClaimsTheButtonsOfItsChain)
{
    std::map<uint32_t, uint32_t> const firstRank = { { 100, 100 }, { 101, 100 }, { 105, 100 }, { 200, 200 } };
    auto firstRankOf = [&](uint32_t spell)
    {
        auto const found = firstRank.find(spell);
        return found == firstRank.end() ? spell : found->second;
    };

    std::vector<BarSlot> bar = { { 1, 105 }, { 2, 200 }, { 3, 101 } };
    EXPECT_EQ(ClaimButtons(bar, 100, firstRankOf), (std::vector<uint8_t>{ 1, 3 }));
    EXPECT_EQ(bar, (std::vector<BarSlot>{ { 2, 200 } }));

    EXPECT_TRUE(ClaimButtons(bar, 101, firstRankOf).empty()) << "a later rank finds its buttons already claimed";
    EXPECT_TRUE(ClaimButtons(bar, 300, firstRankOf).empty());
    EXPECT_EQ(ClaimButtons(bar, 200, firstRankOf), (std::vector<uint8_t>{ 2 }));
    EXPECT_TRUE(bar.empty());
}

TEST(CoAPrestige, ThePrestigeDailiesAreExemptFromTheQuestReset)
{
    for (PrestigeDaily const& daily : PrestigeDailies)
        EXPECT_TRUE(IsPrestigeDaily(daily.questId));
    EXPECT_FALSE(IsPrestigeDaily(0));
    EXPECT_FALSE(IsPrestigeDaily(1));
    EXPECT_FALSE(IsPrestigeDaily(900001));
}
