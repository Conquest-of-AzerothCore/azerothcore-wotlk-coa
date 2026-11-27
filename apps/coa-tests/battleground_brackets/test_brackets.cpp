#include "../../../src/server/game/Battlegrounds/AscensionBattlegroundBracketsPolicy.h"
#include <cmath>
#include <iostream>
#include <cstdlib>
#include <limits>

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
    Lift const baseLift = LiftBetween(HumanWarriorLevelTwelve, HumanWarriorLevelTwentyNine);
    CHECK(baseLift.health == 239.0f);
    CHECK(!baseLift.Empty());
    CHECK(LiftBetween(HumanWarriorLevelTwentyNine, HumanWarriorLevelTwelve).Empty());
    CHECK(LiftBetween(HumanWarriorLevelTwelve, HumanWarriorLevelTwelve).Empty());

    Lift const playerLift = PlayerLiftBetween(HumanWarriorLevelTwelve, HumanWarriorLevelTwentyNine);
    CHECK(playerLift.health == 459.0f);
    CHECK(!playerLift.Empty());
    CHECK(PlayerLiftBetween(HumanWarriorLevelTwentyNine, HumanWarriorLevelTwelve).Empty());
    CHECK(PlayerLiftBetween(HumanWarriorLevelTwelve, HumanWarriorLevelTwelve).Empty());
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
    float const own = PlayerOutputHealth(HumanWarriorLevelTwelve);
    float const top = PlayerOutputHealth(HumanWarriorLevelTwentyNine);
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

static void ComputesGearBudgetsAndCatchUp()
{
    CHECK(GearHealthBudget(10) == 140.0f);
    CHECK(GearHealthBudget(12) == 158.0f);
    CHECK(GearHealthBudget(13) == 167.0f);
    CHECK(GearHealthBudget(29) == 365.0f);
    CHECK(GearHealthBudget(59) == 900.0f);
    CHECK(GearHealthBudget(5) == 140.0f);
    CHECK(GearHealthBudget(70) == 900.0f);

    for (std::uint32_t level = 10; level < 59; ++level)
    {
        CHECK(GearHealthBudget(level) <= GearHealthBudget(level + 1));
        CHECK(GearShieldArmorBudget(level, true) <= GearShieldArmorBudget(level + 1, true));
        CHECK(GearShieldArmorBudget(level, false) <= GearShieldArmorBudget(level + 1, false));
        for (ArmorTier tier : { ArmorTier::Cloth, ArmorTier::Leather, ArmorTier::Mail, ArmorTier::Plate })
        {
            CHECK(GearArmorBudget(tier, level, true) <= GearArmorBudget(tier, level + 1, true));
            CHECK(GearArmorBudget(tier, level, false) <= GearArmorBudget(tier, level + 1, false));
        }
    }

    CHECK(GearArmorBudget(ArmorTier::Plate, 15, true) == 638.0f);
    CHECK(GearArmorBudget(ArmorTier::Plate, 59, true) == 2798.0f);
    CHECK(GearArmorBudget(ArmorTier::Cloth, 59, false) == 1471.0f);

    CHECK(GearCatchUpAmount(185.0f, 900.0f, 185.0f, 1.0f) == 715.0f);
    CHECK(GearCatchUpAmount(185.0f, 900.0f, 0.0f, 1.0f) == 715.0f);
    CHECK(GearCatchUpAmount(880.0f, 900.0f, 200.0f, 1.0f) == 20.0f);
    CHECK(GearCatchUpAmount(820.0f, 900.0f, 1100.0f, 1.0f) == 0.0f);
    CHECK(GearCatchUpAmount(185.0f, 900.0f, 185.0f, 0.0f) == 0.0f);
    CHECK(GearCatchUpAmount(185.0f, 900.0f, 185.0f, 0.5f) == 265.0f);
    CHECK(GearCatchUpAmount(185.0f, 900.0f, -50.0f, 1.0f) == 715.0f);
    CHECK(GearCatchUpAmount(185.0f, 900.0f, 0.0f, -0.5f) == 0.0f);
    CHECK(PlayerGearLift(15, 59, ArmorTier::Plate, ArmorTier::Plate, true, GearValues{}, -0.5f).Empty());
    CHECK(GearArmorBudget(ArmorTier::Plate, 45, true) == 1512.0f);
    CHECK(GearArmorBudget(ArmorTier::Plate, 46, true) == 2258.0f);

    Lift const greenFifteen = PlayerGearLift(15, 59, ArmorTier::Cloth, ArmorTier::Cloth, true,
        GearValues{ 185.0f, 130.0f, 0.0f, false }, 1.0f);
    CHECK(greenFifteen.health == 715.0f && greenFifteen.armor == 264.0f);

    Lift const nakedFifteen = PlayerGearLift(15, 59, ArmorTier::Cloth, ArmorTier::Cloth, true,
        GearValues{ 0.0f, 0.0f, 0.0f, false }, 1.0f);
    CHECK(nakedFifteen.health == 715.0f && nakedFifteen.armor == 264.0f);
    CHECK(nakedFifteen.health < 185.0f + greenFifteen.health);

    Lift const withShield = PlayerGearLift(15, 59, ArmorTier::Plate, ArmorTier::Plate, true,
        GearValues{ 185.0f, 638.0f, 231.0f, true }, 1.0f);
    CHECK(withShield.health == 715.0f);
    CHECK(withShield.armor == (2798.0f - 638.0f) + (1513.0f - 231.0f));

    Lift const warFifteenToFiftyNine = PlayerGearLift(15, 59, ArmorTier::Mail, ArmorTier::Plate, false,
        GearValues{ 185.0f, 794.0f, 0.0f, false }, 1.0f);
    CHECK(warFifteenToFiftyNine.armor == 2536.0f - 794.0f);

    CHECK(PlayerGearLift(59, 59, ArmorTier::Plate, ArmorTier::Plate, true, GearValues{}, 1.0f).Empty());
    CHECK(PlayerGearLift(15, 59, ArmorTier::Plate, ArmorTier::Plate, true, GearValues{}, 0.0f).Empty());
}

