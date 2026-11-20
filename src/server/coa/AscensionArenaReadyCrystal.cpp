/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AllBattlegroundScript.h"
#include "ArenaScript.h"
#include "Battleground.h"
#include "Chat.h"
#include "GameObject.h"
#include "GameObjectScript.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include <array>
#include <cmath>
#include <mutex>
#include <unordered_map>
#include <unordered_set>

namespace
{
constexpr uint32 ArenaReadyCrystalEntry = 9900053;
constexpr float CrystalDistanceFromStart = 3.0f;

struct ArenaReadiness
{
    std::unordered_set<ObjectGuid> ReadyPlayers;
    std::array<ObjectGuid, PVP_TEAMS_COUNT> Crystals{};
};

std::mutex ReadinessLock;
std::unordered_map<uint32, ArenaReadiness> Readiness;

bool InPreparation(Battleground const* bg)
{
    return bg && bg->isArena() && bg->GetStatus() == STATUS_WAIT_JOIN;
}

void RemoveCrystals(Battleground* bg, ArenaReadiness& readiness)
{
    BattlegroundMap* map = bg->FindBgMap();
    for (ObjectGuid& crystalGuid : readiness.Crystals)
    {
        if (crystalGuid && map)
            if (GameObject* crystal = map->GetGameObject(crystalGuid))
            {
                crystal->SetRespawnTime(0);
                crystal->Delete();
            }
        crystalGuid.Clear();
    }
}

bool BothTeamsReady(Battleground const* bg, ArenaReadiness const& readiness)
{
    for (TeamId team : { TEAM_ALLIANCE, TEAM_HORDE })
        if (bg->GetPlayersCountByTeam(team) != bg->GetArenaType())
            return false;

    for (auto const& [guid, player] : bg->GetPlayers())
        if (!readiness.ReadyPlayers.contains(guid))
            return false;

    return true;
}

uint32 ReadyPresentPlayers(Battleground const* bg, ArenaReadiness const& readiness)
{
    uint32 ready = 0;
    for (auto const& [guid, player] : bg->GetPlayers())
        ready += readiness.ReadyPlayers.contains(guid);
    return ready;
}

class AscensionArenaReadyCrystalSpawner : public AllBattlegroundScript
{
public:
    AscensionArenaReadyCrystalSpawner() : AllBattlegroundScript("AscensionArenaReadyCrystalSpawner",
        { ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_ADD_PLAYER, ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_DESTROY }) { }

    void OnBattlegroundAddPlayer(Battleground* bg, Player* player) override
    {
        if (!InPreparation(bg))
            return;

        TeamId const team = player->GetBgTeamId();
        Position const* start = bg->GetTeamStartPosition(team);
        BattlegroundMap* map = bg->FindBgMap();
        if (team >= PVP_TEAMS_COUNT || !start || !map)
            return;

        std::lock_guard lock(ReadinessLock);
        ObjectGuid& crystalGuid = Readiness[bg->GetInstanceID()].Crystals[team];
        if (crystalGuid)
            return;

        float const orientation = start->GetOrientation();
        Position const spot(start->GetPositionX() + CrystalDistanceFromStart * std::cos(orientation),
            start->GetPositionY() + CrystalDistanceFromStart * std::sin(orientation), start->GetPositionZ(), orientation);
        if (GameObject* crystal = map->SummonGameObject(ArenaReadyCrystalEntry, spot, 0.0f, 0.0f, 0.0f, 0.0f, 0))
        {
            crystal->SetPhaseMask(player->GetPhaseMask(), true);
            crystalGuid = crystal->GetGUID();
        }
    }

    void OnBattlegroundDestroy(Battleground* bg) override
    {
        std::lock_guard lock(ReadinessLock);
        Readiness.erase(bg->GetInstanceID());
    }
};

class AscensionArenaReadyCrystalCleanup : public ArenaScript
{
public:
    AscensionArenaReadyCrystalCleanup() : ArenaScript("AscensionArenaReadyCrystalCleanup",
        { ARENAHOOK_ON_ARENA_START }) { }

    void OnArenaStart(Battleground* bg) override
    {
        std::lock_guard lock(ReadinessLock);
        auto readiness = Readiness.find(bg->GetInstanceID());
        if (readiness != Readiness.end())
            RemoveCrystals(bg, readiness->second);
    }
};

class go_coa_arena_ready_crystal : public GameObjectScript
{
public:
    go_coa_arena_ready_crystal() : GameObjectScript("go_coa_arena_ready_crystal") { }

    bool OnGossipHello(Player* player, GameObject*) override
    {
        Battleground* bg = player->GetBattleground();
        if (!InPreparation(bg))
            return true;

        std::lock_guard lock(ReadinessLock);
        ArenaReadiness& readiness = Readiness[bg->GetInstanceID()];
        readiness.ReadyPlayers.insert(player->GetGUID());

        ChatHandler(player->GetSession()).PSendSysMessage("Ready: {}/{}", ReadyPresentPlayers(bg, readiness),
            uint32(bg->GetArenaType()) * PVP_TEAMS_COUNT);

        if (BothTeamsReady(bg, readiness) && bg->GetStartDelayTime() > BG_START_DELAY_15S)
        {
            bg->SetStartDelayTime(BG_START_DELAY_15S);
            bg->AddStartingEventFlag(BG_STARTING_EVENT_1 | BG_STARTING_EVENT_2);
            RemoveCrystals(bg, readiness);
        }

        return true;
    }
};
}

void AddSC_AscensionArenaReadyCrystal()
{
    new AscensionArenaReadyCrystalSpawner();
    new AscensionArenaReadyCrystalCleanup();
    new go_coa_arena_ready_crystal();
}
