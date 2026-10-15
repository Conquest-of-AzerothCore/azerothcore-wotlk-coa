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

#include "RealmCard.h"
#include "gtest/gtest.h"

TEST(RealmCardTest, FillsTheFirstPageThenTheNextOnes)
{
    EXPECT_EQ(GetRealmCardSlot(0).Page, 1);
    EXPECT_EQ(GetRealmCardSlot(0).Index, 1u);
    EXPECT_EQ(GetRealmCardSlot(5).Page, 1);
    EXPECT_EQ(GetRealmCardSlot(5).Index, 6u);
    EXPECT_EQ(GetRealmCardSlot(6).Page, 2);
    EXPECT_EQ(GetRealmCardSlot(6).Index, 1u);
    EXPECT_EQ(GetRealmCardSlot(12).Page, 3);
    EXPECT_EQ(GetRealmCardSlot(23).Index, 12u);
    EXPECT_EQ(GetRealmCardSlot(24).Page, 4);
    EXPECT_EQ(GetRealmCardSlot(24).Index, 1u);
}

TEST(RealmCardTest, NamesTheRealmThenItsCardFields)
{
    RealmCardStyle const style{ 2, 11, "Default" };
    EXPECT_EQ(BuildRealmCardName("AzerothCore", style, GetRealmCardSlot(0)), "AzerothCore!2!11!Default!1!1!1!0");
    EXPECT_EQ(BuildRealmCardName("Second", style, GetRealmCardSlot(7)), "Second!2!11!Default!1!2!2!0");
}
