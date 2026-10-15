/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef ASCENSION_COMPAT_OPCODES_H
#define ASCENSION_COMPAT_OPCODES_H

#include "Define.h"

class WorldPacket;
class WorldSession;

namespace AscensionCompatOpcodes
{
    using Handler = bool (*)(WorldSession* session, WorldPacket const& packet);

    void Claim(uint16 opcode, Handler handler);

    bool Dispatch(WorldSession* session, WorldPacket const& packet);
}

#endif
