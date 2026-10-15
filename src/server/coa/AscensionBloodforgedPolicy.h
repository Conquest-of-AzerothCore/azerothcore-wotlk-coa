#ifndef COA_ASCENSION_BLOODFORGED_POLICY_H
#define COA_ASCENSION_BLOODFORGED_POLICY_H

#include <array>
#include <algorithm>
#include <cstdint>

namespace Bloodforged
{
using Rates = std::array<unsigned, 3>;
constexpr std::array<Rates, 5> DefaultRates = {{{450, 50, 0}, {400, 100, 0},
    {380, 140, 15}, {360, 180, 25}, {340, 220, 40}}};

constexpr unsigned Band(unsigned level)
{
    return level < 25 ? 0 : level < 35 ? 1 : level < 45 ? 2 : level < 55 ? 3 : 4;
}

constexpr bool ValidRates(Rates const& rates)
{
    return rates[0] <= 10000 && rates[1] < rates[0] && rates[2] < rates[1]
        && rates[0] + rates[1] + rates[2] <= 10000;
}

constexpr unsigned RollQuality(unsigned roll, Rates const& rates)
{
    if (!ValidRates(rates) || roll >= 10000)
        return 0;
    unsigned boundary = 0;
    for (unsigned index = 0; index < rates.size(); ++index)
    {
        boundary += rates[index];
        if (roll < boundary)
            return index + 2;
    }
    return 0;
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
