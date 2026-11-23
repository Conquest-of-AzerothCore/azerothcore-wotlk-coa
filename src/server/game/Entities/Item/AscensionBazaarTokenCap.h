/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_BAZAAR_TOKEN_CAP_H
#define ASCENSION_BAZAAR_TOKEN_CAP_H

#include "Define.h"
#include <string>

class Player;

namespace AscensionBazaarTokenCap
{
constexpr uint32 TOKEN_ITEM = 975001;

struct Allowance
{
    uint32 cap = 0;
    uint32 earned = 0;
    uint32 start = 0;
    uint32 end = 0;
};

uint32 GetCap();
void WarmAccount(Player* player);

uint32 Claim(Player* player, uint32 count);

uint32 ClaimForAccount(uint32 accountId, Player* player, uint32 count);

void Refund(uint32 accountId, uint32 count);

Allowance GetAllowance(uint32 accountId);

uint32 LimitReward(Player* player, uint32 itemId, uint32 count);

uint32 Give(Player* player, uint32 count);

std::string Describe(uint32 accountId);

void Set(uint32 accountId, uint32 earned, uint32 secondsAgo);

bool GetOpenWindow(uint32 accountId, uint32& remaining, uint32& secondsLeft);

void SendClientState(Player* player);
}

#endif
