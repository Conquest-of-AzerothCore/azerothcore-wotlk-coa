#include "CoAQolRules.h"
#include <gtest/gtest.h>

using namespace CoAQol;

namespace
{
    StackPolicy MaterialsPolicy(uint32_t size = 2000)
    {
        StackPolicy policy;
        policy.size = size;
        policy.classes = {7};
        return policy;
    }

    ItemFacts Material(int32_t stackable = 20)
    {
        ItemFacts item;
        item.entry = 2770;
        item.itemClass = 7;
        item.stackable = stackable;
        return item;
    }
}

TEST(CoAQol, IdListsAcceptZeroAndRejectMalformedEntries)
{
    std::set<uint32_t> ids = {99};
    ASSERT_TRUE(ParseIdList("0, 7 ,12,7", ids));
    EXPECT_EQ(ids, (std::set<uint32_t>{0, 7, 12}));
    for (auto invalid : {"1,", ",1", "1,,2", "abc", "-1", "1 2", "4294967296", "1;2"})
    {
        std::set<uint32_t> kept = {5};
        EXPECT_FALSE(ParseIdList(invalid, kept)) << invalid;
        EXPECT_EQ(kept, (std::set<uint32_t>{5})) << invalid;
    }
    EXPECT_TRUE(ParseIdList("  ", ids));
    EXPECT_TRUE(ids.empty());
}

TEST(CoAQol, SelectedMaterialsStackToTheConfiguredSize)
{
    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(), Material(20)), 2000);
    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(200), Material(20)), 200);
    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(), Material(1000)), 2000);
}

TEST(CoAQol, StackSizesOnlyRiseAndOnlyForStackableItems)
{
    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(), Material(2000)), 2000);
    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(), Material(5000)), 5000);
    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(), Material(1)), 1);
    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(), Material(0)), 0);
    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(), Material(-1)), -1);
    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(), Material(INT32_MAX)), INT32_MAX);
}

TEST(CoAQol, StackPolicyHonorsClassesIncludesExcludesAndDisabledSizes)
{
    ItemFacts consumable = Material(20);
    consumable.itemClass = 0;
    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(), consumable), 20);

    StackPolicy included = MaterialsPolicy();
    included.included = {consumable.entry};
    EXPECT_EQ(PlannedStackSize(included, consumable), 2000);

    StackPolicy excluded = MaterialsPolicy();
    excluded.excluded = {Material().entry};
    EXPECT_EQ(PlannedStackSize(excluded, Material(20)), 20);
    excluded.included = {Material().entry};
    EXPECT_EQ(PlannedStackSize(excluded, Material(20)), 20);

    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(0), Material(20)), 20);
    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(1), Material(20)), 20);
    EXPECT_EQ(PlannedStackSize(MaterialsPolicy(UINT32_MAX), Material(20)), int32_t(MaximumStackSize));
}
