#ifndef MANASTORM_OUTLAND_HEALTH_H
#define MANASTORM_OUTLAND_HEALTH_H

#include "Define.h"

namespace ManastormOutlandHealth
{
    constexpr double TBC_DUNGEON_BOSS_HEALTH_MULTIPLIER = 0.5;

    constexpr double Ratio(bool tbcDungeonObjective)
    {
        return tbcDungeonObjective ? TBC_DUNGEON_BOSS_HEALTH_MULTIPLIER : 1.0;
    }
}

#endif
