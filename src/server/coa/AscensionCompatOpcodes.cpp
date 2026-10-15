/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AscensionCompatOpcodes.h"

#include "WorldPacket.h"
#include "WorldSession.h"

#include <utility>
#include <vector>

namespace AscensionCompatOpcodes
{
    namespace
    {
        std::vector<std::pair<uint16, Handler>>& ClaimedOpcodes()
        {
            static std::vector<std::pair<uint16, Handler>> claimed;
            return claimed;
        }
    }

    void Claim(uint16 opcode, Handler handler)
    {
        if (!handler)
            return;

        ClaimedOpcodes().emplace_back(opcode, handler);
    }

    bool Dispatch(WorldSession* session, WorldPacket const& packet)
    {
        uint16 const opcode = packet.GetOpcode();
        for (auto const& [claimed, handler] : ClaimedOpcodes())
            if (claimed == opcode && handler(session, packet))
                return true;
        return false;
    }
}
