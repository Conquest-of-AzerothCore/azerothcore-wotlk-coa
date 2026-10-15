/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */
#ifndef ASCENSION_MANASTORM_RULES_H
#define ASCENSION_MANASTORM_RULES_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include "AscensionManastormCheckpoints.h"

namespace Ascension::Manastorm
{
    inline constexpr std::uint32_t MinPlayerLevel = 10;
    inline constexpr std::uint32_t MaxDepth = 16384;
    inline constexpr std::uint32_t LoadoutSlots = 4;
    inline constexpr std::uint32_t MaxQueuedRequests = 8;
    inline constexpr std::uint32_t ReconnectSeconds = 120;

    enum class Phase : std::uint8_t { Idle, Transferring, Preparing, Running, Committing, Completed, Leaving, Failed };

    inline float PartyStatMultiplier(std::uint32_t players)
    {
        float const count = float(std::clamp(players, 1u, 5u));
        return (std::tanh((count - 2.5f) / 1.5f) + 1.0f) / (std::tanh(2.5f / 1.5f) + 1.0f);
    }

    inline float DepthStatMultiplier(std::uint32_t depth)
    {
        float const extra = float(std::clamp(depth, 1u, MaxDepth) - 1);
        return 1.0f + extra * 0.06f + extra * extra * 0.0004f;
    }

    inline bool IsCache(std::uint32_t entry)
    {
        return (entry >= 97877 && entry <= 97883) || entry == 1278050 || entry == 1278051;
    }

    inline bool CanStart(std::uint32_t depth, std::uint32_t completed, bool endgame = false)
    {
        bool const checkpoint = endgame
            ? std::binary_search(Checkpoints2.begin(), Checkpoints2.end(), depth)
            : std::binary_search(Checkpoints0.begin(), Checkpoints0.end(), depth);
        return depth >= 1 && depth <= MaxDepth && checkpoint && depth - 1 <= completed;
    }

    inline bool CanAdvance(Phase phase, std::uint32_t depth)
    {
        return phase == Phase::Completed && depth < MaxDepth;
    }

    inline std::uint32_t LinkedHealth(std::uint32_t baseHealth, std::uint32_t stacks)
    {
        return std::uint32_t(std::min<std::uint64_t>(1800000000,
            std::uint64_t(baseHealth) * (4 + std::min(stacks, 8u)) / 4));
    }

    inline float LinkedDamage(std::uint32_t stacks)
    {
        return 1.0f + float(std::min(stacks, 8u)) * 0.10f;
    }

    inline std::uint32_t CacheForLevel(std::uint32_t level, std::uint32_t depth, bool endgame)
    {
        if (endgame)
            return depth < 25 ? 1278050 : 1278051;
        return level <= 24 ? 97877 : level <= 30 ? 97878 : level <= 35 ? 97879
            : level <= 45 ? 97880 : level <= 50 ? 97881 : level <= 59 ? 97882 : 97883;
    }

    inline std::uint32_t CacheChance(std::uint32_t pity, std::uint32_t depth, bool endgame)
    {
        return endgame ? std::min(10000u, pity + 1500u + std::min(depth, 1000u) * 5) : 10000u;
    }

    inline std::uint32_t BoltReward(std::uint32_t depth) { return 3 + std::min(depth, 5000u) / 5; }
    inline std::uint32_t BullionReward(std::uint32_t depth) { return 1 + std::min(depth, 5000u) / 50; }
}

#endif
