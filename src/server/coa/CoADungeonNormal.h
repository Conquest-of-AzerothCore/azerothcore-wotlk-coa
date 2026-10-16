/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_DUNGEON_NORMAL_H
#define COA_DUNGEON_NORMAL_H

#include "Define.h"

class SpellInfo;
class Unit;
class WorldObject;

namespace CoADungeonNormal
{
    bool TunesSpell(Unit const* attacker, SpellInfo const* spellInfo);
    uint32 KitRepeat(WorldObject const* source, uint32 repeat);
}

#endif
