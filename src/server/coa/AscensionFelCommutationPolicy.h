#ifndef COA_ASCENSION_FEL_COMMUTATION_POLICY_H
#define COA_ASCENSION_FEL_COMMUTATION_POLICY_H

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <string>
#include <vector>

namespace FelCommutation
{
constexpr unsigned WindowId = 2;
constexpr unsigned SlotCount = 19;
constexpr unsigned ShirtSlot = 4;
constexpr unsigned TabardSlot = 19;
constexpr double DefaultFeeMultiplier = 1.0;
constexpr unsigned DefaultMaxSlots = 3;
constexpr std::uint64_t LevelCapSurcharge = 100000;

struct RateBand
{
    std::uint32_t from;
    std::uint32_t copperPerLevel;
};

constexpr std::array<RateBand, 9> RateBands = {{{0, 28}, {26, 85}, {36, 256}, {46, 361}, {55, 1250}, {63, 1500},
    {106, 2000}, {115, 2500}, {124, 2750}}};

constexpr bool Insurable(unsigned slot)
{
    return slot >= 1 && slot <= SlotCount && slot != ShirtSlot && slot != TabardSlot;
}

enum class ToggleResult : std::uint8_t
{
    Ok,
    AlreadyActive,
    AlreadyInactive,
    NoAltarNearby,
    Unknown
};

constexpr char const* ToggleResultName(ToggleResult result)
{
    switch (result)
    {
        case ToggleResult::Ok:
            return "TOGGLE_FEL_COMMUTATION_OK";
        case ToggleResult::AlreadyActive:
            return "TOGGLE_FEL_COMMUTATION_ALREADY_ACTIVE";
        case ToggleResult::AlreadyInactive:
            return "TOGGLE_FEL_COMMUTATION_ALREADY_INACTIVE";
        case ToggleResult::NoAltarNearby:
            return "TOGGLE_FEL_COMMUTATION_NO_ALTAR_NEARBY";
        case ToggleResult::Unknown:
            break;
    }
    return "TOGGLE_FEL_COMMUTATION_UNKNOWN";
}

constexpr ToggleResult DecideToggle(bool active, bool want, bool altarNearby, bool anywhereAllowed)
{
    if (active == want)
        return want ? ToggleResult::AlreadyActive : ToggleResult::AlreadyInactive;
    if (!altarNearby && !anywhereAllowed)
        return ToggleResult::NoAltarNearby;
    return ToggleResult::Ok;
}

constexpr std::uint32_t CopperPerLevel(std::uint32_t averageItemLevel)
{
    std::uint32_t rate = RateBands.back().copperPerLevel;
    for (RateBand const& band : RateBands)
    {
        if (band.from > averageItemLevel)
            break;
        rate = band.copperPerLevel;
    }
    return rate;
}

inline std::uint64_t ClientCost(float averageItemLevel, bool atLevelCap)
{
    std::int32_t const level = std::int32_t(averageItemLevel);
    double cost = double(level) * double(CopperPerLevel(std::uint32_t(level)));
    if (atLevelCap)
        cost += double(LevelCapSurcharge);
    return cost > 0.0 ? std::uint64_t(std::llround(cost)) : 0;
}

inline std::uint64_t ItemFee(std::uint32_t itemLevel, double feeMultiplier)
{
    double const cost = double(itemLevel) * double(CopperPerLevel(itemLevel)) * std::max(0.0, feeMultiplier);
    return cost > 0.0 ? std::uint64_t(std::llround(cost)) : 0;
}

inline std::string FormatMoney(std::uint64_t copper)
{
    return std::to_string(copper / 10000) + "g " + std::to_string(copper / 100 % 100) + "s " +
        std::to_string(copper % 100) + "c";
}

struct Settlement
{
    bool covered = true;
    std::uint64_t total = 0;
    std::vector<std::uint64_t> perItem;
};

inline Settlement Settle(float averageItemLevel, bool atLevelCap, double feeMultiplier, std::size_t insuredItems,
    std::uint64_t gold)
{
    Settlement settlement;
    double const scaled = double(ClientCost(averageItemLevel, atLevelCap)) * std::max(0.0, feeMultiplier);
    settlement.total = std::uint64_t(std::llround(scaled));
    settlement.perItem.assign(insuredItems, 0);
    if (insuredItems)
    {
        std::uint64_t const share = settlement.total / insuredItems;
        std::uint64_t const remainder = settlement.total % insuredItems;
        for (std::size_t i = 0; i < insuredItems; ++i)
            settlement.perItem[i] = share + (i < remainder ? 1 : 0);
    }

    settlement.covered = settlement.total <= gold;
    return settlement;
}
}

#endif
