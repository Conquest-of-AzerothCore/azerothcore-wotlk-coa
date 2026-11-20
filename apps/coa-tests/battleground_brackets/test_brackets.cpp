#include "../../../src/server/game/Battlegrounds/AscensionBattlegroundBracketsPolicy.h"
#include <cmath>
#include <iostream>
#include <cstdlib>

#define CHECK(condition) \
    do \
    { \
        if (!(condition)) \
        { \
            std::cerr << __FILE__ << ':' << __LINE__ << ": " << #condition << '\n'; \
            std::exit(1); \
        } \
    } while (false)

using namespace AscensionBattlegroundBracketsPolicy;

static bool SameRows(std::vector<BracketRow> const& actual, std::vector<BracketRow> const& expected)
{
    if (actual.size() != expected.size())
        return false;
    for (std::size_t i = 0; i < actual.size(); ++i)
        if (actual[i].bracketId != expected[i].bracketId || actual[i].minLevel != expected[i].minLevel
            || actual[i].maxLevel != expected[i].maxLevel)
            return false;
    return true;
}

static std::vector<BracketRow> const StockTenLevelRows = {
    { 0, 10, 19 }, { 1, 20, 29 }, { 2, 30, 39 }, { 3, 40, 49 }, { 4, 50, 59 } };

static void ParsesDefaultRanges()
{
    auto ranges = ParseRanges("10-29,30-49,50-59");
    CHECK(ranges && ranges->size() == 3);
    CHECK((*ranges)[0].minLevel == 10 && (*ranges)[0].maxLevel == 29);
    CHECK((*ranges)[1].minLevel == 30 && (*ranges)[1].maxLevel == 49);
    CHECK((*ranges)[2].minLevel == 50 && (*ranges)[2].maxLevel == 59);
    auto spaced = ParseRanges(" 10 - 29 , 30-49");
    CHECK(spaced && spaced->size() == 2 && (*spaced)[1].maxLevel == 49);
}

static void RejectsInvalidRanges()
{
    for (char const* text : { "", "10-29,", "29-10", "0-9", "50-60", "10-29,20-39", "30-49,10-29", "a-b", "10",
             "10-29-30", "-29" })
        CHECK(!ParseRanges(text));
}

static void WidensEveryBattlegroundToAlignedIds()
{
    auto ranges = ParseRanges("10-29,30-49,50-59");
    std::vector<BracketRow> const expected = { { 0, 10, 29 }, { 2, 30, 49 }, { 4, 50, 59 } };
    auto warsong = Widen(StockTenLevelRows, *ranges);
    auto arathi = Widen(StockTenLevelRows, *ranges);
    auto eye = Widen(StockTenLevelRows, *ranges);
    CHECK(warsong && SameRows(*warsong, expected));
    CHECK(arathi && SameRows(*arathi, expected));
    CHECK(eye && SameRows(*eye, expected));
}

static void WidensMapStartingAtTwenty()
{
    std::vector<BracketRow> const fromTwenty(StockTenLevelRows.begin() + 1, StockTenLevelRows.end());
    auto widened = Widen(fromTwenty, *ParseRanges("10-29,30-49,50-59"));
    CHECK(widened && SameRows(*widened, { { 1, 20, 29 }, { 2, 30, 49 }, { 4, 50, 59 } }));
}

static void RejectsMapsThatGiveOneRangeDifferentIds()
{
    auto ranges = *ParseRanges("10-29,30-49,50-59");
    auto const tenLevel = *Widen(StockTenLevelRows, ranges);
    std::vector<BracketRow> const fromTwentyStock(StockTenLevelRows.begin() + 1, StockTenLevelRows.end());
    auto const fromTwenty = *Widen(fromTwentyStock, ranges);
    CHECK(!FirstMapWithMisalignedId({ tenLevel, tenLevel, tenLevel }, ranges));
    CHECK(!FirstMapWithMisalignedId({ fromTwenty }, ranges));
    CHECK(!FirstMapWithMisalignedId({ tenLevel, {}, tenLevel }, ranges));
    auto const misaligned = FirstMapWithMisalignedId({ tenLevel, tenLevel, fromTwenty }, ranges);
    CHECK(misaligned && *misaligned == 2);
    auto const reversed = FirstMapWithMisalignedId({ fromTwenty, tenLevel }, ranges);
    CHECK(reversed && *reversed == 1);
}

