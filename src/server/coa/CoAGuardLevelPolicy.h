/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_GUARD_LEVEL_POLICY_H
#define COA_GUARD_LEVEL_POLICY_H

#include <algorithm>
#include <cstdint>

namespace CoAGuardLevel
{
inline std::uint8_t Capped(std::uint8_t level, std::uint32_t maxPlayerLevel)
{
    return static_cast<std::uint8_t>(std::min<std::uint32_t>(level, maxPlayerLevel));
}
}

#endif