static void ComputesTemplarTuningDeltaAndScaleClamp()
{
    CHECK(ClampOutputScale(0.8f) == 0.8f);
    CHECK(ClampOutputScale(0.5f) == 0.5f);
    CHECK(ClampOutputScale(0.0f) == 0.0f);
    CHECK(ClampOutputScale(-0.5f) == 1.0f);
    CHECK(ClampOutputScale(std::numeric_limits<float>::quiet_NaN()) == 1.0f);
    CHECK(ClampOutputScale(std::numeric_limits<float>::infinity()) == 1.0f);

    CHECK(LevelScaledPointsDelta(12, 29, 10, 10, 60, -0.40f) == -7);
    CHECK(LevelScaledPointsDelta(16, 59, 10, 10, 60, -0.40f) == -17);
    CHECK(LevelScaledPointsDelta(59, 59, 10, 10, 60, -0.40f) == 0);
    CHECK(LevelScaledPointsDelta(60, 60, 10, 10, 60, -0.40f) == 0);
    CHECK(LevelScaledPointsDelta(29, 12, 10, 10, 60, -0.40f) == 0);

    CHECK(LevelScaledPointsDelta(16, 59, 10, 10, 60, -0.56f) == -24);
    CHECK(LevelScaledPointsDelta(16, 59, 10, 10, 60, 0.50f) == 21);

    CHECK(LevelScaledPointsDelta(5, 29, 10, 10, 60, -0.40f) == -7);
    CHECK(LevelScaledPointsDelta(16, 70, 10, 10, 60, -0.40f) == -18);
    CHECK(LevelScaledPointsDelta(16, 59, 10, 10, 60, 0.0f) == 0);
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
    ComputesGearBudgetsAndCatchUp();
    ComputesTemplarTuningDeltaAndScaleClamp();
    std::cout << "Battleground wide bracket policy checks passed\n";
}
