/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_BOSS_CONTROL_ROLES_POLICY_H
#define COA_ASCENSION_BOSS_CONTROL_ROLES_POLICY_H

#include <algorithm>
#include <array>
#include <cstdint>

namespace BossControlRoles
{
constexpr std::array<std::uint32_t, 12> TankSpecializations = { 9, 17, 21, 22, 48, 52, 57, 60, 96, 97, 99, 100 };
constexpr std::array<std::uint32_t, 10> HealerSpecializations = { 6, 25, 31, 37, 40, 43, 51, 58, 98, 101 };

inline bool TanksOrHeals(std::uint32_t specialization)
{
    auto const listed = [specialization](auto const& specializations)
    {
        return std::find(specializations.begin(), specializations.end(), specialization) != specializations.end();
    };
    return specialization && (listed(TankSpecializations) || listed(HealerSpecializations));
}
}

#endif
