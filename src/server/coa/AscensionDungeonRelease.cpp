/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDungeonRelease.h"
#include "Chat.h"
#include "DataMap.h"
#include "DBCStores.h"
#include "Group.h"
#include "InstanceScript.h"
#include "LFGMgr.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"

#include <algorithm>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace
{
constexpr char const* PENDING_DUNGEON_RELEASE = "ascension_dungeon_release";
constexpr float RELEASE_RESTORE_PERCENT = 0.5f;
constexpr uint32 SPELL_CORPSE_RUNNER = 84015;
constexpr char const* RAID_RELEASE_HOLD = "ascension_raid_release_hold";
constexpr char const* RAID_RELEASE_REFUSED = "You cannot release your spirit during a boss fight.";

struct PendingDungeonRelease : DataMap::Base { };

struct RaidReleaseHold : DataMap::Base
{
    std::unordered_map<ObjectGuid, std::vector<uint32>> held;
};

bool InRaidFight(Map* map)
{
    if (!map->IsRaid())
        return false;
    InstanceMap* instanceMap = map->ToInstanceMap();
    InstanceScript* instance = instanceMap ? instanceMap->GetInstanceScript() : nullptr;
    return instance && instance->IsEncounterInProgress();
}

void Hold(Player* player)
{
    RaidReleaseHold* hold = player->GetMap()->CustomData.GetDefault<RaidReleaseHold>(RAID_RELEASE_HOLD);
    if (hold->held.count(player->GetGUID()))
        return;

    std::vector<uint32> fighting;
    InstanceScript* instance = player->GetMap()->ToInstanceMap()->GetInstanceScript();
    for (uint32 bossId = 0; bossId < instance->GetEncounterCount(); ++bossId)
        if (instance->GetBossState(bossId) == IN_PROGRESS)
            fighting.push_back(bossId);
    hold->held.emplace(player->GetGUID(), std::move(fighting));
}

std::mutex g_runStartsLock;
std::unordered_map<uint32, std::pair<uint32, Position>> g_runStarts;

struct ReleaseCheckpoint
{
    uint32 bossId;
    Position position;
};

std::mutex g_checkpointsLock;
std::unordered_map<uint32, std::vector<ReleaseCheckpoint>> g_checkpoints;

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

bool CheckpointStart(Player* player, Position& start)
{
    InstanceScript* instance = player->GetInstanceScript();
    if (!instance)
        return false;

    std::lock_guard<std::mutex> guard(g_checkpointsLock);
    auto itr = g_checkpoints.find(player->GetMapId());
    if (itr == g_checkpoints.end())
        return false;

    float nearestDistance = -1.0f;
    for (ReleaseCheckpoint const& checkpoint : itr->second)
        if (instance->GetBossState(checkpoint.bossId) == DONE)
            Nearest(player, checkpoint.position.GetPositionX(), checkpoint.position.GetPositionY(),
                checkpoint.position.GetPositionZ(), checkpoint.position.GetOrientation(), nearestDistance, start);
    return nearestDistance >= 0.0f;
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

    if (CheckpointStart(player, start))
        return true;

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
            {PLAYERHOOK_ON_PLAYER_RELEASED_GHOST, PLAYERHOOK_CAN_REPOP_AT_GRAVEYARD, PLAYERHOOK_ON_PLAYER_ENTER_COMBAT,
                PLAYERHOOK_ON_PLAYER_JUST_DIED, PLAYERHOOK_CAN_RELEASE_SPIRIT}) { }

    bool OnPlayerCanReleaseSpirit(Player* player) override
    {
        if (!InRaidFight(player->GetMap()))
            return true;

        Hold(player);
        ChatHandler(player->GetSession()).SendNotification(RAID_RELEASE_REFUSED);
        return false;
    }

    void OnPlayerJustDied(Player* player) override
    {
        Map* map = player->GetMap();
        if (!InRaidFight(map))
            return;

        if (RaidReleaseHold* hold = map->CustomData.Get<RaidReleaseHold>(RAID_RELEASE_HOLD))
            hold->held.erase(player->GetGUID());
        Hold(player);
    }

    void OnPlayerReleasedGhost(Player* player) override
    {
        if (player->GetMap()->IsDungeon())
            player->CustomData.GetDefault<PendingDungeonRelease>(PENDING_DUNGEON_RELEASE);
    }

    bool OnPlayerCanRepopAtGraveyard(Player* player) override
    {
        if (!player->CustomData.Erase(PENDING_DUNGEON_RELEASE))
            return true;

        if (player->IsAlive() || !player->GetMap()->IsDungeon() || !player->m_InstanceValid
            || InRaidFight(player->GetMap()))
            return true;

        Position start;
        if (!InstanceStart(player, start))
            return true;

        player->ResurrectPlayer(RELEASE_RESTORE_PERCENT);
        if (!player->IsAlive())
            return true;

        player->SpawnCorpseBones();
        player->NearTeleportTo(start.GetPositionX(), start.GetPositionY(), start.GetPositionZ(), start.GetOrientation());
        if (player->GetMap()->IsNonRaidDungeon() && player->GetMap()->GetDifficulty() < DUNGEON_DIFFICULTY_EPIC)
            player->CastSpell(player, SPELL_CORPSE_RUNNER, true);
        return false;
    }

    void OnPlayerEnterCombat(Player* player, Unit*) override
    {
        player->RemoveAurasDueToSpell(SPELL_CORPSE_RUNNER);
    }
};

