/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBloodforgedPolicy.h"
#include "AscensionRaidGearData.h"
#include "AscensionRaidReleasePolicy.h"
#include "ConditionMgr.h"
#include "Config.h"
#include "Creature.h"
#include "Formulas.h"
#include "GameObject.h"
#include "Group.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "LootMgr.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "World.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <memory>
#include <mutex>
#include <set>
#include <sstream>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace Bloodforged
{
constexpr uint32 HighRiskAura = 1004019;
using Pools = std::array<std::array<std::vector<uint32>, 3>, 61>;

struct HeldGear
{
    uint32 mapId;
    bool heroic;
};

struct Settings
{
    std::array<Rates, 5> rates = DefaultRates;
    Pools pools;
    std::unordered_map<uint32, HeldGear> raidGear;
    std::array<std::unique_ptr<LootTemplate>, 61> templates;
    uint32 defeatVersion = 0;
    bool enabled = false;
};

std::shared_ptr<Settings const> settings;
std::mutex rebuildLock;

struct RaidSpawn
{
    uint32 entry;
    uint32 mapId;
};

constexpr std::array<RaidSpawn, 7> ScriptedRaidCreatures = {{
    { 11502, RaidRelease::MapMoltenCore }, { 11583, RaidRelease::MapBlackwingLair },
    { 15082, RaidRelease::MapZulGurub }, { 15083, RaidRelease::MapZulGurub }, { 15084, RaidRelease::MapZulGurub },
    { 15085, RaidRelease::MapZulGurub }, { 15114, RaidRelease::MapZulGurub }
}};

constexpr std::array<RaidSpawn, 2> ScriptedRaidChests = {{
    { 179703, RaidRelease::MapMoltenCore }, { 181366, RaidRelease::MapNaxxramas }
}};

Condition riskCondition = []
{
    Condition condition;
    condition.ConditionType = CONDITION_AURA;
    condition.ConditionValue1 = HighRiskAura;
    return condition;
}();

Condition levelCondition = []
{
    Condition condition;
    condition.ConditionType = CONDITION_LEVEL;
    condition.ConditionValue1 = 15;
    condition.ConditionValue2 = COMP_TYPE_HIGH_EQ;
    return condition;
}();

bool EligiblePlayer(Player const* player, Creature const* creature)
{
    return player && player->GetSession() && !player->GetSession()->IsBot()
        && player->GetLevel() >= 15 && player->HasAura(HighRiskAura)
        && player->IsAtLootRewardDistance(creature)
        && creature->GetLevel() > Acore::XP::GetGrayLevel(player->GetLevel());
}

uint32 RaidMap(uint32 mapId)
{
    return RaidRelease::RaidLootStage(mapId) ? mapId : 0;
}

void CollectLoot(LootStore const& store, uint32 lootId, uint32 mapId, std::unordered_map<uint32, uint32>& raid,
    std::unordered_set<uint32>& outside)
{
    LootTemplate const* loot = lootId ? store.GetLootFor(lootId) : nullptr;
    if (!loot)
        return;
    std::vector<LootStoreItem const*> items;
    loot->CollectItems(items);
    for (LootStoreItem const* item : items)
    {
        if (!mapId)
            outside.insert(item->itemid);
        else
            raid.emplace(item->itemid, mapId);
    }
}

std::unordered_map<uint32, uint32> RaidItemMaps()
{
    std::set<std::pair<uint32, uint32>> creatureLoot, chestLoot;
    for (auto const& [spawnId, data] : sObjectMgr->GetAllCreatureData())
        if (CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(data.id))
            creatureLoot.emplace(RaidMap(data.mapid), creature->lootid);
    for (RaidSpawn const& spawn : ScriptedRaidCreatures)
        if (CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(spawn.entry))
            creatureLoot.emplace(spawn.mapId, creature->lootid);
    for (auto const& [spawnId, data] : sObjectMgr->GetAllGOData())
        if (GameObjectTemplate const* chest = sObjectMgr->GetGameObjectTemplate(data.id))
            chestLoot.emplace(RaidMap(data.mapid), chest->GetLootId());
    for (RaidSpawn const& spawn : ScriptedRaidChests)
        if (GameObjectTemplate const* chest = sObjectMgr->GetGameObjectTemplate(spawn.entry))
            chestLoot.emplace(spawn.mapId, chest->GetLootId());

    std::unordered_map<uint32, uint32> raid;
    std::unordered_set<uint32> outside;
    for (auto const& [mapId, lootId] : creatureLoot)
        CollectLoot(LootTemplates_Creature, lootId, mapId, raid, outside);
    for (auto const& [mapId, lootId] : chestLoot)
        CollectLoot(LootTemplates_Gameobject, lootId, mapId, raid, outside);
    std::erase_if(raid, [&outside](auto const& item) { return outside.contains(item.first); });
    for (RaidRelease::RaidGear const& gear : RaidRelease::RaidGearItems)
        raid[gear.item] = gear.mapId;
    return raid;
}

bool FindHeldGear(uint32 entry, std::unordered_map<uint32, uint32> const& raidItems, HeldGear& held)
{
    uint32 const base = entry % 100000;
    ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry);
    ItemTemplate const* baseItem = base != entry ? sObjectMgr->GetItemTemplate(base) : nullptr;
    if (!item || !baseItem || item->Name1 != "Bloodforged " + baseItem->Name1)
        return false;
    auto it = raidItems.find(base);
    if (it == raidItems.end())
        return false;
    held = { it->second, entry / 100000 == 63 };
    return true;
}

