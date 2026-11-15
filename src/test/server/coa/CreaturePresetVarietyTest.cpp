#include "AscensionCreaturePreset.h"
#include <algorithm>
#include <gtest/gtest.h>
#include <set>

namespace
{
CreatureDisplayPreset CultistPreset()
{
    CreatureDisplayPreset preset;
    preset.entry = 164312;
    preset.display_id = 15475;
    preset.race = 10;
    preset.gender = 1;
    preset.class_id = 1;
    preset.skin = 22;
    preset.face = 0;
    preset.hair = 0;
    preset.haircolor = 0;
    preset.facialhair = 0;
    preset.items = { 48193, 45136, 0, 74340, 0, 0, 74328, 0, 46011, 74310, 0 };
    return preset;
}

CreatureDisplayPresetVariety HighElfVariety()
{
    CreatureDisplayPresetVariety variety;
    variety.skins = ParsePresetVarietyValues("22-25 38 39 50 51");
    variety.faces = ParsePresetVarietyValues("0-24");
    variety.hairs = ParsePresetVarietyValues("0-18");
    variety.hairColors = ParsePresetVarietyValues("0-9");
    variety.facialHairs = ParsePresetVarietyValues("0-10");
    return variety;
}

bool Contains(std::vector<uint8> const& values, uint8 value)
{
    return std::find(values.begin(), values.end(), value) != values.end();
}
}

TEST(CreaturePresetVariety, ParsesValuesAndRanges)
{
    EXPECT_EQ(ParsePresetVarietyValues("22-25 38 39"), (std::vector<uint8>{ 22, 23, 24, 25, 38, 39 }));
    EXPECT_EQ(ParsePresetVarietyValues("0-2,7"), (std::vector<uint8>{ 0, 1, 2, 7 }));
    EXPECT_EQ(ParsePresetVarietyValues("  5  "), (std::vector<uint8>{ 5 }));
}

TEST(CreaturePresetVariety, SkipsMalformedTokens)
{
    EXPECT_TRUE(ParsePresetVarietyValues("").empty());
    EXPECT_TRUE(ParsePresetVarietyValues("5-3 x 300 2-256").empty());
    EXPECT_EQ(ParsePresetVarietyValues("x 4"), (std::vector<uint8>{ 4 }));
}

TEST(CreaturePresetVariety, EmptyListsKeepThePresetLook)
{
    CreatureDisplayPreset const preset = CultistPreset();
    CreatureDisplayPreset const varied = ApplyPresetVariety(preset, CreatureDisplayPresetVariety{}, 9960133);

    EXPECT_EQ(varied.skin, preset.skin);
    EXPECT_EQ(varied.face, preset.face);
    EXPECT_EQ(varied.hair, preset.hair);
    EXPECT_EQ(varied.haircolor, preset.haircolor);
    EXPECT_EQ(varied.facialhair, preset.facialhair);
}

TEST(CreaturePresetVariety, EverySpawnGetsListedHighElfValuesAndKeepsItsOutfit)
{
    CreatureDisplayPreset const preset = CultistPreset();
    CreatureDisplayPresetVariety const variety = HighElfVariety();

    for (uint32 spawnId = 9960100; spawnId < 9960400; ++spawnId)
    {
        CreatureDisplayPreset const varied = ApplyPresetVariety(preset, variety, spawnId);
        EXPECT_TRUE(Contains(variety.skins, varied.skin)) << "spawn " << spawnId << " skin " << int(varied.skin);
        EXPECT_TRUE(Contains(variety.faces, varied.face));
        EXPECT_TRUE(Contains(variety.hairs, varied.hair));
        EXPECT_TRUE(Contains(variety.hairColors, varied.haircolor));
        EXPECT_TRUE(Contains(variety.facialHairs, varied.facialhair));
        EXPECT_EQ(varied.race, preset.race);
        EXPECT_EQ(varied.gender, preset.gender);
        EXPECT_EQ(varied.display_id, preset.display_id);
        EXPECT_EQ(varied.items, preset.items);
    }
}

TEST(CreaturePresetVariety, ASpawnKeepsItsLookAndSpawnsDiffer)
{
    CreatureDisplayPreset const preset = CultistPreset();
    CreatureDisplayPresetVariety const variety = HighElfVariety();

    CreatureDisplayPreset const first = ApplyPresetVariety(preset, variety, 9960133);
    CreatureDisplayPreset const again = ApplyPresetVariety(preset, variety, 9960133);
    EXPECT_EQ(first.skin, again.skin);
    EXPECT_EQ(first.face, again.face);
    EXPECT_EQ(first.hair, again.hair);
    EXPECT_EQ(first.haircolor, again.haircolor);
    EXPECT_EQ(first.facialhair, again.facialhair);

    std::set<uint8> skins;
    std::set<uint8> faces;
    std::set<uint8> hairs;
    for (uint32 spawnId = 9960100; spawnId < 9960140; ++spawnId)
    {
        CreatureDisplayPreset const varied = ApplyPresetVariety(preset, variety, spawnId);
        skins.insert(varied.skin);
        faces.insert(varied.face);
        hairs.insert(varied.hair);
    }
    EXPECT_GE(skins.size(), 5u);
    EXPECT_GE(faces.size(), 10u);
    EXPECT_GE(hairs.size(), 8u);
}
