/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDungeonRelease.h"
#include "DBCStores.h"
#include "Group.h"
#include "LFGMgr.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"

#include <mutex>
#include <unordered_map>

namespace
{
constexpr char const* PENDING_DUNGEON_RELEASE = "ascension_dungeon_release";
constexpr float RELEASE_RESTORE_PERCENT = 0.5f;

struct PendingDungeonRelease : DataMap::Base { };

std::mutex g_runStartsLock;
std::unordered_map<uint32, std::pair<uint32, Position>> g_runStarts;

bool HasStart(lfg::LFGDungeonData const* dungeon, uint32 mapId)
{
    return dungeon && dungeon->map == mapId && (dungeon->x || dungeon->y || dungeon->z);
}

void Nearest(Player* player, float x, float y, float z, float o, float& nearestDistance, Position& start)
{
    float const distance = player->GetExactDistSq(x, y, z);
    if (nearestDistance < 0.0f || distance < nearestDistance)
    {
        nearestDistance = distance;
        start.Relocate(x, y, z, o);
    }
}

bool InstanceStart(Player* player, Position& start)
{
    Map* map = player->GetMap();
    uint32 const mapId = map->GetId();
    {
        std::lock_guard<std::mutex> guard(g_runStartsLock);
        auto itr = g_runStarts.find(map->GetInstanceId());
        if (itr != g_runStarts.end() && itr->second.first == mapId)
        {
            start = itr->second.second;
            return true;
        }
    }

    if (Group* group = player->GetGroup(); group && group->isLFGGroup())
    {
        lfg::LFGDungeonData const* dungeon = sLFGMgr->GetLFGDungeon(sLFGMgr->GetDungeon(group->GetGUID()));
        if (HasStart(dungeon, mapId))
        {
            start.Relocate(dungeon->x, dungeon->y, dungeon->z, dungeon->o);
            return true;
        }
    }

    float nearestDistance = -1.0f;
    bool withoutStart = false;
    for (LFGDungeonEntry const* entry : sLFGDungeonStore)
    {
        if (!entry || entry->MapID != mapId || Difficulty(entry->Difficulty) != map->GetDifficulty()
            || (entry->Flags & lfg::LFG_FLAG_SEASONAL) || entry->TypeID == lfg::LFG_TYPE_RANDOM)
            continue;
        lfg::LFGDungeonData const* dungeon = sLFGMgr->GetLFGDungeon(entry->ID);
        if (HasStart(dungeon, mapId))
            Nearest(player, dungeon->x, dungeon->y, dungeon->z, dungeon->o, nearestDistance, start);
        else
            withoutStart = true;
    }

    if (nearestDistance < 0.0f || withoutStart)
        for (auto const& [triggerId, teleport] : sObjectMgr->GetAllAreaTriggerTeleports())
            if (teleport.target_mapId == mapId)
                Nearest(player, teleport.target_X, teleport.target_Y, teleport.target_Z, teleport.target_Orientation,
                    nearestDistance, start);
    return nearestDistance >= 0.0f;
}

class ascension_dungeon_release_player : public PlayerScript
{
public:
    ascension_dungeon_release_player()
        : PlayerScript("ascension_dungeon_release_player",
            {PLAYERHOOK_ON_PLAYER_RELEASED_GHOST, PLAYERHOOK_CAN_REPOP_AT_GRAVEYARD}) { }

    void OnPlayerReleasedGhost(Player* player) override
    {
        if (player->GetMap()->IsDungeon())
            player->CustomData.GetDefault<PendingDungeonRelease>(PENDING_DUNGEON_RELEASE);
    }

    bool OnPlayerCanRepopAtGraveyard(Player* player) override
    {
        if (!player->CustomData.Erase(PENDING_DUNGEON_RELEASE))
            return true;

        if (player->IsAlive() || !player->GetMap()->IsDungeon() || !player->m_InstanceValid)
            return true;

        Position start;
        if (!InstanceStart(player, start))
            return true;

        player->ResurrectPlayer(RELEASE_RESTORE_PERCENT);
        if (!player->IsAlive())
            return true;

        player->SpawnCorpseBones();
        player->NearTeleportTo(start.GetPositionX(), start.GetPositionY(), start.GetPositionZ(), start.GetOrientation());
        return false;
    }
};

class ascension_dungeon_release_map : public AllMapScript
{
public:
    ascension_dungeon_release_map() : AllMapScript("ascension_dungeon_release_map", {ALLMAPHOOK_ON_CREATE_MAP}) { }

    void OnCreateMap(Map* map) override
    {
        if (!map->Instanceable())
            return;
        std::lock_guard<std::mutex> guard(g_runStartsLock);
        g_runStarts.erase(map->GetInstanceId());
    }
};
}

void CoASetDungeonReleaseStart(Map* map, Position const& start)
{
    std::lock_guard<std::mutex> guard(g_runStartsLock);
    g_runStarts[map->GetInstanceId()] = { map->GetId(), start };
}

void AddSC_AscensionDungeonRelease()
{
    new ascension_dungeon_release_player();
    new ascension_dungeon_release_map();
}
