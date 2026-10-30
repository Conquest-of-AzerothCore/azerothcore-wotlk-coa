#ifndef COA_ASCENSION_HONORABLE_COMBAT_POLICY_H
#define COA_ASCENSION_HONORABLE_COMBAT_POLICY_H

#include <array>
#include <cstdint>

namespace HonorableCombat
{
constexpr unsigned WesternPlaguelands = 28;
constexpr unsigned Winterspring = 618;
constexpr std::array<std::uint32_t, 2> Zones = {WesternPlaguelands, Winterspring};
constexpr std::array<std::uint32_t, 4> WinCriteria = {15691, 15695, 21691, 21695};
constexpr unsigned HonorableAura = 9930870;
constexpr unsigned CombatAura = 9930871;
constexpr unsigned ZonesOpcode = 0x0768;

constexpr bool IsHonorableZone(std::uint32_t zone)
{
    for (std::uint32_t honorable : Zones)
        if (honorable == zone)
            return true;
    return false;
}

constexpr bool Eligible(std::uint32_t zone, bool pvpRuleset)
{
    return pvpRuleset && IsHonorableZone(zone);
}

constexpr bool IsWinCriteria(std::uint32_t criteria)
{
    for (std::uint32_t win : WinCriteria)
        if (win == criteria)
            return true;
    return false;
}

constexpr bool CanEngage(std::uint64_t attacker, std::uint64_t attackerPartner, std::uint64_t target,
    std::uint64_t targetPartner)
{
    return (!targetPartner || targetPartner == attacker) && (!attackerPartner || attackerPartner == target);
}

constexpr bool BlocksAssist(std::uint64_t helper, std::uint64_t helperPartner, std::uint64_t target,
    std::uint64_t targetPartner)
{
    return helper != target && (helperPartner || targetPartner);
}

constexpr bool StartsLock(bool targetHonorable, bool targetInitiated, bool attackerLocked, bool targetLocked)
{
    return targetHonorable && !targetInitiated && !attackerLocked && !targetLocked;
}

constexpr bool IsInitiation(bool attackerLocked, bool targetStartedAgainstAttacker)
{
    return !attackerLocked && !targetStartedAgainstAttacker;
}

constexpr bool IsWin(std::uint64_t killer, std::uint64_t loserPartner, std::uint32_t zone)
{
    return killer && killer == loserPartner && IsHonorableZone(zone);
}
}

#endif
