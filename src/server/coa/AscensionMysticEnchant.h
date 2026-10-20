/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_MYSTIC_ENCHANT_H
#define ASCENSION_MYSTIC_ENCHANT_H

#include "AscensionMysticEnchantRules.h"
#include <vector>

class Player;

namespace AscensionMysticEnchant
{
bool ApplyGuide(Player* player, std::vector<GuideEnchant> const& guide);

uint32 ClearActivePreset(Player* player);
}

#endif
