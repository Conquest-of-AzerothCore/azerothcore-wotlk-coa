#ifndef COA_DUNGEON_HEALTH_H
#define COA_DUNGEON_HEALTH_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <map>
#include <tuple>

namespace DungeonHealth
{
    using Values = std::map<std::tuple<std::uint32_t, std::uint32_t, std::uint32_t>, std::uint32_t>;

    inline bool IsVanillaDungeon(std::uint32_t map)
    {
        switch (map)
        {
            case 33: case 34: case 36: case 43: case 47: case 48: case 70: case 90: case 109: case 129:
            case 189: case 209: case 229: case 230: case 289: case 329: case 349: case 389: case 429:
                return true;
            default:
                return false;
        }
    }

    inline std::uint32_t Scale(std::uint32_t health, double multiplier)
    {
        return static_cast<std::uint32_t>(std::clamp(std::round(health * multiplier),
            1.0, double(std::numeric_limits<std::uint32_t>::max())));
    }

    // Mythic relative to Heroic: 30 % more for bosses and trash alike. The live videos showed trash
    // about 2.5 % lower on Mythic than on Heroic, which is not kept on purpose (Mythic stays harder).
    inline double MythicFromHeroic(bool /*isBoss*/)
    {
        return 1.30;
    }

    inline std::uint32_t Resolve(Values const& values, std::uint32_t map, std::uint8_t difficulty,
        std::uint32_t entry, std::uint32_t currentHealth, std::uint32_t heroicHealth,
        bool hasDifficultyTemplate, bool isPet, bool isBoss = false)
    {
        if (isPet || !IsVanillaDungeon(map) || (difficulty != 1 && difficulty != 2))
            return currentHealth;
        if (auto const it = values.find({map, difficulty, entry}); it != values.end())
            return it->second;
        if (difficulty == 2)
            if (auto const it = values.find({map, 1, entry}); it != values.end())
                return Scale(it->second, MythicFromHeroic(isBoss));
        if (!hasDifficultyTemplate)
            return currentHealth;
        // Normal -> Heroic has no measurement yet; 2.33 stays the working assumption.
        return difficulty == 1 ? Scale(currentHealth, 2.33) : Scale(heroicHealth, 2.33 * MythicFromHeroic(isBoss));
    }
}

#endif
