/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "DBCStores.h"
#include "GridDefines.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "MotionMaster.h"
#include "ObjectMgr.h"
#include "ScriptMgr.h"
#include <algorithm>
#include <array>
#include <set>
#include <utility>

namespace
{
constexpr std::array<uint32, 1> RoamingCreatureEntries = { 10916 };

bool IsRoamingOpenWorldSpawn(CreatureData const& spawn)
{
    if (spawn.movementType != WAYPOINT_MOTION_TYPE
        || std::find(RoamingCreatureEntries.begin(), RoamingCreatureEntries.end(), spawn.id)
            == RoamingCreatureEntries.end())
        return false;

    MapEntry const* mapEntry = sMapStore.LookupEntry(spawn.mapid);
    return mapEntry && !mapEntry->Instanceable() && Acore::IsValidMapCoord(spawn.posX, spawn.posY);
}

class RoamingCreatureGrids : public WorldScript
{
public:
    RoamingCreatureGrids() : WorldScript("CoARoamingCreatureGrids", { WORLDHOOK_ON_BEFORE_WORLD_INITIALIZED }) { }

    void OnBeforeWorldInitialized() override
    {
        uint32 creatures = 0;
        std::set<std::pair<uint32, uint32>> grids;
        for (auto const& [spawnId, spawn] : sObjectMgr->GetAllCreatureData())
        {
            if (!IsRoamingOpenWorldSpawn(spawn))
                continue;

            ++creatures;
            if (grids.emplace(spawn.mapid, Acore::ComputeGridCoord(spawn.posX, spawn.posY).GetId()).second)
                sMapMgr->CreateBaseMap(spawn.mapid)->LoadGrid(spawn.posX, spawn.posY);
        }

        LOG_INFO("server.loading", ">> Loaded {} grids for {} roaming creature spawns", grids.size(), creatures);
    }
};
}

void AddSC_AscensionRoamingCreatureGrids()
{
    new RoamingCreatureGrids();
}
