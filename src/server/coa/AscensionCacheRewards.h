/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */
#ifndef ASCENSION_CACHE_REWARDS_H
#define ASCENSION_CACHE_REWARDS_H

#include "Define.h"
#include <vector>

class Item;
class Player;

namespace AscensionCacheRewards
{
struct Reward
{
    uint32 itemId;
    uint16 itemLevel;
    uint8 statType;
    uint8 armorClass;
    uint32 count = 1;
    int32 randomPropertyId = 0;
};

bool Deliver(Player* player, std::vector<Reward> const& rewards, Item* cache);
}

#endif
