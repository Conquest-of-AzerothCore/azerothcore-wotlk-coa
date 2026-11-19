#include "../../../src/server/game/Battlegrounds/AscensionBattlegroundBracketsPolicy.h"
#include <cassert>
#include <iostream>

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
    assert(ranges && ranges->size() == 3);
    assert((*ranges)[0].minLevel == 10 && (*ranges)[0].maxLevel == 29);
    assert((*ranges)[1].minLevel == 30 && (*ranges)[1].maxLevel == 49);
    assert((*ranges)[2].minLevel == 50 && (*ranges)[2].maxLevel == 59);
    auto spaced = ParseRanges(" 10 - 29 , 30-49");
    assert(spaced && spaced->size() == 2 && (*spaced)[1].maxLevel == 49);
}

static void RejectsInvalidRanges()
{
    for (char const* text : { "", "10-29,", "29-10", "0-9", "50-60", "10-29,20-39", "30-49,10-29", "a-b", "10",
             "10-29-30", "-29" })
        assert(!ParseRanges(text));
}

static void WidensEveryBattlegroundToAlignedIds()
{
    auto ranges = ParseRanges("10-29,30-49,50-59");
    std::vector<BracketRow> const expected = { { 0, 10, 29 }, { 2, 30, 49 }, { 4, 50, 59 } };
    auto warsong = Widen(StockTenLevelRows, *ranges);
    auto arathi = Widen(StockTenLevelRows, *ranges);
    auto eye = Widen(StockTenLevelRows, *ranges);
    assert(warsong && SameRows(*warsong, expected));
    assert(arathi && SameRows(*arathi, expected));
    assert(eye && SameRows(*eye, expected));
}

static void WidensMapStartingAtTwenty()
{
    std::vector<BracketRow> const fromTwenty(StockTenLevelRows.begin() + 1, StockTenLevelRows.end());
    auto widened = Widen(fromTwenty, *ParseRanges("10-29,30-49,50-59"));
    assert(widened && SameRows(*widened, { { 1, 20, 29 }, { 2, 30, 49 }, { 4, 50, 59 } }));
}

static void RejectsMapsThatGiveOneRangeDifferentIds()
{
    auto ranges = *ParseRanges("10-29,30-49,50-59");
    auto const tenLevel = *Widen(StockTenLevelRows, ranges);
    std::vector<BracketRow> const fromTwentyStock(StockTenLevelRows.begin() + 1, StockTenLevelRows.end());
    auto const fromTwenty = *Widen(fromTwentyStock, ranges);
    assert(!FirstMapWithMisalignedId({ tenLevel, tenLevel, tenLevel }, ranges));
    assert(!FirstMapWithMisalignedId({ fromTwenty }, ranges));
    assert(!FirstMapWithMisalignedId({ tenLevel, {}, tenLevel }, ranges));
    auto const misaligned = FirstMapWithMisalignedId({ tenLevel, tenLevel, fromTwenty }, ranges);
    assert(misaligned && *misaligned == 2);
    auto const reversed = FirstMapWithMisalignedId({ fromTwenty, tenLevel }, ranges);
    assert(reversed && *reversed == 1);
}

static void RejectsPartialRowsAndKeepsEmptyMaps()
{
    assert(!Widen(StockTenLevelRows, *ParseRanges("10-25")));
    auto empty = Widen({}, *ParseRanges("10-29,30-49,50-59"));
    assert(empty && empty->empty());
    auto single = Widen(StockTenLevelRows, *ParseRanges("10-19"));
    assert(single && SameRows(*single, { { 0, 10, 19 } }));
}

static void LiftsWarriorFromTwelveToTwentyNine()
{
    LevelValues const own = { 109, 0, { 36, 28, 34, 21, 23 } };
    LevelValues const target = { 348, 0, { 60, 43, 56, 24, 30 } };
    Lift const lift = LiftBetween(own, target);
    assert(lift.health == 239.0f && lift.mana == 0.0f);
    assert(lift.stats[0] == 24.0f && lift.stats[1] == 15.0f && lift.stats[2] == 22.0f);
    assert(lift.stats[3] == 3.0f && lift.stats[4] == 7.0f);
    assert(!lift.Empty());
    Lift const reversed = LiftBetween(target, own);
    assert(reversed.health == 0.0f && reversed.mana == 0.0f && reversed.Empty());
    for (float stat : reversed.stats)
        assert(stat == 0.0f);
    assert(LiftBetween(own, own).Empty());
}

int main()
{
    ParsesDefaultRanges();
    RejectsInvalidRanges();
    WidensEveryBattlegroundToAlignedIds();
    WidensMapStartingAtTwenty();
    RejectsMapsThatGiveOneRangeDifferentIds();
    RejectsPartialRowsAndKeepsEmptyMaps();
    LiftsWarriorFromTwelveToTwentyNine();
    std::cout << "Battleground wide bracket policy checks passed\n";
}
