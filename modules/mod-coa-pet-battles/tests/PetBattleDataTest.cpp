#include "PetBattleData.h"
#include <gtest/gtest.h>
#include <algorithm>

using namespace CoAPetBattles;

namespace
{
DataSet MakeValidData()
{
    DataSet data;
    data.species[10] = { 10, "Young Wolf", 100, true, false, false, false, true, "Ability_Hunter_Pet_Wolf", 0.0f };
    data.species[20] = { 20, "Rat", 200, true, true, true, true, false, "Ability_Druid_Dash", 0.0f };
    data.kits[100] = { 100, "Frostwolf Pup", 7, 100, 0, -100 };
    data.kits[200] = { 200, "Rat", 4, 0, 0, 0 };
    data.abilities[1] = { 1, "Bite", 7, 0, "Bites the enemy.", 0 };
    data.abilities[2] = { 2, "Howl", 7, 3, "Howls.", 0 };
    data.abilities[3] = { 3, "Scratch", 4, 0, "Scratches.", 1 };
    data.kitAbilities = { { 100, 0, 1, 1 }, { 100, 1, 2, 2 }, { 200, 0, 1, 3 } };
    data.turns = { { 1, 1, 0, 255 }, { 2, 1, 0, 255 }, { 3, 1, 0, 255 } };
    data.effects = {
        { 1, 1, 1, 24, 0, { 20, 100, 0, 0, 0, 0 } },
        { 2, 1, 1, 26, 2, { 0, 100, 3, 0, 0, 0 } },
        { 3, 1, 1, 24, 0, { 20, 100, 0, 0, 0, 0 } },
    };
    data.labels = { { 24, 0, "Points" }, { 24, 1, "Accuracy" } };
    data.states[18] = { 18, "Stat_Power" };
    data.auraStates = { { 2, "Mod_DamageDealtPercent", 25 } };
    data.xp[1] = { 1, 1, 50 };
    data.zones[12] = { 12, "Elwynn Forest", 1, 2, 1, 10 };
    data.zoneSpecies = { { 12, 10 }, { 12, 20 } };
    data.presentations = {
        { 10, 0, 1, 1, 1, "Bite", "Bite", "Ability_Druid_Rake", "Bites.", 17253, false, "melee", 0, false, true,
          false },
        { 10, 1, 1, 2, 2, "Howl", "Howl", "Ability_Hunter_Pet_Wolf", "Howls.", 0, false, "self", 0, false, false,
          false },
        { 20, 0, 1, 1, 3, "Scratch", "Scratch", "Ability_Druid_Rake", "Scratches.", 17253, false, "melee", 0, false,
          true, false },
    };
    data.modelSizes[10] = { 10, 2.8737f, 1.9689f, 1.0772f };
    data.displaySizes[26] = { 26, 0.929f };
    data.companions[10685] = { 10685, 20 };
    return data;
}

bool AnyTemplate(uint32_t)
{
    return true;
}

bool Contains(std::vector<std::string> const& messages, std::string const& text)
{
    return std::any_of(messages.begin(), messages.end(),
        [&text](std::string const& message) { return message.find(text) != std::string::npos; });
}
}

TEST(CoAPetBattles, ValidDataHasNoErrors)
{
    Report report = Validate(MakeValidData(), AnyTemplate);
    EXPECT_TRUE(report.errors.empty());
    EXPECT_TRUE(report.warnings.empty());
}

TEST(CoAPetBattles, SpeciesWithUnknownKitIsReported)
{
    DataSet data = MakeValidData();
    data.species[10].kit = 99;
    Report report = Validate(data, AnyTemplate);
    EXPECT_TRUE(Contains(report.errors, "species 10: kit 99 missing"));
}

TEST(CoAPetBattles, PresentationMustMatchTheSpeciesKit)
{
    DataSet data = MakeValidData();
    data.presentations.erase(data.presentations.begin() + 1);
    Report report = Validate(data, AnyTemplate);
    ASSERT_EQ(report.errors.size(), 1u);
    EXPECT_TRUE(Contains(report.errors, "species 10"));
    EXPECT_TRUE(Contains(report.errors, "kit 100"));
}

TEST(CoAPetBattles, ZoneSpeciesNeedsKnownZoneAndSpecies)
{
    DataSet data = MakeValidData();
    data.zoneSpecies.push_back({ 99, 10 });
    data.zoneSpecies.push_back({ 12, 77 });
    Report report = Validate(data, AnyTemplate);
    EXPECT_TRUE(Contains(report.errors, "zone 99"));
    EXPECT_TRUE(Contains(report.errors, "species 77"));
}

TEST(CoAPetBattles, CompanionNeedsKnownSpecies)
{
    DataSet data = MakeValidData();
    data.companions[4055] = { 4055, 77 };
    Report report = Validate(data, AnyTemplate);
    EXPECT_TRUE(Contains(report.errors, "companion 4055: species 77 missing"));
}

TEST(CoAPetBattles, StandInNeedsCreatureTemplate)
{
    Report report = Validate(MakeValidData(), [](uint32_t entry) { return entry != 9800010; });
    EXPECT_TRUE(Contains(report.errors, "species 10: stand-in template 9800010 missing"));
}

TEST(CoAPetBattles, StandInEntryIsOffsetFromSpecies)
{
    DataSet data = MakeValidData();
    EXPECT_EQ(StandInEntry(data, 10), 9800010u);
    EXPECT_EQ(StandInEntry(data, 20), 0u);
    EXPECT_EQ(StandInEntry(data, 30), 0u);
}

