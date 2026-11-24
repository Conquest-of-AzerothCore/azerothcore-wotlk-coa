#ifndef COA_PET_BATTLE_ENGINE_RNG_H
#define COA_PET_BATTLE_ENGINE_RNG_H

#include <cstddef>
#include <cstdint>
#include <random>
#include <string>
#include <utility>
#include <vector>

namespace CoAPetBattles::Engine
{
    class Rng
    {
    public:
        virtual ~Rng() = default;
        virtual int32_t Roll(int32_t lo, int32_t hi) = 0;
    };

    class SeededRng : public Rng
    {
    public:
        explicit SeededRng(uint32_t seed) : _engine(seed) { }
        int32_t Roll(int32_t lo, int32_t hi) override;

    private:
        std::mt19937 _engine;
    };

    struct RecordedRoll
    {
        int32_t lo = 0;
        int32_t hi = 0;
        int32_t value = 0;
    };

    class ReplayRng : public Rng
    {
    public:
        explicit ReplayRng(std::vector<RecordedRoll> rolls) : _rolls(std::move(rolls)) { }
        int32_t Roll(int32_t lo, int32_t hi) override;
        bool Exhausted() const { return _next >= _rolls.size(); }
        std::string const& Divergence() const { return _divergence; }
        size_t Used() const { return _next; }

    private:
        std::vector<RecordedRoll> _rolls;
        size_t _next = 0;
        std::string _divergence;
    };
}

#endif
