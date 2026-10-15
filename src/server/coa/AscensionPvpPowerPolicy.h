#ifndef COA_ASCENSION_PVP_POWER_POLICY_H
#define COA_ASCENSION_PVP_POWER_POLICY_H

#include <algorithm>
#include <cstdint>
#include <limits>

namespace PvpPower
{
constexpr unsigned Cap = 495;

constexpr unsigned SpellPower(unsigned spell)
{
    if (spell >= 101700 && spell <= 101799)
        return spell - 101700;
    switch (spell)
    {
        case 9930954: return 5;
        case 9930955: return 6;
        case 9930956: return 7;
        case 9930957: return 10;
        default: return 0;
    }
}

constexpr std::uint32_t Scale(std::uint32_t amount, unsigned power, unsigned basisPoints, bool reduce = false)
{
    if (!power)
        return amount;
    std::uint64_t adjustment = std::min(power, Cap) * basisPoints;
    std::uint64_t factor = reduce ? 10000 - std::min<std::uint64_t>(10000, adjustment) : 10000 + adjustment;
    return std::uint32_t(std::min<std::uint64_t>(std::uint64_t(amount) * factor / 10000,
        std::numeric_limits<std::int32_t>::max()));
}

constexpr bool HealingContext(bool instance, bool battleground, bool highRisk, bool warMode)
{
    return battleground || (!instance && (highRisk || warMode));
}
}

#endif
