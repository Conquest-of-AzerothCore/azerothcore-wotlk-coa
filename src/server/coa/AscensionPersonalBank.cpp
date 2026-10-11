/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionPersonalBank.h"

#include "Bag.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Guild.h"
#include "GuildPackets.h"
#include "Item.h"
#include "ItemScript.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <string>
#include <unordered_map>

namespace
{
constexpr uint8 BANK_TABS = GUILD_BANK_MAX_TABS;
constexpr uint8 BANK_SLOTS = GUILD_BANK_MAX_SLOTS;

constexpr uint8 OWNER_CHARACTER = 0;
constexpr uint8 OWNER_REALM = 1;

[[nodiscard]] uint64 BankOwnerId(Player const* player, uint8 kind)
{
    return kind == AscensionPersonalBank::REALM
               ? uint64(player->GetSession()->GetAccountId())
               : player->GetGUID().GetCounter();
}

constexpr bool SEND_ALL_SLOTS = true;
constexpr bool SEND_CHANGED_SLOTS = false;

constexpr char const* DEFAULT_TAB_ICON = "achievement_guildperk_mobilebanking";

constexpr uint16 SMSG_BANK_PERMISSIONS = 0x0769;

constexpr float BANK_REACH = 12.0f;

struct OpenBank
{
    uint8 OwnerKind = OWNER_CHARACTER;
    uint64 OwnerId = 0;

    ObjectGuid Vault;

    uint8 Tabs = 1;
    std::array<std::string, BANK_TABS> TabName;
    std::array<std::string, BANK_TABS> TabIcon;
    std::array<std::string, BANK_TABS> TabText;

    std::array<std::array<Item*, BANK_SLOTS>, BANK_TABS> Items{};
    uint64 Money = 0;
};

std::unordered_map<ObjectGuid::LowType, OpenBank> openBanks;

[[nodiscard]] ObjectGuid BankItemOwner(OpenBank const& bank)
{
    return bank.OwnerKind == OWNER_CHARACTER
               ? ObjectGuid::Create<HighGuid::Player>(ObjectGuid::LowType(bank.OwnerId))
               : ObjectGuid::Empty;
}

void LoadBank(OpenBank& bank, ObjectGuid itemOwner)
{
    QueryResult tabs = CharacterDatabase.Query(
        "SELECT tab_index, name, icon, text FROM mod_ascension_bank_tab "
        "WHERE owner_kind = {} AND owner_id = {} ORDER BY tab_index ASC",
        bank.OwnerKind, bank.OwnerId);
    if (tabs)
    {
        do
        {
            Field* fields = tabs->Fetch();
            uint8 const index = fields[0].Get<uint8>();
            if (index >= BANK_TABS)
            {
                LOG_ERROR("coa",
                          "Personal bank tab {} out of range for owner kind {} id {}",
                          index, bank.OwnerKind, bank.OwnerId);
                continue;
            }

            bank.TabName[index] = fields[1].Get<std::string>();
            bank.TabIcon[index] = fields[2].Get<std::string>();
            bank.TabText[index] = fields[3].Get<std::string>();
            bank.Tabs = std::max<uint8>(bank.Tabs, index + 1);
        } while (tabs->NextRow());
    }

    QueryResult money = CharacterDatabase.Query(
        "SELECT money FROM mod_ascension_bank_money WHERE owner_kind = {} AND owner_id = {}",
        bank.OwnerKind, bank.OwnerId);
    bank.Money = money ? money->Fetch()[0].Get<uint64>() : 0;

    QueryResult items = CharacterDatabase.Query(
        "SELECT creatorGuid, giftCreatorGuid, count, duration, charges, flags, enchantments, "
        "randomPropertyId, durability, playedTime, text, bi.tab_index, bi.slot, bi.item_guid, itemEntry "
        "FROM mod_ascension_bank_item bi INNER JOIN item_instance ii ON bi.item_guid = ii.guid "
        "WHERE bi.owner_kind = {} AND bi.owner_id = {}",
        bank.OwnerKind, bank.OwnerId);
    if (items)
    {
        do
        {
            Field* fields = items->Fetch();
            uint8 const tab = fields[11].Get<uint8>();
            uint8 const slot = fields[12].Get<uint8>();
            ObjectGuid::LowType const itemGuid = fields[13].Get<uint32>();
            uint32 const itemEntry = fields[14].Get<uint32>();

            if (tab >= BANK_TABS || slot >= BANK_SLOTS)
            {
                LOG_ERROR("coa",
                          "Personal bank item {} sits in an invalid slot (tab {} slot {})",
                          itemGuid, tab, slot);
                continue;
            }

            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemEntry);
            if (!proto)
            {
                LOG_ERROR("coa",
                          "Personal bank item {} has unknown template {}", itemGuid, itemEntry);
                continue;
            }

            Item* item = NewItemOrBag(proto);
            if (!item->LoadFromDB(itemGuid, itemOwner, fields, itemEntry))
            {
                LOG_ERROR("coa",
                          "Personal bank item {} could not be loaded", itemGuid);
                delete item;
                continue;
            }

            item->AddToWorld();
            bank.Items[tab][slot] = item;
        } while (items->NextRow());
    }
}

void UnloadBank(OpenBank& bank)
{
    for (auto& tab : bank.Items)
    {
        for (Item*& item : tab)
        {
            if (!item)
                continue;

            item->RemoveFromWorld();
            delete item;
            item = nullptr;
        }
    }
}

