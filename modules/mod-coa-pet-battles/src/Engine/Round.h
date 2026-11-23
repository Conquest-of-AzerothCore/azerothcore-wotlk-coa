#ifndef COA_PET_BATTLE_ENGINE_ROUND_H
#define COA_PET_BATTLE_ENGINE_ROUND_H

#include "Battle.h"
#include <functional>
#include <map>
#include <string>
#include <vector>

namespace CoAPetBattles::Engine
{
    struct RoundResult
    {
        std::vector<Event> events;
        std::string status;
    };

    RoundResult Round(Battle& battle, std::string const& commandP, std::string const& commandE);
    std::string AI(Battle& battle, Side side);
    bool CanTrap(Battle const& battle);
    void Finish(Battle& battle);
    std::map<uint16_t, int32_t> const& UnknownEffects(Battle const& battle);
    void LuaSort(std::vector<int32_t>& values, std::function<bool(int32_t, int32_t)> const& less);
}

#endif
