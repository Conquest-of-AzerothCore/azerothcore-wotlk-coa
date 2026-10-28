/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Chat.h"
#include "GameObject.h"
#include "GameObjectScript.h"
#include "Player.h"
#include "ScriptMgr.h"

namespace
{
constexpr char KeepDoorOpenedSetting[] = "core.coa_stormwind_keep_door";
Position const HallwaySide = { -8282.09f, 267.67f, 126.83f };
Position const ChamberSide = { -8277.31f, 271.30f, 126.83f };

class go_coa_stormwind_keep_door : public GameObjectScript
{
public:
    go_coa_stormwind_keep_door() : GameObjectScript("go_coa_stormwind_keep_door") { }

    bool OnGossipHello(Player* player, GameObject*) override
    {
        if (player->GetPlayerSetting(KeepDoorOpenedSetting, 0).value)
            return false;

        bool const fromHallway = player->GetExactDist2d(HallwaySide) < player->GetExactDist2d(ChamberSide);
        if (fromHallway)
        {
            player->UpdatePlayerSetting(KeepDoorOpenedSetting, 0, 1);
            return false;
        }

        ChatHandler(player->GetSession()).SendNotification("The door won't budge.");
        return true;
    }
};
}

void AddSC_AscensionStormwindKeepDoor()
{
    new go_coa_stormwind_keep_door();
}
