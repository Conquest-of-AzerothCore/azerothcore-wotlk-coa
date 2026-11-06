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

constexpr std::uint32_t StageHeroicDungeons = 1;
constexpr std::uint32_t StageMythicDungeons = 2;
constexpr std::uint32_t StageZulGurub = 3;
constexpr std::uint32_t StageMoltenCore = 4;
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
    { MapZulGurub, StageZulGurub },
    { MapMoltenCore, StageMoltenCore },
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

constexpr std::array<RaidStage, 7> RaidLootStages = {{
    { MapZulGurub, StageZulGurub },
    { MapMoltenCore, StageMoltenCore },
    { MapOnyxiasLair, StageOnyxiasLair },
    { MapBlackwingLair, StageBlackwingLair },
    { MapRuinsOfAhnQiraj, StageAhnQiraj },
    { MapTempleOfAhnQiraj, StageAhnQiraj },
    { MapNaxxramas, StageNaxxramas }
}};

constexpr std::uint32_t RaidLootStage(std::uint32_t mapId)
{
    for (RaidStage const& raid : RaidLootStages)
        if (raid.mapId == mapId)
            return raid.stage;
    return 0;
}

constexpr std::uint32_t DefeatedNever = 0;
constexpr std::uint32_t DefeatedNormal = 1;
constexpr std::uint32_t DefeatedHeroic = 2;

struct FinalBoss
{
    std::uint32_t creatureEntry;
    std::uint32_t mapId;
    std::uint32_t opensStage;
    std::uint32_t worldState;
};

constexpr std::array<FinalBoss, 7> FinalBosses = {{
    { 14834, MapZulGurub, StageMoltenCore, 20121 },
    { 11502, MapMoltenCore, StageOnyxiasLair, 20122 },
    { 10184, MapOnyxiasLair, StageBlackwingLair, 20123 },
    { 11583, MapBlackwingLair, StageAhnQiraj, 20124 },
    { 15339, MapRuinsOfAhnQiraj, 0, 20125 },
    { 15727, MapTempleOfAhnQiraj, StageNaxxramas, 20126 },
    { 15990, MapNaxxramas, 0, 20127 }
}};

constexpr FinalBoss const* FindFinalBoss(std::uint32_t creatureEntry)
{
    for (FinalBoss const& boss : FinalBosses)
        if (boss.creatureEntry == creatureEntry)
            return &boss;
    return nullptr;
}

constexpr FinalBoss const* FinalBossOfMap(std::uint32_t mapId)
{
    for (FinalBoss const& boss : FinalBosses)
        if (boss.mapId == mapId)
            return &boss;
    return nullptr;
}

constexpr std::uint32_t DefeatLevel(std::uint32_t spawnMode)
{
    return spawnMode ? DefeatedHeroic : DefeatedNormal;
}

constexpr bool IsBloodforgedReleased(std::uint32_t defeatLevel, bool heroicCopy)
{
    return defeatLevel >= (heroicCopy ? DefeatedHeroic : DefeatedNormal);
}

constexpr std::uint32_t EffectiveStage(std::uint32_t configuredStage, std::uint32_t unlockedStage)
{
    return unlockedStage > configuredStage ? unlockedStage : configuredStage;
}

[[nodiscard]] std::uint32_t ReleasedStage();
[[nodiscard]] std::uint32_t RaidDefeatLevel(std::uint32_t mapId);
[[nodiscard]] std::uint32_t DefeatVersion();
}

#endif
