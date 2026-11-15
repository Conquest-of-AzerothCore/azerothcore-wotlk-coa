/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef QUEST_LOG_SLOTS_H
#define QUEST_LOG_SLOTS_H

#include "Define.h"
#include "QuestDef.h"

#include <array>
#include <optional>

struct QuestLogSlot
{
    uint32 QuestId = 0;
    uint32 State = 0;
    uint64 Counters = 0;
    uint32 Time = 0;
    uint64 LastProgress = 0;
};

struct QuestLogMove
{
    uint16 From;
    uint16 To;
};

class QuestLogSlots
{
public:
    [[nodiscard]] QuestLogSlot const& operator[](uint16 slot) const { return _slots[slot]; }
    [[nodiscard]] QuestLogSlot& operator[](uint16 slot) { return _slots[slot]; }

    [[nodiscard]] uint16 Find(uint32 questId, uint16 searchedSlots) const
    {
        for (uint16 slot = 0; slot < searchedSlots && slot < MAX_QUEST_LOG_SIZE; ++slot)
            if (_slots[slot].QuestId == questId)
                return slot;

        return MAX_QUEST_LOG_SIZE;
    }

    [[nodiscard]] std::optional<QuestLogMove> NextPromotion() const
    {
        uint16 const freeNative = Find(0, NATIVE_QUEST_LOG_SIZE);
        if (freeNative == MAX_QUEST_LOG_SIZE)
            return std::nullopt;

        for (uint16 slot = NATIVE_QUEST_LOG_SIZE; slot < MAX_QUEST_LOG_SIZE; ++slot)
            if (_slots[slot].QuestId)
                return QuestLogMove{ slot, freeNative };

        return std::nullopt;
    }

    template <typename StaysNative>
    [[nodiscard]] uint16 IdlestNative(StaysNative staysNative) const
    {
        uint16 idlest = MAX_QUEST_LOG_SIZE;
        for (uint16 slot = 0; slot < NATIVE_QUEST_LOG_SIZE; ++slot)
        {
            QuestLogSlot const& candidate = _slots[slot];
            if (!candidate.QuestId || staysNative(candidate.QuestId))
                continue;

            if (idlest == MAX_QUEST_LOG_SIZE || candidate.LastProgress < _slots[idlest].LastProgress)
                idlest = slot;
        }

        return idlest;
    }

    [[nodiscard]] bool HasOverflow() const
    {
        for (uint16 slot = NATIVE_QUEST_LOG_SIZE; slot < MAX_QUEST_LOG_SIZE; ++slot)
            if (_slots[slot].QuestId)
                return true;

        return false;
    }

private:
    std::array<QuestLogSlot, MAX_QUEST_LOG_SIZE> _slots{};
};

#endif
