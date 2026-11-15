/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_HIGH_RISK_H
#define ASCENSION_HIGH_RISK_H

#include "Define.h"

class Player;

namespace HighRisk
{
    using LootGuard = bool (*)(Player* looter, uint32 chestOwner);

    void RegisterLootGuard(LootGuard guard);

    [[nodiscard]] bool CanLoot(Player* looter, uint32 chestOwner);
}

#endif
