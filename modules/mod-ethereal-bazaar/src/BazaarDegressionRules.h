/*
 * The degression curve for repeated Bazaar Token kills of the same creature
 * entry, kept free of game objects so the unit harness can drive it directly.
 */

#ifndef MOD_ETHEREAL_BAZAAR_BAZAAR_DEGRESSION_RULES_H
#define MOD_ETHEREAL_BAZAAR_BAZAAR_DEGRESSION_RULES_H

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace BazaarDegression
{
    constexpr uint32_t DEFAULT_FACTOR_PERCENT = 67;
    constexpr uint32_t DEFAULT_RECOVERY_FACTOR = 2;
    constexpr uint32_t DEFAULT_CUTOFF_PERCENT = 5;
    constexpr uint32_t DEFAULT_MAX_ENTRIES = 64;
    constexpr uint32_t DEFAULT_RESPAWN_DELAY_SECONDS = 300;
    constexpr uint32_t MIN_RESPAWN_DELAY_SECONDS = 1;

    // A creature with no respawn timer (0) falls back to a sane default
    // instead of dividing by nothing; anything else is kept, floored at the
    // minimum.
    inline uint32_t EffectiveRespawnDelay(uint32_t respawnDelaySeconds)
    {
        if (respawnDelaySeconds == 0)
            return DEFAULT_RESPAWN_DELAY_SECONDS;
        return respawnDelaySeconds < MIN_RESPAWN_DELAY_SECONDS ? MIN_RESPAWN_DELAY_SECONDS : respawnDelaySeconds;
    }

    // Heat recovers linearly over RecoveryFactor respawn cycles of the
    // creature and never drops below zero.
    inline double DecayHeat(double heat, uint64_t elapsedSeconds, uint32_t respawnDelaySeconds, uint32_t recoveryFactor)
    {
        uint32_t const delay = EffectiveRespawnDelay(respawnDelaySeconds);
        uint32_t const factor = recoveryFactor ? recoveryFactor : 1;
        double const recovery = static_cast<double>(elapsedSeconds) / (static_cast<double>(factor) * delay);
        double const decayed = heat - recovery;
        return decayed > 0.0 ? decayed : 0.0;
    }

    // (Factor/100)^heat: every accumulated kill of the same entry multiplies
    // the reward again, so heat 0 leaves it untouched.
    inline double Multiplier(double heat, uint32_t factorPercent)
    {
        return std::pow(static_cast<double>(factorPercent) / 100.0, heat);
    }

    inline bool IsBelowCutoff(double multiplier, uint32_t cutoffPercent)
    {
        return multiplier < static_cast<double>(cutoffPercent) / 100.0;
    }

    // floor(value) plus one with probability equal to the fractional part, so
    // the expected value of the result is exactly `value`. `draw` is a
    // uniform sample in [0, 1).
    inline uint32_t StochasticRound(double value, double draw)
    {
        double const flo = std::floor(value);
        double const frac = value - flo;
        uint32_t const base = static_cast<uint32_t>(flo);
        return draw < frac ? base + 1 : base;
    }

    inline uint32_t ScaledAmount(uint32_t amount, double multiplier, double draw)
    {
        return StochasticRound(static_cast<double>(amount) * multiplier, draw);
    }

    // One tracked creature entry's heat state.
    struct Entry
    {
        uint32_t key = 0;
        double heat = 0.0;
        uint64_t lastUpdate = 0;
    };

    // The index of the entry least recently updated, the one to drop to make
    // room for a new one. `entries` must not be empty.
    inline std::size_t LeastRecentlyUpdatedIndex(std::vector<Entry> const& entries)
    {
        std::size_t result = 0;
        for (std::size_t i = 1; i < entries.size(); ++i)
            if (entries[i].lastUpdate < entries[result].lastUpdate)
                result = i;
        return result;
    }
}

#endif
