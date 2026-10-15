/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "CombatAI.h"
#include "DBCStores.h"
#include "GridDefines.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectMgr.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "Vehicle.h"
#include "WaypointMgr.h"
#include <algorithm>
#include <array>
#include <set>
#include <utility>
#include <vector>

namespace
{
constexpr std::array<uint32, 5> CaravanCartEntries = { 50470, 50473, 50474, 50475, 50476 };
constexpr uint32 SPELL_RUN_STATE = 992478;
constexpr uint32 SPELL_REINS = 43785;
constexpr uint32 NPC_CARAVAN_HARNESS = 9303000;
constexpr int8 DRIVER_SEAT = 1;

bool IsCaravanCart(CreatureData const& spawn)
{
    return std::find(CaravanCartEntries.begin(), CaravanCartEntries.end(), spawn.id) != CaravanCartEntries.end();
}

bool IsOnOpenWorldMap(CreatureData const& spawn)
{
    MapEntry const* mapEntry = sMapStore.LookupEntry(spawn.mapid);
    return mapEntry && !mapEntry->Instanceable() && Acore::IsValidMapCoord(spawn.posX, spawn.posY);
}

struct npc_coa_caravan_cart : public VehicleAI
{
    explicit npc_coa_caravan_cart(Creature* creature) : VehicleAI(creature) { }

    void PassengerBoarded(Unit*, int8, bool apply) override
    {
        if (apply)
            HarnessBeasts();
    }

    void WaypointReached(uint32 nodeId, uint32 pathId) override
    {
        if (StopsAt(nodeId, pathId))
            for (Creature* beast : Beasts())
                beast->RemoveAurasDueToSpell(SPELL_RUN_STATE);
    }

    void WaypointStarted(uint32, uint32) override
    {
        for (Creature* beast : Beasts())
            if (!beast->HasAura(SPELL_RUN_STATE))
                beast->AddAura(SPELL_RUN_STATE, beast);
    }

private:
    static bool StopsAt(uint32 nodeId, uint32 pathId)
    {
        WaypointPath const* path = sWaypointMgr->GetPath(pathId);
        if (!path)
            return false;
        auto node = std::find_if(path->Nodes.begin(), path->Nodes.end(),
            [nodeId](WaypointNode const& n) { return n.Id == nodeId; });
        return node != path->Nodes.end() && node->Delay > 0;
    }

    std::vector<Creature*> Beasts() const
    {
        std::vector<Creature*> beasts;
        Vehicle* kit = me->GetVehicleKit();
        if (!kit)
            return beasts;
        for (auto const& [seatId, seat] : kit->Seats)
        {
            if (seatId == DRIVER_SEAT)
                continue;
            if (Unit* passenger = kit->GetPassenger(seatId))
                if (Creature* beast = passenger->ToCreature())
                    if (beast->GetEntry() != NPC_CARAVAN_HARNESS)
                        beasts.push_back(beast);
        }
        return beasts;
    }

    void HarnessBeasts()
    {
        Vehicle* kit = me->GetVehicleKit();
        Unit* driver = kit ? kit->GetPassenger(DRIVER_SEAT) : nullptr;
        if (!driver || !driver->IsCreature())
            return;
        for (Creature* beast : Beasts())
            if (!beast->GetCurrentSpell(CURRENT_CHANNELED_SPELL))
                beast->CastSpell(driver, SPELL_REINS, true);
    }
};

class CaravanCartGrids : public WorldScript
{
public:
    CaravanCartGrids() : WorldScript("CoACaravanCartGrids", { WORLDHOOK_ON_BEFORE_WORLD_INITIALIZED }) { }

    void OnBeforeWorldInitialized() override
    {
        uint32 carts = 0;
        std::set<std::pair<uint32, uint32>> grids;
        for (auto const& [spawnId, spawn] : sObjectMgr->GetAllCreatureData())
        {
            if (!IsCaravanCart(spawn) || !IsOnOpenWorldMap(spawn))
                continue;

            ++carts;
            if (grids.emplace(spawn.mapid, Acore::ComputeGridCoord(spawn.posX, spawn.posY).GetId()).second)
                sMapMgr->CreateBaseMap(spawn.mapid)->LoadGrid(spawn.posX, spawn.posY);
        }

        LOG_INFO("server.loading", ">> Loaded {} grids for {} caravan cart spawns", grids.size(), carts);
    }
};
}

void AddSC_AscensionCaravanCarts()
{
    new CaravanCartGrids();
    RegisterCreatureAI(npc_coa_caravan_cart);
}
