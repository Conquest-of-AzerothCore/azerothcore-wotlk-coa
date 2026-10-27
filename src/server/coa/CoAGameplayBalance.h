/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_GAMEPLAY_BALANCE_H
#define COA_GAMEPLAY_BALANCE_H

#include "Define.h"
#include "ObjectGuid.h"
#include <array>
#include <cstddef>
#include <functional>
#include <optional>
#include <span>
#include <vector>

namespace CoAGameplay::Balance
{
    enum class StageOutcome : uint8
    {
        Running,
        Win,
        Loss,
        Timeout,
        Invalid
    };

    inline StageOutcome ResolveStage(bool ownerAlive, uint32 enemiesAlive, bool anyEnemyEvading, uint32 elapsedMs,
                                      uint32 capMs)
    {
        if (!ownerAlive)
            return StageOutcome::Loss;
        if (anyEnemyEvading)
            return StageOutcome::Invalid;
        if (enemiesAlive == 0)
            return StageOutcome::Win;
        if (elapsedMs >= capMs)
            return StageOutcome::Timeout;
        return StageOutcome::Running;
    }

    struct SoloCandidate
    {
        ObjectGuid guid;
        bool engaged;
        float healthPct;
        float distance;
    };

    inline std::optional<ObjectGuid> SelectSoloTarget(std::vector<SoloCandidate> const& candidates,
                                                        std::optional<ObjectGuid> current)
    {
        if (current)
            for (SoloCandidate const& candidate : candidates)
                if (candidate.engaged && candidate.guid == *current)
                    return current;

        SoloCandidate const* best = nullptr;
        for (SoloCandidate const& candidate : candidates)
        {
            if (!candidate.engaged)
                continue;
            if (!best || candidate.healthPct < best->healthPct ||
                (candidate.healthPct == best->healthPct && candidate.distance < best->distance))
                best = &candidate;
        }
        if (!best)
            return std::nullopt;
        return best->guid;
    }

    enum class KitCondition : uint8
    {
        Always,
        SelfAuraMissing,
        PetAuraMissing,
        OwnedBelow,
        HealthBelow
    };

    enum class KitTarget : uint8
    {
        Self,
        Pet,
        Enemy
    };

    struct KitRule
    {
        uint32 spell;
        KitCondition when;
        uint32 aura;
        float value;
        KitTarget target;
    };

    inline std::optional<std::size_t> NextKitRule(std::span<KitRule const> rules,
                                                    std::function<bool(KitRule const&)> const& holds,
                                                    std::function<bool(KitRule const&)> const& castable)
    {
        for (std::size_t index = 0; index < rules.size(); ++index)
            if (holds(rules[index]) && castable(rules[index]))
                return index;
        return std::nullopt;
    }

    enum class SwingResult : uint8
    {
        Normal,
        Crit,
        Glancing,
        Crushing,
        Miss,
        Dodge,
        Parry,
        Block
    };

    struct SwingTally
    {
        uint32 swings{};
        std::array<uint32, 8> results{};
        uint64 normalDamage{};
    };

    inline void AddSwing(SwingTally& tally, SwingResult result, uint32 damage)
    {
        ++tally.swings;
        ++tally.results[std::size_t(result)];
        if (result == SwingResult::Normal)
            tally.normalDamage += damage;
    }

    inline float AverageNormalHit(SwingTally const& tally)
    {
        uint32 const normalSwings = tally.results[std::size_t(SwingResult::Normal)];
        if (normalSwings == 0)
            return 0.0f;
        return float(tally.normalDamage) / float(normalSwings);
    }
}

#endif
