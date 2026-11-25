/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef QUEST_LOG_EXTENDED_H
#define QUEST_LOG_EXTENDED_H

#include "Define.h"
#include "QuestLogSlots.h"
#include "WorldPacket.h"

#include <functional>
#include <optional>
#include <utility>
#include <vector>

namespace QuestLogExtended
{
constexpr uint16 HelloOpcode = 0x8F6;
constexpr uint16 StateOpcode = 0x8F7;
constexpr uint8 Version = 1;
constexpr uint8 FlagFull = 0x01;

struct Entry
{
    uint8 Slot;
    uint32 QuestId;
    uint32 State;
    uint16 Counters[4];
    uint32 Time;
    uint32 Level;
    uint32 RewardXP;
};

struct Hello
{
    uint8 Version;
    uint8 ClientMaxSlots;
};

[[nodiscard]] std::optional<Hello> ParseHello(WorldPacket const& packet);
[[nodiscard]] WorldPacket BuildState(std::vector<Entry> const& entries, uint8 logSize, bool full);
[[nodiscard]] std::vector<Entry> Snapshot(QuestLogSlots const& slots,
    std::function<std::pair<uint32, uint32>(uint32 questId)> levelAndXp);
}

#endif
