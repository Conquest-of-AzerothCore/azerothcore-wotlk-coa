/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */
#ifndef ASCENSION_CHARACTER_SELECTION_H
#define ASCENSION_CHARACTER_SELECTION_H

#include "Define.h"

class WorldSession;
class WorldPacket;

bool IsAscensionCharacterSelectionOpcode(uint16 opcode);

bool HandleAscensionCharacterSelectionPacket(WorldSession* session, WorldPacket const& packet);

void SendAscensionCharacterListInfo(WorldSession* session);

#endif
