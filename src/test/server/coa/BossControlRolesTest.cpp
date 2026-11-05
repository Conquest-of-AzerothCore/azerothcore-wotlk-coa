/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBossControlRolesPolicy.h"
#include <gtest/gtest.h>
#include <set>

namespace
{
std::set<std::uint32_t> const ProtectedSpecializations = {
    9, 17, 21, 22, 48, 52, 57, 60, 96, 97, 99, 100,
    6, 25, 31, 37, 40, 43, 51, 58, 98, 101 };
}

TEST(BossControlRoles, EveryCoATankAndHealerSpecializationIsProtected)
{
    for (std::uint32_t specialization : ProtectedSpecializations)
        EXPECT_TRUE(BossControlRoles::TanksOrHeals(specialization)) << specialization;
}

TEST(BossControlRoles, EveryOtherSpecializationIsATarget)
{
    for (std::uint32_t specialization = 0; specialization <= 200; ++specialization)
        if (!ProtectedSpecializations.contains(specialization))
            EXPECT_FALSE(BossControlRoles::TanksOrHeals(specialization)) << specialization;
}

TEST(BossControlRoles, HereticMoonPriestFleshweaverAndGrovekeeperHeal)
{
    EXPECT_TRUE(BossControlRoles::TanksOrHeals(40));
    EXPECT_TRUE(BossControlRoles::TanksOrHeals(43));
    EXPECT_TRUE(BossControlRoles::TanksOrHeals(25));
    EXPECT_TRUE(BossControlRoles::TanksOrHeals(58));
}
