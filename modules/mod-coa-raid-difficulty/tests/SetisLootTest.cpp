#include "SetisLoot.h"

#include "gtest/gtest.h"

TEST(SetisLoot, TwoItemsForEveryTenPlayers)
{
    EXPECT_EQ(coa_setis::LootItems(10), 2u);
    EXPECT_EQ(coa_setis::LootItems(25), 5u);
    EXPECT_EQ(coa_setis::LootItems(40), 8u);
    EXPECT_EQ(coa_setis::LootItems(13), 3u);
    EXPECT_EQ(coa_setis::LootItems(20), 4u);
}

TEST(SetisLoot, NeverFewerThanTwoNorMoreThanEight)
{
    EXPECT_EQ(coa_setis::LootItems(0), 2u);
    EXPECT_EQ(coa_setis::LootItems(1), 2u);
    EXPECT_EQ(coa_setis::LootItems(60), 8u);
}
