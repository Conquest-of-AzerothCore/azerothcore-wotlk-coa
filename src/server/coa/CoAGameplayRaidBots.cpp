/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAGameplayRaidBots.h"

namespace CoAGameplay
{
    RaidRole RaidRoleFromName(std::string_view name)
    {
        if (name == "tank")
            return RaidRole::Tank;
        if (name == "healer")
            return RaidRole::Healer;
        if (name == "melee")
            return RaidRole::Melee;
        if (name == "ranged")
            return RaidRole::Ranged;
        return RaidRole::None;
    }

    std::optional<ObjectGuid> SelectHealTarget(std::vector<HealCandidate> const& members, float thresholdPct,
        float maxRange)
    {
        HealCandidate const* lowest = nullptr;
        for (HealCandidate const& member : members)
            if (member.alive && member.distance <= maxRange && member.healthPct < thresholdPct &&
                (!lowest || member.healthPct < lowest->healthPct))
                lowest = &member;
        if (!lowest)
            return std::nullopt;
        return lowest->guid;
    }

    bool ShouldTaunt(bool bossTargetsTank, bool tauntReady)
    {
        return !bossTargetsTank && tauntReady;
    }

    std::optional<uint32> NextRotationSpell(std::vector<uint32> const& rotation,
        std::function<bool(uint32)> const& canCast)
    {
        for (uint32 spell : rotation)
            if (canCast(spell))
                return spell;
        return std::nullopt;
    }
}
