/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_VOID_PORTAL_CYCLE_H
#define ASCENSION_VOID_PORTAL_CYCLE_H

#include <cstdint>
#include <optional>
#include <random>
#include <utility>
#include <vector>

namespace Ascension::VoidPortal
{
constexpr std::int64_t PointLifetimeMs = 300'000;
constexpr std::int64_t GroupLifetimeMs = 3'600'000;
constexpr std::uint32_t ProximityChancePercent = 50;

struct Point
{
    std::uint32_t spawnId;
    std::uint16_t mapId;
    float x;
    float y;
    float z;
    float orientation;
};

struct SpawnGroup
{
    std::uint32_t groupId;
    std::vector<Point> points;
};

class Schedule
{
public:
    void StartPoint(std::int64_t nowMs) { _pointExpiryMs = nowMs + PointLifetimeMs; }
    void StartGroup(std::int64_t nowMs) { _groupExpiryMs = nowMs + GroupLifetimeMs; }

    [[nodiscard]] std::int64_t PointExpiry() const { return _pointExpiryMs; }
    [[nodiscard]] std::int64_t GroupExpiry() const { return _groupExpiryMs; }

private:
    std::int64_t _pointExpiryMs{0};
    std::int64_t _groupExpiryMs{0};
};

class Selection
{
public:
    explicit Selection(std::vector<SpawnGroup> groups) : _groups(std::move(groups)) { }

    [[nodiscard]] bool Empty() const { return _groups.empty(); }
    [[nodiscard]] std::vector<SpawnGroup> const& Groups() const { return _groups; }

    [[nodiscard]] std::optional<std::uint32_t> ChooseGroup(std::uint32_t previousGroupId,
        std::mt19937& rng) const
    {
        if (_groups.empty())
            return std::nullopt;

        std::vector<std::size_t> candidates;
        candidates.reserve(_groups.size());
        for (std::size_t index = 0; index < _groups.size(); ++index)
            if (_groups.size() == 1 || _groups[index].groupId != previousGroupId)
                candidates.push_back(index);

        std::uniform_int_distribution<std::size_t> distribution(0, candidates.size() - 1);
        return _groups[candidates[distribution(rng)]].groupId;
    }

    [[nodiscard]] std::optional<Point> ChoosePoint(SpawnGroup const& group,
        std::uint32_t currentSpawnId, std::mt19937& rng) const
    {
        if (group.points.empty())
            return std::nullopt;

        std::vector<std::size_t> candidates;
        candidates.reserve(group.points.size());
        for (std::size_t index = 0; index < group.points.size(); ++index)
            if (group.points.size() == 1 || group.points[index].spawnId != currentSpawnId)
                candidates.push_back(index);

        std::uniform_int_distribution<std::size_t> distribution(0, candidates.size() - 1);
        return group.points[candidates[distribution(rng)]];
    }

    [[nodiscard]] static bool ProximityRollSucceeds(std::uint32_t roll)
    {
        return roll >= 1 && roll <= ProximityChancePercent;
    }

private:
    std::vector<SpawnGroup> _groups;
};
}

#endif
