/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "QuestLogSlots.h"
#include "gtest/gtest.h"

namespace
{
QuestLogSlots FullNativeLog()
{
    QuestLogSlots slots;
    for (uint16 slot = 0; slot < NATIVE_QUEST_LOG_SIZE; ++slot)
    {
        slots[slot].QuestId = 1000 + slot;
        slots[slot].LastProgress = 500 + slot;
    }

    return slots;
}

bool NothingStaysNative(uint32)
{
    return false;
}
}

TEST(QuestLogSlots, FreeSlotSearchStopsAtTheGivenCapacity)
{
    QuestLogSlots slots = FullNativeLog();

    EXPECT_EQ(slots.Find(0, NATIVE_QUEST_LOG_SIZE), MAX_QUEST_LOG_SIZE);
    EXPECT_EQ(slots.Find(0, MAX_QUEST_LOG_SIZE), NATIVE_QUEST_LOG_SIZE);
}

TEST(QuestLogSlots, QuestSearchCoversOverflowSlots)
{
    QuestLogSlots slots = FullNativeLog();
    slots[40].QuestId = 7;

    EXPECT_EQ(slots.Find(7, MAX_QUEST_LOG_SIZE), 40);
    EXPECT_TRUE(slots.HasOverflow());
}

TEST(QuestLogSlots, NoPromotionWhileTheNativeLogIsFull)
{
    QuestLogSlots slots = FullNativeLog();
    slots[30].QuestId = 7;

    EXPECT_FALSE(slots.NextPromotion().has_value());
}

TEST(QuestLogSlots, FirstOverflowQuestFillsTheFirstFreeNativeSlot)
{
    QuestLogSlots slots = FullNativeLog();
    slots[3].QuestId = 0;
    slots[10].QuestId = 0;
    slots[33].QuestId = 8;
    slots[30].QuestId = 7;

    std::optional<QuestLogMove> const move = slots.NextPromotion();
    ASSERT_TRUE(move.has_value());
    EXPECT_EQ(move->From, 30);
    EXPECT_EQ(move->To, 3);
}

TEST(QuestLogSlots, NoPromotionWithoutOverflowQuests)
{
    QuestLogSlots slots = FullNativeLog();
    slots[3].QuestId = 0;

    EXPECT_FALSE(slots.NextPromotion().has_value());
    EXPECT_FALSE(slots.HasOverflow());
}

TEST(QuestLogSlots, IdlestNativeQuestHasTheOldestProgress)
{
    QuestLogSlots slots = FullNativeLog();
    slots[17].LastProgress = 10;

    EXPECT_EQ(slots.IdlestNative(NothingStaysNative), 17);
}

TEST(QuestLogSlots, PinnedQuestsAreNeverTheIdlest)
{
    QuestLogSlots slots = FullNativeLog();
    slots[17].LastProgress = 10;
    slots[4].LastProgress = 20;

    EXPECT_EQ(slots.IdlestNative([](uint32 questId) { return questId == 1017; }), 4);
}

TEST(QuestLogSlots, NoIdlestNativeQuestWhenAllArePinned)
{
    QuestLogSlots slots = FullNativeLog();

    EXPECT_EQ(slots.IdlestNative([](uint32) { return true; }), MAX_QUEST_LOG_SIZE);
}
