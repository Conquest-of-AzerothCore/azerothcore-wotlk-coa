/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_ITEM_POWER_H
#define COA_ASCENSION_ITEM_POWER_H

#include "Item.h"
#include "ItemTemplate.h"
#include "Player.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <algorithm>
#include <charconv>
#include <string_view>

namespace AscensionItemPower
{
constexpr uint32 MaxMarkerAmount = 1000;
constexpr uint32 EquippedCap = 495;

[[nodiscard]] inline uint32 OfItem(ItemTemplate const* proto, bool pvp)
{
    uint32 power = 0;
    std::string_view const prefix = pvp ? "PvP Power (+" : "PvE Power (+";
    for (auto const& effect : proto->Spells)
    {
        if (effect.SpellTrigger != ITEM_SPELLTRIGGER_ON_EQUIP)
            continue;

        SpellInfo const* spell = sSpellMgr->GetSpellInfo(effect.SpellId);
        if (!spell || !spell->SpellName[0])
            continue;

        std::string_view const name(spell->SpellName[0]);
        if (!name.starts_with(prefix) || !name.ends_with(')'))
            continue;

        uint32 amount = 0;
        char const* first = name.data() + prefix.size();
        char const* last = name.data() + name.size() - 1;
        auto const parsed = std::from_chars(first, last, amount);
        if (parsed.ec == std::errc() && parsed.ptr == last && amount <= MaxMarkerAmount)
            power += amount;
    }
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
