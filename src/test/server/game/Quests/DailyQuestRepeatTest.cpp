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

#include "Field.h"
#include "ObjectMgr.h"
#include "QuestDef.h"
#include "ScriptDefines/PlayerScript.h"
#include "IntegrationTestFixture.h"
#include <array>

namespace
{
constexpr uint32 DailyQuestId = 99991;
constexpr uint32 SiblingQuestId = 99992;
constexpr int32 ExclusiveGroupId = 99993;

class DailyQuest : public Quest
{
public:
    DailyQuest(::Field* record, uint32 id) : Quest(record)
    {
        Id = id;
        Flags = QUEST_FLAGS_DAILY;
        SpecialFlags = QUEST_SPECIAL_FLAGS_REPEATABLE;
        ExclusiveGroup = ExclusiveGroupId;
    }
};

class RepeatDailyQuestScript : public PlayerScript
{
public:
    RepeatDailyQuestScript() : PlayerScript("RepeatDailyQuestTest", { PLAYERHOOK_CAN_REPEAT_DAILY_QUEST }) { }

    bool OnPlayerCanRepeatDailyQuest(Player const* player, Quest const* quest) override
    {
        return player == AllowedPlayer && quest->GetQuestId() == DailyQuestId;
    }

    inline static Player const* AllowedPlayer = nullptr;
};

class DailyQuestRepeatTest : public IntegrationTestFixture
{
protected:
    void SetUp() override
    {
        IntegrationTestFixture::SetUp();
        static auto* script = new RepeatDailyQuestScript();
        (void)script;

        player = CreateTestPlayer();
        QuestTemplates().emplace(DailyQuestId, &daily);
        QuestTemplates().emplace(SiblingQuestId, &sibling);
        sObjectMgr->mExclusiveQuestGroups.emplace(ExclusiveGroupId, DailyQuestId);
        sObjectMgr->mExclusiveQuestGroups.emplace(ExclusiveGroupId, SiblingQuestId);
    }

    void TearDown() override
    {
        RepeatDailyQuestScript::AllowedPlayer = nullptr;
        sObjectMgr->mExclusiveQuestGroups.erase(ExclusiveGroupId);
        QuestTemplates().erase(DailyQuestId);
        QuestTemplates().erase(SiblingQuestId);
        IntegrationTestFixture::TearDown();
    }

    static ObjectMgr::QuestMap& QuestTemplates()
    {
        return const_cast<ObjectMgr::QuestMap&>(sObjectMgr->GetQuestTemplates());
    }

    std::array<::Field, 106> emptyQuestRecord;
    DailyQuest daily{emptyQuestRecord.data(), DailyQuestId};
    DailyQuest sibling{emptyQuestRecord.data(), SiblingQuestId};
    TestPlayer* player = nullptr;
};

TEST_F(DailyQuestRepeatTest, RepeatPermissionLeavesSiblingBlocked)
{
    player->SetDailyQuestStatus(DailyQuestId);
    EXPECT_FALSE(player->SatisfyQuestDay(&daily, false));

    RepeatDailyQuestScript::AllowedPlayer = player;
    EXPECT_TRUE(player->SatisfyQuestDay(&daily, false));
    EXPECT_TRUE(player->SatisfyQuestExclusiveGroup(&daily, false));
    EXPECT_FALSE(player->SatisfyQuestExclusiveGroup(&sibling, false));
}

TEST_F(DailyQuestRepeatTest, RepeatCompletionKeepsFirstEmptySlotAvailable)
{
    player->SetUInt32Value(PLAYER_FIELD_DAILY_QUESTS_1 + 1, DailyQuestId);
    RepeatDailyQuestScript::AllowedPlayer = player;
    ASSERT_TRUE(player->SatisfyQuestDay(&daily, false));

    player->SetDailyQuestStatus(DailyQuestId);
    EXPECT_EQ(player->GetUInt32Value(PLAYER_FIELD_DAILY_QUESTS_1), 0u);
    EXPECT_EQ(player->GetUInt32Value(PLAYER_FIELD_DAILY_QUESTS_1 + 1), DailyQuestId);

    player->SetDailyQuestStatus(SiblingQuestId);
    EXPECT_EQ(player->GetUInt32Value(PLAYER_FIELD_DAILY_QUESTS_1), SiblingQuestId);
}
}
