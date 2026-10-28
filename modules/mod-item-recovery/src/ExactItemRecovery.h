#ifndef EXACT_ITEM_RECOVERY_H
#define EXACT_ITEM_RECOVERY_H

#include "Define.h"
#include <string>
#include <vector>

class Player;

namespace ExactItemRecovery
{
struct Offer
{
    uint64 id;
    uint32 originalGuid;
    uint32 entry;
    uint32 count;
    uint32 price;
    uint32 timestamp;
};

void Initialize();
void Configure();
std::vector<Offer> Offers(Player* player, bool deleted);
char const* Restore(Player* player, uint64 id, bool deleted);
}

#endif
