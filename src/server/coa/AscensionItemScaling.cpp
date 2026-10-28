/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionItemScaling.h"
#include "AscensionItemScalingPolicy.h"
#include "AscensionItemStatData.h"
#include "AscensionNativeItemScaling.h"
#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "Group.h"
#include "Item.h"
#include "ItemEnchantmentMgr.h"
#include "LocalLevelScaling.h"
#include "Log.h"
#include "LootMgr.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <fmt/ranges.h>
#include <algorithm>
#include <atomic>
#include <filesystem>
#include <fstream>
#include <map>
#include <memory>
#include <mutex>
#include <shared_mutex>
#include <tuple>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace ItemScaling
{
namespace
{
constexpr uint32 MaximumSampleEntry = 60000;

std::atomic<bool> liftsEnabled{true};
std::shared_mutex unliftableMutex;
std::unordered_set<uint32> unliftableEntries;
CapturedStats::Table capturedStats;

void LoadCapturedStats()
{
    auto const path = std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "ItemStat.dbc";
    std::ifstream source(path, std::ios::binary);
    std::string error;
    if (!capturedStats.Load(source, error))
    {
        LOG_ERROR("server.loading", "Unable to load captured item stats from {}: {}; using estimated scaling",
            path.string(), error);
        return;
    }
    LOG_INFO("server.loading", ">> Loaded {} captured item-stat rows", capturedStats.Size());
    if (capturedStats.InvalidRows() || capturedStats.DuplicateRows())
        LOG_WARN("server.loading", "Skipped {} invalid and {} duplicate captured item-stat rows from {}",
            capturedStats.InvalidRows(), capturedStats.DuplicateRows(), path.string());
}

using CurveKey = std::tuple<uint32, uint32, uint32, uint32>;
using CurveSet = std::map<CurveKey, LevelCurve>;

struct Curves
{
    CurveSet armor;
    CurveSet damagePerSecond;
    CurveSet block;
    CurveSet sellPrice;
    std::map<CurveKey, std::map<uint32, int32>> randomProperties;
    std::map<CurveKey, DisenchantLadder> disenchantLadders;
};

constexpr uint32 AnySubClass = UINT32_MAX;

bool Eligible(ItemTemplate const& proto)
{
    return EligibleItem(proto.Quality, proto.Class, proto.InventoryType, proto.ItemLevel,
        proto.ScalingStatDistribution, proto.StartQuest);
}

bool Liftable(ItemTemplate const& proto)
{
    if (!Eligible(proto) || IsWorldforgedDescription(proto.Description))
        return false;

    std::shared_lock lock(unliftableMutex);
    return !unliftableEntries.contains(proto.ItemId);
}

CurveKey KeyOf(ItemTemplate const& proto)
{
    uint32 const inventoryType = proto.InventoryType == INVTYPE_ROBE ? INVTYPE_CHEST : proto.InventoryType;
    return { proto.Class, proto.SubClass, inventoryType, proto.Quality };
}

CurveKey SlotKeyOf(ItemTemplate const& proto)
{
    CurveKey key = KeyOf(proto);
    std::get<1>(key) = AnySubClass;
    return key;
}

double DamagePerSecond(ItemTemplate const& proto)
{
    if (!proto.Delay)
        return 0.0;

    double damage = 0.0;
    for (auto const& component : proto.Damage)
        damage += (component.DamageMin + component.DamageMax) / 2.0;
    return damage * 1000.0 / proto.Delay;
}

uint32 PropertyPoints(uint32 itemLevel, uint32 quality)
{
    RandomPropertiesPointsEntry const* points = sRandomPropertiesPointsStore.LookupEntry(itemLevel);
    if (!points)
        return 0;

    switch (quality)
    {
        case ITEM_QUALITY_POOR:
        case ITEM_QUALITY_NORMAL:
        case ITEM_QUALITY_UNCOMMON:
            return points->UncommonPropertiesPoints[0];
        case ITEM_QUALITY_RARE:
            return points->RarePropertiesPoints[0];
        default:
            return points->EpicPropertiesPoints[0];
    }
}

std::unique_ptr<Curves> BuildCurves()
{
    auto curves = std::make_unique<Curves>();
    std::vector<ItemTemplate*> const& store = *sObjectMgr->GetItemTemplateStoreFast();
    std::size_t const end = std::min<std::size_t>(store.size(), MaximumSampleEntry);
    for (std::size_t entry = 1; entry < end; ++entry)
    {
        ItemTemplate const* proto = store[entry];
        if (!proto || !Eligible(*proto))
            continue;

        CurveKey const key = KeyOf(*proto);
        curves->armor[key].Add(proto->ItemLevel, proto->Armor);
        if (proto->Class == ITEM_CLASS_WEAPON)
            curves->damagePerSecond[key].Add(proto->ItemLevel, DamagePerSecond(*proto));
        curves->block[key].Add(proto->ItemLevel, proto->Block);
        curves->sellPrice[key].Add(proto->ItemLevel, proto->SellPrice);
        if (proto->RandomProperty)
            curves->randomProperties[key].emplace(proto->ItemLevel, proto->RandomProperty);
        for (CurveKey const& ladder : { key, SlotKeyOf(*proto) })
            curves->disenchantLadders[ladder].Add(proto->ItemLevel, proto->DisenchantID,
                proto->RequiredDisenchantSkill);
    }

    for (CurveSet* set : { &curves->armor, &curves->damagePerSecond, &curves->block, &curves->sellPrice })
        for (auto& [key, curve] : *set)
            curve.Finish();

    return curves;
}

Curves const& SampleCurves()
{
    static std::unique_ptr<Curves> const curves = BuildCurves();
    return *curves;
}

double SetRatio(CurveSet const& set, CurveKey const& key, uint32 fromLevel, uint32 toLevel, double fallback)
{
    auto const curve = set.find(key);
    return curve == set.end() ? fallback : CurveRatio(curve->second, fromLevel, toLevel, fallback);
}

DisenchantBracket BracketAtOrBelow(Curves const& curves, CurveKey const& key, uint32 itemLevel)
{
    auto const ladder = curves.disenchantLadders.find(key);
    return ladder == curves.disenchantLadders.end() ? DisenchantBracket{} : ladder->second.AtOrBelow(itemLevel);
}

void RebracketDisenchant(ItemTemplate& proto, ItemTemplate const& base, uint32 itemLevel, Curves const& curves)
{
    if (!Disenchantable(base.DisenchantID, base.RequiredDisenchantSkill))
        return;

    DisenchantBracket const bracket = NearestDisenchantBracket(
        BracketAtOrBelow(curves, KeyOf(base), itemLevel),
        BracketAtOrBelow(curves, SlotKeyOf(base), itemLevel));
    if (!bracket.disenchantId)
        return;

    proto.DisenchantID = bracket.disenchantId;
    proto.RequiredDisenchantSkill = std::max(base.RequiredDisenchantSkill, bracket.requiredSkill);
}

std::unique_ptr<ItemTemplate> BuildTemplate(uint32 entry, ItemTemplate const& base, uint32 lift, Curves const& curves)
{
    auto proto = std::make_unique<ItemTemplate>(base);
    uint32 const itemLevel = base.ItemLevel + lift;
    proto->ItemId = entry;
    proto->ItemLevel = itemLevel;
    RebracketDisenchant(*proto, base, itemLevel, curves);
    if (CapturedStats::Record const* record = capturedStats.Find(base.ItemId, itemLevel))
    {
        record->Apply(*proto);
        if (base.BuyPrice > 0)
        {
            double const price = base.SellPrice ? double(proto->SellPrice) / base.SellPrice :
                std::max(1.0, SetRatio(curves.sellPrice, KeyOf(base), base.ItemLevel, itemLevel,
                    PointsRatio(PropertyPoints(base.ItemLevel, base.Quality),
                        PropertyPoints(itemLevel, base.Quality))));
            proto->BuyPrice = int32(std::min(std::round(double(base.BuyPrice) * price), double(INT32_MAX)));
        }
        return proto;
    }
    proto->RequiredLevel = LiftedRequiredLevel(base.RequiredLevel, base.ItemLevel, lift,
        sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL));

    double const points = PointsRatio(PropertyPoints(base.ItemLevel, base.Quality),
        PropertyPoints(itemLevel, base.Quality));
    for (auto& stat : proto->ItemStat)
        stat.ItemStatValue = ScaleSigned(stat.ItemStatValue, points);
    for (int32* resistance : { &proto->HolyRes, &proto->FireRes, &proto->NatureRes, &proto->FrostRes,
        &proto->ShadowRes, &proto->ArcaneRes })
        *resistance = ScaleSigned(*resistance, points);

    CurveKey const key = KeyOf(base);
    proto->Armor = ScaleUnsigned(base.Armor, SetRatio(curves.armor, key, base.ItemLevel, itemLevel, points));
    proto->Block = ScaleUnsigned(base.Block, SetRatio(curves.block, key, base.ItemLevel, itemLevel, points));

    double const damage = SetRatio(curves.damagePerSecond, key, base.ItemLevel, itemLevel, points);
    for (auto& component : proto->Damage)
    {
        component.DamageMin = ScaleFloat(component.DamageMin, damage);
        component.DamageMax = ScaleFloat(component.DamageMax, damage);
    }

    double const price = SetRatio(curves.sellPrice, key, base.ItemLevel, itemLevel, points);
    proto->SellPrice = ScaleUnsigned(base.SellPrice, price);
    if (base.BuyPrice > 0)
        proto->BuyPrice = int32(std::min<uint32>(ScaleUnsigned(uint32(base.BuyPrice), price), INT32_MAX));

    if (base.RandomProperty)
        if (auto const donors = curves.randomProperties.find(key); donors != curves.randomProperties.end())
            if (auto donor = donors->second.upper_bound(itemLevel); donor != donors->second.begin())
                proto->RandomProperty = std::prev(donor)->second;

    return proto;
}

ClientItemRow RowOf(ItemTemplate const& proto)
{
    return { proto.ItemId, proto.Class, proto.SubClass, uint32(proto.SoundOverrideSubclass), uint32(proto.Material),
        proto.DisplayInfoID, proto.InventoryType, proto.Sheath };
}

class Registry
{
public:
    static Registry& Instance()
    {
        static Registry instance;
        return instance;
    }

    void Load()
    {
        QueryResult result = CharacterDatabase.Query("SELECT `entry`, `base_entry`, `lift` FROM `coa_scaled_item`");

        std::unique_lock lock(_mutex);
        _records.clear();
        _entries.clear();
        _nextEntry = FirstScaledEntry;
        if (result)
        {
            do
            {
                Field* fields = result->Fetch();
                uint32 const entry = fields[0].Get<uint32>();
                uint32 const baseEntry = fields[1].Get<uint32>();
                uint32 const lift = fields[2].Get<uint32>();
                if (!IsScaledEntry(entry) || IsScaledEntry(baseEntry) || !lift)
                {
                    LOG_ERROR("sql.sql", "coa_scaled_item entry {} (base {}, lift {}) is invalid", entry, baseEntry,
                        lift);
                    continue;
                }
                _records[entry] = Record{ baseEntry, lift, nullptr };
                _entries[{ baseEntry, lift }] = entry;
                _nextEntry = std::max(_nextEntry, entry + 1);
            } while (result->NextRow());
        }

        LOG_INFO("server.loading", ">> Loaded {} scaled item templates", _records.size());
    }

    ItemTemplate const* Template(uint32 entry)
    {
        if (!IsScaledEntry(entry))
            return nullptr;

        {
            std::shared_lock lock(_mutex);
            auto const record = _records.find(entry);
            if (record == _records.end())
                return nullptr;
            if (record->second.proto)
                return record->second.proto.get();
        }

        std::unique_lock lock(_mutex);
        auto const record = _records.find(entry);
        if (record == _records.end())
            return nullptr;
        if (!record->second.proto)
        {
            ItemTemplate const* base = sObjectMgr->GetItemTemplate(record->second.baseEntry);
            if (!base)
                return nullptr;
            record->second.proto = BuildTemplate(entry, *base, record->second.lift, SampleCurves());
        }
        return record->second.proto.get();
    }

    uint32 Acquire(uint32 baseEntry, uint32 lift)
    {
        if (!lift || IsScaledEntry(baseEntry))
            return baseEntry;

        {
            std::shared_lock lock(_mutex);
            if (auto const entry = _entries.find({ baseEntry, lift }); entry != _entries.end())
                return entry->second;
        }

        std::unique_lock lock(_mutex);
        if (auto const entry = _entries.find({ baseEntry, lift }); entry != _entries.end())
            return entry->second;
        if (_nextEntry > LastScaledEntry)
        {
            LOG_ERROR("coa", "Item scaling exhausted entries {}-{}; {} stays unscaled", FirstScaledEntry,
                LastScaledEntry, baseEntry);
            return baseEntry;
        }

        uint32 const entry = _nextEntry++;
        CharacterDatabase.DirectExecute("INSERT INTO `coa_scaled_item` (`entry`, `base_entry`, `lift`) "
            "VALUES ({}, {}, {})", entry, baseEntry, lift);
        _records[entry] = Record{ baseEntry, lift, nullptr };
        _entries[{ baseEntry, lift }] = entry;
        return entry;
    }

    uint32 BaseEntry(uint32 entry)
    {
        if (!IsScaledEntry(entry))
            return entry;

        std::shared_lock lock(_mutex);
        auto const record = _records.find(entry);
        return record == _records.end() ? entry : record->second.baseEntry;
    }

    void RestoreUnliftableCopies()
    {
        std::vector<uint32> restorable;
        {
            std::shared_lock lock(_mutex);
            for (auto const& [entry, record] : _records)
                if (ItemTemplate const* base = sObjectMgr->GetItemTemplate(record.baseEntry); base && !Liftable(*base))
                    restorable.push_back(entry);
        }

        if (restorable.empty())
            return;

        CharacterDatabase.DirectExecute("UPDATE `item_instance` SET `itemEntry` = (SELECT `base_entry` "
            "FROM `coa_scaled_item` WHERE `coa_scaled_item`.`entry` = `item_instance`.`itemEntry`) "
            "WHERE `itemEntry` IN ({})",
            fmt::join(restorable, ","));

        LOG_INFO("server.loading", ">> Restored items of {} unliftable scaled item templates to their base entries",
            restorable.size());
    }

private:
    struct Record
    {
        uint32 baseEntry;
        uint32 lift;
        std::unique_ptr<ItemTemplate> proto;
    };

    std::shared_mutex _mutex;
    std::map<uint32, Record> _records;
    std::map<std::pair<uint32, uint32>, uint32> _entries;
    uint32 _nextEntry = FirstScaledEntry;
};

ItemTemplate const* ScaledTemplate(uint32 entry)
{
    return Registry::Instance().Template(entry);
}

bool LiftsActive()
{
    return liftsEnabled.load(std::memory_order_relaxed) && !NativeItemScaling::Active();
}

uint32 EligibleLift(uint32 itemId, uint32 rawLift)
{
    uint32 const lift = SteppedLift(rawLift);
    if (!lift || !LiftsActive())
        return itemId;

    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
    if (!proto || !Liftable(*proto))
        return itemId;
    return Registry::Instance().Acquire(itemId, lift);
}

uint32 QuestRewardItem(Player const* player, uint32 itemId, Quest const* quest)
{
    if (!player)
        return itemId;

    return EligibleLift(itemId, QuestLift(quest->GetQuestLevel(), uint32(player->GetQuestLevel(quest))));
}

uint32 CreatureViewerLift(Player const* player, Creature const* creature)
{
    return LootLift(creature->GetLevel(), LocalLevelScaling::ViewLevelFor(player, creature));
}

uint32 ChestViewerLift(Player const* player, uint32 itemLevel)
{
    if (!LocalLevelScaling::ScalingChoiceEnabled(player) ||
        (LocalLevelScaling::ScalingBlocksFor(player) & LocalLevelScaling::ChallengeBlocksCreatureScaling))
        return 0;
    return ContentLift(itemLevel, player->GetLevel(),
        LocalLevelScaling::CreatureOffset.load(std::memory_order_relaxed));
}

template <typename ViewerLift>
uint32 LooterLift(Player* owner, WorldObject const* source, bool personal, ViewerLift viewerLift)
{
    uint32 lift = viewerLift(owner);
    if (personal || !lift)
        return lift;

    if (Group* group = owner->GetGroup())
        for (GroupReference* reference = group->GetFirstMember(); reference && lift; reference = reference->next())
            if (Player* member = reference->GetSource())
                if (member != owner && member->IsInMap(source) && member->IsAtLootRewardDistance(source))
                    lift = std::min(lift, viewerLift(member));
    return lift;
}

template <typename ItemLift>
void LiftLootItems(Loot& loot, ItemLift itemLift)
{
    for (LootItem& item : loot.items)
    {
        if (item.needs_quest)
            continue;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(item.itemid);
        if (!proto || !Liftable(*proto))
            continue;

        uint32 const scaled = EligibleLift(item.itemid, itemLift(*proto));
        if (scaled == item.itemid)
            continue;

        item.itemid = scaled;
        item.randomSuffix = GenerateEnchSuffixFactor(scaled);
        item.randomPropertyId = Item::GenerateItemRandomPropertyId(scaled);
    }
}

class Configuration : public WorldScript
{
public:
    Configuration() : WorldScript("ItemScalingConfiguration",
        { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_LOAD_CUSTOM_DATABASE_TABLE, WORLDHOOK_ON_STARTUP }) { }

    void OnAfterConfigLoad(bool) override
    {
        liftsEnabled.store(sConfigMgr->GetOption<bool>("CoA.ItemScaling", true), std::memory_order_relaxed);
    }

    void OnLoadCustomDatabaseTable() override
    {
        LoadCapturedStats();
        Registry::Instance().Load();
    }

    void OnStartup() override
    {
        Registry::Instance().RestoreUnliftableCopies();
    }
};

class ScaledLoot : public MiscScript
{
public:
    ScaledLoot() : MiscScript("ItemScalingLoot", { MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS }) { }

    void OnAfterLootTemplateProcess(Loot* loot, LootTemplate const*, LootStore const& store, Player* owner,
        bool personal, bool, uint16) override
    {
        if (!loot || !owner || !LiftsActive() ||
            (&store != &LootTemplates_Creature && &store != &LootTemplates_Gameobject))
            return;

        Map* map = owner->FindMap();
        if (!map)
            return;

        if (&store == &LootTemplates_Creature)
        {
            Creature const* creature = map->GetCreature(loot->sourceWorldObjectGUID);
            if (!creature)
                return;

            uint32 const lift = LooterLift(owner, creature, personal,
                [creature](Player const* viewer) { return CreatureViewerLift(viewer, creature); });
            if (lift)
                LiftLootItems(*loot, [lift](ItemTemplate const&) { return lift; });
        }
        else if (&store == &LootTemplates_Gameobject)
        {
            GameObject const* chest = map->GetGameObject(loot->sourceWorldObjectGUID);
            if (!chest || map->IsScriptedPrivateInstance())
                return;

            LiftLootItems(*loot, [owner, chest, personal](ItemTemplate const& proto)
            {
                return LooterLift(owner, chest, personal,
                    [&proto](Player const* viewer) { return ChestViewerLift(viewer, proto.ItemLevel); });
            });
        }
    }
};

}

