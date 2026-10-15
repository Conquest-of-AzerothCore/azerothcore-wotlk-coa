/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_CLASS_CONTRACTS_26_TO_32_DATA_H
#define ASCENSION_CLASS_CONTRACTS_26_TO_32_DATA_H

#include <array>
#include <cstdint>

namespace AscensionContracts26To32
{
enum class ResourceEvent : std::uint8_t
{
    Cast,
    FirstCriticalDamagingHit,
    FirstSuccessfulDamagingHit,
    FirstSuccessfulHostileTarget,
    PeriodicDamageTick,
};

enum class Mutation : std::uint8_t
{
    AuraStacks,
    NativeRunicPowerInternal,
    TriggerSpell,
};

struct ResourceRule
{
    std::uint8_t ClassId;
    std::uint32_t FirstSpellId;
    std::uint32_t LastSpellId;
    std::uint32_t ResourceId;
    std::int16_t Amount;
    ResourceEvent Event;
    Mutation ResourceMutation;
    std::uint32_t RequiredAuraId;
    std::uint8_t ChancePercent;
};

inline constexpr std::array<ResourceRule, 16> CurrentResourceRuleDecisions =
{{
    {28, 504527, 504527, 801816, 10, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {28, 504589, 504593, 801816, 10, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {28, 572888, 572888, 801816, 10, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 500357, 500357, 805077, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 500357, 500357, 355461, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::TriggerSpell, 0, 100},
    {30, 801328, 801328, 355461, 1, ResourceEvent::FirstSuccessfulHostileTarget, Mutation::TriggerSpell, 0, 100},
    {30, 803834, 803839, 355461, 1, ResourceEvent::FirstSuccessfulHostileTarget, Mutation::TriggerSpell, 0, 100},
    {30, 803992, 803992, 500363, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 503286, 503289, 500363, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 503324, 503324, 500363, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 503531, 503531, 500363, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 805258, 805258, 500363, 3, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 806818, 806824, 500363, 3, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 805185, 805185, 500363, 1, ResourceEvent::Cast, Mutation::AuraStacks, 0, 100},
    {30, 801624, 801624, 6, 200, ResourceEvent::FirstSuccessfulHostileTarget, Mutation::NativeRunicPowerInternal, 0, 100},
    {30, 802422, 802428, 6, 200, ResourceEvent::FirstSuccessfulHostileTarget, Mutation::NativeRunicPowerInternal, 0, 100},
}};

inline constexpr std::array<ResourceRule, 29> TableReadyResourceAdditions =
{{
    {30, 504056, 504058, 805077, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 504056, 504058, 355461, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::TriggerSpell, 0, 100},
    {30, 504557, 504557, 805077, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 504557, 504557, 355461, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::TriggerSpell, 0, 100},
    {30, 505151, 505151, 805077, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 505151, 505151, 355461, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::TriggerSpell, 0, 100},
    {30, 573302, 573303, 805077, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 573302, 573303, 355461, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::TriggerSpell, 0, 100},
    {30, 500376, 500376, 805077, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 500376, 500376, 500363, 1, ResourceEvent::FirstCriticalDamagingHit, Mutation::AuraStacks, 520056, 100},
    {30, 502679, 502684, 805077, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 502679, 502684, 500363, 1, ResourceEvent::FirstCriticalDamagingHit, Mutation::AuraStacks, 520056, 100},
    {30, 504622, 504622, 805077, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {30, 504622, 504622, 500363, 1, ResourceEvent::FirstCriticalDamagingHit, Mutation::AuraStacks, 520056, 100},
    {30, 801624, 801624, 500363, 1, ResourceEvent::Cast, Mutation::AuraStacks, 560412, 100},
    {30, 802422, 802428, 500363, 1, ResourceEvent::Cast, Mutation::AuraStacks, 560412, 100},
    {30, 800172, 800172, 500363, 1, ResourceEvent::FirstCriticalDamagingHit, Mutation::AuraStacks, 704552, 100},
    {30, 502668, 502671, 500363, 1, ResourceEvent::FirstCriticalDamagingHit, Mutation::AuraStacks, 704552, 100},
    {30, 567531, 567532, 500363, 1, ResourceEvent::FirstCriticalDamagingHit, Mutation::AuraStacks, 704552, 100},
    {29, 800880, 800880, 804972, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 807600, 100},
    {29, 502896, 502904, 804972, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 807600, 100},
    {29, 800882, 800882, 804972, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {29, 502905, 502911, 804972, 1, ResourceEvent::FirstSuccessfulDamagingHit, Mutation::AuraStacks, 0, 100},
    {29, 706962, 706962, 804972, 1, ResourceEvent::FirstSuccessfulHostileTarget, Mutation::AuraStacks, 0, 100},
    {29, 707084, 707090, 804972, 1, ResourceEvent::FirstSuccessfulHostileTarget, Mutation::AuraStacks, 0, 100},
    {29, 0, 0, 804972, 1, ResourceEvent::PeriodicDamageTick, Mutation::AuraStacks, 706036, 10},
    {31, 680442, 680442, 680441, 2, ResourceEvent::Cast, Mutation::AuraStacks, 92149, 100},
    {31, 681114, 681117, 680441, 2, ResourceEvent::Cast, Mutation::AuraStacks, 92149, 100},
    {31, 807432, 807432, 680441, 1, ResourceEvent::Cast, Mutation::AuraStacks, 92149, 100},
}};
}

#endif
