/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionQuestLog.h"
#include "Player.h"
#include "PlayerScript.h"

namespace AscensionQuestLog
{
class QuestLogSync : public PlayerScript
{
public:
    QuestLogSync() : PlayerScript("AscensionQuestLog", {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LEVEL_CHANGED}) { }

    void OnPlayerLogin(Player* player) override
    {
        SendAll(player);
    }

    void OnPlayerLevelChanged(Player* player, uint8) override
    {
        SendAll(player);
    }
};
}

void AddSC_AscensionQuestLog()
{
    new AscensionQuestLog::QuestLogSync();
}
