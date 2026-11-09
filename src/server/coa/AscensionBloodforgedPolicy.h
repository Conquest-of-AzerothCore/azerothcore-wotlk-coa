#ifndef COA_ASCENSION_BLOODFORGED_POLICY_H
#define COA_ASCENSION_BLOODFORGED_POLICY_H

#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace Bloodforged
{
using Rates = std::array<unsigned, 3>;
constexpr std::array<Rates, 5> DefaultRates = {{{0, 50, 0}, {0, 100, 0},
    {0, 140, 15}, {0, 180, 25}, {0, 220, 100}}};

constexpr unsigned DefaultEliteEpicPercent = 15;
constexpr float DefaultEliteHeroicUpgradePercent = 2.5f;

constexpr unsigned DefaultHighRiskReleaseStage = 3;
constexpr unsigned MinimumBlueMaxItemLevel = 57;
constexpr std::array<unsigned, 9> DefaultBlueMaxItemLevelByStage = {57, 57, 57, 57, 57, 57, 57, 57, 57};

constexpr unsigned RaisedBlueCap(unsigned itemLevel)
{
    return itemLevel < MinimumBlueMaxItemLevel ? MinimumBlueMaxItemLevel : itemLevel;
}
constexpr std::array<unsigned, 9> DefaultEpicMaxItemLevelByStage = {61, 61, 64, 65, 70, 70, 70, 70, 70};

constexpr std::array<std::uint32_t, 8> EndgameZones = {28, 139, 46, 4, 16, 618, 490, 1377};

constexpr bool IsEndgameZone(std::uint32_t zoneId)
{
    for (std::uint32_t zone : EndgameZones)
        if (zone == zoneId)
            return true;
    return false;
}

struct RareDrop
{
    unsigned raidPercent;
    unsigned heroicRaidPercent;
    unsigned respawnMinMinutes;
    unsigned respawnMaxMinutes;
};

constexpr RareDrop DefaultRare = {15, 5, 90, 150};
constexpr RareDrop DefaultRareElite = {25, 10, 150, 210};
constexpr unsigned DefaultEndgameRespawnMinLevel = 45;
constexpr std::array<unsigned, 2> DefaultEndgameEliteHighRiskRespawnMinutes = {10, 15};
constexpr std::array<unsigned, 2> DefaultHighRiskEliteRespawnMinutes = {45, 60};
constexpr char const* DefaultHighRiskEliteEntries = "918530 918547 918550 918555 918562 918563 918578 918588 918589 "
    "918590 918591 918647 918648 918690 919448 919450";
constexpr unsigned DefaultEndgameRareMinRequiredLevel = 60;
constexpr std::array<std::uint32_t, 3> HiddenCacheLoot = {9670, 9671, 9672};
constexpr std::uint32_t EphemeralKey = 967680;
constexpr std::array<std::uint32_t, 3> EphemeralKeys = {967680, 967681, 967682};
constexpr std::uint32_t SilverMarkOfWar = 1201002;
constexpr std::uint32_t GoldenMarkOfWar = 1201003;

struct MarkDrop
{
    unsigned silver;
    float extraSilverPercent;
    unsigned gold;
    float extraGoldPercent;
};

constexpr float ScaledPercent(float percent, float rate)
{
    return percent * rate > 100.0f ? 100.0f : percent * rate;
}

constexpr bool ValidMarkDrop(MarkDrop const& marks)
{
    return marks.silver <= 100 && marks.gold <= 100 && marks.extraSilverPercent >= 0.0f
        && marks.extraSilverPercent <= 100.0f && marks.extraGoldPercent >= 0.0f && marks.extraGoldPercent <= 100.0f;
}

constexpr MarkDrop NormalMobMarks = {0, 5.0f, 0, 0.5f};
constexpr MarkDrop EliteMobMarks = {0, 8.0f, 0, 0.5f};
constexpr MarkDrop RareMobMarks = {1, 10.0f, 0, 10.0f};
constexpr MarkDrop RareEliteMobMarks = {2, 10.0f, 0, 50.0f};
constexpr std::array<MarkDrop, 3> HiddenCacheMarks = {{{1, 10.0f, 0, 0.0f}, {1, 60.0f, 0, 20.0f}, {2, 50.0f, 1, 20.0f}}};
constexpr std::array<std::uint32_t, 3> DefaultMobBazaarTokens = {300, 300, 300};
constexpr std::array<std::uint32_t, 3> DefaultHiddenCacheBazaarTokens = {40, 100, 150};
constexpr std::array<float, 4> DefaultEphemeralKeyPercent = {8.0f, 50.0f, 100.0f, 100.0f};
constexpr float DefaultHighRiskEliteExtraKeyPercent = 10.0f;
constexpr unsigned DefaultExtraBluePercent = 50;
constexpr unsigned DefaultExtraBlueRaidItemPercent = 50;

struct HiddenCacheChances
{
    unsigned first;
    unsigned second;
};

constexpr HiddenCacheChances DefaultRareHiddenCache = {15, 5};
constexpr HiddenCacheChances DefaultEpicHiddenCache = {5, 15};

constexpr bool WithinItemLevelCap(unsigned quality, unsigned itemLevel, unsigned blueCap, unsigned epicCap)
{
    return quality == 3 ? itemLevel <= blueCap : quality == 4 ? itemLevel <= epicCap : true;
}

constexpr bool AllowedInZone(unsigned requiredLevel, bool endgameZone, bool level60EndgameOnly)
{
    return endgameZone || !level60EndgameOnly || requiredLevel < 60;
}

constexpr unsigned Band(unsigned level)
{
    return level < 25 ? 0 : level < 35 ? 1 : level < 45 ? 2 : level < 55 ? 3 : 4;
}

constexpr bool ValidRates(Rates const& rates)
{
    return rates[0] <= 10000 && (!rates[0] || rates[1] < rates[0]) && rates[2] < rates[1]
        && rates[0] + rates[1] + rates[2] <= 10000;
}

constexpr float EntryChance(unsigned rate, std::size_t poolSize)
{
    return poolSize ? static_cast<float>(rate) / 100.0f / static_cast<float>(poolSize) : 0.0f;
}

constexpr bool EligibleItem(unsigned requiredLevel, unsigned itemLevel, unsigned targetLevel)
{
    return targetLevel >= 15 && targetLevel <= 60
        && requiredLevel <= targetLevel && requiredLevel <= 60
        && itemLevel > 0 && itemLevel <= (targetLevel == 60 ? 92 : targetLevel + 10);
}

constexpr bool InGearTier(unsigned itemLevel, unsigned targetLevel, unsigned highestAvailable)
{
    return itemLevel + 20 >= std::min(targetLevel, highestAvailable);
}
}

#endif
