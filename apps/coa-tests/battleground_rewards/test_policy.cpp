#include "../../../src/server/coa/CoABattlegroundRewardsPolicy.h"
#include <cassert>
#include <iostream>

using CoABattlegroundRewardsPolicy::RewardQuestFor;

static void PaysNothingOutsideTheBattlegroundLevels()
{
    assert(RewardQuestFor(1, true) == 0);
    assert(RewardQuestFor(9, true) == 0);
    assert(RewardQuestFor(61, false) == 0);
    assert(RewardQuestFor(80, true) == 0);
}

static void PaysTheTenLevelQuestsBelowSixty()
{
    assert(RewardQuestFor(10, true) == 90001);
    assert(RewardQuestFor(20, false) == 90008);
    assert(RewardQuestFor(21, true) == 90002);
    assert(RewardQuestFor(30, false) == 90009);
    assert(RewardQuestFor(31, true) == 90003);
    assert(RewardQuestFor(40, false) == 90010);
    assert(RewardQuestFor(41, true) == 90004);
    assert(RewardQuestFor(50, false) == 90011);
    assert(RewardQuestFor(51, true) == 90005);
    assert(RewardQuestFor(59, false) == 90012);
}

static void PaysTheLevelSixtyQuestsAtSixty()
{
    assert(RewardQuestFor(60, true) == 190005);
    assert(RewardQuestFor(60, false) == 190012);
}

int main()
{
    PaysNothingOutsideTheBattlegroundLevels();
    PaysTheTenLevelQuestsBelowSixty();
    PaysTheLevelSixtyQuestsAtSixty();
    std::cout << "Battleground reward quest policy checks passed\n";
}
