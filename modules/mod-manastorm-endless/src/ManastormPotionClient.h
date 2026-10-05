#ifndef MANASTORM_POTION_CLIENT_H
#define MANASTORM_POTION_CLIENT_H

#include "Define.h"

class Player;

// Display-only native transport. The shared Manastorm manager owns every charge and timer.
namespace ManastormPotionClient
{
    void Load();
    void Send(Player const* player, uint8 charges, uint32 remainingMs);
    void Reset(Player const* player);
}

#endif
