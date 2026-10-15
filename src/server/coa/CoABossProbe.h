/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_BOSS_PROBE_H
#define COA_BOSS_PROBE_H

#include "Define.h"

class Creature;

void CoABossProbeSmartCast(Creature* creature, uint32 spellId, int32 result, char const* stage);

#endif
