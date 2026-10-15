/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_REAPER_TALENTS_H
#define ASCENSION_REAPER_TALENTS_H

#include "Define.h"

class Player;
bool HandleAscensionReaperResource(Player* player, uint32 spellId, int32 amount);
void ApplyAscensionReaperSoulInfusionGained(Player* player);
void ApplyAscensionReaperSoulInfusionSpent(Player* player);
void AddSC_AscensionReaperTalents();

#endif
