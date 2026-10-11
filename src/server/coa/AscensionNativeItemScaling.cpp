/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionNativeItemScaling.h"
#include "AscensionCompatOpcodes.h"
#include "AscensionItemLadder.h"
#include "AscensionItemScaling.h"
#include "Bag.h"
#include "Config.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Group.h"
#include "Item.h"
#include "LocalLevelScaling.h"
#include "Log.h"
#include "Mail.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "QuestDef.h"
#include "Timer.h"
#include "World.h"
#include "WorldScript.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <shared_mutex>
#include <unordered_map>
#include <vector>

namespace NativeItemScaling
{
namespace
{
constexpr uint32 HeaderBytes = 20;
constexpr uint32 ScanChunkRecords = 8192;

std::atomic<bool> enabled{false};
std::atomic<int32> lootLevelOffset{0};
std::atomic<bool> questRewards{true};
std::atomic<bool> levelKeys{false};
std::atomic<bool> preview{false};

class LadderStore
{
public:
    static LadderStore& Instance()
    {
        static LadderStore store;
        return store;
    }

    bool Load(std::filesystem::path const& path)
    {
        std::ifstream file(path, std::ios::binary);
        uint32 header[5] = {};
        if (!file || !file.read(reinterpret_cast<char*>(header), sizeof(header)) || header[0] != 0x43424457 ||
            header[2] != ItemLadder::RecordFields || header[3] != ItemLadder::RecordSize)
            return false;

        uint32 const records = header[1];
        std::unordered_map<uint32, std::vector<Span>> spans;
        std::vector<uint8> chunk(std::size_t(ScanChunkRecords) * ItemLadder::RecordSize);
        for (uint32 first = 0; first < records; first += ScanChunkRecords)
        {
            uint32 const count = std::min(ScanChunkRecords, records - first);
            if (!file.read(reinterpret_cast<char*>(chunk.data()), std::streamsize(count) * ItemLadder::RecordSize))
                return false;

            for (uint32 i = 0; i < count; ++i)
            {
                uint8 const* record = chunk.data() + std::size_t(i) * ItemLadder::RecordSize;
                uint32 itemId;
                uint32 level;
                std::memcpy(&itemId, record + sizeof(uint32), sizeof(uint32));
                std::memcpy(&level, record + 2 * sizeof(uint32), sizeof(uint32));
                if (level < 1 || level > ItemLadder::MaxLevel)
                    continue;

                std::vector<Span>& itemSpans = spans[itemId];
                if (!itemSpans.empty() && itemSpans.back().First + itemSpans.back().Count == first + i)
                    ++itemSpans.back().Count;
                else
                    itemSpans.push_back({ first + i, 1 });
            }
        }

        std::unique_lock lock(_mutex);
        _path = path;
        _spans = std::move(spans);
        _ladders.clear();
        return true;
    }

    bool Has(uint32 itemId) const
    {
        std::shared_lock lock(_mutex);
        return _spans.contains(itemId);
    }

    std::size_t Items() const
    {
        std::shared_lock lock(_mutex);
        return _spans.size();
    }

    ItemLadder::Row const* Row(uint32 itemId, uint32 level)
    {
        {
            std::shared_lock lock(_mutex);
            if (auto const ladder = _ladders.find(itemId); ladder != _ladders.end())
                return ladder->second.At(level);
            if (!_spans.contains(itemId))
                return nullptr;
        }

        std::unique_lock lock(_mutex);
        auto [ladder, inserted] = _ladders.try_emplace(itemId);
        if (inserted)
            ladder->second = ItemLadder::Ladder(ReadRows(_spans.at(itemId)), sObjectMgr->GetItemTemplate(itemId));
        return ladder->second.At(level);
    }

private:
    struct Span
    {
        uint32 First;
        uint32 Count;
    };

    std::vector<ItemLadder::Row> ReadRows(std::vector<Span> const& spans) const
    {
        std::vector<ItemLadder::Row> rows;
        std::ifstream file(_path, std::ios::binary);
        std::vector<uint8> buffer;
        for (Span const& span : spans)
        {
            buffer.resize(std::size_t(span.Count) * ItemLadder::RecordSize);
            file.seekg(std::streamoff(HeaderBytes) + std::streamoff(span.First) * ItemLadder::RecordSize);
            if (!file.read(reinterpret_cast<char*>(buffer.data()), std::streamsize(buffer.size())))
            {
                LOG_ERROR("server.loading", "Native item scaling could not read ladder rows from {}", _path.string());
                return {};
            }

            for (uint32 i = 0; i < span.Count; ++i)
                rows.push_back(ItemLadder::ParseRecord(buffer.data() + std::size_t(i) * ItemLadder::RecordSize));
        }
        return rows;
    }

