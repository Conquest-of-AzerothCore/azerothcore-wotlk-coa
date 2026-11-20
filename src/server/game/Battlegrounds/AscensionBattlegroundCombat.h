/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_BATTLEGROUND_COMBAT_H
#define ASCENSION_BATTLEGROUND_COMBAT_H

#include "Define.h"

class Unit;

namespace AscensionBattlegroundCombat
{
    uint8 SharedTopLevel(Unit const* self, Unit const* other);
}

#endif
