/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_NIGHTMARE_DAMAGE_TAKEN_POLICY_H
#define COA_ASCENSION_NIGHTMARE_DAMAGE_TAKEN_POLICY_H

#include <algorithm>
#include <array>
#include <cstdint>
#include <optional>

namespace NightmareDamageTaken
{
constexpr std::array<std::uint32_t, 8> LevelScaledAuras = {
    93132, 93133, 93135, 93136, 93150, 93159, 93196, 900930 };

constexpr std::int32_t PhysicalSchoolMask = 1;
constexpr std::int32_t MagicSchoolMask = 126;
constexpr std::int32_t PhysicalBasePoints = 299;
constexpr std::int32_t MagicBasePoints = 499;

struct DamageTakenEffect
{
    std::int32_t basePoints;
    float realPointsPerLevel;
    std::int32_t schoolMask;
};

inline bool IsLevelScaledAura(std::uint32_t spellId)
{
    return std::find(LevelScaledAuras.begin(), LevelScaledAuras.end(), spellId) != LevelScaledAuras.end();
}

inline std::optional<std::int32_t> FlatBasePoints(std::uint32_t spellId, DamageTakenEffect const& effect)
{
    if (!IsLevelScaledAura(spellId) || effect.realPointsPerLevel == 0.0f)
        return std::nullopt;
    if (effect.schoolMask == PhysicalSchoolMask)
        return PhysicalBasePoints;
    if (effect.schoolMask == MagicSchoolMask)
        return MagicBasePoints;
    return std::nullopt;
}
}

#endif