    mutable std::shared_mutex _mutex;
    std::filesystem::path _path;
    std::unordered_map<uint32, std::vector<Span>> _spans;
    std::unordered_map<uint32, ItemLadder::Ladder> _ladders;
};

std::shared_mutex levelsMutex;
std::unordered_map<ObjectGuid::LowType, uint8> instanceLevels;

std::mutex templatesMutex;
std::unordered_map<uint64, ItemTemplate> scaledTemplates;

uint8 StoredLevel(Item const* item)
{
    std::shared_lock lock(levelsMutex);
    auto const level = instanceLevels.find(item->GetGUID().GetCounter());
    return level == instanceLevels.end() ? 0 : level->second;
}

bool PreviewOn()
{
    return preview.load(std::memory_order_relaxed);
}

bool IsBot(Player const* player)
{
    return !player->GetSession() || player->GetSession()->IsBot();
}

bool IsScalingItem(ItemTemplate const* proto)
{
    return proto && ItemLadder::ScalableItem(*proto) && ItemScaling::LiftableEntry(proto->ItemId) &&
        LadderStore::Instance().Has(proto->ItemId);
}

uint32 ClientLevel(Item const* item)
{
    if (uint8 const level = StoredLevel(item))
        return level;
    ItemTemplate const* proto = item->GetTemplate();
    return PreviewOn() && IsScalingItem(proto) ? proto->ItemLevel : 0;
}

ItemTemplate const* InstanceTemplate(Item const* item)
{
    if (!enabled.load(std::memory_order_relaxed))
        return nullptr;

    uint8 const level = StoredLevel(item);
    ItemTemplate const* base = level ? item->GetTemplate() : nullptr;
    if (!base || (PreviewOn() && level == base->ItemLevel))
        return nullptr;

    ItemLadder::Row const* row = LadderStore::Instance().Row(base->ItemId, level);
    if (!row)
        return nullptr;

    std::lock_guard lock(templatesMutex);
    auto [scaled, inserted] = scaledTemplates.try_emplace((uint64(base->ItemId) << 8) | level, *base);
    if (inserted)
        ItemLadder::ApplyRow(scaled->second, *row);
    return &scaled->second;
}

void SendLevel(Player* player, Item const* item)
{
    if (uint32 const level = ClientLevel(item))
    {
        WorldPacket data = ItemLadder::BuildLevelAddon(item->GetGUID(), level);
        player->SendDirectMessage(&data);
    }
}

void SendAllLevels(Player* player)
{
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < PLAYER_SLOT_END; ++slot)
        if (Item const* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            SendLevel(player, item);

    auto sendBag = [player](uint8 slot)
    {
        if (Bag const* bag = player->GetBagByPos(slot))
            for (uint32 index = 0; index < bag->GetBagSize(); ++index)
                if (Item const* item = bag->GetItemByPos(uint8(index)))
                    SendLevel(player, item);
    };
    for (uint8 slot = INVENTORY_SLOT_BAG_START; slot < INVENTORY_SLOT_BAG_END; ++slot)
        sendBag(slot);
    for (uint8 slot = BANK_SLOT_BAG_START; slot < BANK_SLOT_BAG_END; ++slot)
        sendBag(slot);
}

void ItemArrived(Player* player, Item* item)
{
    if (enabled.load(std::memory_order_relaxed))
        SendLevel(player, item);
}

uint32 DropBase(Player const* looter)
{
    return ItemLadder::DropBase(looter->GetLevel(), lootLevelOffset.load(std::memory_order_relaxed));
}

bool ScalingChosenBy(Player const* player)
{
    return LocalLevelScaling::ScalingChoiceEnabled(player) &&
        !(LocalLevelScaling::ScalingBlocksFor(player) & LocalLevelScaling::ChallengeBlocksCreatureScaling);
}

void AssignLevel(Player* owner, Item* item, uint32 key)
{
    if (!enabled.load(std::memory_order_relaxed) || !owner || !item || item->IsEquipped() ||
        !ScalingChosenBy(owner))
        return;

    ItemTemplate const* proto = item->GetTemplate();
    if (!IsScalingItem(proto) || StoredLevel(item))
        return;

    uint8 const level = ItemLadder::ClampLevel(key);
    {
        std::unique_lock lock(levelsMutex);
        instanceLevels[item->GetGUID().GetCounter()] = level;
    }
    CharacterDatabase.Execute(
        "REPLACE INTO `character_item_scaling` (`item_guid`, `item_entry`, `scaling_level`) VALUES ({}, {}, {})",
        item->GetGUID().GetCounter(), proto->ItemId, level);
    SendLevel(owner, item);
}

void AssignDropLevel(Player* looter, Item* item, uint32 base = 0)
{
    if (!looter)
        return;

    if (!base)
        base = DropBase(looter);
    AssignLevel(looter, item, levelKeys.load(std::memory_order_relaxed) ? ItemLadder::ClientKey(base) : base);
}

void MasterLooted(Player* receiver, Item* item)
{
    AssignDropLevel(receiver, item);
}

void QuestRewardStored(Player* player, Item* item, Quest const* quest)
{
    if (!levelKeys.load(std::memory_order_relaxed) || !questRewards.load(std::memory_order_relaxed))
        return;

    LocalLevelScaling::QuestCurve const* curve = LocalLevelScaling::QuestCurveFor(quest->GetQuestId());
    uint32 const key = curve ? uint32(std::max<int32>(1, LocalLevelScaling::CurveLevel(*curve, player->GetLevel())))
                             : ItemLadder::ClientKey(player->GetLevel());
    AssignLevel(player, item, key);
}

uint32 RollLevel(Player* roller)
{
    if (IsBot(roller) || !ScalingChosenBy(roller))
        return 0;

    uint32 const base = DropBase(roller);
    WorldPacket data = ItemLadder::BuildRollLevel(base);
    roller->SendDirectMessage(&data);
    return base;
}

uint32 CorpseLevel(Player* viewer, Creature const* corpse)
{
    if (IsBot(viewer) || corpse->IsAlive() || !corpse->HasDynamicFlag(UNIT_DYNFLAG_LOOTABLE) ||
        !viewer->isAllowedToLoot(corpse) || !ScalingChosenBy(viewer))
        return 0;
    return std::min<uint32>(DropBase(viewer), 255);
}

void Inspected(Player* inspector, Player* target)
{
    if (IsBot(inspector))
        return;

    std::array<uint32, ItemLadder::InspectSlots> levels{};
    for (uint8 slot = 0; slot < ItemLadder::InspectSlots; ++slot)
        if (Item const* item = target->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            if (uint32 const key = ClientLevel(item))
                levels[slot] = ItemLadder::ClientBaseForKey(key);

    WorldPacket data = ItemLadder::BuildInspectLevels(levels);
    inspector->SendDirectMessage(&data);
}

void MailListed(Player* player)
{
    if (IsBot(player))
        return;

    for (Mail const* mail : player->GetMails())
        for (MailItemInfo const& info : mail->items)
            if (Item const* item = player->GetMItem(info.item_guid))
                SendLevel(player, item);
}

uint32 AuctionLevel(uint32 itemGuidLow, ItemTemplate const* proto)
{
    {
        std::shared_lock lock(levelsMutex);
        if (auto const level = instanceLevels.find(itemGuidLow); level != instanceLevels.end())
            return level->second;
    }
    return IsScalingItem(proto) ? proto->ItemLevel : 0;
}

constexpr LocalLevelScaling::ItemPreviewHooks PreviewHooks = { &RollLevel, &CorpseLevel, &Inspected,
    &MailListed, &AuctionLevel };

void SendPreviewFlag(Player* player)
{
    if (!PreviewOn() || IsBot(player))
        return;

    WorldPacket data = ItemLadder::BuildPreviewAddon(player->GetGUID());
    player->SendDirectMessage(&data);
}

bool HandleItemStatQuery(WorldSession* session, WorldPacket const& packet)
{
    if (!session || packet.size() < 2 * sizeof(uint32) || !enabled.load(std::memory_order_relaxed))
        return true;

    uint32 const itemId = packet.read<uint32>(0);
    uint32 const level = packet.read<uint32>(sizeof(uint32));
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
    if (!level || !proto)
        return true;

    if (PreviewOn() && level == proto->ItemLevel)
    {
        WorldPacket stock = ItemLadder::BuildItemStatResponse(itemId, level, ItemLadder::StockRow(*proto), proto);
        session->SendPacket(&stock);
        return true;
    }

    ItemLadder::Row const* row = LadderStore::Instance().Row(itemId, level);
    if (!row)
        return true;

    WorldPacket reply = ItemLadder::BuildItemStatResponse(itemId, level, *row, proto);
    session->SendPacket(&reply);
    return true;
}

void LoadInstanceLevels()
{
    CharacterDatabase.DirectExecute("DELETE `s` FROM `character_item_scaling` `s` LEFT JOIN `item_instance` `i` "
        "ON `i`.`guid` = `s`.`item_guid` WHERE `i`.`guid` IS NULL");

    std::unordered_map<ObjectGuid::LowType, uint8> levels;
    if (QueryResult result = CharacterDatabase.Query("SELECT `item_guid`, `scaling_level` FROM `character_item_scaling`"))
    {
        do
        {
            Field const* fields = result->Fetch();
            levels[fields[0].Get<uint32>()] = fields[1].Get<uint8>();
        } while (result->NextRow());
    }

    std::size_t const count = levels.size();
    {
        std::unique_lock lock(levelsMutex);
        instanceLevels = std::move(levels);
    }
    LOG_INFO("server.loading", ">> Loaded {} native item scaling levels", count);
}

class Configuration : public WorldScript
{
public:
    Configuration() : WorldScript("NativeItemScalingConfiguration",
        { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP }) { }

    void OnAfterConfigLoad(bool reload) override
    {
        if (!reload)
            _requested = sConfigMgr->GetOption<bool>("CoA.ItemScaling.Native", true);
        lootLevelOffset.store(sConfigMgr->GetOption<int32>("CoA.ItemScaling.Native.LootLevelOffset", 0),
            std::memory_order_relaxed);
        questRewards.store(sConfigMgr->GetOption<bool>("CoA.ItemScaling.Native.QuestRewards", true),
            std::memory_order_relaxed);
        if (reload)
            return;

        levelKeys.store(sConfigMgr->GetOption<bool>("CoA.ItemScaling.Native.LevelKeys", false),
            std::memory_order_relaxed);
        _previewRequested = sConfigMgr->GetOption<bool>("CoA.ItemScaling.Native.Preview", false);
        if (_previewRequested && !levelKeys.load(std::memory_order_relaxed))
        {
            LOG_ERROR("server.loading", "CoA.ItemScaling.Native.Preview needs CoA.ItemScaling.Native.LevelKeys; "
                "the loot preview stays off");
            _previewRequested = false;
        }
    }

    void OnStartup() override
    {
        if (!_requested)
            return;

        uint32 const started = getMSTime();
        std::filesystem::path const path = std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "ItemStat.dbc";
        if (!LadderStore::Instance().Load(path))
        {
            LOG_ERROR("server.loading", "Native item scaling is off: {} is missing or not an ItemStat table",
                path.string());
            return;
        }

        LoadInstanceLevels();
        enabled.store(true, std::memory_order_relaxed);
        if (_previewRequested)
        {
            preview.store(true, std::memory_order_relaxed);
            LocalLevelScaling::ItemPreviewOwner.store(&PreviewHooks, std::memory_order_relaxed);
        }
        LOG_INFO("server.loading", ">> Indexed {} native item scaling ladders in {} ms",
            LadderStore::Instance().Items(), GetMSTimeDiffToNow(started));
    }

private:
    bool _requested = false;
    bool _previewRequested = false;
};

class Acquisition : public PlayerScript
{
public:
    Acquisition() : PlayerScript("NativeItemScalingAcquisition", { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOOT_ITEM,
        PLAYERHOOK_ON_GROUP_ROLL_REWARD_ITEM, PLAYERHOOK_ON_QUEST_REWARD_ITEM, PLAYERHOOK_ON_STORE_NEW_ITEM }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!enabled.load(std::memory_order_relaxed))
            return;

        SendPreviewFlag(player);
        SendAllLevels(player);
    }

    void OnPlayerStoreNewItem(Player* player, Item* item, uint32) override
    {
        if (PreviewOn() && player && item && !IsBot(player))
            SendLevel(player, item);
    }

    void OnPlayerLootItem(Player* player, Item* item, uint32, ObjectGuid) override
    {
        AssignDropLevel(player, item);
    }

    void OnPlayerGroupRollRewardItem(Player* player, Item* item, uint32, RollVote, Roll* roll) override
    {
        uint32 base = 0;
        if (roll && player)
            if (auto const previewed = roll->previewLevels.find(player->GetGUID());
                previewed != roll->previewLevels.end())
                base = previewed->second;
        AssignDropLevel(player, item, base);
    }

    void OnPlayerQuestRewardItem(Player* player, Item* item, uint32) override
    {
        if (questRewards.load(std::memory_order_relaxed))
            AssignDropLevel(player, item);
    }
};
}

bool Active()
{
    return enabled.load(std::memory_order_relaxed);
}

bool Handles(uint32 itemId)
{
    return enabled.load(std::memory_order_relaxed) && LadderStore::Instance().Has(itemId);
}

uint8 InstanceLevel(Item const* item)
{
    return item ? StoredLevel(item) : 0;
}
}

void AddSC_AscensionNativeItemScaling()
{
    LocalLevelScaling::ItemInstanceTemplateOwner.store(&NativeItemScaling::InstanceTemplate,
        std::memory_order_relaxed);
    LocalLevelScaling::ItemArrivalOwner.store(&NativeItemScaling::ItemArrived, std::memory_order_relaxed);
    LocalLevelScaling::MasterLootOwner.store(&NativeItemScaling::MasterLooted, std::memory_order_relaxed);
    LocalLevelScaling::QuestRewardLevelOwner.store(&NativeItemScaling::QuestRewardStored,
        std::memory_order_relaxed);
    AscensionCompatOpcodes::Claim(ItemLadder::ItemStatQueryOpcode, &NativeItemScaling::HandleItemStatQuery);
    new NativeItemScaling::Configuration();
    new NativeItemScaling::Acquisition();
}
