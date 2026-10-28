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

#include "DBCStores.h"
#include "gtest/gtest.h"

namespace
{
FactionEntry MakeFaction(uint32 id, int32 reputationListId)
{
    FactionEntry faction{};
    faction.ID = id;
    faction.reputationListID = reputationListId;
    return faction;
}
}

TEST(SharedReputationListIdTest, BloodsailKeepsItsIndexOverTheUnnamedCoAFaction)
{
    FactionEntry bloodsail = MakeFaction(87, 0);
    FactionEntry bootyBay = MakeFaction(21, 1);
    FactionEntry unnamed = MakeFaction(1162, 0);
    FactionEntry noReputation = MakeFaction(1163, -1);

    auto const released = ReleaseSharedReputationListIds({ &bootyBay, &bloodsail, &unnamed, &noReputation });

    ASSERT_EQ(released.size(), 1u);
    EXPECT_EQ(released[0], std::make_pair(uint32(1162), uint32(87)));
    EXPECT_EQ(bloodsail.reputationListID, 0);
    EXPECT_EQ(bootyBay.reputationListID, 1);
    EXPECT_FALSE(unnamed.CanHaveReputation());
    EXPECT_EQ(noReputation.reputationListID, -1);
}

TEST(SharedReputationListIdTest, DistinctIndicesAreUnchanged)
{
    FactionEntry first = MakeFaction(47, 18);
    FactionEntry second = MakeFaction(54, 19);

    EXPECT_TRUE(ReleaseSharedReputationListIds({ &first, &second }).empty());
    EXPECT_EQ(first.reputationListID, 18);
    EXPECT_EQ(second.reputationListID, 19);
}