void StoreSlot(CharacterDatabaseTransaction trans, OpenBank const& bank, uint8 tab, uint8 slot, Item* item)
{
    trans->Append("DELETE FROM mod_ascension_bank_item WHERE owner_kind = {} AND owner_id = {} "
                  "AND tab_index = {} AND slot = {}",
                  bank.OwnerKind, bank.OwnerId, tab, slot);

    if (!item)
        return;

    trans->Append("INSERT INTO mod_ascension_bank_item (owner_kind, owner_id, tab_index, slot, item_guid) "
                  "VALUES ({}, {}, {}, {}, {})",
                  bank.OwnerKind, bank.OwnerId, tab, slot, item->GetGUID().GetCounter());

    item->SetGuidValue(ITEM_FIELD_CONTAINED, ObjectGuid::Empty);
    item->SetOwnerGUID(BankItemOwner(bank));
    item->FSetState(ITEM_NEW);
    item->SaveToDB(trans);
}

void StoreMoney(OpenBank const& bank)
{
    CharacterDatabase.Execute("REPLACE INTO mod_ascension_bank_money (owner_kind, owner_id, money) "
                              "VALUES ({}, {}, {})",
                              bank.OwnerKind, bank.OwnerId, bank.Money);
}

void StoreTab(OpenBank const& bank, uint8 tab)
{
    std::string name = bank.TabName[tab];
    std::string icon = bank.TabIcon[tab];
    std::string text = bank.TabText[tab];
    CharacterDatabase.EscapeString(name);
    CharacterDatabase.EscapeString(icon);
    CharacterDatabase.EscapeString(text);

    CharacterDatabase.Execute("REPLACE INTO mod_ascension_bank_tab (owner_kind, owner_id, tab_index, name, icon, text) "
                              "VALUES ({}, {}, {}, '{}', '{}', '{}')",
                              bank.OwnerKind, bank.OwnerId, tab, name, icon, text);
}

void LogBankEvent(OpenBank const& bank, uint8 eventType, uint8 tab, Player* player, uint32 itemOrMoney,
                  uint16 count, uint8 destTab = 0)
{
    if (tab >= BANK_TABS)
        return;

    if (eventType == GUILD_BANK_LOG_MOVE_ITEM && tab == destTab)
        return;

    bool const moneyEvent = eventType == GUILD_BANK_LOG_DEPOSIT_MONEY ||
                            eventType == GUILD_BANK_LOG_WITHDRAW_MONEY;

    CharacterDatabase.Execute(
        "INSERT INTO mod_ascension_bank_log (owner_kind, owner_id, tab_index, event_type, player_guid, "
        "item_or_money, stack_count, dest_tab, timestamp) VALUES ({}, {}, {}, {}, {}, {}, {}, {}, {})",
        bank.OwnerKind, bank.OwnerId, moneyEvent ? uint32(GUILD_BANK_MONEY_LOGS_TAB) : uint32(tab), eventType,
        player->GetGUID().GetCounter(), itemOrMoney, count, destTab,
        uint32(GameTime::GetGameTime().count()));

    CharacterDatabase.Execute(
        "DELETE FROM mod_ascension_bank_log WHERE owner_kind = {} AND owner_id = {} AND tab_index = {} AND log_id NOT IN "
        "(SELECT log_id FROM (SELECT log_id FROM mod_ascension_bank_log WHERE owner_kind = {} AND owner_id = {} "
        "AND tab_index = {} ORDER BY log_id DESC LIMIT 25) keep)",
        bank.OwnerKind, bank.OwnerId, moneyEvent ? uint32(GUILD_BANK_MONEY_LOGS_TAB) : uint32(tab),
        bank.OwnerKind, bank.OwnerId, moneyEvent ? uint32(GUILD_BANK_MONEY_LOGS_TAB) : uint32(tab));
}

void SendRights(Player* player, uint8 tabs)
{
    WorldPackets::Guild::GuildPermissionsQueryResults rights;
    rights.RankID = 0;
    rights.Flags = GR_RIGHT_ALL;
    rights.WithdrawGoldLimit = int32(BANK_SLOTS * BANK_TABS);
    rights.NumTabs = int8(std::min<uint8>(tabs, BANK_TABS));
    for (uint8 tab = 0; tab < BANK_TABS; ++tab)
    {
        rights.Tab[tab].Flags = GUILD_BANK_RIGHT_FULL;
        rights.Tab[tab].WithdrawItemLimit = BANK_SLOTS;
    }

    player->GetSession()->SendPacket(rights.Write());
}

