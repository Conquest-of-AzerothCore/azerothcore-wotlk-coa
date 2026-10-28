/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_RUNEMASTER_ECHOES_H
#define ASCENSION_RUNEMASTER_ECHOES_H

#include "Define.h"

class Player;

void SynchronizeAscensionRunemasterEchoes(Player* player, uint32 specializationId);
void SendAscensionRunemasterEchoesCooldown(Player* player);
void AddAscensionRunemasterEchoesScripts();

#endif
