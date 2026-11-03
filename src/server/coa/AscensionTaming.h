/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_TAMING_H
#define ASCENSION_TAMING_H

#include <cstdint>

class Player;

namespace AscensionTaming
{
char const* SummonCosmeticPet(Player* player, std::uint32_t tier, std::uint32_t entry, bool creatureName = false);
}

#endif
