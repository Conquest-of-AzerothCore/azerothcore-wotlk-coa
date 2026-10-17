/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_AVERAGE_ITEM_LEVEL_H
#define COA_ASCENSION_AVERAGE_ITEM_LEVEL_H

#include "Item.h"
#include "Player.h"

namespace AscensionAverageItemLevel
{
[[nodiscard]] inline Item const* EquippedItem(Player const* player, uint8 slot, uint8 emptiedSlot)
{
    return slot == emptiedSlot ? nullptr : player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
}

[[nodiscard]] inline bool WieldsTwoHanderAlone(Player const* player, uint8 emptiedSlot)
{
    Item const* mainHand = EquippedItem(player, EQUIPMENT_SLOT_MAINHAND, emptiedSlot);
    return mainHand && mainHand->GetTemplate()->InventoryType == INVTYPE_2HWEAPON &&
           !EquippedItem(player, EQUIPMENT_SLOT_OFFHAND, emptiedSlot);
}

[[nodiscard]] inline float Equipped(Player const* player, uint8 emptiedSlot = EQUIPMENT_SLOT_END)
{
    bool const offHandHeldByTwoHander = WieldsTwoHanderAlone(player, emptiedSlot);
    float sum = 0.0f;
    uint32 count = 0;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        if (slot == EQUIPMENT_SLOT_TABARD || slot == EQUIPMENT_SLOT_BODY ||
            (slot == EQUIPMENT_SLOT_OFFHAND && offHandHeldByTwoHander))
            continue;

        ++count;
        if (Item const* item = EquippedItem(player, slot, emptiedSlot))
            if (item->GetTemplate()->Quality != ITEM_QUALITY_HEIRLOOM)
                sum += item->GetTemplate()->ItemLevel;
    }
    return sum / count;
}
}

#endif
