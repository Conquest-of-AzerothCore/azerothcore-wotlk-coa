/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "ItemTemplate.h"
#include "gtest/gtest.h"

namespace
{
constexpr uint32 ClassMask(Classes playerClass)
{
    return uint32(1) << (playerClass - 1);
}
}

TEST(ItemClassMaskTest, ClasslessItemsAllowEveryCustomClass)
{
    uint32 mask = GetItemAllowableClassMask(512);

    EXPECT_EQ(mask, 0xFFFFFA00u);
    EXPECT_NE(mask & ClassMask(CLASS_BARBARIAN), 0u);
    EXPECT_NE(mask & ClassMask(CLASS_SPIRIT_MAGE), 0u);
    EXPECT_EQ(mask & 1535u, 0u); // No WotLK playable class bits are added.
}

TEST(ItemClassMaskTest, LegacySetsRetainTheirClassFamilies)
{
    struct ClassFamily
    {
        Classes legacyClass;
        uint32 customMask;
    };

    ClassFamily const families[] =
    {
        {CLASS_WARRIOR, ClassMask(CLASS_FLESHWARDEN) | ClassMask(CLASS_GUARDIAN)},
        {CLASS_PALADIN, ClassMask(CLASS_CULTIST)},
        {CLASS_HUNTER, ClassMask(CLASS_WITCH_HUNTER) | ClassMask(CLASS_RANGER) | ClassMask(CLASS_TINKER)},
        {CLASS_ROGUE, ClassMask(CLASS_BARBARIAN) | ClassMask(CLASS_DEMON_HUNTER) |
            ClassMask(CLASS_MONK) | ClassMask(CLASS_REAPER)},
        {CLASS_PRIEST, ClassMask(CLASS_CHRONOMANCER) | ClassMask(CLASS_SUN_CLERIC)},
        {CLASS_DEATH_KNIGHT, 0},
        {CLASS_SHAMAN, ClassMask(CLASS_WITCH_DOCTOR) | ClassMask(CLASS_STORMBRINGER) |
            ClassMask(CLASS_PROPHET) | ClassMask(CLASS_SPIRIT_MAGE)},
        {CLASS_MAGE, ClassMask(CLASS_PYROMANCER)},
        {CLASS_WARLOCK, ClassMask(CLASS_NECROMANCER)},
        {CLASS_DRUID, ClassMask(CLASS_SON_OF_ARUGAL) | ClassMask(CLASS_STARCALLER) | ClassMask(CLASS_WILDWALKER)}
    };

    for (ClassFamily const& family : families)
        for (uint32 classlessBit : {0u, 512u})
        {
            uint32 original = ClassMask(family.legacyClass) | classlessBit;
            EXPECT_EQ(GetItemAllowableClassMask(original), original | family.customMask) << original;
        }
}

TEST(ItemClassMaskTest, MultiClassTokensAllowOnlyTheirClassFamilies)
{
    uint32 original = ClassMask(CLASS_PALADIN) | ClassMask(CLASS_PRIEST) | ClassMask(CLASS_WARLOCK) | 512u;
    uint32 expected = original | ClassMask(CLASS_CULTIST) | ClassMask(CLASS_CHRONOMANCER) |
        ClassMask(CLASS_SUN_CLERIC) | ClassMask(CLASS_NECROMANCER);

    EXPECT_EQ(GetItemAllowableClassMask(original), expected);
}

TEST(ItemClassMaskTest, ExplicitCustomRestrictionsStayUnchanged)
{
    for (uint8 classId = CLASS_BARBARIAN; classId < MAX_CLASSES; ++classId)
    {
        uint32 original = ClassMask(Classes(classId));
        EXPECT_EQ(GetItemAllowableClassMask(original), original);
        // Mixed masks are authored restrictions too, including the unsigned bit for class 32.
        original |= ClassMask(CLASS_MAGE) | 512u;
        EXPECT_EQ(GetItemAllowableClassMask(original), original);
    }
}

TEST(ItemClassMaskTest, EmptyAndUnrestrictedMasksStayUnchanged)
{
    EXPECT_EQ(GetItemAllowableClassMask(0), 0u);
    EXPECT_EQ(GetItemAllowableClassMask(uint32(-1)), uint32(-1));
    EXPECT_EQ(GetItemAllowableClassMask(CLASSMASK_ALL_PLAYABLE), CLASSMASK_ALL_PLAYABLE);
    EXPECT_EQ(GetItemAllowableClassMask(1535), CLASSMASK_ALL_PLAYABLE);
    EXPECT_EQ(GetItemAllowableClassMask(2047), uint32(-1));
}

TEST(ItemClassMaskTest, LegacyBitsArePreservedAndNormalizationIsIdempotent)
{
    for (uint32 original = 0; original <= 2047; ++original)
    {
        uint32 normalized = GetItemAllowableClassMask(original);
        uint32 expectedLegacyBits = (original & 1535u) == 1535u ? original | ClassMask(CLASS_HERO) : original;
        EXPECT_EQ(normalized & 2047u, expectedLegacyBits) << original;
        EXPECT_EQ(GetItemAllowableClassMask(normalized), normalized) << original;
    }
}

TEST(ItemClassMaskTest, HeroSharesItemsOpenToEveryWotLKClassOnly)
{
    EXPECT_NE(GetItemAllowableClassMask(1535) & ClassMask(CLASS_HERO), 0u);
    EXPECT_EQ(GetItemAllowableClassMask(ClassMask(CLASS_DRUID)) & ClassMask(CLASS_HERO), 0u);
    uint32 twoClassMask = ClassMask(CLASS_WARRIOR) | ClassMask(CLASS_PALADIN);
    EXPECT_EQ(GetItemAllowableClassMask(twoClassMask) & ClassMask(CLASS_HERO), 0u);
}