static void RejectsPartialRowsAndKeepsEmptyMaps()
{
    CHECK(!Widen(StockTenLevelRows, *ParseRanges("10-25")));
    auto empty = Widen({}, *ParseRanges("10-29,30-49,50-59"));
    CHECK(empty && empty->empty());
    auto single = Widen(StockTenLevelRows, *ParseRanges("10-19"));
    CHECK(single && SameRows(*single, { { 0, 10, 19 } }));
}

static LevelValues const HumanWarriorLevelTen = { 97, 0, { 33, 26, 31, 21, 23 } };
static LevelValues const HumanWarriorLevelTwelve = { 109, 0, { 36, 28, 34, 21, 23 } };
static LevelValues const HumanWarriorLevelTwentyNine = { 348, 0, { 60, 43, 56, 24, 30 } };
static LevelValues const HumanWarriorLevelFiftyNine = { 1619, 0, { 118, 79, 108, 30, 44 } };

static void LiftsWarriorHealthOnly()
{
    Lift const lift = LiftBetween(HumanWarriorLevelTwelve, HumanWarriorLevelTwentyNine);
    CHECK(lift.health == 239.0f && lift.stamina == 22.0f);
    CHECK(!lift.Empty());
    CHECK(LiftBetween(HumanWarriorLevelTwentyNine, HumanWarriorLevelTwelve).Empty());
    CHECK(LiftBetween(HumanWarriorLevelTwelve, HumanWarriorLevelTwelve).Empty());
}

static void CapsLiftLevel()
{
    CHECK(CappedLiftLevel(12, 29, 0) == 29);
    CHECK(CappedLiftLevel(12, 29, 5) == 17);
    CHECK(CappedLiftLevel(12, 29, 40) == 29);
    CHECK(CappedLiftLevel(10, 59, 0) == 59);
    CHECK(CappedLiftLevel(29, 29, 3) == 29);
}

static void ComputesWarriorRatio()
{
    float const own = static_cast<float>(HumanWarriorLevelTwelve.health) + PlayerStaminaHealth(34);
    float const top = static_cast<float>(HumanWarriorLevelTwentyNine.health) + PlayerStaminaHealth(56);
    CHECK(own == 269.0f && top == 728.0f);
    CHECK(std::abs(OutputRatio(own, top) - 728.0f / 269.0f) < 1e-6f);
    CHECK(OutputRatio(728.0f, 269.0f) == 1.0f);
    CHECK(OutputRatio(0.0f, 728.0f) == 1.0f);
    CHECK(PlayerStaminaHealth(15) == 15.0f);
}

static void BridgesFortyNineLevels()
{
    float const own = static_cast<float>(HumanWarriorLevelTen.health)
        + PlayerStaminaHealth(HumanWarriorLevelTen.stats[2]);
    float const top = static_cast<float>(HumanWarriorLevelFiftyNine.health)
        + PlayerStaminaHealth(HumanWarriorLevelFiftyNine.stats[2]);
    float const ratio = OutputRatio(own, top);
    CHECK(ratio > 1.0f && std::isfinite(ratio));
    CHECK(ScaleAmount(4000000000u, ratio) == UINT32_MAX);
    CHECK(ScaleAmount(std::int32_t(2000000000), ratio) == INT32_MAX);
    CHECK(ScaleAmount(1000u, 1.0f) == 1000u);
    CHECK(ScaleAmount(1000u, 728.0f / 269.0f) == 2706u);
}

static void KeepsHealthShare()
{
    CHECK(KeptHealth(269, 269, 728) == 728);
    CHECK(KeptHealth(0, 269, 728) == 0);
    CHECK(KeptHealth(1, 728, 269) == 1);
    CHECK(KeptHealth(364, 728, 269) == 135);
    CHECK(KeptHealth(100, 0, 728) == 100);
    CHECK(KeptHealth(728, 728, 269) == 269);
}

int main()
{
    ParsesDefaultRanges();
    RejectsInvalidRanges();
    WidensEveryBattlegroundToAlignedIds();
    WidensMapStartingAtTwenty();
    RejectsMapsThatGiveOneRangeDifferentIds();
    RejectsPartialRowsAndKeepsEmptyMaps();
    LiftsWarriorHealthOnly();
    CapsLiftLevel();
    ComputesWarriorRatio();
    BridgesFortyNineLevels();
    KeepsHealthShare();
    std::cout << "Battleground wide bracket policy checks passed\n";
}
