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

#include "Realm.h"
#include "gtest/gtest.h"
#include <boost/asio/ip/address.hpp>

namespace
{
    Realm WithLevel(AccountTypes level)
    {
        Realm realm;
        realm.AllowedSecurityLevel = level;
        return realm;
    }
}

TEST(RealmAccessTest, OpenRealmIsOpenToPlayers)
{
    EXPECT_TRUE(WithLevel(SEC_PLAYER).IsOpenTo(SEC_PLAYER));
    EXPECT_TRUE(WithLevel(SEC_PLAYER).IsOpenTo(SEC_ADMINISTRATOR));
}

TEST(RealmAccessTest, GmRealmIsClosedToLowerAccounts)
{
    EXPECT_FALSE(WithLevel(SEC_GAMEMASTER).IsOpenTo(SEC_PLAYER));
    EXPECT_FALSE(WithLevel(SEC_GAMEMASTER).IsOpenTo(SEC_MODERATOR));
    EXPECT_TRUE(WithLevel(SEC_GAMEMASTER).IsOpenTo(SEC_GAMEMASTER));
    EXPECT_TRUE(WithLevel(SEC_GAMEMASTER).IsOpenTo(SEC_ADMINISTRATOR));
}

// The worldserver treats SEC_CONSOLE and above as no restriction (World::SetPlayerSecurityLimit).
TEST(RealmAccessTest, ConsoleLevelMeansNoRestriction)
{
    EXPECT_TRUE(WithLevel(SEC_CONSOLE).IsOpenTo(SEC_PLAYER));
    EXPECT_TRUE(WithLevel(AccountTypes(5)).IsOpenTo(SEC_PLAYER));
}
