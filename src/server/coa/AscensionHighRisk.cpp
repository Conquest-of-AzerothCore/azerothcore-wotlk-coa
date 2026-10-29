/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionFelCommutation.h"
#include "AscensionFelCommutationPolicy.h"
#include "AscensionHighRiskPolicy.h"
#include "AscensionBloodforging.h"
#include "Bag.h"
#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Errors.h"
#include "GameObject.h"
#include "Group.h"
#include "Item.h"
#include "LFGMgr.h"
#include "LootMgr.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "Random.h"
#include "StringFormat.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <map>
#include <memory>
#include <mutex>

namespace HighRisk
{
struct StoredItem
{
    uint32 guid = 0;
    uint32 entry = 0;
    uint32 count = 0;
    int32 property = 0;
    uint32 suffix = 0;
    bool claimed = false;
};

struct Chest
{
    uint64 id = 0;
    uint32 owner = 0;
    uint32 map = 0;
    uint32 phase = 1;
    Position position;
    uint32 gold = 0;
    ObjectGuid object;
    std::map<uint8, StoredItem> items;

    bool Empty() const
    {
        return !gold && std::all_of(items.begin(), items.end(),
            [](auto const& row) { return row.second.claimed; });
    }
};

std::mutex mutex;
std::map<uint64, Chest> chests;
uint64 nextId = 0;
std::atomic_bool loaded{false};
std::atomic_bool enabled{false};
std::atomic<float> gearChance{50.0f};
std::atomic<float> resourceChance{50.0f};
std::atomic<float> goldChance{50.0f};

bool OpenWorld(Player const* player)
{
    return player->GetMap() && !player->GetMap()->Instanceable();
}

std::string SelectItemInstance(uint64 chestId, uint8 slot)
{
    return Acore::StringFormat(
        "SELECT ii.creatorGuid,ii.giftCreatorGuid,ii.count,ii.duration,ii.charges,ii.flags,ii.enchantments,"
        "ii.randomPropertyId,ii.durability,ii.playedTime,ii.text,ii.guid,ii.itemEntry "
        "FROM highrisk_chest_item ci JOIN item_instance ii ON ii.guid=ci.item_guid "
        "WHERE ci.chest_id={} AND ci.slot={} AND ci.claimant=0 AND ii.owner_guid=0 "
        "AND NOT EXISTS (SELECT 1 FROM character_inventory inv WHERE inv.item=ii.guid)", chestId, uint32(slot));
}

bool InHighRisk(Player const* player)
{
    return player->HasAura(HighRiskAura);
}

bool CannotQueue(Player const* player)
{
    return QueueBlocked(InHighRisk(player), OpenWorld(player), player->HasPlayerFlag(PLAYER_FLAGS_RESTING),
        player->GetSession()->IsBot());
}

bool RefuseOutsideRest(Player* player, bool wholeGroup, std::string_view action)
{
    Player* blocked = CannotQueue(player) ? player : nullptr;
    if (Group* group = wholeGroup ? player->GetGroup() : nullptr)
        for (GroupReference* member = group->GetFirstMember(); member && !blocked; member = member->next())
            if (Player* source = member->GetSource(); source && CannotQueue(source))
                blocked = source;
    if (!blocked)
        return false;

    ChatHandler(player->GetSession()).SendSysMessage(Acore::StringFormat(
        "{} must be in a city or inn to {} while in High-Risk.", blocked == player ? "You" : blocked->GetName(),
        action));
    return true;
}

void Commit(CharacterDatabaseTransaction transaction)
{
    auto result = CharacterDatabase.AsyncCommitTransaction(transaction);
    if (!result.m_future.get())
        ABORT("High Risk inventory transaction failed; refusing to continue");
}

bool Transferable(Item const* item)
{
    if (!item || item->IsBag() || item->IsSoulBound() || item->IsBoundAccountWide()
        || item->IsInTrade() || item->IsWrapped()
        || item->IsRefundable() || item->IsBOPTradable() || item->GetCount() > 255)
        return false;

    auto const* info = item->GetTemplate();
    if (info->StartQuest || info->Duration || info->Bonding == BIND_QUEST_ITEM
        || info->HasFlag(ITEM_FLAG_CONJURED)
        || item->GetEnchantmentDuration(TEMP_ENCHANTMENT_SLOT))
        return false;

    return info->Class == ITEM_CLASS_ARMOR || info->Class == ITEM_CLASS_WEAPON
        || info->Class == ITEM_CLASS_TRADE_GOODS;
}

void FillLoot(GameObject* object, Chest const& chest)
{
    auto& loot = object->loot;
    loot.clear();
    loot.sourceWorldObjectGUID = object->GetGUID();
    loot.loot_type = LOOT_CORPSE;
    loot.gold = chest.gold;
    if (!chest.items.empty())
        loot.items.resize(chest.items.rbegin()->first + 1);

    for (auto& item : loot.items)
        item.is_looted = true;

    for (auto const& [slot, stored] : chest.items)
    {
        auto& item = loot.items[slot];
        item.itemid = stored.entry;
        item.itemIndex = slot;
        item.count = stored.count;
        item.randomPropertyId = stored.property;
        item.randomSuffix = stored.suffix;
        item.is_looted = stored.claimed;
        item.is_underthreshold = true;
        item.is_counted = true;
        if (!stored.claimed)
            ++loot.unlootedCount;
    }
    object->SetLootState(GO_ACTIVATED);
}

void Spawn(Map* map, Chest& chest)
{
    if (chest.Empty() || chest.map != map->GetId() || map->GetInstanceId())
        return;
    if (chest.object && map->GetGameObject(chest.object))
        return;

    bool nearby = false;
    for (auto const& reference : map->GetPlayers())
        if (Player* player = reference.GetSource())
            if (player->GetExactDist(&chest.position) < 200.0f)
            {
                nearby = true;
                break;
            }
    if (!nearby)
        return;

    auto object = std::make_unique<GameObject>();
    auto const& p = chest.position;
    if (!object->Create(map->GenerateLowGuid<HighGuid::GameObject>(), ChestEntry, map, chest.phase,
        p.GetPositionX(), p.GetPositionY(), p.GetPositionZ(), p.GetOrientation(),
        G3D::Quat(0, 0, 0, 1), 255, GO_STATE_READY))
        return;

    object->SetSpawnedByDefault(false);
    object->SetRespawnTime(0);
    FillLoot(object.get(), chest);
    if (map->AddToMap(object.get()))
    {
        chest.object = object->GetGUID();
        object.release();
    }
}

Chest* Find(GameObject const* object)
{
    if (!object || object->GetEntry() != ChestEntry)
        return nullptr;
    for (auto& [id, chest] : chests)
        if (chest.map == object->GetMapId() && chest.object == object->GetGUID())
            return &chest;
    return nullptr;
}

bool Access(Player* player, GameObject* object)
{
    return player && object && player->IsAlive() && OpenWorld(player)
        && player->InSamePhase(object) && object->IsWithinDistInMap(player, INTERACTION_DISTANCE)
        && !player->HasPlayerFlag(PLAYER_FLAGS_NO_PLAY_TIME)
        && !player->GetSession()->IsBot() && player->GetLevel() >= MinimumLevel && InHighRisk(player);
}

void Close(Player* player, GameObject* object)
{
    object->loot.RemoveLooter(player->GetGUID());
    player->SetLootGUID(ObjectGuid::Empty);
    player->RemoveUnitFlag(UNIT_FLAG_LOOTING);
    player->SendLootRelease(object->GetGUID());
}

void Open(Player* player, GameObject* object)
{
    if (!Access(player, object))
    {
        ChatHandler(player->GetSession()).SendSysMessage(
            "You must be alive, in High-Risk mode and close to the chest to recover its contents.");
        LOG_INFO("server.worldserver", "High Risk chest access denied for {}: alive {}, mode {}, distance {}",
            player->GetGUID().ToString(), player->IsAlive(), InHighRisk(player), player->GetDistance(object));
        player->SendLootError(object->GetGUID(), LOOT_ERROR_DIDNT_KILL);
        return;
    }
    if (player->GetLootGUID())
        player->GetSession()->DoLootRelease(player->GetLootGUID());

    std::lock_guard<std::mutex> lock(mutex);
    Chest* chest = Find(object);
    if (!chest || chest->Empty())
    {
        player->SendLootRelease(object->GetGUID());
        return;
    }
    player->RemoveAurasByType(SPELL_AURA_MOD_STEALTH);
    player->RemoveAurasByType(SPELL_AURA_MOD_INVISIBILITY);
    player->RemoveAurasByType(SPELL_AURA_FEIGN_DEATH);
    player->SetLootGUID(object->GetGUID());
    WorldPacket packet(SMSG_LOOT_RESPONSE, 80);
    packet << object->GetGUID() << uint8(LOOT_CORPSE) << LootView(object->loot, player, ALL_PERMISSION);
    player->SendDirectMessage(&packet);
    object->loot.AddLooter(player->GetGUID());
    player->SetUnitFlag(UNIT_FLAG_LOOTING);
    LOG_INFO("server.worldserver", "High Risk chest {} opened by {}", chest->id, player->GetGUID().ToString());
}

void ClaimItem(Player* player, GameObject* object, uint8 slot)
{
    if (!Access(player, object))
    {
        Close(player, object);
        return;
    }
    std::lock_guard<std::mutex> lock(mutex);
    Chest* chest = Find(object);
    if (!chest)
        return;
    auto found = chest->items.find(slot);
    if (found == chest->items.end() || found->second.claimed)
        return;
    if (slot >= object->loot.items.size()
        || !object->loot.items[slot].AllowedForPlayer(player, object->GetGUID()))
        return;

    QueryResult result = CharacterDatabase.Query(SelectItemInstance(chest->id, slot));
    if (!result)
        return;

    Field* fields = result->Fetch();
    auto item = std::make_unique<Item>();
    if (!item->LoadFromDB(fields[11].Get<uint32>(), ObjectGuid::Empty, fields, fields[12].Get<uint32>()))
        return;
    ItemPosCountVec destination;
    InventoryResult error = player->CanStoreItem(NULL_BAG, NULL_SLOT, destination, item.get(), false);
    if (error != EQUIP_ERR_OK)
    {
        player->SendEquipError(error, item.get(), nullptr);
        return;
    }

    uint32 entry = item->GetEntry();
    uint32 count = item->GetCount();
    item->SetState(ITEM_UNCHANGED);
    auto transaction = CharacterDatabase.BeginTransaction();
    player->MoveItemToInventory(destination, item.release(), true);
    player->SaveInventoryAndGoldToDB(transaction);
    transaction->Append(
        "UPDATE highrisk_chest_item SET claimant={},claimed_at=CURRENT_TIMESTAMP WHERE chest_id={} AND slot={} "
        "AND claimant=0", player->GetGUID().GetCounter(), chest->id, uint32(slot));
    Commit(transaction);
    found->second.claimed = true;
    if (!destination.empty())
        if (Item* received = player->GetItemByPos(destination.back().pos))
            player->SendNewItem(received, count, false, false, true);
    object->loot.items[slot].is_looted = true;
    --object->loot.unlootedCount;
    object->loot.NotifyItemRemoved(slot);
    LOG_INFO("server.worldserver", "High Risk chest {}: {} recovered item {} x{} (original GUID {})",
        chest->id, player->GetGUID().ToString(), entry, count, found->second.guid);
    if (chest->Empty())
    {
        Close(player, object);
        object->AddObjectToRemoveList();
    }
}

void ClaimGold(Player* player, GameObject* object)
{
    if (!Access(player, object))
    {
        Close(player, object);
        return;
    }
    std::lock_guard<std::mutex> lock(mutex);
    Chest* chest = Find(object);
    if (!chest || !chest->gold)
        return;
    if (uint64(player->GetMoney()) + chest->gold > MAX_MONEY_AMOUNT)
    {
        ChatHandler(player->GetSession()).SendSysMessage("You cannot carry any more gold.");
        return;
    }

    uint32 gold = chest->gold;
    auto transaction = CharacterDatabase.BeginTransaction();
    player->ModifyMoney(gold);
    player->SaveInventoryAndGoldToDB(transaction);
    transaction->Append(
        "UPDATE highrisk_chest SET gold=0,gold_claimant={},gold_claimed_at=CURRENT_TIMESTAMP WHERE id={} AND gold>0",
        player->GetGUID().GetCounter(), chest->id);
    Commit(transaction);
    chest->gold = 0;
    object->loot.gold = 0;
    object->loot.NotifyMoneyRemoved();
    WorldPacket packet(SMSG_LOOT_MONEY_NOTIFY, 5);
    packet << gold << uint8(1);
    player->SendDirectMessage(&packet);
    if (chest->Empty())
    {
        Close(player, object);
        object->AddObjectToRemoveList();
    }
}

void Drop(Player* player)
{
    if (!enabled || !loaded || !OpenWorld(player) || player->GetLevel() < MinimumLevel
        || player->GetSession()->IsBot())
        return;
    if (!Eligible(player->GetLevel(), InHighRisk(player), !OpenWorld(player), player->GetSession()->IsBot()))
        return;

    std::vector<Item*> gear;
    std::vector<Item*> resources;
    std::vector<Item*> insurable;
    auto add = [&](Item* item)
    {
        if (!Transferable(item))
            return;
        if (item->GetTemplate()->Class == ITEM_CLASS_TRADE_GOODS)
            resources.push_back(item);
        else
        {
            gear.push_back(item);
            if (item->IsEquipped() && FelCommutation::Insurable(item->GetSlot() + 1))
                insurable.push_back(item);
        }
    };
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        add(player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
    for (uint8 bag = INVENTORY_SLOT_BAG_START; bag < INVENTORY_SLOT_BAG_END; ++bag)
        if (Bag* container = player->GetBagByPos(bag))
            for (uint32 slot = 0; slot < container->GetBagSize(); ++slot)
                add(container->GetItemByPos(slot));

    std::vector<Item*> losses;
    auto choose = [&](std::vector<Item*>& pool)
    {
        if (pool.empty())
            return;
        uint32 index = urand(0, pool.size() - 1);
        losses.push_back(pool[index]);
        pool.erase(pool.begin() + index);
    };
    if (roll_chance_f(gearChance.load()))
        for (unsigned i = 0, count = urand(1, GearLimit(player->GetLevel())); i < count; ++i)
            choose(gear);
    if (roll_chance_f(resourceChance.load()))
        choose(resources);
    uint32 const insuranceFee = FelCommutation::Shield(player, insurable, losses);
    uint32 const carried = player->GetMoney() > insuranceFee ? player->GetMoney() - insuranceFee : 0;
    uint32 gold = roll_chance_f(goldChance.load()) ? GoldLoss(carried, urand(1, 5)) : 0;
    if (losses.empty() && !gold && !insuranceFee)
    {
        std::vector<unsigned> available;
        if (!gear.empty() && gearChance > 0.0f)
            available.push_back(0);
        if (!resources.empty() && resourceChance > 0.0f)
            available.push_back(1);
        if (carried && goldChance > 0.0f)
            available.push_back(2);
        if (!available.empty())
            switch (available[urand(0, available.size() - 1)])
            {
                case 0:
                    choose(gear);
                    break;
                case 1:
                    choose(resources);
                    break;
                case 2:
                    gold = std::max(uint32(1), GoldLoss(carried, urand(1, 5)));
                    break;
            }
    }
    if (losses.empty() && !gold && !insuranceFee)
    {
        ChatHandler(player->GetSession()).SendSysMessage(
            "No High-Risk chest was created: you have no eligible items or money to lose.");
        LOG_INFO("server.worldserver", "High Risk death for {}: no eligible losses; map {}, level {}",
            player->GetGUID().ToString(), player->GetMapId(), player->GetLevel());
        return;
    }

    FelCommutation::ReportLoss(player, insuranceFee, gold);
    std::lock_guard<std::mutex> lock(mutex);
    Chest chest;
    chest.id = ++nextId;
    chest.owner = player->GetGUID().GetCounter();
    chest.map = player->GetMapId();
    chest.phase = player->GetPhaseMask();
    chest.position.Relocate(player);
    chest.gold = gold + insuranceFee;
    auto transaction = CharacterDatabase.BeginTransaction();
    transaction->Append(
        "INSERT INTO highrisk_chest (id,owner,map,phase,x,y,z,o,gold,original_gold) "
        "VALUES ({},{},{},{},{},{},{},{},{},{})", chest.id, chest.owner, chest.map, chest.phase,
        chest.position.GetPositionX(), chest.position.GetPositionY(), chest.position.GetPositionZ(),
        chest.position.GetOrientation(), chest.gold, chest.gold);

    uint8 slot = 0;
    for (Item* item : losses)
    {
        player->MoveItemFromInventory(item->GetBagSlot(), item->GetSlot(), true);
        item->DeleteFromInventoryDB(transaction);
        Bloodforging::Convert(*item, Bloodforging::Method::HighRiskDrop);
        StoredItem stored{item->GetGUID().GetCounter(), item->GetEntry(), item->GetCount(),
            item->GetItemRandomPropertyId(), item->GetItemSuffixFactor(), false};
        if (item->GetState() == ITEM_UNCHANGED)
            item->FSetState(ITEM_CHANGED);
        item->SetOwnerGUID(ObjectGuid::Empty);
        item->SaveToDB(transaction);
        transaction->Append(
            "INSERT INTO highrisk_chest_item (chest_id,slot,item_guid,entry,count) VALUES ({},{},{},{},{})",
            chest.id, uint32(slot), stored.guid, stored.entry, stored.count);
        chest.items.emplace(slot++, stored);
    }
    player->ModifyMoney(-int32(chest.gold));
    player->SaveInventoryAndGoldToDB(transaction);
    Commit(transaction);
    for (Item* item : losses)
        delete item;
    auto [found, inserted] = chests.emplace(chest.id, std::move(chest));
    Spawn(player->GetMap(), found->second);
    ChatHandler(player->GetSession()).SendSysMessage(
        "Your High-Risk losses are in a chest at your death location. Any High-Risk player can recover them.");
    LOG_INFO("server.worldserver", "High Risk chest {} created for {}: {} items, {} copper",
        found->first, player->GetGUID().ToString(), losses.size(), chest.gold);
}

class RiskWorld final : public WorldScript
{
public:
    RiskWorld() : WorldScript("highrisk_world", {WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnAfterConfigLoad(bool) override
    {
        enabled = sConfigMgr->GetOption<bool>("HighRisk.Losses", false);
        gearChance = std::clamp(sConfigMgr->GetOption<float>("HighRisk.GearChance", 50.0f), 0.0f, 100.0f);
        resourceChance = std::clamp(sConfigMgr->GetOption<float>("HighRisk.ResourceChance", 50.0f), 0.0f, 100.0f);
        goldChance = std::clamp(sConfigMgr->GetOption<float>("HighRisk.GoldChance", 50.0f), 0.0f, 100.0f);
    }

    void OnStartup() override
    {
        OnAfterConfigLoad(false);
        std::lock_guard<std::mutex> lock(mutex);
        auto result = CharacterDatabase.Query("SELECT COALESCE(MAX(id),0) FROM highrisk_chest");
        ASSERT(result, "High Risk chest schema is missing");
        nextId = result->Fetch()[0].Get<uint64>();
        result = CharacterDatabase.Query(
            "SELECT id,owner,map,phase,x,y,z,o,gold FROM highrisk_chest c WHERE gold>0 OR EXISTS "
            "(SELECT 1 FROM highrisk_chest_item i WHERE i.chest_id=c.id AND i.claimant=0)");
        if (result)
        {
            do
            {
                Field* f = result->Fetch();
                Chest chest;
                chest.id = f[0].Get<uint64>();
                chest.owner = f[1].Get<uint32>();
                chest.map = f[2].Get<uint16>();
                chest.phase = f[3].Get<uint32>();
                chest.position.Relocate(f[4].Get<float>(), f[5].Get<float>(), f[6].Get<float>(), f[7].Get<float>());
                chest.gold = f[8].Get<uint32>();
                if (auto items = CharacterDatabase.Query(
                    "SELECT ci.slot,ci.item_guid,ci.entry,ci.count,ii.randomPropertyId FROM highrisk_chest_item ci "
                    "LEFT JOIN item_instance ii ON ii.guid=ci.item_guid WHERE ci.chest_id={} AND ci.claimant=0",
                    chest.id))
                {
                    do
                    {
                        Field* i = items->Fetch();
                        auto instance = CharacterDatabase.Query(SelectItemInstance(chest.id, i[0].Get<uint8>()));
                        if (!instance)
                        {
                            LOG_ERROR("coa.highrisk", "Chest {} slot {}: escrow inconsistency; new losses disabled",
                                chest.id, i[0].Get<uint8>());
                            enabled = false;
                            continue;
                        }
                        Item item;
                        if (!item.LoadFromDB(i[1].Get<uint32>(), ObjectGuid::Empty, instance->Fetch(), i[2].Get<uint32>()))
                        {
                            LOG_ERROR("coa.highrisk", "Chest {}: item {} cannot load; new losses disabled",
                                chest.id, i[1].Get<uint32>());
                            enabled = false;
                            continue;
                        }
                        chest.items.emplace(i[0].Get<uint8>(), StoredItem{i[1].Get<uint32>(), i[2].Get<uint32>(),
                            i[3].Get<uint32>(), i[4].Get<int32>(), item.GetItemSuffixFactor(), false});
                    } while (items->NextRow());
                }
                chests.emplace(chest.id, std::move(chest));
            } while (result->NextRow());
        }
        loaded = true;
        LOG_INFO("server.worldserver", "Restored {} High Risk chests; losses {}", chests.size(), enabled.load());
    }
};

class RiskPlayer final : public PlayerScript
{
public:
    RiskPlayer() : PlayerScript("highrisk_death", {PLAYERHOOK_ON_PLAYER_JUST_DIED, PLAYERHOOK_ON_LOGIN}) { }
    void OnPlayerJustDied(Player* player) override { Drop(player); }

    void OnPlayerLogin(Player* player) override
    {
        if (player->GetSession()->IsBot())
            return;
        WorldPacket query(CMSG_GAMEOBJECT_QUERY, 12);
        query << uint32(ChestEntry) << ObjectGuid::Empty;
        player->GetSession()->HandleGameObjectQueryOpcode(query);
    }
};

class RiskQueues final : public PlayerScript
{
public:
    RiskQueues() : PlayerScript("highrisk_queues", {PLAYERHOOK_CAN_JOIN_LFG, PLAYERHOOK_CAN_LFG_TELEPORT,
        PLAYERHOOK_CAN_JOIN_IN_BATTLEGROUND_QUEUE, PLAYERHOOK_CAN_JOIN_IN_ARENA_QUEUE,
        PLAYERHOOK_CAN_BATTLEFIELD_PORT}) { }

    bool OnPlayerCanJoinLfg(Player* player, uint8, lfg::LfgDungeonSet&, std::string const&) override
    {
        if (!RefuseOutsideRest(player, true, "queue"))
            return true;
        player->GetSession()->SendLfgJoinResult(lfg::LfgJoinResultData(
            player->GetGroup() ? lfg::LFG_JOIN_PARTY_NOT_MEET_REQS : lfg::LFG_JOIN_NOT_MEET_REQS));
        return false;
    }

    bool OnPlayerCanJoinInBattlegroundQueue(Player* player, ObjectGuid, BattlegroundTypeId, uint8 joinAsGroup,
        GroupJoinBattlegroundResult& err) override
    {
        return !Refuse(player, joinAsGroup, err);
    }

    bool OnPlayerCanJoinInArenaQueue(Player* player, ObjectGuid, uint8, BattlegroundTypeId, uint8 joinAsGroup,
        uint8, GroupJoinBattlegroundResult& err) override
    {
        return !Refuse(player, joinAsGroup, err);
    }

    bool OnPlayerCanLfgTeleport(Player* player) override
    {
        return !RefuseOutsideRest(player, false, "teleport into a dungeon");
    }

    bool OnPlayerCanBattleFieldPort(Player* player, uint8, BattlegroundTypeId, uint8 action) override
    {
        return action != BattlefieldPortEnter || !RefuseOutsideRest(player, false, "enter");
    }

private:
    static constexpr uint8 BattlefieldPortEnter = 1;

    static bool Refuse(Player* player, uint8 joinAsGroup, GroupJoinBattlegroundResult& err)
    {
        if (!RefuseOutsideRest(player, joinAsGroup, "queue"))
            return false;
        err = ERR_BATTLEGROUND_NONE;
        return true;
    }
};

class RiskMaps final : public AllMapScript
{
public:
    RiskMaps() : AllMapScript("highrisk_maps", {ALLMAPHOOK_ON_MAP_UPDATE}) { }
    void OnMapUpdate(Map* map, uint32 diff) override
    {
        if (!loaded || map->Instanceable())
            return;
        std::lock_guard<std::mutex> lock(mutex);
        uint32& elapsed = refresh[map->GetId()];
        elapsed += diff;
        if (elapsed < 1000)
            return;
        elapsed = 0;
        for (auto it = chests.begin(); it != chests.end();)
        {
            if (it->second.Empty())
                it = chests.erase(it);
            else
            {
                Spawn(map, it->second);
                ++it;
            }
        }
    }

private:
    std::map<uint32, uint32> refresh;
};

class RiskChest final : public GameObjectScript
{
public:
    RiskChest() : GameObjectScript("highrisk_chest") { }
    bool OnGossipHello(Player* player, GameObject* object) override
    {
        Open(player, object);
        return true;
    }
};

class RiskPackets final : public ServerScript
{
public:
    RiskPackets() : ServerScript("highrisk_loot", {SERVERHOOK_CAN_PACKET_RECEIVE}) { }
    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        if (!session || !session->GetPlayer())
            return true;
        Player* player = session->GetPlayer();
        if (!player->IsInWorld())
            return true;

        auto opcode = packet.GetOpcode();
        if (opcode == CMSG_LOOT || opcode == CMSG_GAMEOBJ_USE || opcode == CMSG_GAMEOBJ_REPORT_USE)
        {
            if (packet.size() < 8)
                return true;
            ObjectGuid guid(packet.read<uint64>(0));
            if (!guid.IsGameObject())
                return true;
            GameObject* object = player->GetMap()->GetGameObject(guid);
            if (!object || object->GetEntry() != ChestEntry)
                return true;
            Open(player, object);
            return false;
        }
        if (opcode != CMSG_AUTOSTORE_LOOT_ITEM && opcode != CMSG_LOOT_MONEY
            && opcode != CMSG_LOOT_MASTER_GIVE && opcode != CMSG_LOOT_RELEASE)
            return true;
        ObjectGuid guid = player->GetLootGUID();
        if (!guid.IsGameObject())
            return true;
        GameObject* object = player->GetMap()->GetGameObject(guid);
        if (!object || object->GetEntry() != ChestEntry)
            return true;
        if (opcode == CMSG_AUTOSTORE_LOOT_ITEM && packet.size())
            ClaimItem(player, object, packet.read<uint8>(0));
        else if (opcode == CMSG_LOOT_MONEY)
            ClaimGold(player, object);
        else if (opcode == CMSG_LOOT_RELEASE)
            Close(player, object);
        return false;
    }
};
}

void AddSC_AscensionHighRisk()
{
    new HighRisk::RiskWorld();
    new HighRisk::RiskPlayer();
    new HighRisk::RiskQueues();
    new HighRisk::RiskMaps();
    new HighRisk::RiskChest();
    new HighRisk::RiskPackets();
}
