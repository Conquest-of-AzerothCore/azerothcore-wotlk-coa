/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_LEVEL_DAMAGE_SUMMONS_H
#define ASCENSION_LEVEL_DAMAGE_SUMMONS_H

#include "Define.h"
#include <algorithm>
#include <array>

constexpr std::array<uint32, 3> AscensionLevelDamageSummons = {
    51265,
    100481,
    250305,
};

inline bool IsAscensionLevelDamageSummon(uint32 entry)
{
    return std::find(AscensionLevelDamageSummons.begin(), AscensionLevelDamageSummons.end(), entry) !=
        AscensionLevelDamageSummons.end();
}

#endif
