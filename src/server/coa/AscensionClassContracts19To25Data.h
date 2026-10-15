/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_CLASS_CONTRACTS_19_TO_25_DATA_H
#define ASCENSION_CLASS_CONTRACTS_19_TO_25_DATA_H

#include <array>
#include <cstdint>

namespace AscensionContracts19To25
{
enum class ResourceEvent : std::uint8_t
{
    Cast,
    EachCriticalDamagingHit,
    EachSuccessfulDamagingHit,
    FirstSuccessfulHostileTarget,
    PeriodicDamageTick,
};

enum class ResourceAction : std::uint8_t
{
    Keep,
    ChangeEvent,
    Delete,
    Add
};

struct ResourceRule
{
    std::uint8_t ClassId;
    std::uint32_t FirstSpellId;
    std::uint32_t LastSpellId;
    std::uint32_t ResourceId;
    std::int16_t Amount;
    ResourceEvent Event;
    std::uint32_t RequiredAuraId;
    std::uint32_t ForbiddenAuraId;
    ResourceAction Action;
};

inline constexpr std::array<ResourceRule, 26>
    CurrentResourceRuleDecisions =
{{
    {24, 502020, 502031, 807389, 10, ResourceEvent::PeriodicDamageTick, 0, 0, ResourceAction::ChangeEvent},
    {24, 800791, 800791, 807389, 10, ResourceEvent::PeriodicDamageTick, 0, 0, ResourceAction::ChangeEvent},
    {24, 801905, 801905, 807389, 10, ResourceEvent::EachSuccessfulDamagingHit, 0, 0, ResourceAction::ChangeEvent},
    {24, 502107, 502113, 807389, 30, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {24, 802107, 802107, 807389, 30, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {24, 504380, 504380, 807389, 30, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {24, 500135, 500135, 807389, 50, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {24, 502055, 502056, 807389, 50, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {24, 800816, 800816, 807389, 50, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {24, 805477, 805477, 807389, 50, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {24, 807620, 807623, 807389, 50, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 500714, 500714, 500706, 10, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 502235, 502243, 500706, 10, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 502213, 502220, 500706, 10, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 800446, 800446, 500706, 10, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 560109, 560109, 500706, 10, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 578263, 578263, 500706, 10, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 806222, 806222, 500706, 10, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 806825, 806828, 500706, 10, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 805572, 805572, 500706, 10, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 806893, 806897, 500706, 10, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 807969, 807969, 500706, 10, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 500720, 500720, 500706, 20, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 800416, 800416, 500706, 10, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 500712, 500712, 500706, 20, ResourceEvent::Cast, 0, 0, ResourceAction::Keep},
    {25, 800429, 800429, 500706, 15, ResourceEvent::Cast, 0, 0, ResourceAction::Delete},
}};

inline constexpr std::array<ResourceRule, 21>
    TableReadyResourceAdditions =
{{
    {24, 800790, 800790, 807389, 20, ResourceEvent::Cast, 0, 0, ResourceAction::Add},
    {24, 502011, 502019, 807389, 20, ResourceEvent::Cast, 0, 0, ResourceAction::Add},
    {24, 800806, 800806, 807389, 30, ResourceEvent::Cast, 0, 0, ResourceAction::Add},
    {24, 502044, 502052, 807389, 30, ResourceEvent::Cast, 0, 0, ResourceAction::Add},
    {24, 800806, 800806, 807389, 30, ResourceEvent::Cast, 804230, 0, ResourceAction::Add},
    {24, 502044, 502052, 807389, 30, ResourceEvent::Cast, 804230, 0, ResourceAction::Add},
    {24, 805496, 805496, 807389, 20, ResourceEvent::EachSuccessfulDamagingHit, 0, 0, ResourceAction::Add},
    {24, 807406, 807410, 807389, 20, ResourceEvent::EachSuccessfulDamagingHit, 0, 0, ResourceAction::Add},
    {24, 806611, 806611, 807389, 10, ResourceEvent::EachSuccessfulDamagingHit, 504754, 0, ResourceAction::Add},
    {24, 807615, 807619, 807389, 10, ResourceEvent::EachSuccessfulDamagingHit, 504754, 0, ResourceAction::Add},
    {23, 704355, 704355, 6, 200, ResourceEvent::FirstSuccessfulHostileTarget, 704680, 0, ResourceAction::Add},
    {23, 707399, 707402, 6, 200, ResourceEvent::FirstSuccessfulHostileTarget, 704680, 0, ResourceAction::Add},
    {23, 707911, 707911, 6, 200, ResourceEvent::FirstSuccessfulHostileTarget, 704680, 0, ResourceAction::Add},
    {25, 500110, 500110, 500706, 10, ResourceEvent::Cast, 807512, 0, ResourceAction::Add},
    {25, 502135, 502143, 500706, 10, ResourceEvent::Cast, 807512, 0, ResourceAction::Add},
    {25, 805116, 805116, 500706, 10, ResourceEvent::EachCriticalDamagingHit, 301180, 0, ResourceAction::Add},
    {25, 806498, 806499, 500706, 10, ResourceEvent::EachCriticalDamagingHit, 301180, 0, ResourceAction::Add},
    {25, 806829, 806833, 500706, 10, ResourceEvent::EachCriticalDamagingHit, 301180, 0, ResourceAction::Add},
    {25, 503487, 503488, 500706, 3, ResourceEvent::EachSuccessfulDamagingHit, 681087, 0, ResourceAction::Add},
    {25, 524876, 524876, 500706, 3, ResourceEvent::EachSuccessfulDamagingHit, 681087, 0, ResourceAction::Add},
    {25, 804208, 804208, 500706, 3, ResourceEvent::EachSuccessfulDamagingHit, 681087, 0, ResourceAction::Add},
}};
}

#endif
