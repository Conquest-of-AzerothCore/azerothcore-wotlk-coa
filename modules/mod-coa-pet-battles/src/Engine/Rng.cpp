#include "Rng.h"

namespace CoAPetBattles::Engine
{
    int32_t SeededRng::Roll(int32_t lo, int32_t hi)
    {
        if (hi <= lo)
            return lo;
        uint64_t const span = static_cast<uint64_t>(static_cast<int64_t>(hi) - static_cast<int64_t>(lo)) + 1;
        uint64_t const draws = uint64_t(1) << 32;
        uint64_t const limit = draws - draws % span;
        uint64_t value = 0;
        do
            value = _engine();
        while (value >= limit);
        return static_cast<int32_t>(static_cast<int64_t>(lo) + static_cast<int64_t>(value % span));
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
