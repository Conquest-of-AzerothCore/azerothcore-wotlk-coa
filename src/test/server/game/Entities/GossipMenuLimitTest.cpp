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

#include "GossipDef.h"
#include "gtest/gtest.h"

TEST(GossipMenuLimitTest, OptionsPastTheClientLimitAreDropped)
{
    GossipMenu menu;
    for (uint32 i = 0; i < GOSSIP_MAX_MENU_ITEMS + 8; ++i)
        menu.AddMenuItem(-1, 0, "option", 0, i, "", 0);

    EXPECT_EQ(menu.GetMenuItemCount(), GOSSIP_MAX_MENU_ITEMS);
}
