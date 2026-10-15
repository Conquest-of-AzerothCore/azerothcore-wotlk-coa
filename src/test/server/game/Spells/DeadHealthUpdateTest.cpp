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
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfoTestHelper.h"
#include "gtest/gtest.h"

namespace
{
class DeadHealthUpdateTest : public IntegrationTestFixture
{
protected:
    TestPlayer* CreateHealthTarget()
    {
        TestPlayer* player = CreateTestPlayer();
        player->SetCreateHealth(1000);
        player->SetCanModifyStats(true);
        player->UpdateMaxHealth();
        player->SetHealth(400);
        return player;
    }

    std::unique_ptr<SpellInfo> CreateHealthAura()
    {
        return SpellInfoBuilder()
            .WithId(990050)
            .WithAttributesEx3(SPELL_ATTR3_ALLOW_AURA_WHILE_DEAD)
            .WithEffect(0, SPELL_EFFECT_APPLY_AURA, SPELL_AURA_MOD_INCREASE_HEALTH)
            .WithEffectBasePoints(0, 200)
            .BuildUnique();
    }
};

TEST_F(DeadHealthUpdateTest, ResetPowersLeavesCorpseHealthAtZero)
{
    TestPlayer* player = CreateHealthTarget();
    player->Unit::setDeathState(DeathState::Corpse);
    player->SetHealth(0);
    player->SetMaxPower(POWER_MANA, 500);
    player->SetPower(POWER_MANA, 100);

    player->ResetAllPowers();

    EXPECT_EQ(player->getDeathState(), DeathState::Corpse);
    EXPECT_EQ(player->GetHealth(), 0u);
    EXPECT_EQ(player->GetPower(POWER_MANA), 500u);
}

TEST_F(DeadHealthUpdateTest, ResetPowersRestoresLivingHealth)
{
    TestPlayer* player = CreateHealthTarget();

    player->ResetAllPowers();

    EXPECT_EQ(player->GetHealth(), player->GetMaxHealth());
    EXPECT_TRUE(player->IsAlive());
}

TEST_F(DeadHealthUpdateTest, HealthAuraChangesMaximumWithoutHealingCorpse)
{
    TestPlayer* player = CreateHealthTarget();
    player->Unit::setDeathState(DeathState::Corpse);
    player->SetHealth(0);
    auto spell = CreateHealthAura();
    uint32 const maxHealth = player->GetMaxHealth();

    Aura* aura = player->AddAura(spell.get(), 1, player);
    ASSERT_NE(aura, nullptr);
    ASSERT_NE(aura->GetApplicationOfTarget(player->GetGUID()), nullptr);
    int32 const amount = aura->GetEffect(0)->GetAmount();

    EXPECT_GT(amount, 0);
    EXPECT_EQ(player->GetMaxHealth(), maxHealth + amount);
    EXPECT_EQ(player->GetHealth(), 0u);
    EXPECT_EQ(player->getDeathState(), DeathState::Corpse);

    aura->Remove();

    EXPECT_EQ(player->GetMaxHealth(), maxHealth);
    EXPECT_EQ(player->GetHealth(), 0u);
}

TEST_F(DeadHealthUpdateTest, HealthAuraPreservesLivingHealthChanges)
{
    TestPlayer* player = CreateHealthTarget();
    auto spell = CreateHealthAura();
    uint32 const health = player->GetHealth();
    uint32 const maxHealth = player->GetMaxHealth();

    Aura* aura = player->AddAura(spell.get(), 1, player);
    ASSERT_NE(aura, nullptr);
    int32 const amount = aura->GetEffect(0)->GetAmount();

    EXPECT_EQ(player->GetMaxHealth(), maxHealth + amount);
    EXPECT_EQ(player->GetHealth(), health + amount);

    aura->Remove();

    EXPECT_EQ(player->GetMaxHealth(), maxHealth);
    EXPECT_EQ(player->GetHealth(), health);
}
}
