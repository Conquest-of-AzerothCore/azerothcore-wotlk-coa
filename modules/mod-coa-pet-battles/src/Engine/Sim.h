#ifndef COA_PET_BATTLE_ENGINE_SIM_H
#define COA_PET_BATTLE_ENGINE_SIM_H

#include "Catalog.h"
#include <cstdint>
#include <string>
#include <vector>

namespace CoAPetBattles::Engine
{
    inline constexpr int32_t SimRoundLimit = 50;

    struct SimResult
    {
        std::vector<std::string> lines;
        std::string error;
    };

    SimResult RunSim(Catalog const& catalog, uint32_t speciesA, uint32_t speciesB, int32_t level, uint32_t seed);
}

#endif
