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

#include "ScriptDefines/PlayerScript.h"
#include "IntegrationTestFixture.h"

namespace
{
class ExperienceCapScript : public PlayerScript
{
public:
    ExperienceCapScript() : PlayerScript("ExperienceCapTest", { PLAYERHOOK_ON_GET_MAX_ALLOWED_LEVEL }) { }

    uint8 OnPlayerGetMaxAllowedLevel(Player* /*player*/) override { return Cap; }

    inline static uint8 Cap = 0;
};

class ExperienceCapTest : public IntegrationTestFixture
{
protected:
    void SetUp() override
    {
        IntegrationTestFixture::SetUp();
        static auto* script = new ExperienceCapScript();
        (void)script;
        ExperienceCapScript::Cap = 19;
        ON_CALL(*GetWorldMock(), getIntConfig(CONFIG_MAX_PLAYER_LEVEL)).WillByDefault(Return(80));
        player = CreateTestPlayer(1);
        player->SetLevel(19);
        player->SetMaxHealth(100);
        player->SetHealth(100);
        player->SetUInt32Value(PLAYER_NEXT_LEVEL_XP, 10000);
        player->SetUInt32Value(PLAYER_XP, 9000);
        player->SetRestBonus(1000);
        // A player victim exercises kill/rested XP without a creature loot recipient fixture.
        victim = CreateTestPlayer(2);
    }

    void TearDown() override
    {
        ExperienceCapScript::Cap = 0;
        IntegrationTestFixture::TearDown();
    }

    TestPlayer* player = nullptr;
    TestPlayer* victim = nullptr;
};
}

TEST_F(ExperienceCapTest, MultipliedGainSpendsOnlyRestedExperienceThatFits)
{
    // 100 base XP at x8 has already passed through OnPlayerGiveXP.
    player->GiveXP(800, victim);
    EXPECT_EQ(player->GetLevel(), 19);
    EXPECT_EQ(player->GetUInt32Value(PLAYER_XP), 9999u);
    EXPECT_FLOAT_EQ(player->GetRestBonus(), 801.0f);
}

TEST_F(ExperienceCapTest, BaseExperienceFillsRemainingRoomWithoutSpendingRest)
{
    player->GiveXP(2000, victim);
    EXPECT_EQ(player->GetUInt32Value(PLAYER_XP), 9999u);
    EXPECT_FLOAT_EQ(player->GetRestBonus(), 1000.0f);
}

TEST_F(ExperienceCapTest, FullBarPreservesRestedExperience)
{
    player->SetUInt32Value(PLAYER_XP, 9999);
    player->GiveXP(800, victim);
    EXPECT_EQ(player->GetUInt32Value(PLAYER_XP), 9999u);
    EXPECT_FLOAT_EQ(player->GetRestBonus(), 1000.0f);
}

TEST_F(ExperienceCapTest, QuestGainDoesNotConsumeRestedExperience)
{
    player->GiveXP(2000, nullptr);
    EXPECT_EQ(player->GetUInt32Value(PLAYER_XP), 9999u);
    EXPECT_FLOAT_EQ(player->GetRestBonus(), 1000.0f);
}

TEST_F(ExperienceCapTest, UncappedGainKeepsNormalRestedBonus)
{
    ExperienceCapScript::Cap = 0;
    player->GiveXP(200, victim);
    EXPECT_EQ(player->GetUInt32Value(PLAYER_XP), 9400u);
    EXPECT_FLOAT_EQ(player->GetRestBonus(), 800.0f);
}