void SendTabList(Player* player, OpenBank const& bank, uint8 tab, bool sendAllSlots)
{
    WorldPackets::Guild::GuildBankQueryResults packet;
    packet.Money = bank.Money;
    packet.Tab = tab;
    packet.FullUpdate = sendAllSlots;
    packet.WithdrawalsRemaining = BANK_SLOTS;

    if (sendAllSlots && tab == 0)
    {
        packet.TabInfo.reserve(bank.Tabs);
        for (uint8 i = 0; i < bank.Tabs; ++i)
        {
            WorldPackets::Guild::GuildBankTabInfo info;
            info.Name = bank.TabName[i];
            info.Icon = bank.TabIcon[i].empty() ? DEFAULT_TAB_ICON : bank.TabIcon[i];
            packet.TabInfo.push_back(info);
        }
    }

    if (tab >= bank.Tabs)
    {
        player->GetSession()->SendPacket(packet.Write());
        return;
    }

    for (uint8 slot = 0; slot < BANK_SLOTS; ++slot)
    {
        Item* item = bank.Items[tab][slot];
        if (!item && sendAllSlots)
            continue;

        WorldPackets::Guild::GuildBankItemInfo info;
        info.Slot = slot;

        if (item)
        {
            info.ItemID = item->GetEntry();
            info.Count = int32(item->GetCount());
            info.Charges = int32(std::abs(item->GetSpellCharges()));
            info.EnchantmentID = int32(item->GetEnchantmentId(PERM_ENCHANTMENT_SLOT));
            info.Flags = item->GetInt32Value(ITEM_FIELD_FLAGS);
            info.RandomPropertiesID = item->GetItemRandomPropertyId();
            info.RandomPropertiesSeed = int32(item->GetItemSuffixFactor());

            for (uint32 socketSlot = 0; socketSlot < MAX_GEM_SOCKETS; ++socketSlot)
            {
                uint32 const enchantId = item->GetEnchantmentId(EnchantmentSlot(SOCK_ENCHANTMENT_SLOT + socketSlot));
                if (!enchantId)
                    continue;

                WorldPackets::Guild::GuildBankSocketEnchant gem;
                gem.SocketIndex = socketSlot;
                gem.SocketEnchantID = int32(enchantId);
                info.SocketEnchant.push_back(gem);
            }
        }

        packet.ItemInfo.push_back(info);
    }

    player->GetSession()->SendPacket(packet.Write());
}

void SendTabChanged(Player* player, OpenBank const& bank, uint8 tab)
{
    SendTabList(player, bank, tab, SEND_CHANGED_SLOTS);
}

void SendBankData(Player* player, OpenBank const& bank, uint8 kind, bool fullSlots)
{
    bool const allSlots = fullSlots ? SEND_ALL_SLOTS : SEND_CHANGED_SLOTS;

    AscensionPersonalBank::SendKindHint(player, kind);
    SendRights(player, bank.Tabs);
    SendTabList(player, bank, 0, allSlots);
    SendTabList(player, bank, 0, allSlots);
    SendTabChanged(player, bank, 0);
    AscensionPersonalBank::SendKindHint(player, kind);
}

void DestroyBankItem(CharacterDatabaseTransaction trans, OpenBank& bank, uint8 tab, uint8 slot, Item* item)
{
    bank.Items[tab][slot] = nullptr;
    StoreSlot(trans, bank, tab, slot, nullptr);
    item->RemoveFromWorld();
    item->FSetState(ITEM_REMOVED);
    item->SaveToDB(trans);
}

[[nodiscard]] uint32 ItemCount(OpenBank const& bank)
{
    uint32 count = 0;
    for (auto const& tab : bank.Items)
        for (Item* item : tab)
            if (item)
                ++count;

    return count;
}

[[nodiscard]] Item* BankItem(OpenBank const& bank, uint8 tab, uint8 slot)
{
    if (tab >= bank.Tabs || slot >= BANK_SLOTS)
        return nullptr;

    return bank.Items[tab][slot];
}

[[nodiscard]] bool FindBankSlotFor(OpenBank const& bank, uint8 tab, Item* item, uint8& outSlot)
{
    if (tab >= bank.Tabs)
        return false;

    uint32 const maxStack = item->GetMaxStackCount();
    for (uint8 slot = 0; slot < BANK_SLOTS; ++slot)
    {
        Item* existing = bank.Items[tab][slot];
        if (existing && existing->GetEntry() == item->GetEntry() && existing->GetCount() < maxStack)
        {
            outSlot = slot;
            return true;
        }
    }

    for (uint8 slot = 0; slot < BANK_SLOTS; ++slot)
    {
        if (!bank.Items[tab][slot])
        {
            outSlot = slot;
            return true;
        }
    }

    return false;
}

[[nodiscard]] bool CanMergeInto(Item* dest, Item* item)
{
    return dest && item && dest->GetEntry() == item->GetEntry() && dest->GetCount() < dest->GetMaxStackCount();
}

void ReduceBankItem(CharacterDatabaseTransaction trans, OpenBank& bank, uint8 tab, uint8 slot, Item* item, uint32 amount)
{
    if (amount >= item->GetCount())
    {
        DestroyBankItem(trans, bank, tab, slot, item);
        return;
    }

    item->SetCount(item->GetCount() - amount);
    item->FSetState(ITEM_CHANGED);
    item->SaveToDB(trans);
}

void StoreInBank(CharacterDatabaseTransaction trans, OpenBank& bank, uint8 tab, uint8 slot, Item* item)
{
    bank.Items[tab][slot] = item;
    if (!item->IsInWorld())
        item->AddToWorld();

    StoreSlot(trans, bank, tab, slot, item);
}

void RemoveFromInventory(CharacterDatabaseTransaction trans, Player* player, uint8 bag, uint8 slot, Item* item)
{
    player->MoveItemFromInventory(bag, slot, true);
    item->DeleteFromInventoryDB(trans);
    player->SaveInventoryAndGoldToDB(trans);
}

void MoveIntoInventory(CharacterDatabaseTransaction trans, Player* player, ItemPosCountVec const& dest, Item* item)
{
    player->MoveItemToInventory(dest, item, true);
    player->SaveInventoryAndGoldToDB(trans);
}

