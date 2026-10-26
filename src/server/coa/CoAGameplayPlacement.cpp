/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAGameplayPlacement.h"
#include "ClientDBC.h"
#include "CreatureData.h"
#include "SharedDefines.h"
#include "UnitDefines.h"
#include <cmath>

namespace CoAGameplay
{
    std::optional<float> GroundGap(PlacementSample const& sample)
    {
        if (sample.floorZ)
            return sample.z - *sample.floorZ;
        if (sample.terrainZ)
            return sample.z - *sample.terrainZ;
        return std::nullopt;
    }

    PlacementVerdict ClassifyPlacement(PlacementSample const& sample, float tolerance)
    {
        if (!sample.terrainAvailable)
            return PlacementVerdict::Unchecked;

        std::optional<float> const gap = GroundGap(sample);
        if (!gap)
            return sample.liquidLevel ? PlacementVerdict::Unchecked : PlacementVerdict::UnderGround;

        if (*gap < -tolerance)
            return PlacementVerdict::UnderGround;

        if (*gap > tolerance)
        {
            bool const onLiquidSurface = sample.liquidLevel && std::fabs(sample.z - *sample.liquidLevel) <= tolerance;
            bool const swimming = sample.maySwim && sample.liquidLevel && sample.z <= *sample.liquidLevel + tolerance;
            if (sample.mayFloat || onLiquidSurface || swimming)
                return PlacementVerdict::Exempt;
            return PlacementVerdict::Floating;
        }

        return PlacementVerdict::Grounded;
    }

    bool IsSubmerged(PlacementSample const& sample)
    {
        return sample.liquidLevel && sample.z < *sample.liquidLevel;
    }

    DisplayState ClassifyDisplay(bool inServerStore, bool inClientDbc)
    {
        if (inClientDbc)
            return DisplayState::Client;
        if (inServerStore)
            return DisplayState::ServerOnly;
        return DisplayState::Missing;
    }

    bool CreatureMayFloat(CreatureMovementData const& movement, uint32 flagsExtra, uint8 animTier)
    {
        return movement.IsFlightAllowed() || movement.Ground == CreatureGroundMovementType::Hover
            || (flagsExtra & CREATURE_FLAG_EXTRA_TRIGGER) || (animTier & UNIT_BYTE1_FLAG_HOVER);
    }

    bool GameObjectMayFloat(uint32 type, uint32 displayId)
    {
        return displayId == 0 || type == GAMEOBJECT_TYPE_TRANSPORT || type == GAMEOBJECT_TYPE_MO_TRANSPORT;
    }

    std::string_view PlacementVerdictName(PlacementVerdict verdict)
    {
        switch (verdict)
        {
            case PlacementVerdict::Grounded:
                return "grounded";
            case PlacementVerdict::Floating:
                return "floating";
            case PlacementVerdict::UnderGround:
                return "under_ground";
            case PlacementVerdict::Exempt:
                return "exempt";
            case PlacementVerdict::Unchecked:
                return "unchecked";
        }
        return "unchecked";
    }

    std::string_view DisplayStateName(DisplayState state)
    {
        switch (state)
        {
            case DisplayState::Missing:
                return "missing";
            case DisplayState::ServerOnly:
                return "server_only";
            case DisplayState::Client:
                return "client";
        }
        return "missing";
    }

    std::optional<std::unordered_set<uint32>> ReadClientDbcIds(std::string const& path)
    {
        ClientDBC dbc;
        if (!dbc.Load(path, 1))
            return std::nullopt;

        std::unordered_set<uint32> ids;
        ids.reserve(dbc.GetRecordCount());
        for (uint32 row = 0; row < dbc.GetRecordCount(); ++row)
            ids.insert(dbc.GetRecord(row).GetUInt32(0));
        return ids;
    }

    std::optional<uint32> PositiveGameEventId(std::size_t eventCount, std::size_t spawnListIndex)
    {
        if (spawnListIndex < eventCount)
            return std::nullopt;
        return uint32(spawnListIndex - eventCount + 1);
    }
}
