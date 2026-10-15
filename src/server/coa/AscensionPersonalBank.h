/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef MOD_ASCENSION_PERSONAL_BANK_H
#define MOD_ASCENSION_PERSONAL_BANK_H

#include "Define.h"
#include "ObjectGuid.h"

class Player;
class WorldPacket;

namespace AscensionPersonalBank
{
    enum Kind : uint8
    {
        PERSONAL = 0,
        REALM = 1
    };

    void Opened(Player* player, uint8 kind, ObjectGuid vault);

    [[nodiscard]] bool IsOpen(Player* player);

    bool HandlePacket(Player* player, WorldPacket const& packet);

    void Closed(Player* player);

    bool AddTab(Player* player, uint8 kind);

    void SendKindHint(Player* player, uint8 kind);
}

#endif
