/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCacheRewards.h"
#include "Bag.h"
#include "Chat.h"
#include "Item.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include <algorithm>
#include <string>
#include <utility>

namespace AscensionCacheRewards
{
namespace
{
bool IsVisiblePosition(uint8 bag, uint8 slot)
{
    if (bag == INVENTORY_SLOT_BAG_0)
        return slot >= INVENTORY_SLOT_ITEM_START && slot < INVENTORY_SLOT_ITEM_END;
    return bag >= INVENTORY_SLOT_BAG_START && bag < INVENTORY_SLOT_BAG_END;
}

bool FindVisibleDestination(Player* player, uint32 itemId, uint32 count, ItemPosCountVec& dest)
{
    for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        if (player->CanStoreItem(INVENTORY_SLOT_BAG_0, slot, dest, itemId, count) == EQUIP_ERR_OK)
            return true;

    for (uint8 bag = INVENTORY_SLOT_BAG_START; bag < INVENTORY_SLOT_BAG_END; ++bag)
    {
        Bag* container = player->GetBagByPos(bag);
        if (!container)
            continue;

        for (uint8 slot = 0; slot < container->GetBagSize(); ++slot)
            if (player->CanStoreItem(bag, slot, dest, itemId, count) == EQUIP_ERR_OK)
                return true;
    }

    return false;
}

InventoryResult StoreOne(Player* player, Reward const& reward, Item*& stored)
{
    if (!sObjectMgr->GetItemTemplate(reward.itemId))
        return EQUIP_ERR_ITEM_NOT_FOUND;

    ItemPosCountVec dest;
    if (!FindVisibleDestination(player, reward.itemId, reward.count, dest))
        return EQUIP_ERR_INVENTORY_FULL;

    stored = player->StoreNewItem(dest, reward.itemId, true, reward.randomPropertyId);
    if (!stored || !IsVisiblePosition(stored->GetBagSlot(), stored->GetSlot()))
        return EQUIP_ERR_INVENTORY_FULL;

    return EQUIP_ERR_OK;
}

bool PostOne(Player* player, Reward const& reward)
{
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(reward.itemId);
    if (!proto)
        return false;

    uint32 remaining = reward.count;
    uint32 const perStack = std::max<uint32>(1, proto->GetMaxStackSize());
    while (remaining)
    {
        uint32 const chunk = std::min<uint32>(remaining, perStack);
        Item* posted = Item::CreateItem(reward.itemId, chunk, player, false, reward.randomPropertyId);
        if (!posted)
            return false;

        player->SendItemRetrievalMail(posted);
        remaining -= chunk;
    }

    return true;
}

void UndoOne(Player* player, Item* item, uint32 count)
{
    if (item->GetCount() > count)
    {
        item->SetCount(item->GetCount() - count);
        item->SetState(ITEM_CHANGED, player);
        return;
    }

    player->DestroyItem(item->GetBagSlot(), item->GetSlot(), true);
}
}

bool Deliver(Player* player, std::vector<Reward> const& rewards, Item* cache)
{
    if (rewards.empty())
        return false;

    for (Reward const& reward : rewards)
        if (!reward.count || !sObjectMgr->GetItemTemplate(reward.itemId))
        {
            LOG_ERROR("coa",
                "cache {} has reward {} x{}, which is not a valid item; cache kept",
                cache ? cache->GetEntry() : 0, reward.itemId, reward.count);
            return false;
        }

    std::vector<std::pair<Item*, uint32>> stored;
    stored.reserve(rewards.size());
    std::vector<Reward> posted;

    for (Reward const& reward : rewards)
    {
        uint32 held = player->GetItemCount(reward.itemId);
        Item* item = nullptr;
        InventoryResult result = StoreOne(player, reward, item);
        if (result == EQUIP_ERR_OK && player->GetItemCount(reward.itemId) < held + reward.count)
            result = EQUIP_ERR_INVENTORY_FULL;

        if (result == EQUIP_ERR_OK)
        {
            stored.emplace_back(item, reward.count);
            continue;
        }

        if (item)
            UndoOne(player, item, reward.count);
        posted.push_back(reward);
    }

    for (Reward const& reward : posted)
        if (!PostOne(player, reward))
        {
            for (auto const& given : stored)
                UndoOne(player, given.first, given.second);
            LOG_ERROR("coa",
                "cache {} reward {} x{} could not be taken by the bags or posted to {}; cache kept",
                cache ? cache->GetEntry() : 0, reward.itemId, reward.count,
                player->GetGUID().ToString());
            return false;
        }

    for (auto const& given : stored)
        player->SendNewItem(given.first, given.second, true, false, false);

    if (!posted.empty())
    {
        std::string message = "Your bags were full, so your reward was sent to your mailbox.";
        if (posted.size() > 1)
            message = "Your bags were full, so all " + std::to_string(posted.size()) +
                " of your rewards were sent to your mailbox.";
        ChatHandler handler(player->GetSession());
        handler.SendSysMessage(message);
        handler.SendNotification(message);

        LOG_DEBUG("coa",
            "cache {} posted {} reward(s) to {} because the bags were full",
            cache ? cache->GetEntry() : 0, uint32(posted.size()), player->GetGUID().ToString());
    }

    uint32 count = 1;
    player->DestroyItemCount(cache, count, true);
    return true;
}
}
