/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_PRIMALIST_EARTHSHAPING_H
#define ASCENSION_PRIMALIST_EARTHSHAPING_H

class SpellInfo;
class Player;

void ApplyAscensionPrimalistEarthshapingContracts(SpellInfo* spellInfo);
bool HandleAscensionPrimalistEarthshapingGain(Player* player);
void AddSC_AscensionPrimalistEarthshaping();

#endif
