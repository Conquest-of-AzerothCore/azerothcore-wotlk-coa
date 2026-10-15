#ifndef COA_ASCENSION_RAID_RELEASE_POLICY_H
#define COA_ASCENSION_RAID_RELEASE_POLICY_H

#include <array>
#include <cstdint>

namespace RaidRelease
{
constexpr std::uint32_t MapZulGurub = 309;
constexpr std::uint32_t MapMoltenCore = 409;
constexpr std::uint32_t MapOnyxiasLair = 249;
constexpr std::uint32_t MapBlackwingLair = 469;
constexpr std::uint32_t MapRuinsOfAhnQiraj = 509;
constexpr std::uint32_t MapTempleOfAhnQiraj = 531;
constexpr std::uint32_t MapNaxxramas = 533;

constexpr std::uint32_t AllRaidsReleased = 7;

struct RaidStage
{
    std::uint32_t mapId;
    std::uint32_t stage;
};

constexpr std::array<RaidStage, 7> RaidStages = {{
    { MapZulGurub, 1 },
    { MapMoltenCore, 2 },
    { MapOnyxiasLair, 3 },
    { MapBlackwingLair, 4 },
    { MapRuinsOfAhnQiraj, 5 },
    { MapTempleOfAhnQiraj, 6 },
    { MapNaxxramas, 7 }
}};

constexpr bool IsRaidReleased(std::uint32_t mapId, std::uint32_t releasedStage)
{
    for (RaidStage const& raid : RaidStages)
        if (raid.mapId == mapId)
            return raid.stage <= releasedStage;
    return true;
}
}

#endif
