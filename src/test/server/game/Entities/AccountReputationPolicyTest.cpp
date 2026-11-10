#include "AscensionAccountReputationPolicy.h"
#include <gtest/gtest.h>

using AccountReputation::SiblingStanding;
using AccountReputation::StandingsToRaise;

namespace
{
constexpr uint32 Timbermaw = 576;
constexpr uint32 Darnassus = 69;
constexpr uint32 ArgentDawn = 529;
}

TEST(AccountReputation, SameTeamSiblingsShareEveryVisibleFaction)
{
    EXPECT_TRUE(AccountReputation::IsShared(true, 3100, 0, FACTION_FLAG_VISIBLE));
}

TEST(AccountReputation, OppositeTeamSharesOnlyFactionsWithTheSameBaseStanding)
{
    EXPECT_TRUE(AccountReputation::IsShared(false, -3500, -3500, 0));
    EXPECT_FALSE(AccountReputation::IsShared(false, 3100, -42000, 0));
}

TEST(AccountReputation, HiddenFactionsStayPerCharacter)
{
    EXPECT_FALSE(AccountReputation::IsShared(true, 0, 0, FACTION_FLAG_HIDDEN));
}

TEST(AccountReputation, OnlyStandingEarnedAboveTheSiblingsBaseIsShared)
{
    EXPECT_TRUE(AccountReputation::HasEarned(1));
    EXPECT_FALSE(AccountReputation::HasEarned(0));
    EXPECT_FALSE(AccountReputation::HasEarned(-500));
}

TEST(AccountReputation, CharacterRisesToTheBestSharedSiblingStanding)
{
    std::vector<SiblingStanding> const siblings = {
        { Timbermaw, 9000, true }, { Timbermaw, 21000, true }, { Darnassus, 42999, false } };

    std::map<uint32, int32> const raises = StandingsToRaise(siblings, [](uint32) { return 0; });

    EXPECT_EQ(raises, (std::map<uint32, int32>{ { Timbermaw, 21000 } }));
}

TEST(AccountReputation, HigherOwnStandingIsNeverLowered)
{
    std::vector<SiblingStanding> const siblings = { { Timbermaw, 9000, true }, { ArgentDawn, -2000, true } };

    std::map<uint32, int32> const raises = StandingsToRaise(siblings,
        [](uint32 faction) { return faction == Timbermaw ? 15000 : 0; });

    EXPECT_TRUE(raises.empty());
}
