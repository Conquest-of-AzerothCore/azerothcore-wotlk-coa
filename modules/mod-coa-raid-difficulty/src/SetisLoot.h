#ifndef MOD_COA_RAID_DIFFICULTY_SETIS_LOOT_H
#define MOD_COA_RAID_DIFFICULTY_SETIS_LOOT_H

#include <algorithm>
#include <cstdint>

namespace coa_setis
{
    constexpr std::uint32_t MinItems = 1;

    // One item for every four players in his map, rounded down, and never none.
    constexpr std::uint32_t LootItems(std::uint32_t players)
    {
        return std::max<std::uint32_t>(players / 4, MinItems);
    }
}

#endif
