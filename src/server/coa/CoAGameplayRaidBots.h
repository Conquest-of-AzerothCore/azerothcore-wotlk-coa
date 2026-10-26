/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_GAMEPLAY_RAID_BOTS_H
#define COA_GAMEPLAY_RAID_BOTS_H

#include "CoARotationAssist.h"
#include "Define.h"
#include "ObjectGuid.h"
#include <functional>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace CoAGameplay
{
    enum class RaidRole : uint8
    {
        None,
        Tank,
        Healer,
        Melee,
        Ranged
    };

    enum class RaidSpellSource : uint8
    {
        Scenario,
        RotationAssist
    };

    constexpr float RaidHealThresholdPct = 90.0f;
    constexpr float RaidHealRange = 40.0f;
    constexpr float RaidRangedDistance = 30.0f;
    constexpr float RaidTankThreatFactor = 1.1f;
    constexpr float RaidTankThreatMargin = 100.0f;

    struct HealCandidate
    {
        ObjectGuid guid;
        bool alive{false};
        float healthPct{0.0f};
        float distance{0.0f};
    };

    RaidRole RaidRoleFromName(std::string_view name);
    std::optional<ObjectGuid> SelectHealTarget(std::vector<HealCandidate> const& members, float thresholdPct,
        float maxRange);
    bool ShouldTaunt(bool bossTargetsTank, bool tauntReady);
    bool RoleMayAct(RaidRole role, bool bossTargetsTank);
    bool ActsInTankPass(RaidRole role);
    float ThreatFloor(float highestOther);
    float TankThreatRaise(float tankThreat, float highestOther);
    std::optional<uint32> NextRotationSpell(std::vector<uint32> const& rotation,
        std::function<bool(uint32)> const& canCast);
    RaidSpellSource SpellSourceFor(bool rotationAssist, uint32 specialization,
        std::span<CoARotationAssist::Rule const> rules);
    std::optional<uint32> NextRaidSpell(RaidSpellSource source, std::function<uint32()> const& rotationChoice,
        std::vector<uint32> const& scenarioSpells, std::function<bool(uint32)> const& canCast);
}

#endif
