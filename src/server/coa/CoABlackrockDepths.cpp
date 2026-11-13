/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AllGameObjectScript.h"
#include "Creature.h"
#include "GameObject.h"
#include "GameTime.h"
#include "Map.h"
#include "UnitScript.h"

namespace
{
    constexpr uint32 MapBlackrockDepths = 230;
    constexpr uint32 NpcLordIncendius = 9017;
    constexpr uint32 GoGiantDoors = 157923;
    constexpr ObjectGuid::LowType IncendiusSpawn = 47733;

    bool IncendiusDead(Map const* map)
    {
        return map->GetCreatureRespawnTime(IncendiusSpawn) > GameTime::GetGameTime().count();
    }

    void SetGiantDoors(Map* map, GOState state)
    {
        for (auto const& [spawnId, door] : map->GetGameObjectBySpawnIdStore())
            if (door->GetEntry() == GoGiantDoors)
                door->SetGoState(state);
    }
}

class CoABrdGiantDoors final : public AllGameObjectScript
{
public:
    CoABrdGiantDoors() : AllGameObjectScript("CoABrdGiantDoors") { }

    void OnGameObjectAddWorld(GameObject* go) override
    {
        if (go->GetEntry() != GoGiantDoors || go->GetMapId() != MapBlackrockDepths)
            return;
        go->SetGoState(IncendiusDead(go->GetMap()) ? GO_STATE_ACTIVE : GO_STATE_READY);
    }
};

class CoABrdIncendiusOpensGiantDoors final : public UnitScript
{
public:
    CoABrdIncendiusOpensGiantDoors() : UnitScript("CoABrdIncendiusOpensGiantDoors", true, { UNITHOOK_ON_UNIT_DEATH }) { }

    void OnUnitDeath(Unit* unit, Unit*) override
    {
        Creature* creature = unit->ToCreature();
        if (!creature || creature->GetEntry() != NpcLordIncendius || creature->GetMapId() != MapBlackrockDepths)
            return;
        SetGiantDoors(creature->GetMap(), GO_STATE_ACTIVE);
    }
};

void AddSC_CoABlackrockDepths()
{
    new CoABrdGiantDoors();
    new CoABrdIncendiusOpensGiantDoors();
}
