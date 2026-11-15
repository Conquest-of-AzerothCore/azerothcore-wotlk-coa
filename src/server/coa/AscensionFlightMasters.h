/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_FLIGHT_MASTERS_H
#define ASCENSION_FLIGHT_MASTERS_H

#include "CreatureData.h"
#include "DBCStores.h"
#include "ObjectMgr.h"
#include "SharedDefines.h"
#include "UnitDefines.h"
#include <algorithm>
#include <array>
#include <unordered_map>
#include <utility>
#include <vector>

namespace AscensionFlightMasters
{
constexpr float Reach = 40.0f;

inline bool InMask(TaxiMask const& mask, uint32 node)
{
    return mask[(node - 1) / 32] & (1 << ((node - 1) % 32));
}

struct ServedNodes
{
    std::array<std::vector<uint32>, 2> nodes;
    std::unordered_map<uint32, uint32> masterEntries;
};

inline ServedNodes const& Served()
{
    static ServedNodes const served = []
    {
        std::vector<CreatureData const*> masters;
        for (auto const& [spawnId, data] : sObjectMgr->GetAllCreatureData())
        {
            CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(data.id);
            if (creature && ((creature->npcflag | data.npcflag) & UNIT_NPC_FLAG_FLIGHTMASTER))
                masters.push_back(&data);
        }

        ServedNodes result;
        for (uint32 node = 1; node < sTaxiNodesStore.GetNumRows(); ++node)
        {
            TaxiNodesEntry const* entry = sTaxiNodesStore.LookupEntry(node);
            if (!entry || !sTaxiPathSetBySource.count(node))
                continue;

            CreatureData const* closest = nullptr;
            float closestDist = Reach * Reach;
            for (CreatureData const* master : masters)
            {
                float dx = master->posX - entry->x, dy = master->posY - entry->y, dz = master->posZ - entry->z;
                float dist = dx * dx + dy * dy + dz * dz;
                if (master->mapid == entry->map_id && dist <= closestDist)
                {
                    closest = master;
                    closestDist = dist;
                }
            }
            if (!closest)
                continue;

            result.masterEntries[node] = closest->id;
            if (InMask(sAllianceTaxiNodesMask, node))
                result.nodes[TEAM_ALLIANCE].push_back(node);
            if (InMask(sHordeTaxiNodesMask, node))
                result.nodes[TEAM_HORDE].push_back(node);
        }
        return result;
    }();
    return served;
}

inline std::vector<uint32> const& Nodes(TeamId team)
{
    return Served().nodes[team == TEAM_HORDE ? TEAM_HORDE : TEAM_ALLIANCE];
}

inline uint32 MasterEntry(uint32 node)
{
    auto const itr = Served().masterEntries.find(node);
    return itr != Served().masterEntries.end() ? itr->second : 0;
}

inline std::vector<uint32> NearestNodes(float x, float y, float z, uint32 mapid, TeamId team, std::size_t count)
{
    std::vector<std::pair<float, uint32>> candidates;
    for (uint32 node : Nodes(team))
    {
        TaxiNodesEntry const* entry = sTaxiNodesStore.LookupEntry(node);
        if (!entry || entry->map_id != mapid)
            continue;

        float dist = (entry->x - x) * (entry->x - x) + (entry->y - y) * (entry->y - y) + (entry->z - z) * (entry->z - z);
        candidates.emplace_back(dist, node);
    }

    std::size_t const kept = std::min(count, candidates.size());
    std::partial_sort(candidates.begin(), candidates.begin() + kept, candidates.end());
    std::vector<uint32> nearest;
    for (std::size_t i = 0; i < kept; ++i)
        nearest.push_back(candidates[i].second);
    return nearest;
}
}

#endif
