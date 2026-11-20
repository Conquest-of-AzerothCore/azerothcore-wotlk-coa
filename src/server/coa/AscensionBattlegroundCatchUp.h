/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_BATTLEGROUND_CATCH_UP_H
#define ASCENSION_BATTLEGROUND_CATCH_UP_H

#include "Define.h"

class SpellInfo;
class Unit;

namespace AscensionBattlegroundCatchUp
{
    float OutputRatio(Unit const* unit);
    uint32 ScaledOutput(Unit const* source, Unit const* target, uint32 amount, SpellInfo const* spell, bool healing);
}

#endif
