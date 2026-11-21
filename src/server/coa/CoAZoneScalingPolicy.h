/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_ZONE_SCALING_POLICY_H
#define COA_ZONE_SCALING_POLICY_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>

namespace ZoneScaling
{
struct Definition
{
    std::uint32_t zone = 0;
    std::uint32_t map = 0;
    std::uint32_t order = 0;
    float healthStep = 0.2f;
    float damageStep = 0.2f;
};

struct Budget
{
    std::uint8_t level = 60;
    std::uint32_t health = 100000;
    float melee = 1.0f;
    float spell = 1.0f;
};

inline bool Valid(Definition const& zone)
{
    return zone.zone && std::isfinite(zone.healthStep) && std::isfinite(zone.damageStep) &&
        zone.healthStep >= 0.0f && zone.damageStep >= 0.0f &&
        1.0 + double(zone.order) * zone.healthStep <= std::numeric_limits<float>::max() &&
        1.0 + double(zone.order) * zone.damageStep <= std::numeric_limits<float>::max();
}

inline bool Valid(Budget const& budget)
{
    return budget.level && budget.level <= 63 && budget.health && std::isfinite(budget.melee) &&
        std::isfinite(budget.spell) && budget.melee > 0.0f && budget.spell > 0.0f;
}

inline float Factor(std::uint32_t order, float step)
{
    return 1.0f + float(order) * step;
}

inline std::uint32_t Health(Definition const& zone, Budget const& budget)
{
    double const value = double(budget.health) * Factor(zone.order, zone.healthStep);
    return std::uint32_t(std::clamp(std::round(value), 1.0, double(std::numeric_limits<std::uint32_t>::max())));
}

inline float Melee(Definition const& zone, Budget const& budget)
{
    return budget.melee * Factor(zone.order, zone.damageStep);
}

inline float Spell(Definition const& zone, Budget const& budget)
{
    return budget.spell * Factor(zone.order, zone.damageStep);
}
}

#endif
