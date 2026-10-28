/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_GAMEPLAY_ISOLATION_H
#define COA_GAMEPLAY_ISOLATION_H

#include "Define.h"
#include <cstddef>
#include <map>
#include <string>
#include <string_view>

namespace CoAGameplay
{
    inline constexpr uint32 MaxLanes = 15;
    inline constexpr uint32 FirstConcurrentLaneBit = 16;
    inline constexpr uint32 FixturePhaseMask = 1u << 30;

    uint32 LanePhase(uint32 lane);
    uint32 LanePhases(uint32 lanes);

    inline constexpr std::string_view GeneratedNamePrefix = "H";
    inline constexpr std::size_t GeneratedNameLength = 10;

    constexpr std::string_view GeneratedNameLetters(std::size_t position)
    {
        return position % 2 ? std::string_view("aeiou") : std::string_view("bcdfghjklmnpqrstvwxz");
    }

    constexpr uint64 GeneratedNameCombinations()
    {
        uint64 combinations = 1;
        for (std::size_t position = GeneratedNamePrefix.size(); position < GeneratedNameLength; ++position)
            combinations *= GeneratedNameLetters(position).size();
        return combinations;
    }

    inline constexpr uint64 GeneratedNameCapacity = GeneratedNameCombinations();

    std::string GeneratedName(uint64 index);

    class NameAllocator
    {
    public:
        std::string Next();

    private:
        uint64 _next = 0;
    };

    std::string SubstituteLegacyNames(std::string_view text, std::map<char, std::string> const& names);
}

#endif