void DepositToBank(Player* player, OpenBank& bank, uint8 bag, uint8 slot, uint8 tab, uint8 bankSlot,
                   uint32 split)
{
    Item* source = player->GetItemByPos(bag, slot);
    if (!source)
        return;

    uint32 const sourceEntry = source->GetEntry();
    uint32 const sourceCount = source->GetCount();

    if (source->IsNotEmptyBag())
    {
        player->SendEquipError(EQUIP_ERR_CAN_ONLY_DO_WITH_EMPTY_BAGS, source, nullptr);
        return;
    }

    if (tab >= bank.Tabs)
        return;

    if (bankSlot == NULL_SLOT && !FindBankSlotFor(bank, tab, source, bankSlot))
    {
        player->SendEquipError(EQUIP_ERR_BANK_FULL, source, nullptr);
        return;
    }

    if (bankSlot >= BANK_SLOTS)
        return;

    if (split == 0 || split >= source->GetCount())
        split = 0;

    Item* dest = bank.Items[tab][bankSlot];
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();

    if (split)
    {
        if (CanMergeInto(dest, source))
            split = std::min(split, dest->GetMaxStackCount() - dest->GetCount());

        Item* moved = source->CloneItem(split, player);
        if (!moved)
        {
            CharacterDatabase.CommitTransaction(trans);
            player->SendEquipError(EQUIP_ERR_ITEM_NOT_FOUND, source, nullptr);
            return;
        }

        if (dest)
        {
            if (CanMergeInto(dest, moved))
            {
                dest->SetCount(dest->GetCount() + moved->GetCount());
                dest->FSetState(ITEM_CHANGED);
                dest->SaveToDB(trans);
                delete moved;
            }
            else
            {
                CharacterDatabase.CommitTransaction(trans);
                delete moved;
                player->SendEquipError(EQUIP_ERR_BANK_FULL, source, nullptr);
                return;
            }
        }
        else
        {
            StoreInBank(trans, bank, tab, bankSlot, moved);
        }

        source->SetCount(source->GetCount() - split);
        source->SetState(ITEM_CHANGED, player);
        player->SaveInventoryAndGoldToDB(trans);
    }
    else if (dest)
    {
        if (CanMergeInto(dest, source))
        {
            uint32 const room = dest->GetMaxStackCount() - dest->GetCount();
            uint32 const amount = std::min<uint32>(room, source->GetCount());

            dest->SetCount(dest->GetCount() + amount);
            dest->FSetState(ITEM_CHANGED);
            dest->SaveToDB(trans);

            if (amount >= source->GetCount())
                RemoveFromInventory(trans, player, bag, slot, source);
            else
            {
                source->SetCount(source->GetCount() - amount);
                source->SetState(ITEM_CHANGED, player);
                player->SaveInventoryAndGoldToDB(trans);
            }
        }
        else
        {
            ItemPosCountVec destPos;
            InventoryResult msg = player->CanStoreItem(bag, slot, destPos, dest, true);
            if (msg != EQUIP_ERR_OK)
            {
                CharacterDatabase.CommitTransaction(trans);
                player->SendEquipError(msg, dest, nullptr);
                return;
            }

            bank.Items[tab][bankSlot] = nullptr;
            StoreSlot(trans, bank, tab, bankSlot, nullptr);
            dest->FSetState(ITEM_CHANGED);
            dest->SaveToDB(trans);

            LogBankEvent(bank, GUILD_BANK_LOG_WITHDRAW_ITEM, tab, player, dest->GetEntry(),
                         uint16(dest->GetCount()));

            RemoveFromInventory(trans, player, bag, slot, source);
            StoreInBank(trans, bank, tab, bankSlot, source);
            MoveIntoInventory(trans, player, destPos, dest);
        }
    }
    else
    {
        RemoveFromInventory(trans, player, bag, slot, source);
        StoreInBank(trans, bank, tab, bankSlot, source);
    }

    CharacterDatabase.CommitTransaction(trans);
    SendTabChanged(player, bank, tab);
    LogBankEvent(bank, GUILD_BANK_LOG_DEPOSIT_ITEM, tab, player, sourceEntry,
                 uint16(split ? split : sourceCount));
}

