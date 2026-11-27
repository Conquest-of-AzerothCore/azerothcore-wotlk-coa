/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AllBattlegroundScript.h"
#include "AscensionConquest.h"
#include "Battleground.h"
#include "CoABattlegroundRewardsPolicy.h"
#include "ObjectMgr.h"
#include "Player.h"

class CoABattlegroundRewards final : public AllBattlegroundScript
{
public:
    CoABattlegroundRewards()
        : AllBattlegroundScript("CoABattlegroundRewards", { ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_END_REWARD }) { }

    void OnBattlegroundEndReward(Battleground* bg, Player* player, TeamId winnerTeamId) override
    {
        if (!bg || !player || bg->isArena())
            return;

        bool const won = player->GetBgTeamId() == winnerTeamId;
        uint8 const level = player->GetLevel();
        uint32 const questId = CoABattlegroundRewardsPolicy::RewardQuestFor(level, won);
        Quest const* quest = questId ? sObjectMgr->GetQuestTemplate(questId) : nullptr;
        if (!quest)
            return;

        player->RewardQuest(quest, 0, nullptr, false, true);
        if (int32 const arenaPoints = quest->GetRewArenaPoints(); arenaPoints > 0)
            AscensionConquest::AnnounceArenaPoints(player, uint32(arenaPoints));
    }
};

void AddSC_CoABattlegroundRewards()
{
    new CoABattlegroundRewards();
}
