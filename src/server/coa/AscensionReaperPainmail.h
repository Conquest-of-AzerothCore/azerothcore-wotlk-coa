/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_REAPER_PAINMAIL_H
#define ASCENSION_REAPER_PAINMAIL_H

#include "Define.h"

class Player;
class Spell;
class Unit;

void HandleAscensionReaperPainmailHit(Spell* spell, Player* player,
    Unit* target, uint8 missInfo, uint32 damage);

#endif
