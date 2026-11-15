/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_ASCENSION_GUARDIAN_TRAVEL_POLICY_H
#define COA_ASCENSION_GUARDIAN_TRAVEL_POLICY_H

#include <cstdint>
#include <vector>

namespace GuardianTravel
{
constexpr std::uint32_t ExplodingNecromancerKinds[] = {50133, 50303};
constexpr std::uint32_t NecromancerFollowerProperties = 61;
constexpr std::uint32_t MinimumRemainingMs = 1500;
constexpr std::uint32_t ArrivalWaitMs = 120000;
constexpr float ArrivalRadius = 15.0f;
constexpr float NearEnough = 20.0f;
constexpr float FarTeleport = 100.0f;

constexpr std::uint32_t TypeTimedOrDead = 1;
constexpr std::uint32_t TypeTimedOrCorpse = 2;
constexpr std::uint32_t TypeTimed = 3;
constexpr std::uint32_t TypeTimedOutOfCombat = 4;
constexpr std::uint32_t TypeCorpseTimed = 6;
constexpr std::uint32_t TypeDead = 7;
constexpr std::uint32_t TypeDespawned = 9;
constexpr std::uint32_t TypeTimedOutOfCombatAlive = 10;

enum class Timer : std::uint8_t
{
    None,
    Countdown,
    Delay
};

constexpr Timer TimerOf(std::uint32_t type)
{
    switch (type)
    {
        case TypeTimedOrDead:
        case TypeTimedOrCorpse:
        case TypeTimed:
        case TypeTimedOutOfCombat:
        case TypeTimedOutOfCombatAlive:
            return Timer::Countdown;
        case TypeCorpseTimed:
            return Timer::Delay;
        default:
            return Timer::None;
    }
}

constexpr bool OnItsWayOut(std::uint32_t type)
{
    return type == TypeDespawned || type == 0 || type > TypeTimedOutOfCombatAlive;
}

constexpr std::uint32_t CopyType(std::uint32_t recorded, std::uint32_t lifetime)
{
    if (OnItsWayOut(recorded))
        return lifetime ? TypeTimed : TypeDead;
    if (TimerOf(recorded) != Timer::None && !lifetime)
        return TypeDead;
    return recorded;
}

struct Candidate
{
    std::uint32_t Entry = 0;
    std::uint32_t Properties = 0;
    bool Alive = false;
    bool Owned = false;
    bool Leaving = false;
    std::uint32_t Type = TypeDead;
    std::uint32_t RemainingMs = 0;
    bool Necromancer = false;
    bool Follows = true;
    bool Walks = false;
    bool Hidden = false;
};

constexpr bool StaysBehind(std::uint32_t entry)
{
    for (std::uint32_t kind : ExplodingNecromancerKinds)
        if (kind == entry)
            return true;
    return false;
}

constexpr bool Travels(Candidate const& guardian)
{
    bool const row = guardian.Necromancer ? guardian.Properties == NecromancerFollowerProperties :
        guardian.Properties != 0;
    return guardian.Alive && guardian.Owned && !guardian.Leaving && !OnItsWayOut(guardian.Type) &&
        !guardian.Hidden && row && guardian.Follows && !StaysBehind(guardian.Entry) &&
        (guardian.Necromancer || guardian.Walks) &&
        (TimerOf(guardian.Type) != Timer::Countdown || guardian.RemainingMs >= MinimumRemainingMs);
}

constexpr bool CarryFor(bool otherMap, float distance2d, bool battlegroundOrArena)
{
    return !battlegroundOrArena && (otherMap || distance2d > FarTeleport);
}

enum class Arrival : std::uint8_t
{
    Wait,
    Restore,
    Drop
};

constexpr Arrival Check(bool inWorld, bool teleporting, bool atDestinationMap, float distance,
                        std::uint32_t waitedMs)
{
    if (!inWorld || teleporting)
        return waitedMs > ArrivalWaitMs ? Arrival::Drop : Arrival::Wait;
    if (!atDestinationMap || distance > ArrivalRadius)
        return Arrival::Drop;
    return Arrival::Restore;
}

enum class Step : std::uint8_t
{
    Keep,
    Move,
    Recreate,
    Skip
};

constexpr Step Plan(bool worldChanged, bool present, float distance, bool allowed)
{
    if (worldChanged)
        return allowed ? Step::Recreate : Step::Skip;
    if (!present)
        return Step::Skip;
    return distance > NearEnough ? Step::Move : Step::Keep;
}

struct Kind
{
    std::uint32_t Entry = 0;
    std::uint32_t Spell = 0;
};

inline std::vector<bool> Shortfall(std::vector<Kind> const& carried, std::vector<Kind> present)
{
    std::vector<bool> make;
    make.reserve(carried.size());
    for (Kind const& kind : carried)
    {
        bool found = false;
        for (auto it = present.begin(); it != present.end(); ++it)
            if (it->Entry == kind.Entry && it->Spell == kind.Spell)
            {
                present.erase(it);
                found = true;
                break;
            }
        make.push_back(!found);
    }
    return make;
}

constexpr bool TimeLeft(std::uint32_t type, std::uint32_t remainingMs, std::uint32_t elapsedMs,
                        std::uint32_t& left)
{
    left = 0;
    switch (TimerOf(type))
    {
        case Timer::None:
            return true;
        case Timer::Delay:
            left = remainingMs;
            return true;
        case Timer::Countdown:
            if (remainingMs < elapsedMs || remainingMs - elapsedMs < MinimumRemainingMs)
                return false;
            left = remainingMs - elapsedMs;
            return true;
    }
    return false;
}
}

#endif