void WithdrawToPlayer(Player* player, OpenBank& bank, uint8 tab, uint8 bankSlot, uint8 bag, uint8 slot,
                      uint32 split, bool autoStore)
{
    Item* source = BankItem(bank, tab, bankSlot);
    if (!source)
        return;

    uint32 const sourceEntry = source->GetEntry();
    uint32 const sourceCount = source->GetCount();

    if (split == 0 || split >= source->GetCount())
        split = 0;

    uint32 const movedAmount = split ? split : sourceCount;
    ItemPosCountVec destPos;
    InventoryResult msg = player->CanStoreItem(bag, slot, destPos, sourceEntry, movedAmount, source, false);
    if (autoStore || msg != EQUIP_ERR_OK)
    {
        destPos.clear();
        msg = player->CanStoreItem(NULL_BAG, NULL_SLOT, destPos, sourceEntry, movedAmount, source, false);
    }

    if (msg != EQUIP_ERR_OK)
    {
        player->SendEquipError(msg, source, nullptr);
        return;
    }

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();

    auto finish = [&]()
    {
        CharacterDatabase.CommitTransaction(trans);
        SendTabChanged(player, bank, tab);
        LogBankEvent(bank, GUILD_BANK_LOG_WITHDRAW_ITEM, tab, player, sourceEntry, uint16(movedAmount));
    };

    if (split)
    {
        Item* moved = source->CloneItem(split, player);
        if (!moved)
        {
            CharacterDatabase.CommitTransaction(trans);
            player->SendEquipError(EQUIP_ERR_ITEM_NOT_FOUND, source, nullptr);
            return;
        }

        ReduceBankItem(trans, bank, tab, bankSlot, source, split);
        MoveIntoInventory(trans, player, destPos, moved);
        finish();
        return;
    }

    if (!autoStore && bag != NULL_BAG && slot != NULL_SLOT)
    {
        if (Item* destItem = player->GetItemByPos(bag, slot))
        {
            if (CanMergeInto(destItem, source))
            {
                uint32 const room = destItem->GetMaxStackCount() - destItem->GetCount();
                uint32 const amount = std::min<uint32>(room, source->GetCount());

                destItem->SetCount(destItem->GetCount() + amount);
                destItem->SetState(ITEM_CHANGED, player);
                ReduceBankItem(trans, bank, tab, bankSlot, source, amount);
                player->SaveInventoryAndGoldToDB(trans);
                finish();
                return;
            }

            if (destItem->IsNotEmptyBag())
            {
                CharacterDatabase.CommitTransaction(trans);
                player->SendEquipError(EQUIP_ERR_CAN_ONLY_DO_WITH_EMPTY_BAGS, destItem, nullptr);
                return;
            }

            ItemPosCountVec swapPos;
            InventoryResult const swapMsg = player->CanStoreItem(bag, slot, swapPos, destItem, true);
            if (swapMsg != EQUIP_ERR_OK)
            {
                CharacterDatabase.CommitTransaction(trans);
                player->SendEquipError(swapMsg, destItem, nullptr);
                return;
            }

            LogBankEvent(bank, GUILD_BANK_LOG_DEPOSIT_ITEM, tab, player, destItem->GetEntry(),
                         uint16(destItem->GetCount()));

            RemoveFromInventory(trans, player, bag, slot, destItem);
            StoreInBank(trans, bank, tab, bankSlot, destItem);
            MoveIntoInventory(trans, player, destPos, source);
            finish();
            return;
        }
    }

    bank.Items[tab][bankSlot] = nullptr;
    StoreSlot(trans, bank, tab, bankSlot, nullptr);
    MoveIntoInventory(trans, player, destPos, source);
    finish();
}

void MoveWithinBank(Player* player, OpenBank& bank, uint8 tab, uint8 slot, uint8 destTab, uint8 destSlot,
                    uint32 split)
{
    Item* source = BankItem(bank, tab, slot);
    if (!source || destTab >= bank.Tabs || destSlot >= BANK_SLOTS || (tab == destTab && slot == destSlot))
        return;

    uint32 const sourceEntry = source->GetEntry();
    uint32 const sourceCount = source->GetCount();

    if (split == 0 || split >= source->GetCount())
        split = 0;

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    Item* dest = bank.Items[destTab][destSlot];

    if (split)
    {
        if (dest && !CanMergeInto(dest, source))
        {
            CharacterDatabase.CommitTransaction(trans);
            return;
        }

        if (dest)
        {
            dest->SetCount(dest->GetCount() + split);
            dest->FSetState(ITEM_CHANGED);
            dest->SaveToDB(trans);
        }
        else
        {
            Item* moved = source->CloneItem(split, player);
            if (!moved)
            {
                CharacterDatabase.CommitTransaction(trans);
                return;
            }

            StoreInBank(trans, bank, destTab, destSlot, moved);
        }

        ReduceBankItem(trans, bank, tab, slot, source, split);
    }
    else if (dest && CanMergeInto(dest, source))
    {
        uint32 const room = dest->GetMaxStackCount() - dest->GetCount();
        uint32 const amount = std::min<uint32>(room, source->GetCount());

        dest->SetCount(dest->GetCount() + amount);
        dest->FSetState(ITEM_CHANGED);
        dest->SaveToDB(trans);
        ReduceBankItem(trans, bank, tab, slot, source, amount);
    }
    else
    {
        bank.Items[tab][slot] = dest;
        bank.Items[destTab][destSlot] = source;
        StoreSlot(trans, bank, tab, slot, dest);
        StoreSlot(trans, bank, destTab, destSlot, source);
    }

    CharacterDatabase.CommitTransaction(trans);
    SendTabChanged(player, bank, tab);
    if (destTab != tab)
        SendTabChanged(player, bank, destTab);

    LogBankEvent(bank, GUILD_BANK_LOG_MOVE_ITEM, tab, player, sourceEntry,
                 uint16(split ? split : sourceCount), destTab);
}

[[nodiscard]] uint32 TabPrice(uint8 tab)
{
    switch (tab)
    {
        case 0: return sWorld->getIntConfig(CONFIG_GUILD_BANK_TAB_COST_0);
        case 1: return sWorld->getIntConfig(CONFIG_GUILD_BANK_TAB_COST_1);
        case 2: return sWorld->getIntConfig(CONFIG_GUILD_BANK_TAB_COST_2);
        case 3: return sWorld->getIntConfig(CONFIG_GUILD_BANK_TAB_COST_3);
        case 4: return sWorld->getIntConfig(CONFIG_GUILD_BANK_TAB_COST_4);
        case 5: return sWorld->getIntConfig(CONFIG_GUILD_BANK_TAB_COST_5);
        default: return 0;
    }
}

template <typename T, typename Use>
void WithBankPacket(WorldPacket const& packet, Use&& use)
{
    try
    {
        WorldPacket copy(packet);
        T parsed(std::move(copy));
        parsed.Read();
        use(parsed);
    }
    catch (...)
    {
        LOG_DEBUG("coa", "Ignored a malformed bank packet (opcode {})",
                  packet.GetOpcode());
    }
}

