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

constexpr std::uint32_t StageHeroicDungeons = 1;
constexpr std::uint32_t StageMythicDungeons = 2;
constexpr std::uint32_t StageMoltenCore = 3;
constexpr std::uint32_t StageZulGurub = 4;
constexpr std::uint32_t StageOnyxiasLair = 5;
constexpr std::uint32_t StageBlackwingLair = 6;
constexpr std::uint32_t StageAhnQiraj = 7;
constexpr std::uint32_t StageNaxxramas = 8;
constexpr std::uint32_t AllReleased = StageNaxxramas;

constexpr std::uint32_t DungeonDifficultyHeroic = 1;
constexpr std::uint32_t DungeonDifficultyMythic = 2;

struct RaidStage
{
    std::uint32_t mapId;
    std::uint32_t stage;
};

constexpr std::array<RaidStage, 6> RaidStages = {{
    { MapMoltenCore, StageMoltenCore },
    { MapZulGurub, StageZulGurub },
    { MapOnyxiasLair, StageOnyxiasLair },
    { MapBlackwingLair, StageBlackwingLair },
    { MapRuinsOfAhnQiraj, StageAhnQiraj },
    { MapTempleOfAhnQiraj, StageAhnQiraj }
}};

constexpr bool IsRaidReleased(std::uint32_t mapId, std::uint32_t releasedStage)
{
    for (RaidStage const& raid : RaidStages)
        if (raid.mapId == mapId)
            return raid.stage <= releasedStage;
    return true;
}

constexpr bool IsDungeonDifficultyReleased(std::uint32_t difficulty, std::uint32_t releasedStage)
{
    if (difficulty == DungeonDifficultyHeroic)
        return StageHeroicDungeons <= releasedStage;
    if (difficulty >= DungeonDifficultyMythic)
        return StageMythicDungeons <= releasedStage;
    return true;
}

[[nodiscard]] std::uint32_t ReleasedStage();
}

#endif
