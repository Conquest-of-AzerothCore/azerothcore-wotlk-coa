#include "AscensionAdventurerCachePolicy.h"
#include "AscensionSpecLoot.h"
#include "ItemTemplate.h"
#include <gtest/gtest.h>

using AdventurerCache::Gear;
using AdventurerCache::GearChoices;

TEST(AdventurerCache, GearComesFromAtMostFiveLevelsBelowThePlayer)
{
    EXPECT_TRUE(AdventurerCache::InGearLevelWindow(30, 30));
    EXPECT_TRUE(AdventurerCache::InGearLevelWindow(25, 30));
    EXPECT_FALSE(AdventurerCache::InGearLevelWindow(24, 30));
    EXPECT_FALSE(AdventurerCache::InGearLevelWindow(31, 30));
}

TEST(AdventurerCache, GreenCacheAddsOneSupplyAndRareCacheTwo)
{
    EXPECT_EQ(AdventurerCache::SupplyCount(AdventurerCache::GreenQuality), 1u);
    EXPECT_EQ(AdventurerCache::SupplyCount(AdventurerCache::BlueQuality), 2u);
}

TEST(AdventurerCache, RareCacheOffersOnlyBlueGearWhenBlueGearFits)
{
    std::vector<Gear> const gear = { { 2, 30, 0 }, { 3, 28, 0 }, { 3, 20, 0 }, { 3, 31, 0 } };
    EXPECT_EQ(GearChoices(gear, 30, 3), std::vector<std::size_t>({ 1 }));
    EXPECT_EQ(GearChoices(gear, 30, 2), std::vector<std::size_t>({ 0 }));
}

TEST(AdventurerCache, RareCacheFallsBackToGreenGearBelowTheFirstBlues)
{
    std::vector<Gear> const gear = { { 2, 10, 1 }, { 3, 13, 1 } };
    EXPECT_EQ(GearChoices(gear, 12, 3), std::vector<std::size_t>({ 0 }));
    EXPECT_TRUE(GearChoices(gear, 4, 3).empty());
}

TEST(AdventurerCache, BodyArmorIsLimitedToTheHeaviestTypeOnOffer)
{
    std::vector<Gear> const gear = { { 2, 30, 1 }, { 2, 30, 2 }, { 2, 30, 3 }, { 2, 30, 0 } };
    EXPECT_EQ(GearChoices(gear, 30, 2), std::vector<std::size_t>({ 2, 3 }));

    std::vector<Gear> const belowPlate = { { 2, 35, 3 }, { 2, 45, 4 } };
    EXPECT_EQ(GearChoices(belowPlate, 38, 2), std::vector<std::size_t>({ 0 }));
    EXPECT_EQ(GearChoices(belowPlate, 45, 2), std::vector<std::size_t>({ 1 }));
}

TEST(AdventurerCache, AffixStatsDecideHowGearFitsTheSpecialization)
{
    AscensionSpecLoot::PrimaryStats const agility = { ITEM_MOD_AGILITY, ITEM_MOD_STAMINA, 0 };
    AscensionSpecLoot::StatList const ofTheMonkey = { { ITEM_MOD_AGILITY, 5 }, { ITEM_MOD_STAMINA, 5 } };
    AscensionSpecLoot::StatList const ofTheOwl = { { ITEM_MOD_INTELLECT, 5 }, { ITEM_MOD_SPIRIT, 5 } };
    EXPECT_EQ(AscensionSpecLoot::StatsFit(agility, ofTheMonkey), AscensionSpecLoot::Fit::Primary);
    EXPECT_EQ(AscensionSpecLoot::StatsFit(agility, ofTheOwl), AscensionSpecLoot::Fit::None);
    EXPECT_EQ(AscensionSpecLoot::StatsFit({}, ofTheMonkey), AscensionSpecLoot::Fit::None);
}

TEST(AdventurerCache, PreferFitKeepsEveryCandidateWhenNoneFits)
{
    using AscensionSpecLoot::Fit;
    std::vector<int> const candidates = { 1, 2, 3 };
    EXPECT_EQ(AscensionSpecLoot::PreferFit(candidates, [](int value) { return value == 2 ? Fit::Primary : Fit::None; }),
        std::vector<int>({ 2 }));
    EXPECT_EQ(AscensionSpecLoot::PreferFit(candidates, [](int value) { return value == 3 ? Fit::Shared : Fit::None; }),
        std::vector<int>({ 3 }));
    EXPECT_EQ(AscensionSpecLoot::PreferFit(candidates, [](int) { return Fit::None; }), candidates);
}
