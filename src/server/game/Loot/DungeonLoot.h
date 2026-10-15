/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_DUNGEON_LOOT_H
#define COA_DUNGEON_LOOT_H

#include <array>
#include <cstdint>
#include <unordered_map>

namespace DungeonLoot
{
    using Variants = std::unordered_map<std::uint32_t, std::array<std::uint32_t, 2>>;

    inline std::uint8_t Difficulty(std::uint32_t map, std::uint8_t difficulty, bool worldLoot)
    {
        if (!worldLoot || difficulty < 1 || difficulty > 2)
            return 0;

        switch (map)
        {
            case 33: case 34: case 36: case 43: case 47: case 48: case 70: case 90: case 109:
            case 129: case 189: case 209: case 229: case 230: case 289: case 329: case 349: case 389: case 429:
                return difficulty;
            default:
                return 0;
        }
    }

    inline std::uint32_t Resolve(Variants const& variants, std::uint32_t item,
        std::uint8_t difficulty, bool questRequired)
    {
        if (questRequired || difficulty < 1 || difficulty > 2)
            return item;

        auto const found = variants.find(item);
        if (found == variants.end())
            return item;

        std::uint32_t const target = found->second[difficulty - 1];
        return target ? target : item;
    }
}

#endif
