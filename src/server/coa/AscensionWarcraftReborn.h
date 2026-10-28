/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_WARCRAFT_REBORN_H
#define ASCENSION_WARCRAFT_REBORN_H

#include "Define.h"
#include <unordered_set>

class Player;

namespace AscensionWarcraftReborn
{
bool IsRebornCharacter(Player const* player);
uint32 ResetActiveTalents(Player* player);
std::unordered_set<uint32> ForgetClassSpellsAbove(Player* player, uint8 level);
}

#endif
