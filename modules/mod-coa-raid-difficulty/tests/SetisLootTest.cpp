#include "SetisLoot.h"

#include "gtest/gtest.h"

TEST(SetisLoot, OneItemForEveryFourPlayersRoundedDown)
{
    EXPECT_EQ(coa_setis::LootItems(10), 2u);
    EXPECT_EQ(coa_setis::LootItems(23), 5u);
    EXPECT_EQ(coa_setis::LootItems(25), 6u);
    EXPECT_EQ(coa_setis::LootItems(40), 10u);
}

TEST(SetisLoot, NeverNone)
{
    EXPECT_EQ(coa_setis::LootItems(0), 1u);
    EXPECT_EQ(coa_setis::LootItems(3), 1u);
}
