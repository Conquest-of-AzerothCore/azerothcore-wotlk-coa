#ifndef COA_ASCENSION_PVE_POWER_POLICY_H
#define COA_ASCENSION_PVE_POWER_POLICY_H

#include "AscensionPvpPowerPolicy.h"
#include <cstdint>

namespace PvePower
{
constexpr unsigned Cap = PvpPower::Cap;
constexpr unsigned MinimumLevel = 60;
constexpr unsigned DamageBasisPoints = 5;
constexpr unsigned HealingBasisPoints = 2;

enum MapKind : std::uint8_t
{
    OpenWorld = 1,
    Instance = 2,
    Battleground = 4,
};

constexpr std::uint8_t AllMaps = OpenWorld | Instance | Battleground;
constexpr std::uint8_t DamageMaps = AllMaps;
constexpr std::uint8_t HealingMaps = Instance;

constexpr bool Applies(std::uint8_t maps, MapKind kind)
{
    return (maps & kind) != 0;
}

constexpr unsigned SpellPower(unsigned spell)
{
    return spell >= 101600 && spell <= 101699 ? spell - 101600 : 0;
}
}

#endif
