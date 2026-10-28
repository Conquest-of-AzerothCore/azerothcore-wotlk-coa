/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "GameObject.h"
#include "GameObjectAI.h"
#include "GameObjectScript.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"

namespace
{
constexpr uint32 QUEST_NO_MATTER_THE_COST = 175043;
constexpr uint32 NPC_TEXT_CARDENS_JOURNAL = 2300689;

struct go_coa_cardens_diary : public GameObjectAI
{
    explicit go_coa_cardens_diary(GameObject* go) : GameObjectAI(go) { }

    bool GossipHello(Player* player, bool reportUse) override
    {
        if (reportUse || player->GetQuestStatus(QUEST_NO_MATTER_THE_COST) == QUEST_STATUS_NONE)
            return false;

        ClearGossipMenuFor(player);
        SendGossipMenuFor(player, NPC_TEXT_CARDENS_JOURNAL, me->GetGUID());
        return true;
    }
};
}

void AddSC_AscensionCardensDiary()
{
    RegisterGameObjectAI(go_coa_cardens_diary);
}