bool AnyoneFighting(Map* map)
{
    bool fighting = false;
    map->DoForAllPlayers([&fighting](Player* player)
    {
        if (player->IsAlive() && !player->IsGameMaster() && player->IsInCombat())
            fighting = true;
    });
    return fighting;
}

void ResolveHeld(Player* player, std::vector<uint32> const& fighting)
{
    InstanceScript* instance = player->GetInstanceScript();
    bool const killed = instance && std::any_of(fighting.begin(), fighting.end(),
        [instance](uint32 bossId) { return instance->GetBossState(bossId) == DONE; });

    Position start;
    bool const moved = !killed && InstanceStart(player, start);

    player->ResurrectPlayer(RELEASE_RESTORE_PERCENT);
    if (!player->IsAlive())
        return;

    player->SpawnCorpseBones();
    if (moved)
        player->NearTeleportTo(start.GetPositionX(), start.GetPositionY(), start.GetPositionZ(), start.GetOrientation());
}

class ascension_dungeon_release_map : public AllMapScript
{
public:
    ascension_dungeon_release_map()
        : AllMapScript("ascension_dungeon_release_map", {ALLMAPHOOK_ON_CREATE_MAP, ALLMAPHOOK_ON_MAP_UPDATE}) { }

    void OnMapUpdate(Map* map, uint32) override
    {
        if (!map->IsRaid())
            return;

        RaidReleaseHold* hold = map->CustomData.Get<RaidReleaseHold>(RAID_RELEASE_HOLD);
        if (!hold || (InRaidFight(map) && AnyoneFighting(map)))
            return;

        std::unordered_map<ObjectGuid, std::vector<uint32>> held = std::move(hold->held);
        map->CustomData.Erase(RAID_RELEASE_HOLD);
        for (auto const& [guid, fighting] : held)
        {
            Player* player = ObjectAccessor::GetPlayer(map, guid);
            if (player && !player->IsAlive() && !player->HasPlayerFlag(PLAYER_FLAGS_GHOST))
                ResolveHeld(player, fighting);
        }
    }

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

void CoAAddDungeonReleaseCheckpoint(uint32 mapId, uint32 bossId, Position const& position)
{
    std::lock_guard<std::mutex> guard(g_checkpointsLock);
    g_checkpoints[mapId].push_back({ bossId, position });
}

void AddSC_AscensionDungeonRelease()
{
    new ascension_dungeon_release_player();
    new ascension_dungeon_release_map();
}
