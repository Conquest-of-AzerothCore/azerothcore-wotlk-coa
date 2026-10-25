/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAGameplayRaidBots.h"
#include "ObjectGuid.h"
#include "gtest/gtest.h"
#include <set>

using namespace CoAGameplay;

namespace
{
ObjectGuid Player(uint32 low)
{
    return ObjectGuid::Create<HighGuid::Player>(low);
}

HealCandidate Member(uint32 low, float healthPct, float distance = 10.0f, bool alive = true)
{
    return HealCandidate{Player(low), alive, healthPct, distance};
}

std::optional<ObjectGuid> Select(std::vector<HealCandidate> const& members)
{
    return SelectHealTarget(members, RaidHealThresholdPct, RaidHealRange);
}
}

TEST(CoAGameplayRaidBots, ConstantsMatchTheRoleContract)
{
    EXPECT_FLOAT_EQ(RaidHealThresholdPct, 90.0f);
    EXPECT_FLOAT_EQ(RaidHealRange, 40.0f);
    EXPECT_FLOAT_EQ(RaidRangedDistance, 30.0f);
}

TEST(CoAGameplayRaidBots, RaidRoleFromNameKnowsTheFourRoles)
{
    EXPECT_EQ(RaidRoleFromName("tank"), RaidRole::Tank);
    EXPECT_EQ(RaidRoleFromName("healer"), RaidRole::Healer);
    EXPECT_EQ(RaidRoleFromName("melee"), RaidRole::Melee);
    EXPECT_EQ(RaidRoleFromName("ranged"), RaidRole::Ranged);
    EXPECT_EQ(RaidRoleFromName(""), RaidRole::None);
    EXPECT_EQ(RaidRoleFromName("Tank"), RaidRole::None);
    EXPECT_EQ(RaidRoleFromName("dps"), RaidRole::None);
}

TEST(CoAGameplayRaidBots, SelectHealTargetPicksLowestBelowThreshold)
{
    EXPECT_EQ(Select({Member(1, 85.0f), Member(2, 40.0f), Member(3, 60.0f)}), Player(2));
    EXPECT_EQ(Select({Member(1, 95.0f), Member(2, 89.9f)}), Player(2));
    EXPECT_EQ(Select({Member(1, 50.0f), Member(2, 50.0f)}), Player(1));
    EXPECT_EQ(Select({Member(1, 90.0f)}), std::nullopt);
}

TEST(CoAGameplayRaidBots, SelectHealTargetSkipsDeadAndOutOfRange)
{
    EXPECT_EQ(Select({Member(1, 10.0f, 10.0f, false), Member(2, 70.0f)}), Player(2));
    EXPECT_EQ(Select({Member(1, 10.0f, 40.5f), Member(2, 70.0f, 40.0f)}), Player(2));
    EXPECT_EQ(Select({Member(1, 0.0f, 5.0f, false), Member(2, 20.0f, 41.0f)}), std::nullopt);
}

TEST(CoAGameplayRaidBots, SelectHealTargetNoneWhenAllHealthy)
{
    EXPECT_EQ(Select({}), std::nullopt);
    EXPECT_EQ(Select({Member(1, 100.0f), Member(2, 95.0f), Member(3, 90.0f)}), std::nullopt);
}

TEST(CoAGameplayRaidBots, ShouldTauntOnlyWhenBossOffTankAndReady)
{
    EXPECT_TRUE(ShouldTaunt(false, true));
    EXPECT_FALSE(ShouldTaunt(true, true));
    EXPECT_FALSE(ShouldTaunt(false, false));
    EXPECT_FALSE(ShouldTaunt(true, false));
}

TEST(CoAGameplayRaidBots, DamageRolesHoldUntilBossTargetsTank)
{
    EXPECT_FALSE(RoleMayAct(RaidRole::Melee, false));
    EXPECT_FALSE(RoleMayAct(RaidRole::Ranged, false));
    EXPECT_TRUE(RoleMayAct(RaidRole::Melee, true));
    EXPECT_TRUE(RoleMayAct(RaidRole::Ranged, true));
    EXPECT_TRUE(RoleMayAct(RaidRole::Tank, false));
    EXPECT_TRUE(RoleMayAct(RaidRole::Healer, false));
    EXPECT_FALSE(RoleMayAct(RaidRole::None, true));
}

TEST(CoAGameplayRaidBots, TanksActInTheFirstPass)
{
    EXPECT_TRUE(ActsInTankPass(RaidRole::Tank));
    EXPECT_FALSE(ActsInTankPass(RaidRole::Healer));
    EXPECT_FALSE(ActsInTankPass(RaidRole::Melee));
    EXPECT_FALSE(ActsInTankPass(RaidRole::Ranged));
    EXPECT_FALSE(ActsInTankPass(RaidRole::None));
}

TEST(CoAGameplayRaidBots, ThreatFloorLeadsTheHighestOtherThreat)
{
    EXPECT_FLOAT_EQ(RaidTankThreatFactor, 1.1f);
    EXPECT_FLOAT_EQ(RaidTankThreatMargin, 100.0f);
    EXPECT_FLOAT_EQ(ThreatFloor(1000.0f), 1200.0f);
    EXPECT_FLOAT_EQ(ThreatFloor(0.0f), 100.0f);
}

TEST(CoAGameplayRaidBots, TankThreatRaiseOnlyWhenBelowTheFloor)
{
    EXPECT_FLOAT_EQ(TankThreatRaise(500.0f, 1000.0f), 700.0f);
    EXPECT_FLOAT_EQ(TankThreatRaise(1200.0f, 1000.0f), 0.0f);
    EXPECT_FLOAT_EQ(TankThreatRaise(5000.0f, 1000.0f), 0.0f);
    EXPECT_FLOAT_EQ(TankThreatRaise(0.0f, 0.0f), 0.0f);
    EXPECT_FLOAT_EQ(TankThreatRaise(50.0f, -1.0f), 0.0f);
}

TEST(CoAGameplayRaidBots, NextRotationSpellSkipsUncastable)
{
    std::set<uint32> castable{30, 40};
    std::vector<uint32> asked;
    auto canCast = [&](uint32 spell)
    {
        asked.push_back(spell);
        return castable.count(spell) > 0;
    };
    EXPECT_EQ(NextRotationSpell({10, 20, 30, 40}, canCast), 30u);
    EXPECT_EQ(asked, (std::vector<uint32>{10, 20, 30}));
    EXPECT_EQ(NextRotationSpell({40, 30}, canCast), 40u);
    EXPECT_EQ(NextRotationSpell({10, 20}, canCast), std::nullopt);
    EXPECT_EQ(NextRotationSpell({}, canCast), std::nullopt);
}
