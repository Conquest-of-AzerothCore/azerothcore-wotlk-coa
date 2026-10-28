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

#include "IntegrationTestFixture.h"

namespace
{
class CustomClassAttackPowerTest : public IntegrationTestFixture
{
protected:
    TestPlayer* CreatePlayerWithStats(Classes playerClass, uint8 level, int32 strength, int32 agility)
    {
        TestPlayer* player = CreateTestPlayer(++_guid);
        player->SetByteValue(UNIT_FIELD_BYTES_0, 1, uint8(playerClass));
        player->SetLevel(level);
        player->SetStat(STAT_STRENGTH, strength);
        player->SetStat(STAT_AGILITY, agility);
        return player;
    }

private:
    ObjectGuid::LowType _guid = 0;
};
}

TEST_F(CustomClassAttackPowerTest, ConfirmedCoABaselineStatConversions)
{
    struct ConversionCase
    {
        Classes playerClass;
        int32 strengthGain;
        int32 agilityGain;
    };

    // Official CoA changelog, 2026-07-09: 69019-69020, 69036-69038 and 69043.
    // Assert the conversion slopes independently of the still-approximate level terms and offsets.
    for (ConversionCase const& conversion : {ConversionCase{CLASS_BARBARIAN, 10, 10},
        ConversionCase{CLASS_STARCALLER, 10, 10}, ConversionCase{CLASS_SUN_CLERIC, 20, 0}})
    {
        for (uint8 level : {1, 60, 80})
        {
            SCOPED_TRACE(uint32(conversion.playerClass));
            SCOPED_TRACE(uint32(level));
            TestPlayer* player = CreatePlayerWithStats(conversion.playerClass, level, 100, 200);
            player->UpdateAttackPowerAndDamage();
            int32 const baseline = player->GetInt32Value(UNIT_FIELD_ATTACK_POWER);

            player->SetStat(STAT_STRENGTH, 110);
            player->UpdateAttackPowerAndDamage();
            EXPECT_EQ(player->GetInt32Value(UNIT_FIELD_ATTACK_POWER) - baseline, conversion.strengthGain);

            player->SetStat(STAT_STRENGTH, 100);
            player->SetStat(STAT_AGILITY, 210);
            player->UpdateAttackPowerAndDamage();
            EXPECT_EQ(player->GetInt32Value(UNIT_FIELD_ATTACK_POWER) - baseline, conversion.agilityGain);
        }
    }
}

TEST_F(CustomClassAttackPowerTest, ReaperCorrectsStrengthWithoutInventingAnAgilityConversion)
{
    TestPlayer* player = CreatePlayerWithStats(CLASS_REAPER, 60, 100, 200);
    player->UpdateAttackPowerAndDamage();
    int32 const baseline = player->GetInt32Value(UNIT_FIELD_ATTACK_POWER);

    player->SetStat(STAT_STRENGTH, 110);
    player->UpdateAttackPowerAndDamage();
    EXPECT_EQ(player->GetInt32Value(UNIT_FIELD_ATTACK_POWER) - baseline, 20);

    // No CoA Agility coefficient is established for Reaper. Preserve the existing compatibility term.
    player->SetStat(STAT_STRENGTH, 100);
    player->SetStat(STAT_AGILITY, 210);
    player->UpdateAttackPowerAndDamage();
    EXPECT_EQ(player->GetInt32Value(UNIT_FIELD_ATTACK_POWER) - baseline, 10);
}

TEST_F(CustomClassAttackPowerTest, PreservesProvisionalLevelContributions)
{
    struct LevelCase
    {
        Classes playerClass;
        int32 expectedGain;
    };

    // This is compatibility preservation, not a claim about official CoA progression.
    for (LevelCase const& test : {LevelCase{CLASS_BARBARIAN, 3}, LevelCase{CLASS_REAPER, 2},
        LevelCase{CLASS_SUN_CLERIC, 0}, LevelCase{CLASS_STARCALLER, 0}})
    {
        SCOPED_TRACE(uint32(test.playerClass));
        TestPlayer* player = CreatePlayerWithStats(test.playerClass, 59, 100, 200);
        player->UpdateAttackPowerAndDamage();
        int32 const baseline = player->GetInt32Value(UNIT_FIELD_ATTACK_POWER);
        player->SetLevel(60);
        player->UpdateAttackPowerAndDamage();
        EXPECT_EQ(player->GetInt32Value(UNIT_FIELD_ATTACK_POWER) - baseline, test.expectedGain);
    }
}

TEST_F(CustomClassAttackPowerTest, PreservesBaseFlatAndTotalAttackPowerModifiers)
{
    for (Classes playerClass : {CLASS_BARBARIAN, CLASS_SON_OF_ARUGAL})
    {
        TestPlayer* player = CreatePlayerWithStats(playerClass, 80, 200, 300);
        player->SetStatPctModifier(UNIT_MOD_ATTACK_POWER, BASE_PCT, 1.5f);
        player->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER, TOTAL_VALUE, 40.0f);
        player->SetStatPctModifier(UNIT_MOD_ATTACK_POWER, TOTAL_PCT, 1.1f);
        player->UpdateAttackPowerAndDamage();

        EXPECT_EQ(player->GetInt32Value(UNIT_FIELD_ATTACK_POWER), playerClass == CLASS_BARBARIAN ? 1080 : 960);
        EXPECT_EQ(player->GetInt32Value(UNIT_FIELD_ATTACK_POWER_MODS), 40);
        EXPECT_FLOAT_EQ(player->GetTotalAttackPowerValue(BASE_ATTACK),
            playerClass == CLASS_BARBARIAN ? 1232.0f : 1100.0f);
    }
}

