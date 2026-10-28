/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_FLIGHT_MASTERS_H
#define ASCENSION_FLIGHT_MASTERS_H

#include "CreatureData.h"
#include "DBCStores.h"
#include "ObjectMgr.h"
#include "SharedDefines.h"
#include "UnitDefines.h"
#include <array>
#include <vector>

namespace AscensionFlightMasters
{
constexpr float Reach = 40.0f;

inline bool InMask(TaxiMask const& mask, uint32 node)
{
    return mask[(node - 1) / 32] & (1 << ((node - 1) % 32));
}

inline std::vector<uint32> const& Nodes(TeamId team)
{
    static std::array<std::vector<uint32>, 2> const nodes = []
    {
        std::vector<CreatureData const*> masters;
        for (auto const& [spawnId, data] : sObjectMgr->GetAllCreatureData())
        {
            CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(data.id);
            if (creature && ((creature->npcflag | data.npcflag) & UNIT_NPC_FLAG_FLIGHTMASTER))
                masters.push_back(&data);
        }

        std::array<std::vector<uint32>, 2> result;
        for (uint32 node = 1; node < sTaxiNodesStore.GetNumRows(); ++node)
        {
            TaxiNodesEntry const* entry = sTaxiNodesStore.LookupEntry(node);
            if (!entry || !sTaxiPathSetBySource.count(node))
                continue;

            bool served = false;
            for (CreatureData const* master : masters)
            {
                float dx = master->posX - entry->x, dy = master->posY - entry->y, dz = master->posZ - entry->z;
                if (master->mapid == entry->map_id && dx * dx + dy * dy + dz * dz <= Reach * Reach)
                {
                    served = true;
                    break;
                }
            }
            if (!served)
                continue;

            if (InMask(sAllianceTaxiNodesMask, node))
                result[TEAM_ALLIANCE].push_back(node);
            if (InMask(sHordeTaxiNodesMask, node))
                result[TEAM_HORDE].push_back(node);
        }
        return result;
    }();
    return nodes[team == TEAM_HORDE ? TEAM_HORDE : TEAM_ALLIANCE];
}

inline uint32 NearestNode(float x, float y, float z, uint32 mapid, TeamId team)
{
    uint32 id = 0;
    float best = 0.0f;
    for (uint32 node : Nodes(team))
    {
        TaxiNodesEntry const* entry = sTaxiNodesStore.LookupEntry(node);
        if (!entry || entry->map_id != mapid)
            continue;

        float dist = (entry->x - x) * (entry->x - x) + (entry->y - y) * (entry->y - y) + (entry->z - z) * (entry->z - z);
        if (!id || dist < best)
        {
            id = node;
            best = dist;
        }
    }
    return id;
}
}

#endif
