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

#include "PoolMgr.h"
#include "gtest/gtest.h"

TEST(PoolGatherNodeLimitTest, EmptyZoneKeepsTheMinimum)
{
    EXPECT_EQ(PoolMgr::GatherNodeLimit(20, 0, 0.10f, 0.015f, 0.35f), 2u);
}

TEST(PoolGatherNodeLimitTest, PlayersRaiseTheLimitUpToTheMaximum)
{
    EXPECT_EQ(PoolMgr::GatherNodeLimit(20, 10, 0.10f, 0.015f, 0.35f), 5u);
    EXPECT_EQ(PoolMgr::GatherNodeLimit(20, 300, 0.10f, 0.015f, 0.35f), 7u);
}

TEST(PoolGatherNodeLimitTest, AnAreaAlwaysKeepsOneSpot)
{
    EXPECT_EQ(PoolMgr::GatherNodeLimit(1, 0, 0.10f, 0.015f, 0.35f), 1u);
    EXPECT_EQ(PoolMgr::GatherNodeLimit(3, 0, 0.0f, 0.0f, 0.35f), 1u);
}
