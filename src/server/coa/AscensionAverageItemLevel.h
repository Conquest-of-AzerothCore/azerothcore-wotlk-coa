/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_AVERAGE_ITEM_LEVEL_H
#define COA_ASCENSION_AVERAGE_ITEM_LEVEL_H

#include "Item.h"
#include "Player.h"

namespace AscensionAverageItemLevel
{
[[nodiscard]] inline float Equipped(Player const* player, uint8 emptiedSlot = EQUIPMENT_SLOT_END)
{
    float sum = 0.0f;
    uint32 count = 0;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        if (slot == EQUIPMENT_SLOT_TABARD || slot == EQUIPMENT_SLOT_RANGED || slot == EQUIPMENT_SLOT_OFFHAND ||
            slot == EQUIPMENT_SLOT_BODY)
            continue;

        ++count;
        if (Item const* item = slot == emptiedSlot ? nullptr : player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            sum += item->GetTemplate()->Quality == ITEM_QUALITY_HEIRLOOM ? player->GetLevel()
                                                                        : item->GetTemplate()->ItemLevel;
    }
    return sum / count;
}
}

#endif
