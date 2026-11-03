/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_TANK_STANCES_H
#define ASCENSION_TANK_STANCES_H

#include "Define.h"

namespace Ascension
{
    constexpr uint32 FIRST_TANK_STANCE_AURA = 807725;
    constexpr uint32 LAST_TANK_STANCE_AURA = 807736;

    constexpr bool IsTankStanceAura(uint32 spellId)
    {
        return spellId >= FIRST_TANK_STANCE_AURA && spellId <= LAST_TANK_STANCE_AURA;
    }
}

#endif