void HandleQueryTab(Player* player, OpenBank& bank, WorldPacket const& packet)
{
    WithBankPacket<WorldPackets::Guild::GuildBankQueryTab>(packet,
        [&](WorldPackets::Guild::GuildBankQueryTab& query)
        {
            if (query.Banker != bank.Vault)
                return;

            SendTabList(player, bank, uint8(query.Tab), query.FullUpdate);
        });
}

void HandleSwapItems(Player* player, OpenBank& bank, WorldPacket const& packet)
{
    WithBankPacket<WorldPackets::Guild::GuildBankSwapItems>(packet,
        [&](WorldPackets::Guild::GuildBankSwapItems& swap)
        {
            if (swap.Banker != bank.Vault)
                return;

            if (swap.BankOnly)
            {
                MoveWithinBank(player, bank, uint8(swap.BankTab1), uint8(swap.BankSlot1),
                               uint8(swap.BankTab), uint8(swap.BankSlot),
                               uint32(std::max<int32>(0, swap.BankItemCount)));
                return;
            }

            if (swap.ToSlot || swap.AutoStore)
            {
                WithdrawToPlayer(player, bank, uint8(swap.BankTab), uint8(swap.BankSlot),
                                 swap.ContainerSlot, swap.ContainerItemSlot,
                                 uint32(std::max<int32>(0, swap.StackCount)), swap.AutoStore);
                sScriptMgr->OnPlayerBankWithdraw(player, bank.OwnerKind == OWNER_REALM
                    ? AscensionPersonalBank::REALM : AscensionPersonalBank::PERSONAL);
            }
            else
                DepositToBank(player, bank, swap.ContainerSlot, swap.ContainerItemSlot,
                              uint8(swap.BankTab), uint8(swap.BankSlot),
                              uint32(std::max<int32>(0, swap.StackCount)));
        });
}

void HandleDepositMoney(Player* player, OpenBank& bank, WorldPacket const& packet)
{
    WithBankPacket<WorldPackets::Guild::GuildBankDepositMoney>(packet,
        [&](WorldPackets::Guild::GuildBankDepositMoney& deposit)
        {
            if (deposit.Banker != bank.Vault || !deposit.Money || !player->HasEnoughMoney(deposit.Money))
                return;

            player->ModifyMoney(-int32(deposit.Money));
            bank.Money += deposit.Money;
            StoreMoney(bank);
            SendTabChanged(player, bank, 0);
            LogBankEvent(bank, GUILD_BANK_LOG_DEPOSIT_MONEY, 0, player, deposit.Money, 0);
        });
}

void HandleWithdrawMoney(Player* player, OpenBank& bank, WorldPacket const& packet)
{
    WithBankPacket<WorldPackets::Guild::GuildBankWithdrawMoney>(packet,
        [&](WorldPackets::Guild::GuildBankWithdrawMoney& withdraw)
        {
            if (withdraw.Banker != bank.Vault || !withdraw.Money || bank.Money < withdraw.Money)
                return;

            bank.Money -= withdraw.Money;
            player->ModifyMoney(int32(withdraw.Money));
            StoreMoney(bank);
            SendTabChanged(player, bank, 0);
            LogBankEvent(bank, GUILD_BANK_LOG_WITHDRAW_MONEY, 0, player, withdraw.Money, 0);
            sScriptMgr->OnPlayerBankWithdraw(player, bank.OwnerKind == OWNER_REALM
                ? AscensionPersonalBank::REALM : AscensionPersonalBank::PERSONAL);
        });
}

void HandleBuyTab(Player* player, OpenBank& bank, WorldPacket const& packet)
{
    WithBankPacket<WorldPackets::Guild::GuildBankBuyTab>(packet,
        [&](WorldPackets::Guild::GuildBankBuyTab& buy)
        {
            if (buy.Banker != bank.Vault || bank.Tabs >= BANK_TABS || uint8(buy.BankTab) != bank.Tabs)
                return;

            uint32 const price = TabPrice(bank.Tabs);
            if (!price || !player->HasEnoughMoney(price))
                return;

            player->ModifyMoney(-int32(price));
            StoreTab(bank, bank.Tabs);
            ++bank.Tabs;

            SendBankData(player, bank, bank.OwnerKind == OWNER_REALM ? AscensionPersonalBank::REALM
                                                                     : AscensionPersonalBank::PERSONAL,
                         true);

            LogBankEvent(bank, GUILD_BANK_LOG_WITHDRAW_MONEY, 0, player, price, 0);

            LOG_INFO("coa",
                     "Personal bank: {} bought tab {} ({} copper) as kind {} id {}",
                     player->GetName(), bank.Tabs - 1, price, bank.OwnerKind, bank.OwnerId);
        });
}

void HandleUpdateTab(Player* player, OpenBank& bank, WorldPacket const& packet)
{
    WithBankPacket<WorldPackets::Guild::GuildBankUpdateTab>(packet,
        [&](WorldPackets::Guild::GuildBankUpdateTab& update)
        {
            if (update.Banker != bank.Vault || uint8(update.BankTab) >= bank.Tabs ||
                update.Name.empty() || update.Icon.empty())
                return;

            bank.TabName[uint8(update.BankTab)] = std::string(update.Name);
            bank.TabIcon[uint8(update.BankTab)] = std::string(update.Icon);
            StoreTab(bank, uint8(update.BankTab));
            SendTabList(player, bank, 0, SEND_ALL_SLOTS);
        });
}

void SendTabText(Player* player, OpenBank const& bank, uint8 tab)
{
    WorldPackets::Guild::GuildBankTextQueryResult result;
    result.Tab = tab;
    result.Text = bank.TabText[tab];
    player->GetSession()->SendPacket(result.Write());
}

