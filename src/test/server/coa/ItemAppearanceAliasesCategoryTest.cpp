#include "AscensionItemAppearanceAliases.h"
#include "ItemTemplate.h"
#include <gtest/gtest.h>

TEST(ItemAppearanceAliasesCategory, MapsEachArmorSlotToItsOwnCategory)
{
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_HEAD), 1u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_SHOULDERS), 2u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_CLOAK), 3u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_CHEST), 4u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_ROBE), 4u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_TABARD), 5u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_BODY), 6u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_WRISTS), 7u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_HANDS), 8u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_WAIST), 9u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_LEGS), 10u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_FEET), 11u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_RANGED), 12u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_WEAPON), 13u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_2HWEAPON), 13u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_WEAPONMAINHAND), 13u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_WEAPONOFFHAND), 14u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_SHIELD), 14u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_HOLDABLE), 14u);
}

TEST(ItemAppearanceAliasesCategory, NonArmorSlotsAreNotCategorized)
{
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_NECK), 0u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_FINGER), 0u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_TRINKET), 0u);
    EXPECT_EQ(AscensionItemAppearanceAliases::CategoryFromInventoryType(INVTYPE_NON_EQUIP), 0u);
}
