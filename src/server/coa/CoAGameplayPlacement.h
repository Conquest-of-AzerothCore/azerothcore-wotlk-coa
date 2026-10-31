/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_GAMEPLAY_PLACEMENT_H
#define COA_GAMEPLAY_PLACEMENT_H

#include "Define.h"
#include <cstddef>
#include <functional>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_set>
#include <vector>

struct CreatureMovementData;

namespace CoAGameplay
{
    enum class PlacementVerdict : uint8
    {
        Grounded = 0,
        Floating = 1,
        UnderGround = 2,
        Exempt = 3,
        Unchecked = 4
    };

    enum class DisplayState : uint8
    {
        Missing = 0,
        ServerOnly = 1,
        Client = 2
    };

    inline constexpr float DefaultPlacementTolerance = 0.8f;
    inline constexpr float ClearanceReach = 10.0f;

    struct ClearanceRay
    {
        float originHeight{0.0f};
        float dx{0.0f};
        float dy{0.0f};
        float dz{0.0f};
    };

    struct PlacementSample
    {
        float z{0.0f};
        std::optional<float> floorZ;
        std::optional<float> terrainZ;
        std::optional<float> liquidLevel;
        bool terrainAvailable{true};
        bool mayFloat{false};
        bool maySwim{false};
    };

    std::optional<float> GroundGap(PlacementSample const& sample);
    PlacementVerdict ClassifyPlacement(PlacementSample const& sample, float tolerance);
    bool IsSubmerged(PlacementSample const& sample);
    std::vector<ClearanceRay> const& LevelRays();
    std::vector<ClearanceRay> const& HeadroomRays();
    float NearestHit(std::vector<ClearanceRay> const& rays,
        std::function<std::optional<float>(ClearanceRay const&)> const& hitDistance);
    DisplayState ClassifyDisplay(bool inServerStore, bool inClientDbc);
    bool CreatureMayFloat(CreatureMovementData const& movement, uint32 flagsExtra, uint8 animTier);
    bool GameObjectMayFloat(uint32 type, uint32 displayId);
    std::string_view PlacementVerdictName(PlacementVerdict verdict);
    std::string_view DisplayStateName(DisplayState state);
    std::optional<std::unordered_set<uint32>> ReadClientDbcIds(std::string const& path);
    std::optional<uint32> PositiveGameEventId(std::size_t eventCount, std::size_t spawnListIndex);
}

#endif
