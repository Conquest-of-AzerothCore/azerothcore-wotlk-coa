/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_REAPER_SOUL_STRIKE_H
#define ASCENSION_REAPER_SOUL_STRIKE_H

#include "Define.h"

class Player;
class Spell;
class Unit;

void HandleAscensionReaperSoulStrikeHit(Spell* spell, Player* player,
    Unit* target, uint8 missInfo);

#endif
