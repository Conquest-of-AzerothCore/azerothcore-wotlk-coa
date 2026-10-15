/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */
#ifndef ASCENSION_MANASTORM_PROTOCOL_H
#define ASCENSION_MANASTORM_PROTOCOL_H

#include <array>
#include <cstdint>
#include <vector>

namespace Ascension::Manastorm
{
    enum Opcode : std::uint16_t
    {
        Enter = 0x651, EnterResult = 0x652, ProgressUpdate = 0x65D,
        CompletedLevel = 0x65E, Data = 0x65F, ActiveData = 0x660,
        Leave = 0x665, LeaveResult = 0x666, Fail = 0x67B,
        ChaoticLink = 0x67F, LoadoutData = 0x688, SetSlot = 0x689,
        SetSlotResult = 0x68A, UpdateSlot = 0x68B
    };

    inline constexpr std::array<char const*, 8> Types = {
        "SOLO", "DUO", "TRIO", "GROUP", "SOLO_END_GAME", "DUO_END_GAME", "TRIO_END_GAME", "GROUP_END_GAME"
    };
    using Progress = std::array<std::vector<std::uint32_t>, 8>;

    template<class Buffer>
    void WriteProgress(Buffer& packet, Progress const& progress)
    {
        packet << std::uint32_t(progress.size());
        for (auto const& levels : progress)
        {
            packet << std::uint32_t(levels.size());
            for (std::uint32_t level : levels)
                packet << level;
        }
    }

    template<class Buffer>
    void WriteActive(Buffer& packet, std::uint32_t depth, std::uint32_t scene, std::uint8_t type,
        std::uint32_t caches = 0, float chance = 0, std::uint32_t item = 0)
    {
        packet << depth << scene << Types.at(type) << caches << chance << item;
    }
}

#endif
