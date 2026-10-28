/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionQuestClues.h"
#include "GameObject.h"
#include "Player.h"
#include "QuestDef.h"
#include "UpdateData.h"

namespace Ascension
{
    namespace
    {
        constexpr uint8 CLUE_COUNTER = 0;
    }

    uint16 QuestClueAI::CluesCounted(Player const* player) const
    {
        uint16 const slot = player->FindQuestSlot(_clues.Quest);
        return slot < MAX_QUEST_LOG_SIZE ? player->GetQuestSlotCounter(slot, CLUE_COUNTER) : 0;
    }

    uint32 QuestClueAI::InvestigatedClues(Player const* player) const
    {
        PlayerSettingVector const* settings = player->FindPlayerSettings(_clues.InvestigatedSetting);
        return settings && !settings->empty() ? settings->front().value : 0;
    }

    uint32 QuestClueAI::ClueBit() const
    {
        return 1u << (me->GetEntry() - _clues.FirstClue);
    }

    bool QuestClueAI::Investigated(Player const* player) const
    {
        return CluesCounted(player) && (InvestigatedClues(player) & ClueBit());
    }

    bool QuestClueAI::CanBeSeen(Player const* seer)
    {
        return _clues.StaysVisible || !Investigated(seer);
    }

    bool QuestClueAI::CanActivateToQuest(Player* player)
    {
        return !Investigated(player);
    }

    void QuestClueAI::ShowInvestigated(Player* player)
    {
        if (!_clues.StaysVisible)
        {
            player->UpdateVisibilityOf(me);
            return;
        }

        UpdateData data;
        me->BuildValuesUpdateBlockForPlayer(&data, player);
        WorldPacket packet;
        data.BuildPacket(packet);
        player->SendDirectMessage(&packet);
    }

    bool QuestClueAI::GossipHello(Player* player, bool reportUse)
    {
        if (reportUse)
            return SmartGameObjectAI::GossipHello(player, reportUse);

        if (Investigated(player))
            return true;

        uint32 const earlier = CluesCounted(player) ? InvestigatedClues(player) : 0;
        SmartGameObjectAI::GossipHello(player, reportUse);
        player->UpdatePlayerSetting(_clues.InvestigatedSetting, 0, earlier | ClueBit());
        ShowInvestigated(player);
        return false;
    }
}
