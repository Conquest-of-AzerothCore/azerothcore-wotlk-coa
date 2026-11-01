#ifndef WORLDFORGED_REFUNDS_H
#define WORLDFORGED_REFUNDS_H

#include "Define.h"
#include <string>
#include <vector>

class Player;

namespace WorldforgedRefunds
{
struct Offer
{
    uint32 id;
    uint32 originalGuid;
    uint32 required;
    uint32 refunded;
    uint32 runes;
    uint32 starts;
    uint32 ends;
};

void Load();
bool Available();
std::string Id(Offer const& offer);
std::vector<Offer> Offers(Player* player);
char const* Restore(Player* player, Offer const& offer);
}

#endif