void HandleTabTextQuery(Player* player, OpenBank& bank, WorldPacket const& packet)
{
    WithBankPacket<WorldPackets::Guild::GuildBankTextQuery>(packet,
        [&](WorldPackets::Guild::GuildBankTextQuery& query)
        {
            if (uint8(query.Tab) >= bank.Tabs)
                return;

            SendTabText(player, bank, uint8(query.Tab));
        });
}

void HandleSetTabText(Player* player, OpenBank& bank, WorldPacket const& packet)
{
    WithBankPacket<WorldPackets::Guild::GuildBankSetTabText>(packet,
        [&](WorldPackets::Guild::GuildBankSetTabText& set)
        {
            if (uint8(set.Tab) >= bank.Tabs)
                return;

            bank.TabText[uint8(set.Tab)] = std::string(set.TabText);
            StoreTab(bank, uint8(set.Tab));

            SendTabText(player, bank, uint8(set.Tab));
        });
}

void HandleLogQuery(Player* player, OpenBank& bank, WorldPacket const& packet)
{
    WithBankPacket<WorldPackets::Guild::GuildBankLogQuery>(packet,
        [&](WorldPackets::Guild::GuildBankLogQuery& query)
        {
            bool const moneyLog = uint8(query.Tab) >= BANK_TABS;
            if (!moneyLog && uint8(query.Tab) >= bank.Tabs)
                return;

            uint32 const storedTab = moneyLog ? uint32(GUILD_BANK_MONEY_LOGS_TAB) : uint32(uint8(query.Tab));

            QueryResult rows = CharacterDatabase.Query(
                "SELECT event_type, player_guid, item_or_money, stack_count, dest_tab, timestamp FROM "
                "(SELECT * FROM mod_ascension_bank_log WHERE owner_kind = {} AND owner_id = {} "
                "AND tab_index = {} ORDER BY log_id DESC LIMIT 25) recent ORDER BY log_id ASC",
                bank.OwnerKind, bank.OwnerId, storedTab);

            WorldPackets::Guild::GuildBankLogQueryResults result;
            result.Tab = uint8(query.Tab);

            if (rows)
            {
                do
                {
                    Field* fields = rows->Fetch();
                    uint8 const eventType = fields[0].Get<uint8>();

                    WorldPackets::Guild::GuildBankLogEntry entry;
                    entry.PlayerGUID = ObjectGuid::Create<HighGuid::Player>(fields[1].Get<uint32>());
                    entry.TimeOffset = int32(GameTime::GetGameTime().count()) - int32(fields[5].Get<uint32>());
                    entry.EntryType = int8(eventType);

                    if (eventType == GUILD_BANK_LOG_DEPOSIT_ITEM || eventType == GUILD_BANK_LOG_WITHDRAW_ITEM)
                    {
                        entry.ItemID = int32(fields[2].Get<uint32>());
                        entry.Count = int32(fields[3].Get<uint16>());
                    }
                    else if (eventType == GUILD_BANK_LOG_MOVE_ITEM || eventType == GUILD_BANK_LOG_MOVE_ITEM2)
                    {
                        entry.ItemID = int32(fields[2].Get<uint32>());
                        entry.Count = int32(fields[3].Get<uint16>());
                        entry.OtherTab = int8(fields[4].Get<uint8>());
                    }
                    else
                        entry.Money = fields[2].Get<uint32>();

                    result.Entry.push_back(entry);
                } while (rows->NextRow());
            }

            player->GetSession()->SendPacket(result.Write());
        });
}

void HandleWithdrawAllowanceQuery(Player* player, OpenBank&, WorldPacket const& packet)
{
    WithBankPacket<WorldPackets::Guild::GuildBankRemainingWithdrawMoneyQuery>(packet,
        [&](WorldPackets::Guild::GuildBankRemainingWithdrawMoneyQuery&)
        {
            WorldPackets::Guild::GuildBankRemainingWithdrawMoney result;
            result.RemainingWithdrawMoney = std::numeric_limits<int32>::max();
            player->GetSession()->SendPacket(result.Write());
        });
}
}

