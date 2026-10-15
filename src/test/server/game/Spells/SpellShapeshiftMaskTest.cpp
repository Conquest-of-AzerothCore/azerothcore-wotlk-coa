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

#include "SpellInfoTestHelper.h"
#include "SpellInfo.h"
#include "SharedDefines.h"
#include "gtest/gtest.h"

/**
 * @brief SpellInfo::CheckShapeshift with forms above 32.
 *
 * Spell.dbc stores m_shapeshiftMask and m_shapeshiftExclude as 64-bit masks: form N is bit N - 1, forms 33-64 in
 * the high words (fields 13 and 15). CoA's own forms are numbered above 32 (Spider Form 52, Scorpid Form 53,
 * Vizier Form 62), so their rules live only in the high words.
 */

namespace
{
    constexpr uint32 FORM_ABOVE_32 = 52;
    constexpr uint32 FORM_ABOVE_32_HIGH_BIT = 1u << (FORM_ABOVE_32 - 33);
    // 52 - 1 wrapped to 32 bits: the low-word form a 32-bit shift confuses it with.
    constexpr uint32 ALIASED_LOW_FORM = 20;
    constexpr uint32 ALIASED_LOW_FORM_BIT = 1u << (ALIASED_LOW_FORM - 1);
}

TEST(SpellShapeshiftMaskTest, ExcludedFormAbove32_IsRefused)
{
    auto spell = SpellInfoBuilder().WithStancesNot(0, FORM_ABOVE_32_HIGH_BIT).BuildUnique();

    EXPECT_EQ(spell->CheckShapeshift(FORM_ABOVE_32), SPELL_FAILED_NOT_SHAPESHIFT);
}

TEST(SpellShapeshiftMaskTest, RequiredFormAbove32_IsAllowedInThatForm)
{
    auto spell = SpellInfoBuilder().WithStances(0, FORM_ABOVE_32_HIGH_BIT).BuildUnique();

    EXPECT_EQ(spell->CheckShapeshift(FORM_ABOVE_32), SPELL_CAST_OK);
}

TEST(SpellShapeshiftMaskTest, RequiredFormAbove32_IsRefusedOutsideAnyForm)
{
    auto spell = SpellInfoBuilder().WithStances(0, FORM_ABOVE_32_HIGH_BIT).BuildUnique();

    EXPECT_EQ(spell->CheckShapeshift(0), SPELL_FAILED_ONLY_SHAPESHIFT);
}

TEST(SpellShapeshiftMaskTest, RequiredFormAbove32_AllowWhileNotShapeshifted)
{
    auto spell = SpellInfoBuilder()
        .WithStances(0, FORM_ABOVE_32_HIGH_BIT)
        .WithAttributesEx2(SPELL_ATTR2_ALLOW_WHILE_NOT_SHAPESHIFTED)
        .BuildUnique();

    EXPECT_EQ(spell->CheckShapeshift(0), SPELL_CAST_OK);
}

TEST(SpellShapeshiftMaskTest, FormAbove32_IsNotTheLowWordForm)
{
    // Excluded from form 20 only, allowed in form 52.
    auto spell = SpellInfoBuilder()
        .WithStancesNot(ALIASED_LOW_FORM_BIT)
        .WithStances(0, FORM_ABOVE_32_HIGH_BIT)
        .BuildUnique();

    EXPECT_EQ(spell->CheckShapeshift(ALIASED_LOW_FORM), SPELL_FAILED_NOT_SHAPESHIFT);
    EXPECT_EQ(spell->CheckShapeshift(FORM_ABOVE_32), SPELL_CAST_OK);
}

TEST(SpellShapeshiftMaskTest, LowAndHighWordsCombine)
{
    auto spell = SpellInfoBuilder().WithStances(0x1, FORM_ABOVE_32_HIGH_BIT).BuildUnique();

    EXPECT_EQ(spell->Stances, uint64(0x1) | (uint64(FORM_ABOVE_32_HIGH_BIT) << 32));
}
