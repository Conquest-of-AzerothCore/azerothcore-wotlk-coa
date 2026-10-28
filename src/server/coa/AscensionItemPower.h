/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_ITEM_POWER_H
#define COA_ASCENSION_ITEM_POWER_H

#include "AscensionItemPowerTable.h"
#include "AscensionPvePowerPolicy.h"
#include "AscensionPvpPowerPolicy.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "Player.h"
#include <algorithm>

namespace AscensionItemPower
{
constexpr uint32 EquippedCap = 495;

[[nodiscard]] inline uint32 OfItem(ItemTemplate const* proto, bool pvp)
{
    ItemPowerTable::Table const& table = ItemPowerTable::Loaded();
    if (uint32 const authored = pvp ? table.Pvp(proto->ItemId) : table.Pve(proto->ItemId))
        return authored;

    uint32 power = 0;
    for (auto const& effect : proto->Spells)
        if (effect.SpellTrigger == ITEM_SPELLTRIGGER_ON_EQUIP)
            power += pvp ? PvpPower::SpellPower(effect.SpellId) : PvePower::SpellPower(effect.SpellId);
    return power;
}

[[nodiscard]] inline uint32 EquippedPvE(Player const* player)
{
    uint32 power = 0;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item const* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            power += OfItem(item->GetTemplate(), false);
    return std::min(power, EquippedCap);
}
}

#endif
