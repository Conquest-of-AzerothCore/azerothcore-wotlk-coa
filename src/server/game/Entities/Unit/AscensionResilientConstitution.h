/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_RESILIENT_CONSTITUTION_H
#define ASCENSION_RESILIENT_CONSTITUTION_H

#include <algorithm>
#include <atomic>
#include <cstdint>

namespace ResilientConstitution
{
constexpr std::uint32_t Aura = 552011;
constexpr std::uint32_t DefaultDamageReductionPct = 50;
constexpr std::uint32_t DefaultCriticalReductionPct = 20;
constexpr std::uint32_t DefaultPetSharePct = 85;

inline std::atomic<std::uint32_t> damageReductionPct{DefaultDamageReductionPct};
inline std::atomic<std::uint32_t> criticalReductionPct{DefaultCriticalReductionPct};
inline std::atomic<std::uint32_t> petSharePct{DefaultPetSharePct};

constexpr std::int32_t Apply(std::int32_t damage, bool critical, std::uint32_t damagePct,
    std::uint32_t criticalPct, std::uint32_t sharePct)
{
    if (damage <= 0)
        return damage;
    std::int64_t const share = std::min<std::uint32_t>(sharePct, 100);
    std::int64_t kept = std::int64_t(damage) * (10000 - std::min<std::uint32_t>(damagePct, 100) * share) / 10000;
    if (critical)
        kept = kept * (10000 - std::min<std::uint32_t>(criticalPct, 100) * share) / 10000;
    return std::int32_t(kept);
}

inline std::int32_t Reduce(std::int32_t damage, bool critical, bool pet)
{
    return Apply(damage, critical, damageReductionPct.load(std::memory_order_relaxed),
        criticalReductionPct.load(std::memory_order_relaxed), pet ? petSharePct.load(std::memory_order_relaxed) : 100);
}
}

#endif
