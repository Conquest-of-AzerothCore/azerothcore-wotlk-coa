/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_CREATURE_SCALING_POLICY_H
#define COA_CREATURE_SCALING_POLICY_H

#include <cstdint>
#include <limits>
#include <map>
#include <sstream>
#include <stdexcept>
#include <string>

namespace CreatureScaling
{
enum class Context
{
    None,
    World,
    Dungeon,
    Raid
};

struct Multipliers
{
    float world = 1.0f;
    float dungeon = 1.0f;
    float raid = 1.0f;
    std::map<std::uint32_t, float> maps;
};

struct Settings
{
    bool enabled = false;
    Multipliers health{ 2.5f, 2.5f, 2.2f, { { 36, 2.2f }, { 43, 2.0f }, { 229, 4.0f }, { 389, 3.0f }, { 469, 5.0f } } };
    Multipliers damage{ 2.0f, 1.5f, 1.0f, {} };
};

inline Context ContextOf(bool battlegroundOrArena, bool scriptedPrivateInstance, bool regularDifficulty, bool raid,
    bool dungeon)
{
    if (battlegroundOrArena || scriptedPrivateInstance || !regularDifficulty)
        return Context::None;
    if (raid)
        return Context::Raid;
    return dungeon ? Context::Dungeon : Context::World;
}

inline float Multiplier(Multipliers const& multipliers, Context context, std::uint32_t mapId)
{
    if (context == Context::None)
        return 1.0f;
    if (auto itr = multipliers.maps.find(mapId); itr != multipliers.maps.end())
        return itr->second;
    switch (context)
    {
        case Context::World:
            return multipliers.world;
        case Context::Dungeon:
            return multipliers.dungeon;
        default:
            return multipliers.raid;
    }
}

inline std::uint32_t Scaled(std::uint32_t value, float multiplier)
{
    if (multiplier <= 0.0f || value == 0)
        return value;
    double const scaled = double(value) * multiplier + 0.5;
    if (scaled >= double(std::numeric_limits<std::uint32_t>::max()))
        return std::numeric_limits<std::uint32_t>::max();
    return scaled < 1.0 ? 1 : std::uint32_t(scaled);
}

inline std::string FormatMapMultipliers(std::map<std::uint32_t, float> const& maps)
{
    std::ostringstream stream;
    for (auto const& [mapId, value] : maps)
        stream << (stream.tellp() > 0 ? " " : "") << mapId << ':' << value;
    return stream.str();
}

inline std::map<std::uint32_t, float> ParseMapMultipliers(std::string const& text)
{
    std::map<std::uint32_t, float> result;
    std::istringstream stream(text);
    std::string token;
    while (stream >> token)
    {
        std::size_t const separator = token.find(':');
        if (separator == std::string::npos || separator == 0 || separator + 1 == token.size())
            continue;
        try
        {
            std::size_t mapEnd = 0;
            std::size_t valueEnd = 0;
            unsigned long const mapId = std::stoul(token.substr(0, separator), &mapEnd);
            float const value = std::stof(token.substr(separator + 1), &valueEnd);
            if (mapEnd != separator || valueEnd != token.size() - separator - 1 || value <= 0.0f
                || mapId > std::numeric_limits<std::uint32_t>::max())
                continue;
            result[std::uint32_t(mapId)] = value;
        }
        catch (std::exception const&)
        {
        }
    }
    return result;
}
}

#endif
