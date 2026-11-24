/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_REALM_LEVEL_PURCHASE_H
#define ASCENSION_REALM_LEVEL_PURCHASE_H

#include "Define.h"

class Player;

namespace AscensionRealmLevelPurchase
{
    bool Refuse(Player* player, uint32 itemId);
}

#endif