void BuildTemplates(Settings& next, uint32 defeatVersion)
{
    next.defeatVersion = defeatVersion;
    for (unsigned level = 15; level <= 60; ++level)
    {
        auto entriesForLevel = std::make_unique<LootTemplate>();
        for (unsigned index = 0; index < 3; ++index)
        {
            unsigned rate = next.rates[Band(level)][index];
            std::vector<uint32> pool;
            for (uint32 entry : next.pools[level][index])
            {
                auto it = next.raidGear.find(entry);
                if (it == next.raidGear.end() || RaidRelease::IsBloodforgedReleased(
                    RaidRelease::RaidDefeatLevel(it->second.mapId), it->second.heroic))
                    pool.push_back(entry);
            }
            if (!rate || pool.empty())
                continue;
            for (uint32 entry : pool)
            {
                auto* item = new LootStoreItem(entry, 0, EntryChance(rate, pool.size()), false,
                    LOOT_MODE_DEFAULT, index + 1, 1, 1);
                item->conditions = { &riskCondition, &levelCondition };
                entriesForLevel->AddEntry(item);
            }
        }
        next.templates[level] = std::move(entriesForLevel);
    }
}

std::shared_ptr<Settings const> CurrentSettings()
{
    auto current = std::atomic_load(&settings);
    uint32 const defeatVersion = RaidRelease::DefeatVersion();
    if (!current || !current->enabled || current->defeatVersion == defeatVersion)
        return current;

    std::lock_guard<std::mutex> guard(rebuildLock);
    current = std::atomic_load(&settings);
    if (!current->enabled || current->defeatVersion == defeatVersion)
        return current;
    auto next = std::make_shared<Settings>();
    next->rates = current->rates;
    next->pools = current->pools;
    next->raidGear = current->raidGear;
    next->enabled = true;
    BuildTemplates(*next, defeatVersion);
    std::shared_ptr<Settings const> rebuilt = std::move(next);
    std::atomic_store(&settings, rebuilt);
    return rebuilt;
}

class Configuration : public WorldScript
{
public:
    Configuration() : WorldScript("BloodforgedConfiguration") { }

    void OnStartup() override { Load(); }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            Load();
    }

private:
    static void Load()
    {
        auto next = std::make_shared<Settings>();
        std::atomic_store(&settings, std::make_shared<Settings const>());
        if (!sConfigMgr->GetOption<bool>("Bloodforged.Enable", false))
            return;
        if (!sConfigMgr->GetOption<bool>("PvpPower.Enable", true))
        {
            LOG_ERROR("server.loading", "Bloodforged disabled: PvP Power support must be enabled first");
            return;
        }

        for (unsigned band = 0; band < next->rates.size(); ++band)
        {
            std::string key = "Bloodforged.Rates" + std::to_string(15 + band * 10);
            std::string value = sConfigMgr->GetOption<std::string>(key, "");
            if (value.empty())
                continue;
            std::istringstream input(value);
            double green, blue, purple;
            std::string extra;
            if (!(input >> green >> blue >> purple) || input >> extra
                || !std::isfinite(green) || !std::isfinite(blue) || !std::isfinite(purple)
                || green < 0 || green > 100 || blue < 0 || blue > 100 || purple < 0 || purple > 100)
            {
                LOG_ERROR("server.loading", "Bloodforged disabled: invalid rates in {}", key);
                return;
            }
            next->rates[band] = {unsigned(std::lround(green * 100)), unsigned(std::lround(blue * 100)),
                unsigned(std::lround(purple * 100))};
            if (!ValidRates(next->rates[band]))
            {
                LOG_ERROR("server.loading", "Bloodforged disabled: invalid rarity order in {}", key);
                return;
            }
        }

        Pools pools;
        std::set<uint32> entries;
        QueryResult catalogue = WorldDatabase.Query(
            "SELECT entry,quality,required_level,item_level FROM coa_bloodforged_catalogue");
        if (!catalogue)
        {
            LOG_ERROR("server.loading", "Bloodforged disabled: coa_bloodforged_catalogue is empty or missing");
            return;
        }
        do
        {
            Field* fields = catalogue->Fetch();
            uint32 entry = fields[0].Get<uint32>();
            uint32 quality = fields[1].Get<uint32>();
            uint32 requiredLevel = fields[2].Get<uint32>();
            uint32 itemLevel = fields[3].Get<uint32>();
            auto const* item = sObjectMgr->GetItemTemplate(entry);
            if (!item || !entries.insert(entry).second || quality < 2 || quality > 4
                || item->Quality != quality || item->RequiredLevel != requiredLevel
                || item->ItemLevel != itemLevel || requiredLevel > 60
                || (item->Class != ITEM_CLASS_WEAPON && item->Class != ITEM_CLASS_ARMOR)
                || item->HasFlag(ITEM_FLAG_MULTI_DROP) || item->StartQuest)
            {
                LOG_ERROR("server.loading", "Bloodforged disabled: template mismatch for {}", entry);
                return;
            }
            for (unsigned level = 15; level <= 60; ++level)
                if (EligibleItem(requiredLevel, itemLevel, level))
                    pools[level][quality - 2].push_back(entry);
        } while (catalogue->NextRow());
        if (entries.empty())
        {
            LOG_ERROR("server.loading", "Bloodforged disabled: empty or incomplete catalogue");
            return;
        }
        for (unsigned level = 15; level <= 60; ++level)
            for (auto& pool : pools[level])
            {
                uint32 highest = 0;
                for (uint32 entry : pool)
                    highest = std::max(highest, sObjectMgr->GetItemTemplate(entry)->ItemLevel);
                std::erase_if(pool, [highest, level](uint32 entry)
                {
                    return !InGearTier(sObjectMgr->GetItemTemplate(entry)->ItemLevel, level, highest);
                });
            }
        for (unsigned level = 15; level <= 60; ++level)
            if (pools[level][0].empty() || pools[level][1].empty())
            {
                LOG_ERROR("server.loading", "Bloodforged disabled: green/blue pool missing at level {}", level);
                return;
            }
        std::unordered_map<uint32, uint32> const raidItems = RaidItemMaps();
        for (uint32 entry : entries)
            if (HeldGear held; FindHeldGear(entry, raidItems, held))
                next->raidGear.emplace(entry, held);
        next->pools = std::move(pools);
        BuildTemplates(*next, RaidRelease::DefeatVersion());
        next->enabled = true;
        std::atomic_store(&settings, std::shared_ptr<Settings const>(next));
        LOG_INFO("server.loading", "Bloodforged world drops ready: {} verified catalogue entries, {} raid items held "
            "until their raid is defeated", entries.size(), next->raidGear.size());
    }
};

