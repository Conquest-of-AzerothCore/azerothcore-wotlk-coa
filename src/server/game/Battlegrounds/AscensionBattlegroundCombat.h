/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_BATTLEGROUND_COMBAT_H
#define ASCENSION_BATTLEGROUND_COMBAT_H

#include "Define.h"

class SpellInfo;
class Unit;

namespace AscensionBattlegroundCombat
{
    uint8 SharedTopLevel(Unit const* self, Unit const* other);
    uint8 StealthDetectionLevel(Unit const* detector, Unit const* stealthed);
    float OutputRatio(Unit const* unit);
    uint32 ScaledOutput(Unit const* source, Unit const* target, uint32 amount, SpellInfo const* spell, bool healing,
        bool absorb = false);
    float UnscaledFactor(Unit const* source, Unit const* target, SpellInfo const* spell, bool healing,
        bool absorb = false);
    float UnitUnscaledFactor(Unit const* unit);
}

#endif
