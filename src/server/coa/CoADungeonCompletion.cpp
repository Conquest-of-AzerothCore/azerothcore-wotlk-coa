/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoADungeonCompletion.h"
#include "GlobalScript.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"

void CoAResurrectDeadPlayers(Map* map)
{
    if (!map)
        return;
    map->DoForAllPlayers([map](Player* player)
    {
        if (player->IsAlive() || !player->IsInWorld())
            return;
        player->ResurrectPlayer(1.0f);
        player->SpawnCorpseBones();
        LOG_INFO("module", "Dungeon complete: {} resurrected on map {} instance {}", player->GetName(), map->GetId(),
            map->GetInstanceId());
    });
}

class CoADungeonCompletion final : public GlobalScript
{
public:
    CoADungeonCompletion() : GlobalScript("CoADungeonCompletion", { GLOBALHOOK_ON_AFTER_UPDATE_ENCOUNTER_STATE }) { }

    void OnAfterUpdateEncounterState(Map* map, EncounterCreditType, uint32, Unit*, Difficulty,
        std::list<DungeonEncounter const*> const*, uint32 dungeonCompleted, bool) override
    {
        if (dungeonCompleted && map && map->IsNonRaidDungeon())
            CoAResurrectDeadPlayers(map);
    }
};

void AddSC_CoADungeonCompletion()
{
    new CoADungeonCompletion();
}