class WorldDrops : public MiscScript
{
public:
    WorldDrops() : MiscScript("BloodforgedWorldDrops", { MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS }) { }

    void OnAfterLootTemplateProcess(Loot* loot, LootTemplate const*, LootStore const& store,
        Player* owner, bool personal, bool, uint16 lootMode) override
    {
        auto current = CurrentSettings();
        if (!current || !current->enabled || !owner || !loot || personal
            || &store != &LootTemplates_Creature || !(lootMode & LOOT_MODE_DEFAULT)
            || !owner->GetMap() || owner->GetMap()->Instanceable())
            return;

        auto* creature = owner->GetMap()->GetCreature(loot->sourceWorldObjectGUID);
        if (!creature || !creature->GetSpawnId() || creature->IsPet()
            || creature->IsSummon() || creature->GetCharmerOrOwnerGUID()
            || creature->GetCreatureType() == CREATURE_TYPE_CRITTER)
            return;

        Player* eligibleOwner = EligiblePlayer(owner, creature) ? owner : nullptr;
        if (!eligibleOwner)
            if (Group* group = owner->GetGroup())
                for (auto* reference = group->GetFirstMember(); reference; reference = reference->next())
                    if (EligiblePlayer(reference->GetSource(), creature))
                    {
                        eligibleOwner = reference->GetSource();
                        break;
                    }
        if (!eligibleOwner)
            return;

        unsigned targetLevel = std::clamp<unsigned>(eligibleOwner->GetLevel(), 15, 60);
        current->templates[targetLevel]->Process(*loot, store, lootMode, eligibleOwner);
    }
};

class NativeRates : public GlobalScript
{
public:
    NativeRates() : GlobalScript("BloodforgedNativeRates", { GLOBALHOOK_ON_ITEM_ROLL }) { }

    bool OnItemRoll(Player const*, LootStoreItem const* item, float& chance, Loot&, LootStore const& store) override
    {
        if (&store != &LootTemplates_Creature || item->conditions.empty() || item->conditions.front() != &riskCondition)
            return true;
        auto const* proto = sObjectMgr->GetItemTemplate(item->itemid);
        if (proto && proto->Quality >= ITEM_QUALITY_UNCOMMON && proto->Quality <= ITEM_QUALITY_EPIC)
            chance *= sWorld->getRate(QualityRates[proto->Quality - ITEM_QUALITY_UNCOMMON]);
        return true;
    }

private:
    static constexpr std::array<ServerConfigs, 3> QualityRates =
        { RATE_DROP_ITEM_UNCOMMON, RATE_DROP_ITEM_RARE, RATE_DROP_ITEM_EPIC };
};
}

void AddSC_AscensionBloodforged()
{
    new Bloodforged::Configuration();
    new Bloodforged::WorldDrops();
    new Bloodforged::NativeRates();
}
