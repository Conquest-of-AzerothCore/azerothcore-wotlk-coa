#ifndef MANASTORM_MOBILITY_CLIENT_H
#define MANASTORM_MOBILITY_CLIENT_H

#include "Define.h"

class Player;

namespace ManastormMobilityClient
{
    bool IsMixture(uint32 spellId);
    void Load();
    void Sync(Player* player);
    void PrepareEntry(Player* player);
    void SyncAuras(Player* player);
    void OnMixtureRemoved(Player* player);
}

#endif
