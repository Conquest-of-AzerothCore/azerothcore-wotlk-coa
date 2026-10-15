/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "GameObject.h"
#include "GameObjectScript.h"
#include "Player.h"
#include "QuestDef.h"
#include "ScriptMgr.h"
#include "SmartAI.h"

namespace
{
constexpr uint32 QUEST_THEY_GRABBED_HER_BY_THE_ANKLE = 175069;
constexpr uint32 GO_FIRST_CLUE = 2300672;
constexpr uint8 CLUE_COUNTER = 0;
constexpr char InvestigatedCluesSetting[] = "core.coa_shadewell_clues";

uint16 CluesCounted(Player const* player)
{
    uint16 const slot = player->FindQuestSlot(QUEST_THEY_GRABBED_HER_BY_THE_ANKLE);
    return slot < MAX_QUEST_LOG_SIZE ? player->GetQuestSlotCounter(slot, CLUE_COUNTER) : 0;
}

uint32 InvestigatedClues(Player const* player)
{
    PlayerSettingVector const* settings = player->FindPlayerSettings(InvestigatedCluesSetting);
    return settings && !settings->empty() ? settings->front().value : 0;
}

struct go_coa_shadewell_clue : public SmartGameObjectAI
{
    explicit go_coa_shadewell_clue(GameObject* go) : SmartGameObjectAI(go) { }

    uint32 ClueBit() const
    {
        return 1u << (me->GetEntry() - GO_FIRST_CLUE);
    }

    bool Investigated(Player const* player) const
    {
        return CluesCounted(player) && (InvestigatedClues(player) & ClueBit());
    }

    bool CanBeSeen(Player const* seer) override
    {
        return !Investigated(seer);
    }

    bool GossipHello(Player* player, bool reportUse) override
    {
        if (reportUse)
            return SmartGameObjectAI::GossipHello(player, reportUse);

        if (Investigated(player))
            return true;

        uint32 const earlier = CluesCounted(player) ? InvestigatedClues(player) : 0;
        SmartGameObjectAI::GossipHello(player, reportUse);
        player->UpdatePlayerSetting(InvestigatedCluesSetting, 0, earlier | ClueBit());
        player->UpdateVisibilityOf(me);
        return false;
    }
};
}

void AddSC_AscensionShadewellClues()
{
    RegisterGameObjectAI(go_coa_shadewell_clue);
}
