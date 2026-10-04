#ifndef MANASTORM_MOBILITY_CLIENT_H
#define MANASTORM_MOBILITY_CLIENT_H

class Player;

namespace ManastormMobilityClient
{
    // Opt-in native family-38 proof; the shared server backend remains authoritative.
    void Load();
    void Sync(Player* player);
}

#endif
