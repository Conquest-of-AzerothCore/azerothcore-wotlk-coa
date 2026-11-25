/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "QuestLogExtended.h"

namespace QuestLogExtended
{
std::optional<Hello> ParseHello(WorldPacket const& packet)
{
    if (packet.size() < 2)
        return std::nullopt;

    Hello hello{ packet.read<uint8>(0), packet.read<uint8>(1) };
    if (hello.Version != Version || hello.ClientMaxSlots < NATIVE_QUEST_LOG_SIZE)
        return std::nullopt;

    return hello;
}

WorldPacket BuildState(std::vector<Entry> const& entries, uint8 logSize, bool full)
{
    WorldPacket data(StateOpcode, 4 + entries.size() * 29);
    data << Version << uint8(full ? FlagFull : 0) << logSize << uint8(entries.size());
    for (Entry const& entry : entries)
    {
        data << entry.Slot << entry.QuestId << entry.State;
        for (uint16 counter : entry.Counters)
            data << counter;
        data << entry.Time << entry.Level << entry.RewardXP;
    }

    return data;
}

std::vector<Entry> Snapshot(QuestLogSlots const& slots,
    std::function<std::pair<uint32, uint32>(uint32 questId)> levelAndXp)
{
    std::vector<Entry> entries;
    for (uint16 slot = NATIVE_QUEST_LOG_SIZE; slot < MAX_QUEST_LOG_SIZE; ++slot)
    {
        QuestLogSlot const& source = slots[slot];
        if (!source.QuestId)
            continue;

        auto const [level, rewardXP] = levelAndXp(source.QuestId);
        Entry entry{ uint8(slot), source.QuestId, source.State, {}, source.Time, level, rewardXP };
        for (uint8 i = 0; i < 4; ++i)
            entry.Counters[i] = uint16(source.Counters >> (i * 16));

        entries.push_back(entry);
    }

    return entries;
}
}
