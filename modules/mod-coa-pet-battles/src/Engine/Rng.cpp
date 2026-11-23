#include "Rng.h"

namespace CoAPetBattles::Engine
{
    int32_t SeededRng::Roll(int32_t lo, int32_t hi)
    {
        if (hi <= lo)
            return lo;
        std::uniform_int_distribution<int32_t> distribution(lo, hi);
        return distribution(_engine);
    }

    int32_t ReplayRng::Roll(int32_t lo, int32_t hi)
    {
        size_t const index = _next++;
        if (index >= _rolls.size())
        {
            if (_divergence.empty())
                _divergence = "roll " + std::to_string(index) + ": engine asked for " + std::to_string(lo) + ".." +
                    std::to_string(hi) + " after the recorded rolls ended";
            return lo;
        }
        RecordedRoll const& roll = _rolls[index];
        if (roll.lo != lo || roll.hi != hi)
        {
            if (_divergence.empty())
                _divergence = "roll " + std::to_string(index) + ": recorded " + std::to_string(roll.lo) + ".." +
                    std::to_string(roll.hi) + ", engine asked for " + std::to_string(lo) + ".." + std::to_string(hi);
            return lo;
        }
        return roll.value;
    }
}