uint32 BaseEntry(uint32 entry)
{
    return Registry::Instance().BaseEntry(entry);
}

std::optional<ClientItemRow> ClientRow(uint32 entry)
{
    if (ItemTemplate const* proto = Registry::Instance().Template(entry))
        return RowOf(*proto);
    return std::nullopt;
}

void RebracketDisenchant(ItemTemplate& scaled, ItemTemplate const& base, uint32 itemLevel)
{
    RebracketDisenchant(scaled, base, itemLevel, SampleCurves());
}

bool LiftableEntry(uint32 entry)
{
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
    return proto && Liftable(*proto);
}

void HandleStatQuery(WorldSession* session, WorldPacket const& packet)
{
    if (!session || packet.size() != sizeof(uint64) || !capturedStats.Size())
        return;

    uint32 const item = packet.read<uint32>(0);
    uint32 const level = packet.read<uint32>(sizeof(uint32));
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(item);
    if (!proto || NativeItemScaling::Handles(item))
        return;
    CapturedStats::Record const* record = capturedStats.Find(BaseEntry(item), level);
    if (!record)
        return;

    std::array<uint32, 2> const damageTypes = { proto->Damage[0].DamageType, proto->Damage[1].DamageType };
    WorldPacket response(CapturedStats::ResponseOpcode, CapturedStats::ResponseWords * sizeof(uint32));
    for (uint32 word : record->Response(item, damageTypes))
        response << word;
    session->SendPacket(&response);
}

void SetUnliftableEntries(std::unordered_set<uint32> entries)
{
    {
        std::unique_lock lock(unliftableMutex);
        unliftableEntries = std::move(entries);
    }
    Registry::Instance().RestoreUnliftableCopies();
}
}

void AddSC_AscensionItemScaling()
{
    LocalLevelScaling::ScaledItemTemplateOwner.store(&ItemScaling::ScaledTemplate, std::memory_order_relaxed);
    LocalLevelScaling::QuestRewardItemOwner.store(&ItemScaling::QuestRewardItem, std::memory_order_relaxed);
    new ItemScaling::Configuration();
    new ItemScaling::ScaledLoot();
}
