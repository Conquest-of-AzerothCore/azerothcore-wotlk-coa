/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_QUEST_CLUES_H
#define ASCENSION_QUEST_CLUES_H

#include "SmartAI.h"

namespace Ascension
{
    struct QuestClues
    {
        uint32 Quest;
        uint32 FirstClue;
        char const* InvestigatedSetting;
        bool StaysVisible = false;
    };

    class QuestClueAI : public SmartGameObjectAI
    {
    public:
        QuestClueAI(GameObject* go, QuestClues const& clues) : SmartGameObjectAI(go), _clues(clues) { }

        bool CanBeSeen(Player const* seer) override;
        bool CanActivateToQuest(Player* player) override;
        bool GossipHello(Player* player, bool reportUse) override;

    private:
        void ShowInvestigated(Player* player);
        uint16 CluesCounted(Player const* player) const;
        uint32 InvestigatedClues(Player const* player) const;
        uint32 ClueBit() const;
        bool Investigated(Player const* player) const;

        QuestClues const _clues;
    };
}

#endif