TEST_F(CustomClassAttackPowerTest, BloodmageMatchesRogueAtStartingAndMaximumLevel)
{
    struct StatsCase
    {
        uint8 level;
        int32 strength;
        int32 agility;
        int32 expectedAttackPower;
    };

    for (StatsCase const& stats : {StatsCase{1, 19, 20, 21}, StatsCase{80, 200, 300, 640}})
    {
        TestPlayer* bloodmage = CreatePlayerWithStats(CLASS_SON_OF_ARUGAL, stats.level, stats.strength, stats.agility);
        TestPlayer* rogue = CreatePlayerWithStats(CLASS_ROGUE, stats.level, stats.strength, stats.agility);
        bloodmage->UpdateAttackPowerAndDamage();
        rogue->UpdateAttackPowerAndDamage();

        EXPECT_EQ(bloodmage->GetInt32Value(UNIT_FIELD_ATTACK_POWER), stats.expectedAttackPower);
        EXPECT_EQ(bloodmage->GetInt32Value(UNIT_FIELD_ATTACK_POWER), rogue->GetInt32Value(UNIT_FIELD_ATTACK_POWER));
    }
}

TEST_F(CustomClassAttackPowerTest, BloodmageGainsAttackPowerFromBothStatsAndLevel)
{
    TestPlayer* player = CreatePlayerWithStats(CLASS_SON_OF_ARUGAL, 79, 200, 300);
    player->UpdateAttackPowerAndDamage();
    EXPECT_EQ(player->GetInt32Value(UNIT_FIELD_ATTACK_POWER), 638);

    player->SetStat(STAT_AGILITY, 310);
    player->UpdateAttackPowerAndDamage();
    EXPECT_EQ(player->GetInt32Value(UNIT_FIELD_ATTACK_POWER), 648);

    player->SetStat(STAT_STRENGTH, 210);
    player->SetLevel(80);
    player->UpdateAttackPowerAndDamage();
    EXPECT_EQ(player->GetInt32Value(UNIT_FIELD_ATTACK_POWER), 660);
}

TEST_F(CustomClassAttackPowerTest, PreservesRogueMeleeAttackPowerAndOtherCompatibility)
{
    TestPlayer* rogue = CreatePlayerWithStats(CLASS_ROGUE, 80, 200, 300);
    rogue->UpdateAttackPowerAndDamage();

    EXPECT_EQ(rogue->GetInt32Value(UNIT_FIELD_ATTACK_POWER), 640);
    EXPECT_EQ(GetLegacyClassForCustomClass(CLASS_BARBARIAN), CLASS_ROGUE);
    EXPECT_EQ(GetLegacyClassForCustomClass(CLASS_SON_OF_ARUGAL), CLASS_DRUID);
    EXPECT_EQ(GetLegacyClassForCustomClass(CLASS_HERO), CLASS_DRUID);
}

TEST_F(CustomClassAttackPowerTest, PreservesWarriorPriestAndDruidBaselines)
{
    struct LegacyCase
    {
        Classes playerClass;
        int32 expectedAttackPower;
    };

    for (LegacyCase const& test : {LegacyCase{CLASS_WARRIOR, 560}, LegacyCase{CLASS_PRIEST, 190},
        LegacyCase{CLASS_DRUID, 380}})
    {
        SCOPED_TRACE(uint32(test.playerClass));
        TestPlayer* player = CreatePlayerWithStats(test.playerClass, 60, 200, 300);
        player->UpdateAttackPowerAndDamage();
        EXPECT_EQ(player->GetInt32Value(UNIT_FIELD_ATTACK_POWER), test.expectedAttackPower);
    }
}

TEST_F(CustomClassAttackPowerTest, MeleeRecalculationDoesNotOverwriteRangedAttackPower)
{
    for (Classes playerClass : {CLASS_BARBARIAN, CLASS_STARCALLER, CLASS_SUN_CLERIC, CLASS_REAPER})
    {
        SCOPED_TRACE(uint32(playerClass));
        TestPlayer* player = CreatePlayerWithStats(playerClass, 60, 200, 300);
        player->UpdateAttackPowerAndDamage(true);
        int32 const rangedAttackPower = player->GetInt32Value(UNIT_FIELD_RANGED_ATTACK_POWER);
        player->UpdateAttackPowerAndDamage();
        EXPECT_EQ(player->GetInt32Value(UNIT_FIELD_RANGED_ATTACK_POWER), rangedAttackPower);
    }
}

TEST(ClassProjectileAmmoTest, OnlyStockClassesUseProjectileAmmo)
{
    EXPECT_TRUE(UsesProjectileAmmo(CLASS_HUNTER));
    EXPECT_TRUE(UsesProjectileAmmo(CLASS_WARRIOR));
    EXPECT_FALSE(UsesProjectileAmmo(CLASS_HERO));
    EXPECT_FALSE(UsesProjectileAmmo(CLASS_RANGER));
    EXPECT_FALSE(UsesProjectileAmmo(CLASS_WITCH_HUNTER));
}
