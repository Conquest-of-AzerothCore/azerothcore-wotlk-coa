/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_BATTLE_RESURRECTION_H
#define ASCENSION_BATTLE_RESURRECTION_H

#include <cstdint>

class Map;

namespace Ascension::BattleResurrection
{
constexpr std::uint32_t LargeRaidPlayers = 16;
constexpr std::uint32_t SmallRaidCharges = 2;
constexpr std::uint32_t LargeRaidCharges = 3;
constexpr std::uint32_t MythicPlusCharges = 1;

constexpr std::uint32_t RaidCharges(std::uint32_t players)
{
    return players >= LargeRaidPlayers ? LargeRaidCharges : SmallRaidCharges;
}

class Budget
{
public:
    void Start(std::uint32_t charges)
    {
        _total = charges;
        _remaining = charges;
    }

    [[nodiscard]] bool Available() const { return _remaining > 0; }

    bool Consume()
    {
        if (!_remaining)
            return false;

        --_remaining;
        return true;
    }

    [[nodiscard]] std::uint32_t Remaining() const { return _remaining; }
    [[nodiscard]] std::uint32_t Total() const { return _total; }

private:
    std::uint32_t _total = 0;
    std::uint32_t _remaining = 0;
};

void StartMythicPlusRun(Map* map);
}

#endif
