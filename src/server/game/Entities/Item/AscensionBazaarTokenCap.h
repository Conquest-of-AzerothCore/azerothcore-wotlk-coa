/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_BAZAAR_TOKEN_CAP_H
#define ASCENSION_BAZAAR_TOKEN_CAP_H

#include "Define.h"
#include <string>

class Player;

// Hourly limit on earned Bazaar Tokens (975001), per account.
// The first token an account earns opens a window of CoA.BazaarTokens.HourlyCap.WindowSeconds (one hour). Within it
// the account earns at most CoA.BazaarTokens.HourlyCap.Amount tokens; a reward that would go over pays the rest up to
// the limit, and after that nothing until the window has run out. The next token earned then opens a new window.
// Counted: Ethereal Bazaar kill, boss and quest tokens and quest reward items. Not counted and never limited: the
// Elite Warchest, the Groot Coin exchange, Recruit-a-Friend rewards, GM commands, and tokens moved between players
// (trade, mail, auction house, guild bank).
namespace AscensionBazaarTokenCap
{
constexpr uint32 TOKEN_ITEM = 975001;

// 0 turns the limit off.
uint32 GetCap();

// The player's account earns `count` tokens: returns how many it may receive (0 to count) and counts them.
uint32 Claim(Player* player, uint32 count);

// Quest reward items: Bazaar Tokens go through Claim, every other item keeps its count.
uint32 LimitReward(Player* player, uint32 itemId, uint32 count);

// Earned tokens and time left in the account's current window, for the player.
std::string Describe(uint32 accountId);

// GM: put the account at `earned` tokens in a window that opened `secondsAgo` seconds ago.
void Set(uint32 accountId, uint32 earned, uint32 secondsAgo);
}

#endif