TEST(CoAPetBattles, StandInBeyondTheReservedRangeIsReported)
{
    DataSet data = MakeValidData();
    data.species[50000] = { 50000, "Too Far", 100, true, false, false, false, true, "", 0.0f };
    data.presentations.push_back(data.presentations[0]);
    data.presentations.back().species = 50000;
    data.presentations.push_back(data.presentations[1]);
    data.presentations.back().species = 50000;
    Report report = Validate(data, AnyTemplate);
    EXPECT_TRUE(Contains(report.errors, "species 50000: stand-in entry 9850000 outside reserved range"));
}

TEST(CoAPetBattles, UnknownEffectAuraIsOnlyAWarning)
{
    DataSet data = MakeValidData();
    data.effects[0].aura = 831;
    Report report = Validate(data, AnyTemplate);
    EXPECT_TRUE(report.errors.empty());
    EXPECT_TRUE(Contains(report.warnings, "aura 831"));
}

TEST(CoAPetBattles, AbilityReferencesMustResolve)
{
    DataSet data = MakeValidData();
    data.kitAbilities.push_back({ 200, 1, 2, 404 });
    data.turns.push_back({ 405, 1, 0, 255 });
    data.effects.push_back({ 1, 2, 1, 24, 0, { 0, 0, 0, 0, 0, 0 } });
    data.abilities[3].base = 406;
    Report report = Validate(data, AnyTemplate);
    EXPECT_TRUE(Contains(report.errors, "kit 200: ability 404 missing"));
    EXPECT_TRUE(Contains(report.errors, "turn 405/1: ability 405 missing"));
    EXPECT_TRUE(Contains(report.errors, "effect 1/2/1: turn missing"));
    EXPECT_TRUE(Contains(report.errors, "ability 3: base 406 missing"));
}

TEST(CoAPetBattles, QualityWeightsParseStrictly)
{
    std::optional<std::array<uint32_t, 4>> weights = ParseQualityWeights("55 28 13 4");
    ASSERT_TRUE(weights.has_value());
    EXPECT_EQ(*weights, (std::array<uint32_t, 4>{ 55, 28, 13, 4 }));
    EXPECT_FALSE(ParseQualityWeights("55 28 13").has_value());
    EXPECT_FALSE(ParseQualityWeights("55 x 13 4").has_value());
    EXPECT_FALSE(ParseQualityWeights("0 0 0 0").has_value());
    EXPECT_FALSE(ParseQualityWeights("55 28 13 4 1").has_value());
    EXPECT_FALSE(ParseQualityWeights("-1 28 13 4").has_value());
}

TEST(CoAPetBattles, DecimalsParseLikeLua)
{
    ASSERT_TRUE(ParseDecimal("0.35").has_value());
    EXPECT_EQ(*ParseDecimal("0.35"), 0.35);
    EXPECT_EQ(*ParseDecimal("1"), 1.0);
    EXPECT_FALSE(ParseDecimal("").has_value());
    EXPECT_FALSE(ParseDecimal("0.3x").has_value());
    EXPECT_FALSE(ParseDecimal("nan").has_value());
    EXPECT_FALSE(ParseDecimal("inf").has_value());
}

TEST(CoAPetBattles, DecimalDefaultsPrintAsTheConfigValue)
{
    EXPECT_EQ(DecimalText(0.35), "0.35");
    EXPECT_EQ(DecimalText(0.2), "0.2");
    EXPECT_EQ(DecimalText(1), "1");
    EXPECT_EQ(*ParseDecimal(DecimalText(Settings().captureHealth)), Settings().captureHealth);
    EXPECT_EQ(*ParseDecimal(DecimalText(Settings().xpStep)), Settings().xpStep);
}

TEST(CoAPetBattles, KitAbilitiesNeedATurn)
{
    DataSet data = MakeValidData();
    data.turns.erase(std::remove_if(data.turns.begin(), data.turns.end(),
        [](AbilityTurn const& turn) { return turn.ability == 2; }), data.turns.end());
    data.effects.erase(std::remove_if(data.effects.begin(), data.effects.end(),
        [](AbilityEffect const& effect) { return effect.ability == 2; }), data.effects.end());
    Report const report = Validate(data, AnyTemplate);
    EXPECT_TRUE(Contains(report.errors, "ability 2 has no turns")) << report.errors.size();
}

TEST(CoAPetBattles, AuraOnlyAbilitiesNeedNoTurn)
{
    DataSet data = MakeValidData();
    data.abilities[4] = { 4, "Stunned", 7, 0, "", 0 };
    data.effects.push_back({ 1, 1, 2, 26, 4, { 0, 100, 1, 0, 0, 0 } });
    EXPECT_TRUE(Validate(data, AnyTemplate).errors.empty());
}

TEST(CoAPetBattles, KitFamilyMustBeKnown)
{
    DataSet data = MakeValidData();
    data.kits[200].family = 10;
    EXPECT_TRUE(Contains(Validate(data, AnyTemplate).errors, "kit 200: family 10 unknown"));
    data.kits[200].family = 255;
    EXPECT_TRUE(Contains(Validate(data, AnyTemplate).errors, "kit 200: family 255 unknown"));
    data.kits[200].family = 9;
    EXPECT_TRUE(Validate(data, AnyTemplate).errors.empty());
}
