/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_BAZAAR_TOKEN_CAP_H
#define ASCENSION_BAZAAR_TOKEN_CAP_H

#include "Define.h"
#include <string>

class Player;

namespace AscensionBazaarTokenCap
{
constexpr uint32 TOKEN_ITEM = 975001;

uint32 GetCap();

uint32 Claim(Player* player, uint32 count);

uint32 LimitReward(Player* player, uint32 itemId, uint32 count);

std::string Describe(uint32 accountId);

void Set(uint32 accountId, uint32 earned, uint32 secondsAgo);
}

#endif
