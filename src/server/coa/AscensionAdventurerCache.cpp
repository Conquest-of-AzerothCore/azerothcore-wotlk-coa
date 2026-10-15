/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCacheRewards.h"
#include "AscensionSpecialization.h"
#include "Chat.h"
#include "Item.h"
#include "ItemScript.h"
#include "Log.h"
#include "LootMgr.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>
#include <vector>

namespace
{
enum CacheItems : uint32
{
    AdventurerSatchel = 1397884,
    AdventurerCache = 1397885,
    AdventurerRareCache = 1397886
};

bool IsAdventurerReward(uint32 entry)
{
    return entry == AdventurerSatchel || entry == AdventurerCache || entry == AdventurerRareCache;
}

constexpr uint32 FirstHelpfulGoodsSatchel = 51999;
constexpr uint32 LastHelpfulGoodsSatchel = 52002;

bool IsHelpfulGoodsSatchel(uint32 entry)
{
    return entry >= FirstHelpfulGoodsSatchel && entry <= LastHelpfulGoodsSatchel;
}

LootStoreItem* BestWearableEntry(Player const* player, std::list<LootStoreItem*> const& entries)
{
    LootStoreItem* best = nullptr;
    uint32 bestArmorClass = 0;
    for (LootStoreItem* entry : entries)
    {
        ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry->itemid);
        if (!item || entry->reference || item->RequiredLevel > player->GetLevel() ||
            player->CanUseItem(item) != EQUIP_ERR_OK || (item->GetSkill() && !player->GetSkillValue(item->GetSkill())))
            continue;
        if (!best || item->SubClass > bestArmorClass)
        {
            best = entry;
            bestArmorClass = item->SubClass;
        }
    }
    return best;
}

enum RewardKind : uint8
{
    Food,
    Potion,
    Material,
    Armor,
    RewardKindCount
};

void OpenCache(Player* player, Item* item)
{
    player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);
    if (!player->IsAlive() || player->IsInCombat())
        return;

    Loot loot;
    loot.containerGUID = item->GetGUID();
    loot.FillLoot(item->GetEntry(), LootTemplates_Item, player, true, true);

    std::vector<AscensionCacheRewards::Reward> rewards;
    uint32 const slots = loot.GetMaxSlotInLootFor(player);
    for (uint32 slot = 0; slot < slots; ++slot)
    {
        LootItem const* reward = loot.LootItemInSlot(slot, player);
        if (!reward)
            continue;
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(reward->itemid);
        if (!proto)
            continue;
        rewards.push_back({ reward->itemid, uint16(proto->ItemLevel), uint8(5), uint8(proto->SubClass),
            uint32(reward->count ? reward->count : 1), reward->randomPropertyId });
    }

    if (rewards.empty())
        return;

    AscensionCacheRewards::Deliver(player, rewards, item);
}

class item_ascension_adventurer_cache : public ItemScript
{
public:
    item_ascension_adventurer_cache() : ItemScript("item_ascension_adventurer_cache") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        if (!IsAdventurerReward(item->GetEntry()))
            return false;
        OpenCache(player, item);
        return true;
    }
};

class adventurer_cache_open : public ServerScript
{
public:
    adventurer_cache_open() : ServerScript("adventurer_cache_open", {SERVERHOOK_CAN_PACKET_RECEIVE}) { }

    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        if (packet.GetOpcode() != CMSG_OPEN_ITEM || packet.size() < 2)
            return true;
        Player* player = session ? session->GetPlayer() : nullptr;
        if (!player || player->m_mover != player)
            return true;
        Item* item = player->GetItemByPos(packet.read<uint8>(0), packet.read<uint8>(1));
        if (!item || !IsAdventurerReward(item->GetEntry()))
            return true;

        ObjectGuid const cache = item->GetGUID();
        OpenCache(player, item);
        player->SendLootRelease(cache);
        return false;
    }
};

class adventurer_cache_loot : public GlobalScript
{
public:
    adventurer_cache_loot() : GlobalScript("adventurer_cache_loot",
        {GLOBALHOOK_ON_BEFORE_LOOT_EQUAL_CHANCED}) { }

    bool OnBeforeLootEqualChanced(Player const* player, std::list<LootStoreItem*> entries,
        Loot& loot, LootStore const& store) override
    {
        if (!player || &store != &LootTemplates_Item)
            return true;
        Item const* container = player->GetItemByGuid(loot.containerGUID);
        if (container && IsHelpfulGoodsSatchel(container->GetEntry()) && IsAscensionCustomClassId(player->getClass()))
        {
            if (LootStoreItem* wearable = BestWearableEntry(player, entries))
                loot.AddItem(*wearable);
            return false;
        }
        if (!container || !IsAdventurerReward(container->GetEntry()))
            return true;

        std::array<std::vector<LootStoreItem*>, RewardKindCount> rewards;
        std::array<uint32, RewardKindCount> bestLevel{};
        for (LootStoreItem* entry : entries)
        {
            ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry->itemid);
            if (!item || entry->reference)
                continue;
            RewardKind kind;
            if (item->Class == ITEM_CLASS_TRADE_GOODS)
                kind = Material;
            else if (item->Class == ITEM_CLASS_ARMOR)
                kind = Armor;
            else if (item->Class == ITEM_CLASS_CONSUMABLE && item->SubClass == ITEM_SUBCLASS_FOOD)
                kind = Food;
            else if (item->IsPotion())
                kind = Potion;
            else
                continue;

            uint32 level = kind == Material ? item->ItemLevel : item->RequiredLevel;
            uint32 ceiling = player->GetLevel() + (kind == Material ? 5 : 0);
            if (level > ceiling || (kind != Material && player->CanUseItem(item) != EQUIP_ERR_OK) ||
                (kind == Armor && item->GetSkill() && !player->GetSkillValue(item->GetSkill())))
                continue;
            rewards[kind].push_back(entry);
            bestLevel[kind] = std::max(bestLevel[kind], level);
        }

        std::vector<uint8> kinds;
        for (uint8 kind = 0; kind < RewardKindCount; ++kind)
        {
            std::erase_if(rewards[kind], [kind, &bestLevel](LootStoreItem const* entry)
            {
                ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry->itemid);
                uint32 level = kind == Material ? item->ItemLevel : item->RequiredLevel;
                return level + 10 < bestLevel[kind];
            });
            if (!rewards[kind].empty())
                kinds.push_back(kind);
        }
        if (!kinds.empty())
        {
            auto const& choices = rewards[kinds[urand(0, uint32(kinds.size() - 1))]];
            loot.AddItem(*choices[urand(0, uint32(choices.size() - 1))]);
        }
        return false;
    }
};
}

void AddSC_AscensionAdventurerCache()
{
    new item_ascension_adventurer_cache();
    new adventurer_cache_open();
    new adventurer_cache_loot();
}
