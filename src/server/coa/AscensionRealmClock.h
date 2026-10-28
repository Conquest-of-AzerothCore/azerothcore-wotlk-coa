/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_REALM_CLOCK_H
#define ASCENSION_REALM_CLOCK_H

#include "GameTime.h"
#include "Timer.h"

namespace AscensionRealmClock
{
inline bool IsNight()
{
    uint32 const hour = Acore::Time::GetHours(GameTime::GetGameTime());
    return hour < 6 || hour >= 18;
}
}

#endif
