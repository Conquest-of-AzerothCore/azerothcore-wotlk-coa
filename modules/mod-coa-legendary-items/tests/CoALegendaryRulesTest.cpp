#include "CoALegendaryCatalog.h"
#include <gtest/gtest.h>
#include <array>
#include <set>
#include <string>

using namespace CoALegendary;

TEST(CoALegendaryCatalog, CoversOnlyTheTwentyOneCustomClasses)
{
    std::array<uint32_t, 33> counts{};
    std::set<std::string> names;
    for (Design const& design : Catalog)
    {
        ASSERT_TRUE(design.classId == 0 || IsCustomClass(design.classId));
        ++counts[design.classId];
        EXPECT_TRUE(names.insert(design.name).second);
        if (design.power == Power::Movement)
            EXPECT_EQ(design.inventoryType, 8);
        if (design.power == Power::Signature)
        {
            EXPECT_NE(design.signatureSpell, 0);
            EXPECT_EQ(design.inventoryType, 12);
        }
    }
    EXPECT_EQ(counts[0], 1);
    for (uint32_t classId = 1; classId <= 32; ++classId)
    {
        EXPECT_EQ(counts[classId], IsCustomClass(classId) ? 3 : 0);
        uint32_t eligible = 0;
        for (Design const& design : Catalog)
            eligible += FitsClass(design, classId);
        EXPECT_EQ(eligible, IsCustomClass(classId) ? 4 : 0);
    }
}

TEST(CoALegendaryVariants, PreserveCreatureLevelAndTwelveItemLevels)
{
    auto const wolf = DecodeEntry(9700029);
    ASSERT_TRUE(wolf);
    EXPECT_EQ(wolf->requiredLevel, 29);
    EXPECT_EQ(ItemLevel(wolf->requiredLevel), 41);
    EXPECT_EQ(ItemLevel(20), 32);
    for (uint32_t index = 0; index < DesignCount; ++index)
        for (uint32_t level = 1; level <= MaximumCreatureLevel; ++level)
        {
            auto const variant = DecodeEntry(EntryForLevel(index, level));
            ASSERT_TRUE(variant);
            EXPECT_EQ(variant->design, index);
            EXPECT_EQ(variant->requiredLevel, level);
        }
    EXPECT_FALSE(DecodeEntry(9700000));
    EXPECT_TRUE(DecodeEntry(9700060));
    EXPECT_FALSE(DecodeEntry(9700061));
    EXPECT_FALSE(DecodeEntry(9700080));
    EXPECT_FALSE(DecodeEntry(9700081));
    EXPECT_FALSE(DecodeEntry(9699999));
    EXPECT_FALSE(DecodeEntry(9706401));
}

TEST(CoALegendaryDrops, ExcludesGrayTargetsAndThePlayerLevelCutoff)
{
    EXPECT_TRUE(CanDrop(12, 32, 29, 60, true));
    EXPECT_TRUE(CanDrop(32, 59, 60, 60, true));
    EXPECT_FALSE(CanDrop(32, 59, 61, 60, true));
    EXPECT_FALSE(CanDrop(32, 59, 62, 60, true));
    EXPECT_FALSE(CanDrop(12, 32, 10, 60, false));
    EXPECT_FALSE(CanDrop(12, 60, 57, 60, true));
    EXPECT_FALSE(CanDrop(12, 80, 80, 60, true));
    EXPECT_FALSE(CanDrop(8, 32, 29, 60, true));
    EXPECT_FALSE(CanDrop(10, 32, 29, 60, true));
    EXPECT_FALSE(CanDrop(33, 32, 29, 60, true));
    EXPECT_FALSE(CanDrop(12, 32, 0, 60, true));
    EXPECT_FALSE(CanDrop(12, 32, 81, 60, true));
    EXPECT_FALSE(CanDrop(12, 1, 1, 1, true));
    EXPECT_TRUE(CanDrop(12, 60, 60, 70, true));
}

TEST(CoALegendaryPowers, ConditionsHaveInclusiveHealthBoundariesAndExpire)
{
    EXPECT_TRUE(ConditionActive(Condition::Healthy, 80.0f, true, 0));
    EXPECT_FALSE(ConditionActive(Condition::Healthy, 79.9f, true, 0));
    EXPECT_TRUE(ConditionActive(Condition::Wounded, 35.0f, true, 0));
    EXPECT_FALSE(ConditionActive(Condition::Wounded, 35.1f, true, 0));
    EXPECT_TRUE(ConditionActive(Condition::AfterKill, 100.0f, false, 1));
    EXPECT_FALSE(ConditionActive(Condition::AfterKill, 100.0f, false, 0));
    EXPECT_TRUE(ConditionActive(Condition::OutOfCombat, 100.0f, false, 0));
    EXPECT_FALSE(ConditionActive(Condition::OutOfCombat, 100.0f, true, 0));
    EXPECT_TRUE(ConditionActive(Condition::InCombat, 100.0f, true, 0));
    EXPECT_FALSE(ConditionActive(Condition::InCombat, 100.0f, false, 0));
    EXPECT_EQ(AttackPowerBonus(29), 82);
    EXPECT_EQ(SpellPowerBonus(29), 41);
}
