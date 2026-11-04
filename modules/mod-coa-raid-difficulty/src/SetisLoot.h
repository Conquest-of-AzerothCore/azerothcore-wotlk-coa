#ifndef MOD_COA_RAID_DIFFICULTY_SETIS_LOOT_H
#define MOD_COA_RAID_DIFFICULTY_SETIS_LOOT_H

#include <algorithm>
#include <cstdint>

namespace coa_setis
{
    constexpr std::uint32_t MinItems = 2;
    constexpr std::uint32_t MaxItems = 8;

    // Two items for every ten players in his map, to the nearest: 2 for 10, 5 for 25, 8 for 40 and more.
    constexpr std::uint32_t LootItems(std::uint32_t players)
    {
        return std::clamp<std::uint32_t>((players + 2) / 5, MinItems, MaxItems);
    }
}

#endif
