/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "GlobalScript.h"
#include "Group.h"
#include "LFGMgr.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>

namespace
{
constexpr uint16 SMSG_LFG_UPDATE_CUSTOM = 0x066D;

class lfg_objective_dungeon : public PlayerScript
{
public:
    lfg_objective_dungeon() : PlayerScript("lfg_objective_dungeon", {PLAYERHOOK_ON_MAP_CHANGED}) { }

    void OnPlayerMapChanged(Player* player) override
    {
        WorldSession* session = player ? player->GetSession() : nullptr;
        if (!session)
            return;

        uint32 dungeonId = 0;
        Map const* map = player->GetMap();
        Group const* group = player->GetGroup();
        if (map && group && group->isLFGGroup()
            && sLFGMgr->inLfgDungeonMap(group->GetGUID(), map->GetId(), map->GetDifficulty()))
            dungeonId = sLFGMgr->GetDungeon(group->GetGUID());

        WorldPacket packet(SMSG_LFG_UPDATE_CUSTOM, 4);
        packet << uint32(dungeonId);
        session->SendPacket(&packet);
    }
};

bool HasOwnFinalEncounter(std::list<DungeonEncounter const*> const* encounters, uint32 dungeonId)
{
    return encounters && std::any_of(encounters->begin(), encounters->end(),
        [dungeonId](DungeonEncounter const* encounter) { return encounter->lastEncounterDungeon == dungeonId; });
}

bool IsCreditedFinalEncounter(std::list<DungeonEncounter const*> const* encounters, uint32 dungeonId,
    EncounterCreditType type, uint32 creditEntry)
{
    return encounters && std::any_of(encounters->begin(), encounters->end(),
        [dungeonId, type, creditEntry](DungeonEncounter const* encounter)
        {
            return encounter->lastEncounterDungeon == dungeonId && encounter->creditType == type &&
                encounter->creditEntry == creditEntry;
        });
}

class lfg_final_boss_reward : public GlobalScript
{
public:
    lfg_final_boss_reward() : GlobalScript("lfg_final_boss_reward", {GLOBALHOOK_ON_AFTER_UPDATE_ENCOUNTER_STATE}) { }

    void OnAfterUpdateEncounterState(Map* map, EncounterCreditType type, uint32 creditEntry, Unit*, Difficulty,
        std::list<DungeonEncounter const*> const* encounters, uint32 dungeonCompleted, bool) override
    {
        if (!map || !dungeonCompleted)
            return;

        lfg::LFGDungeonData const* completed = sLFGMgr->GetLFGDungeon(dungeonCompleted);
        if (!completed || completed->map != map->GetId())
            return;

        Map::PlayerList const& players = map->GetPlayers();
        for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
        {
            Player* player = itr->GetSource();
            Group* group = player ? player->GetGroup() : nullptr;
            if (!group || !group->isLFGGroup())
                continue;

            uint32 const queued = sLFGMgr->GetDungeon(group->GetGUID());
            if (queued && queued != dungeonCompleted &&
                (IsCreditedFinalEncounter(encounters, queued, type, creditEntry) ||
                    !HasOwnFinalEncounter(encounters, queued)))
            {
                lfg::LFGDungeonData const* selected = sLFGMgr->GetLFGDungeon(queued);
                if (selected && selected->map == completed->map)
                    sLFGMgr->FinishDungeon(group->GetGUID(), queued, map);
            }
            return;
        }
    }
};
}

void AddSC_AscensionLfgObjective()
{
    new lfg_objective_dungeon();
    new lfg_final_boss_reward();
}
