/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_BAZAAR_TOKEN_RESERVE_H
#define ASCENSION_BAZAAR_TOKEN_RESERVE_H

#include "Define.h"

class Player;

// Realm Bound Bazaar Tokens from the Elite Warchest.
// The warchest's tokens are the same item (975001) as farmed tokens, so they stack and stay tradeable as items.
// Instead each account keeps a reserve: the number of warchest tokens it still holds. The reserve is spent first
// (any token destroyed by a purchase lowers it) and tokens may only leave the account (trade, mail to another
// account, auction house, guild bank) while the account keeps at least the reserve. Mail between the account's
// own characters is free.
namespace AscensionBazaarTokenReserve
{
constexpr uint32 TOKEN_ITEM = 975001;

bool IsEnabled();

uint32 GetReserve(uint32 accountId);

// The Elite Warchest handed out `count` tokens (in bags or by mail to the same character).
void AddReserve(Player* player, uint32 count);

// `count` tokens were destroyed (spent or thrown away) by the player: the reserve is used up first.
void OnSpent(Player* player, uint32 count);

// A character is being deleted: its tokens leave the account and lower the reserve first.
void OnCharacterDeleted(uint32 accountId, uint32 lowGuid);

// Tokens on the account: the online character from memory, the account's other characters and all mail sent to
// the account's characters from the characters DB.
uint32 CountAccountTokens(Player* player);

// True when `count` tokens may leave the account without going below the reserve.
bool CanGiveAway(Player* player, uint32 count);

void SendRefusal(Player* player);

// Lowers the reserve by the tokens DestroyItem/DestroyItemCount remove while the scope is alive (purchases,
// consumed or destroyed stacks). Nested scopes count once.
class SpendScope
{
public:
    SpendScope(Player* player, uint32 itemEntry);
    ~SpendScope();
    SpendScope(SpendScope const&) = delete;
    SpendScope& operator=(SpendScope const&) = delete;

private:
    Player* _player;
    uint32 _before;
};
}

#endif
