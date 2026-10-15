#ifndef COA_ASCENSION_HIGHRISK_POLICY_H
#define COA_ASCENSION_HIGHRISK_POLICY_H

#include <cstdint>

namespace HighRisk
{
constexpr unsigned MinimumLevel = 15;
constexpr unsigned MaximumLevel = 60;
constexpr unsigned ChestEntry = 994300;
constexpr unsigned HighRiskAura = 1004019;

constexpr bool Eligible(unsigned level, bool highRisk, bool instance, bool bot)
{
    return level >= MinimumLevel && highRisk && !instance && !bot;
}

constexpr unsigned GearLimit(unsigned level)
{
    return level >= MaximumLevel ? 2 : 1;
}

constexpr std::uint32_t GoldLoss(std::uint32_t carried, unsigned percent)
{
    return static_cast<std::uint32_t>(static_cast<std::uint64_t>(carried) * percent / 100);
}
}

#endif
