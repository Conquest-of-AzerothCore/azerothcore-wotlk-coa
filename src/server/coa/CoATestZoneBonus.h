/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_TEST_ZONE_BONUS_H
#define COA_TEST_ZONE_BONUS_H

#include <cstdint>

class Player;

namespace TestZoneBonus
{
enum class Reward
{
    Experience,
    Runes,
    BazaarTokens
};

std::uint32_t Apply(Player const* player, Reward reward, std::uint32_t amount);
}

#endif
