/*
 * Shared player count for flex-scaled content: non-GM players currently in
 * the instance, clamped to the 10..25 raid-size label. See FlexHealth.cpp for
 * why (boss health scaling); other flex-by-raid-size mechanics (Sacrificial
 * Chains' chained-player count) reuse the same clamp rather than recompute it.
 */

#ifndef COA_FLEX_HEALTH_H
#define COA_FLEX_HEALTH_H

#include "Define.h"

class Map;

namespace coa_flex
{
    uint32 CountPlayers(Map* map);
}

#endif
