/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAGameplayRaidBots.h"
#include "CoARotationData.h"
#include "ObjectGuid.h"
#include "gtest/gtest.h"
#include <set>

using namespace CoAGameplay;

namespace
{
ObjectGuid PlayerGuid(uint32 low)
{
    return ObjectGuid::Create<HighGuid::Player>(low);
}

HealCandidate Member(uint32 low, float healthPct, float distance = 10.0f, bool alive = true)
{
    return HealCandidate{PlayerGuid(low), alive, healthPct, distance};
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
    EXPECT_EQ(Select({Member(1, 85.0f), Member(2, 40.0f), Member(3, 60.0f)}), PlayerGuid(2));
    EXPECT_EQ(Select({Member(1, 95.0f), Member(2, 89.9f)}), PlayerGuid(2));
    EXPECT_EQ(Select({Member(1, 50.0f), Member(2, 50.0f)}), PlayerGuid(1));
    EXPECT_EQ(Select({Member(1, 90.0f)}), std::nullopt);
}

TEST(CoAGameplayRaidBots, SelectHealTargetSkipsDeadAndOutOfRange)
{
    EXPECT_EQ(Select({Member(1, 10.0f, 10.0f, false), Member(2, 70.0f)}), PlayerGuid(2));
    EXPECT_EQ(Select({Member(1, 10.0f, 40.5f), Member(2, 70.0f, 40.0f)}), PlayerGuid(2));
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

TEST(CoAGameplayRaidBots, SpellSourceFollowsOptInAndRuleCoverage)
{
    CoARotationAssist::Rule const rules[] = {
        { 38, "Ignite", CoARotationAssist::RuleCondition::MissingDebuff, "Ignite", 0 },
        { 98, "Bless", CoARotationAssist::RuleCondition::Ready, "", 0 } };
    EXPECT_EQ(SpellSourceFor(true, 38, rules), RaidSpellSource::RotationAssist);
    EXPECT_EQ(SpellSourceFor(true, 98, rules), RaidSpellSource::RotationAssist);
    EXPECT_EQ(SpellSourceFor(true, 0, rules), RaidSpellSource::Scenario);
    EXPECT_EQ(SpellSourceFor(true, 37, rules), RaidSpellSource::Scenario);
    EXPECT_EQ(SpellSourceFor(true, 38, {}), RaidSpellSource::Scenario);
    EXPECT_EQ(SpellSourceFor(false, 38, rules), RaidSpellSource::Scenario);
    EXPECT_EQ(SpellSourceFor(false, 98, rules), RaidSpellSource::Scenario);
}

TEST(CoAGameplayRaidBots, ImportedRotationsCoverEveryCoAClassSpecialization)
{
    for (uint32 spec = 1; spec <= 63; ++spec)
        EXPECT_EQ(SpellSourceFor(true, spec, CoARotationAssist::Rules), RaidSpellSource::RotationAssist) << spec;
    for (uint32 spec = 95; spec <= 101; ++spec)
        EXPECT_EQ(SpellSourceFor(true, spec, CoARotationAssist::Rules), RaidSpellSource::RotationAssist) << spec;
    for (uint32 spec : { 0u, 64u, 93u, 94u, 102u })
        EXPECT_EQ(SpellSourceFor(true, spec, CoARotationAssist::Rules), RaidSpellSource::Scenario) << spec;
}

TEST(CoAGameplayRaidBots, NextRaidSpellTakesOnlyTheRotationChoiceWhenCovered)
{
    std::vector<uint32> asked;
    auto canCast = [&](uint32 spell)
    {
        asked.push_back(spell);
        return true;
    };
    EXPECT_EQ(NextRaidSpell(RaidSpellSource::RotationAssist, [] { return 800791u; }, {2137}, canCast), 800791u);
    EXPECT_EQ(NextRaidSpell(RaidSpellSource::RotationAssist, [] { return 0u; }, {2137}, canCast), std::nullopt);
    EXPECT_TRUE(asked.empty());
}

TEST(CoAGameplayRaidBots, NextRaidSpellUsesTheScenarioListOtherwise)
{
    uint32 choices = 0;
    auto rotationChoice = [&]
    {
        ++choices;
        return 800791u;
    };
    std::set<uint32> castable{20, 30};
    auto canCast = [&](uint32 spell) { return castable.count(spell) > 0; };
    EXPECT_EQ(NextRaidSpell(RaidSpellSource::Scenario, rotationChoice, {10, 20, 30}, canCast), 20u);
    EXPECT_EQ(NextRaidSpell(RaidSpellSource::Scenario, rotationChoice, {}, canCast), std::nullopt);
    EXPECT_EQ(choices, 0u);
}

TEST(CoAGameplayRaidBots, HealerTakesTheRotationHealChoiceOnlyWhenOptedIn)
{
    uint32 constexpr healSpell = 500143;
    uint32 constexpr rotationHeal = 1001;
    auto const rotationChoice = [] { return rotationHeal; };
    auto const canCast = [](uint32) { return true; };
    RaidSpellSource const optedIn = SpellSourceFor(true, 98, CoARotationAssist::Rules);
    RaidSpellSource const optedOut = SpellSourceFor(false, 98, CoARotationAssist::Rules);
    EXPECT_EQ(NextRaidSpell(optedIn, rotationChoice, {healSpell}, canCast), rotationHeal);
    EXPECT_EQ(NextRaidSpell(optedOut, rotationChoice, {healSpell}, canCast), healSpell);
}

TEST(CoAGameplayRaidBots, TankRotationReplacesTheScenarioListOnlyWhenOptedIn)
{
    for (bool const optedIn : { true, false })
    {
        RaidSpellSource const source = SpellSourceFor(optedIn, 96, CoARotationAssist::Rules);
        EXPECT_EQ(source, optedIn ? RaidSpellSource::RotationAssist : RaidSpellSource::Scenario);
        EXPECT_EQ(NextRaidSpell(source, [] { return 0u; }, {801576}, [](uint32) { return true; }),
            optedIn ? std::nullopt : std::optional<uint32>(801576));
    }
}