namespace AscensionPersonalBank
{
void SendKindHint(Player* player, uint8 kind)
{
    WorldPacket packet(SMSG_BANK_PERMISSIONS, 2);
    packet << uint8(kind == PERSONAL ? 1 : 0);
    packet << uint8(kind == REALM ? 1 : 0);
    player->GetSession()->SendPacket(&packet);
}

bool IsOpen(Player* player)
{
    return player && openBanks.find(player->GetGUID().GetCounter()) != openBanks.end();
}

void Opened(Player* player, uint8 kind, ObjectGuid vault)
{
    if (!player)
        return;

    ObjectGuid::LowType const guid = player->GetGUID().GetCounter();

    auto existing = openBanks.find(guid);
    if (existing != openBanks.end())
    {
        UnloadBank(existing->second);
        openBanks.erase(existing);
    }

    OpenBank bank;
    bank.OwnerKind = kind == REALM ? OWNER_REALM : OWNER_CHARACTER;
    bank.OwnerId = BankOwnerId(player, kind);
    bank.Vault = vault;
    LoadBank(bank, BankItemOwner(bank));

    OpenBank const& stored = openBanks.emplace(guid, std::move(bank)).first->second;

    SendBankData(player, stored, kind, true);

    LOG_INFO("coa",
             "{} bank opened for {} (kind {}, owner {} id {}, {} tabs, {} items, {} copper)",
             kind == REALM ? "Realm" : "Personal", player->GetName(), uint32(kind),
             uint32(stored.OwnerKind), stored.OwnerId, stored.Tabs, ItemCount(stored), stored.Money);
}

bool HandlePacket(Player* player, WorldPacket const& packet)
{
    if (!player)
        return false;

    auto itr = openBanks.find(player->GetGUID().GetCounter());
    if (itr == openBanks.end())
        return false;

    OpenBank& bank = itr->second;

    GameObject* vault = ObjectAccessor::GetGameObject(*player, bank.Vault);
    if (!vault || !vault->IsInWorld() || player->GetDistance(vault) > BANK_REACH)
    {
        LOG_INFO("coa", "Personal bank closed for {} (bank object gone or out of reach)",
                 player->GetName());
        Closed(player);
        return false;
    }

    switch (packet.GetOpcode())
    {
        case CMSG_GUILD_BANK_QUERY_TAB:
            HandleQueryTab(player, bank, packet);
            return true;
        case CMSG_GUILD_BANK_SWAP_ITEMS:
            HandleSwapItems(player, bank, packet);
            return true;
        case CMSG_GUILD_BANK_DEPOSIT_MONEY:
            HandleDepositMoney(player, bank, packet);
            return true;
        case CMSG_GUILD_BANK_WITHDRAW_MONEY:
            HandleWithdrawMoney(player, bank, packet);
            return true;
        case CMSG_GUILD_BANK_BUY_TAB:
            HandleBuyTab(player, bank, packet);
            return true;
        case CMSG_GUILD_BANK_UPDATE_TAB:
            HandleUpdateTab(player, bank, packet);
            return true;
        case MSG_QUERY_GUILD_BANK_TEXT:
            HandleTabTextQuery(player, bank, packet);
            return true;
        case CMSG_SET_GUILD_BANK_TEXT:
            HandleSetTabText(player, bank, packet);
            return true;
        case MSG_GUILD_BANK_LOG_QUERY:
            HandleLogQuery(player, bank, packet);
            return true;
        case MSG_GUILD_BANK_MONEY_WITHDRAWN:
            HandleWithdrawAllowanceQuery(player, bank, packet);
            return true;
        default:
            return false;
    }
}

void Closed(Player* player)
{
    if (!player)
        return;

    auto itr = openBanks.find(player->GetGUID().GetCounter());
    if (itr == openBanks.end())
        return;

    UnloadBank(itr->second);
    openBanks.erase(itr);
}

bool AddTab(Player* player, uint8 kind)
{
    if (!player)
        return false;

    uint8 const ownerKind = kind == REALM ? OWNER_REALM : OWNER_CHARACTER;
    uint64 const ownerId = BankOwnerId(player, kind);

    auto itr = openBanks.find(player->GetGUID().GetCounter());
    bool const isOpen = itr != openBanks.end() && itr->second.OwnerKind == ownerKind &&
                        itr->second.OwnerId == ownerId;

    uint8 tabs = 1;
    if (isOpen)
    {
        tabs = itr->second.Tabs;
    }
    else
    {
        QueryResult rows = CharacterDatabase.Query(
            "SELECT MAX(tab_index) FROM mod_ascension_bank_tab WHERE owner_kind = {} AND owner_id = {}",
            ownerKind, ownerId);
        if (rows)
        {
            Field* field = rows->Fetch();
            if (!field[0].IsNull())
                tabs = std::max<uint8>(tabs, field[0].Get<uint8>() + 1);
        }
    }

    if (tabs >= BANK_TABS)
        return false;

    OpenBank owner;
    owner.OwnerKind = ownerKind;
    owner.OwnerId = ownerId;
    StoreTab(owner, tabs);

    if (isOpen)
    {
        itr->second.Tabs = tabs + 1;
        SendBankData(player, itr->second, kind, true);
    }

    LOG_INFO("coa", "{} bank: {} unlocked tab {} with a voucher (owner {} id {})",
             kind == REALM ? "Realm" : "Personal", player->GetName(), tabs, uint32(ownerKind), ownerId);
    return true;
}
}

namespace
{
class AscensionPersonalBankPlayerScript : public PlayerScript
{
public:
    AscensionPersonalBankPlayerScript()
        : PlayerScript("AscensionPersonalBankPlayerScript", {PLAYERHOOK_ON_LOGOUT})
    {
    }

    void OnPlayerLogout(Player* player) override
    {
        AscensionPersonalBank::Closed(player);
    }
};

class item_ascension_bank_tab_voucher : public ItemScript
{
public:
    item_ascension_bank_tab_voucher() : ItemScript("item_ascension_bank_tab_voucher") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        uint8 kind = 0;
        char const* which = nullptr;
        switch (item->GetEntry())
        {
            case 110002:
            case 134986:
                kind = AscensionPersonalBank::PERSONAL;
                which = "personal bank";
                break;
            case 1180485:
                kind = AscensionPersonalBank::REALM;
                which = "realm bank";
                break;
            default:
                return false;
        }

        player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);

        if (!AscensionPersonalBank::AddTab(player, kind))
        {
            ChatHandler(player->GetSession())
                .PSendSysMessage("Your {} already owns every tab.", which);
            return true;
        }

        ChatHandler(player->GetSession())
            .PSendSysMessage("A new tab has been unlocked in your {}.", which);

        uint32 count = 1;
        player->DestroyItemCount(item, count, true);
        return true;
    }
};
}

void AddSC_AscensionPersonalBank()
{
    new AscensionPersonalBankPlayerScript();
    new item_ascension_bank_tab_voucher();
}
