#ifndef COA_ASCENSION_ADVENTURER_CACHE_POLICY_H
#define COA_ASCENSION_ADVENTURER_CACHE_POLICY_H

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace AdventurerCache
{
constexpr std::uint32_t GreenQuality = 2;
constexpr std::uint32_t BlueQuality = 3;
constexpr std::uint32_t GearLevelWindow = 5;

struct Gear
{
    std::uint32_t quality = 0;
    std::uint32_t requiredLevel = 0;
    std::uint32_t bodyArmorClass = 0;
};

inline bool InGearLevelWindow(std::uint32_t requiredLevel, std::uint32_t playerLevel)
{
    return requiredLevel <= playerLevel && requiredLevel + GearLevelWindow >= playerLevel;
}

inline std::uint32_t SupplyCount(std::uint32_t cacheQuality)
{
    return cacheQuality >= BlueQuality ? 2 : 1;
}

inline std::vector<std::size_t> GearChoices(std::vector<Gear> const& gear, std::uint32_t playerLevel,
    std::uint32_t cacheQuality)
{
    for (std::uint32_t quality = std::min(cacheQuality, BlueQuality); quality >= GreenQuality; --quality)
    {
        std::vector<std::size_t> choices;
        std::uint32_t bestBodyArmor = 0;
        for (std::size_t index = 0; index < gear.size(); ++index)
            if (gear[index].quality == quality && InGearLevelWindow(gear[index].requiredLevel, playerLevel))
            {
                choices.push_back(index);
                bestBodyArmor = std::max(bestBodyArmor, gear[index].bodyArmorClass);
            }

        if (choices.empty())
            continue;

        std::erase_if(choices, [&gear, bestBodyArmor](std::size_t index)
        {
            return gear[index].bodyArmorClass && gear[index].bodyArmorClass < bestBodyArmor;
        });
        return choices;
    }
    return {};
}
}

#endif
