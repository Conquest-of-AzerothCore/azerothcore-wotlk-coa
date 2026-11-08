/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBloodforged.h"
#include "AscensionBloodforgedPolicy.h"
#include "AscensionBazaarTokenCap.h"
#include "AscensionRaidGearData.h"
#include "AscensionRaidReleasePolicy.h"
#include "ConditionMgr.h"
#include "Config.h"
#include "Containers.h"
#include "Creature.h"
#include "Formulas.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "CommandScript.h"
#include "DBCStores.h"
#include "MapMgr.h"
#include "StringFormat.h"
#include "GameTime.h"
#include "GameObject.h"
#include "Bag.h"
#include "Item.h"
#include "Group.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "LootMgr.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "TemporarySummon.h"
#include "World.h"
#include "WorldState.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <memory>
#include <mutex>
#include <set>
#include <sstream>
#include <string>
#include <string_view>
#include <tuple>
#include <unordered_map>
#include <unordered_set>
#include <vector>
using namespace Acore::ChatCommands;

namespace Bloodforged
{
constexpr uint32 HighRiskAura = 1004019;
constexpr uint32 BloodforgedEntryOffset = 6000000;

struct CatalogueEntry
{
    uint32 entry;
    uint32 quality;
    uint32 requiredLevel;
    uint32 itemLevel;
    bool heroic;
};

struct RaidGearEntry
{
    uint32 entry;
    uint32 mapId;
    uint32 requiredLevel;
    bool heroic;
    uint32 quality;
};

struct LevelPools
{
    std::array<std::vector<uint32>, 3> normal;
    std::vector<uint32> heroic;
    std::unique_ptr<LootTemplate> loot;
    std::unique_ptr<LootTemplate> eliteLoot;
};

struct Options
{
    std::array<Rates, 5> rates = DefaultRates;
    std::array<unsigned, 9> blueCaps = DefaultBlueMaxItemLevelByStage;
    std::array<unsigned, 9> epicCaps = DefaultEpicMaxItemLevelByStage;
    bool level60EndgameOnly = true;
    RareDrop rare = DefaultRare;
    RareDrop rareElite = DefaultRareElite;
    unsigned respawnMinLevel = DefaultEndgameRespawnMinLevel;
    std::array<unsigned, 2> eliteHighRiskRespawn = DefaultEndgameEliteHighRiskRespawnMinutes;
    std::array<unsigned, 2> highRiskEliteRespawn = DefaultHighRiskEliteRespawnMinutes;
    std::unordered_set<uint32> highRiskElites;
    unsigned eliteEpicPercent = DefaultEliteEpicPercent;
    float eliteHeroicUpgradePercent = DefaultEliteHeroicUpgradePercent;
    float highRiskEliteExtraKeyPercent = DefaultHighRiskEliteExtraKeyPercent;
    unsigned extraBluePercent = DefaultExtraBluePercent;
    unsigned extraBlueRaidItemPercent = DefaultExtraBlueRaidItemPercent;
    unsigned endgameRareMinRequiredLevel = DefaultEndgameRareMinRequiredLevel;
    HiddenCacheChances rareHiddenCache = DefaultRareHiddenCache;
    HiddenCacheChances epicHiddenCache = DefaultEpicHiddenCache;
    std::array<float, 4> ephemeralKeyPercent = DefaultEphemeralKeyPercent;
    float rareRate = 1.0f;
    float epicRate = 1.0f;
    float silverMarkRate = 1.0f;
    float goldenMarkRate = 1.0f;
    std::array<MarkDrop, 4> mobMarks = { NormalMobMarks, EliteMobMarks, RareMobMarks, RareEliteMobMarks };
    std::array<MarkDrop, 3> hiddenCacheMarks = HiddenCacheMarks;
    std::array<uint32, 3> mobTokens = DefaultMobBazaarTokens;
    std::array<uint32, 3> hiddenCacheTokens = DefaultHiddenCacheBazaarTokens;
};

struct Settings
{
    Options options;
    std::vector<CatalogueEntry> catalogue;
    std::vector<RaidGearEntry> raidGear;
    std::array<std::array<LevelPools, 2>, 61> pools;
    uint32 stage = 0;
    bool enabled = false;
};

std::shared_ptr<Settings const> settings;
std::mutex rebuildLock;
std::atomic<uint32> highRiskStage{DefaultHighRiskReleaseStage};
std::atomic<uint32> configuredHighRiskStage{DefaultHighRiskReleaseStage};
constexpr uint32 WorldStateHighRiskStageOverride = 20130;

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

bool IsRare(uint32 rank)
{
    return rank == CREATURE_ELITE_RARE || rank == CREATURE_ELITE_RAREELITE;
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

bool RequiresReputation(uint32 entry, ItemTemplate const* item)
{
    if (item->RequiredReputationFaction)
        return true;
    if (entry < BloodforgedEntryOffset)
        return false;
    uint32 const variant = entry - BloodforgedEntryOffset;
    for (uint32 base : { variant, variant % 100000 })
        if (ItemTemplate const* baseItem = sObjectMgr->GetItemTemplate(base); baseItem && baseItem->RequiredReputationFaction)
            return true;
    return false;
}

bool IsHeroicCopy(ItemTemplate const* item)
{
    return item->Description.find("Heroic Bloodforged") != std::string::npos;
}

uint32 RaidMapOf(uint32 entry, ItemTemplate const* item, std::unordered_map<uint32, uint32> const& raidItems)
{
    if (entry < BloodforgedEntryOffset)
        return 0;
    uint32 const variant = entry - BloodforgedEntryOffset;
    for (uint32 base : { variant, variant % 100000 })
    {
        ItemTemplate const* baseItem = sObjectMgr->GetItemTemplate(base);
        if (!baseItem || item->Name1 != "Bloodforged " + baseItem->Name1)
            continue;
        if (auto it = raidItems.find(base); it != raidItems.end())
            return it->second;
    }
    return 0;
}

std::vector<RaidGearEntry> LoadRaidGear(std::unordered_map<uint32, uint32> const& raidItems)
{
    std::vector<RaidGearEntry> gear;
    for (auto const& [entry, item] : *sObjectMgr->GetItemTemplateStore())
    {
        if (entry < BloodforgedEntryOffset || item.Quality < ITEM_QUALITY_RARE || item.Quality > ITEM_QUALITY_EPIC
            || (item.Class != ITEM_CLASS_WEAPON && item.Class != ITEM_CLASS_ARMOR) || item.RequiredLevel > 60
            || item.HasFlag(ITEM_FLAG_MULTI_DROP) || item.StartQuest || RequiresReputation(entry, &item))
            continue;
        if (uint32 mapId = RaidMapOf(entry, &item, raidItems))
            gear.push_back({ entry, mapId, item.RequiredLevel, IsHeroicCopy(&item), item.Quality });
    }
    std::sort(gear.begin(), gear.end(), [](RaidGearEntry const& a, RaidGearEntry const& b) { return a.entry < b.entry; });
    return gear;
}

bool BuildPools(Settings& next, uint32 stage)
{
    next.stage = stage;
    Options const& options = next.options;
    unsigned const epicCap = options.epicCaps[std::min<std::size_t>(stage, options.epicCaps.size() - 1)];
    unsigned const blueCap = options.blueCaps[std::min<std::size_t>(stage, options.blueCaps.size() - 1)];
    for (unsigned level = 15; level <= 60; ++level)
        for (unsigned endgame = 0; endgame < 2; ++endgame)
        {
            LevelPools& pools = next.pools[level][endgame];
            for (CatalogueEntry const& item : next.catalogue)
            {
                if (!EligibleItem(item.requiredLevel, item.itemLevel, level)
                    || !WithinItemLevelCap(item.quality, item.itemLevel, blueCap, epicCap)
                    || !AllowedInZone(item.requiredLevel, endgame, options.level60EndgameOnly))
                    continue;
                if (item.heroic)
                    pools.heroic.push_back(item.entry);
                else
                    pools.normal[item.quality - 2].push_back(item.entry);
            }
            for (auto& pool : pools.normal)
            {
                uint32 highest = 0;
                for (uint32 entry : pool)
                    highest = std::max(highest, sObjectMgr->GetItemTemplate(entry)->ItemLevel);
                std::erase_if(pool, [highest, level](uint32 entry)
                {
                    return !InGearTier(sObjectMgr->GetItemTemplate(entry)->ItemLevel, level, highest);
                });
            }
            Rates const& rates = options.rates[Band(level)];
            for (unsigned index = 0; index < 2; ++index)
                if (rates[index] && pools.normal[index].empty())
                {
                    LOG_ERROR("server.loading", "Bloodforged disabled: quality {} pool missing at level {}",
                        index + 2, level);
                    return false;
                }
            pools.loot = std::make_unique<LootTemplate>();
            pools.eliteLoot = std::make_unique<LootTemplate>();
            for (unsigned index = 0; index < 3; ++index)
            {
                std::vector<uint32> const& pool = pools.normal[index];
                if (!rates[index] || pool.empty())
                    continue;
                for (LootTemplate* loot : { pools.loot.get(), pools.eliteLoot.get() })
                {
                    if (index == 2 && loot == pools.eliteLoot.get())
                        continue;
                    for (uint32 entry : pool)
                    {
                        auto* item = new LootStoreItem(entry, 0, EntryChance(rates[index], pool.size()), false,
                            LOOT_MODE_DEFAULT, index + 1, 1, 1);
                        item->conditions = { &riskCondition, &levelCondition };
                        loot->AddEntry(item);
                    }
                }
            }
        }
    return true;
}

std::shared_ptr<Settings const> CurrentSettings()
{
    auto current = std::atomic_load(&settings);
    uint32 const stage = highRiskStage.load();
    if (!current || !current->enabled || current->stage == stage)
        return current;

    std::lock_guard<std::mutex> guard(rebuildLock);
    current = std::atomic_load(&settings);
    if (!current->enabled || current->stage == stage)
        return current;
    auto next = std::make_shared<Settings>();
    next->options = current->options;
    next->catalogue = current->catalogue;
    next->raidGear = current->raidGear;
    if (!BuildPools(*next, stage))
        return current;
    next->enabled = true;
    std::shared_ptr<Settings const> rebuilt = std::move(next);
    std::atomic_store(&settings, rebuilt);
    return rebuilt;
}

template <typename Number, std::size_t Count>
bool ReadNumbers(std::string const& key, std::array<Number, Count>& values)
{
    std::string value = sConfigMgr->GetOption<std::string>(key, "");
    if (value.empty())
        return true;
    std::istringstream input(value);
    std::array<Number, Count> parsed;
    for (Number& number : parsed)
        if (!(input >> number))
            return false;
    std::string extra;
    if (input >> extra)
        return false;
    values = parsed;
    return true;
}

bool ReadHiddenCache(std::string const& key, HiddenCacheChances& chances)
{
    std::array<unsigned, 2> values = { chances.first, chances.second };
    if (!ReadNumbers(key, values) || values[0] > 100 || values[1] > 100)
        return false;
    chances = { values[0], values[1] };
    return true;
}

bool ReadRareDrop(std::string const& name, RareDrop& drop)
{
    std::array<unsigned, 2> chances = { drop.raidPercent, drop.heroicRaidPercent };
    std::array<unsigned, 2> respawn = { drop.respawnMinMinutes, drop.respawnMaxMinutes };
    if (!ReadNumbers("Bloodforged." + name + "RaidItemPercent", chances)
        || !ReadNumbers("Bloodforged.Endgame" + name + "RespawnMinutes", respawn)
        || chances[0] > 100 || chances[1] > 100 || respawn[0] > respawn[1])
        return false;
    drop = { chances[0], chances[1], respawn[0], respawn[1] };
    return true;
}

bool ReadMarkDrop(std::string const& key, MarkDrop& marks)
{
    std::array<float, 4> values = { float(marks.silver), marks.extraSilverPercent, float(marks.gold),
        marks.extraGoldPercent };
    if (!ReadNumbers(key, values) || values[0] < 0.0f || values[2] < 0.0f
        || values[0] != std::floor(values[0]) || values[2] != std::floor(values[2]))
        return false;
    MarkDrop const parsed = { unsigned(values[0]), values[1], unsigned(values[2]), values[3] };
    if (!ValidMarkDrop(parsed))
        return false;
    marks = parsed;
    return true;
}

bool ReadDropRate(std::string const& key, float& rate)
{
    rate = sConfigMgr->GetOption<float>(key, 1.0f);
    return std::isfinite(rate) && rate >= 0.0f;
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
        uint32 stage = sConfigMgr->GetOption<uint32>("HighRisk.ReleaseStage", DefaultHighRiskReleaseStage);
        if (stage > RaidRelease::AllReleased)
        {
            LOG_ERROR("server.loading", "HighRisk.ReleaseStage {} is above {}, using {}", stage,
                RaidRelease::AllReleased, RaidRelease::AllReleased);
            stage = RaidRelease::AllReleased;
        }
        configuredHighRiskStage = stage;
        if (uint32 stageOverride = uint32(sWorldState->getWorldState(WorldStateHighRiskStageOverride)))
            stage = std::min<uint32>(stageOverride - 1, RaidRelease::AllReleased);
        highRiskStage = stage;
        if (!sConfigMgr->GetOption<bool>("Bloodforged.Enable", false))
            return;
        if (!sConfigMgr->GetOption<bool>("PvpPower.Enable", true))
        {
            LOG_ERROR("server.loading", "Bloodforged disabled: PvP Power support must be enabled first");
            return;
        }

        Options& options = next->options;
        for (unsigned band = 0; band < options.rates.size(); ++band)
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
            options.rates[band] = {unsigned(std::lround(green * 100)), unsigned(std::lround(blue * 100)),
                unsigned(std::lround(purple * 100))};
            if (!ValidRates(options.rates[band]))
            {
                LOG_ERROR("server.loading", "Bloodforged disabled: invalid rarity order in {}", key);
                return;
            }
        }
        {
            std::istringstream input(sConfigMgr->GetOption<std::string>("Bloodforged.HighRiskEliteEntries", DefaultHighRiskEliteEntries));
            for (uint32 entry; input >> entry;)
                options.highRiskElites.insert(entry);
            if (!input.eof())
            {
                LOG_ERROR("server.loading", "Bloodforged disabled: invalid Bloodforged.HighRiskEliteEntries");
                return;
            }
        }
        options.level60EndgameOnly = sConfigMgr->GetOption<bool>("Bloodforged.Level60EndgameZonesOnly", true);
        options.respawnMinLevel = sConfigMgr->GetOption<uint32>("Bloodforged.EndgameRareRespawnMinLevel",
            DefaultEndgameRespawnMinLevel);
        options.eliteEpicPercent = sConfigMgr->GetOption<uint32>("Bloodforged.EliteEpicPercent",
            DefaultEliteEpicPercent);
        options.endgameRareMinRequiredLevel = std::min<uint32>(60, sConfigMgr->GetOption<uint32>(
            "Bloodforged.EndgameRareMinRequiredLevel", DefaultEndgameRareMinRequiredLevel));
        options.eliteHeroicUpgradePercent = sConfigMgr->GetOption<float>("Bloodforged.EliteHeroicUpgradePercent",
            DefaultEliteHeroicUpgradePercent);
        options.highRiskEliteExtraKeyPercent = sConfigMgr->GetOption<float>(
            "Bloodforged.HighRiskEliteExtraKeyPercent", DefaultHighRiskEliteExtraKeyPercent);
        options.extraBluePercent = sConfigMgr->GetOption<uint32>("Bloodforged.ExtraBluePercent",
            DefaultExtraBluePercent);
        options.extraBlueRaidItemPercent = sConfigMgr->GetOption<uint32>("Bloodforged.ExtraBlueRaidItemPercent",
            DefaultExtraBlueRaidItemPercent);
        if (!ReadNumbers("Bloodforged.EpicMaxItemLevelByStage", options.epicCaps)
            || !ReadNumbers("Bloodforged.BlueMaxItemLevelByStage", options.blueCaps)
            || !ReadRareDrop("Rare", options.rare) || !ReadRareDrop("RareElite", options.rareElite)
            || !ReadHiddenCache("Bloodforged.RareHiddenCachePercent", options.rareHiddenCache)
            || !ReadHiddenCache("Bloodforged.EpicHiddenCachePercent", options.epicHiddenCache)
            || !ReadNumbers("Bloodforged.EphemeralKeyPercent", options.ephemeralKeyPercent)
            || !ReadNumbers("Bloodforged.EndgameEliteHighRiskRespawnMinutes", options.eliteHighRiskRespawn)
            || options.eliteHighRiskRespawn[0] > options.eliteHighRiskRespawn[1]
            || !ReadNumbers("Bloodforged.HighRiskEliteRespawnMinutes", options.highRiskEliteRespawn)
            || options.highRiskEliteRespawn[0] > options.highRiskEliteRespawn[1]
            || std::any_of(options.ephemeralKeyPercent.begin(), options.ephemeralKeyPercent.end(),
                [](float percent) { return !(percent >= 0.0f) || percent > 100.0f; })
            || options.eliteEpicPercent > 100 || !(options.eliteHeroicUpgradePercent >= 0.0f)
            || !(options.highRiskEliteExtraKeyPercent >= 0.0f) || options.highRiskEliteExtraKeyPercent > 100.0f
            || options.extraBluePercent > 100 || options.extraBlueRaidItemPercent > 100
            || options.eliteHeroicUpgradePercent > 100.0f)
        {
            LOG_ERROR("server.loading", "Bloodforged disabled: invalid item level caps or rare mob settings");
            return;
        }
        for (unsigned& cap : options.blueCaps)
            if (cap < MinimumBlueMaxItemLevel)
            {
                LOG_WARN("server.loading", "Bloodforged.BlueMaxItemLevelByStage value {} raised to {}", cap,
                    MinimumBlueMaxItemLevel);
                cap = RaisedBlueCap(cap);
            }
        if (!ReadDropRate("Bloodforged.DropRate.Rare", options.rareRate)
            || !ReadDropRate("Bloodforged.DropRate.Epic", options.epicRate)
            || !ReadDropRate("Bloodforged.DropRate.SilverMarkOfWar", options.silverMarkRate)
            || !ReadDropRate("Bloodforged.DropRate.GoldenMarkOfWar", options.goldenMarkRate)
            || !ReadMarkDrop("Bloodforged.MarksOfWar.NormalMob", options.mobMarks[0])
            || !ReadMarkDrop("Bloodforged.MarksOfWar.HighRiskElite", options.mobMarks[1])
            || !ReadMarkDrop("Bloodforged.MarksOfWar.RareMob", options.mobMarks[2])
            || !ReadMarkDrop("Bloodforged.MarksOfWar.RareEliteMob", options.mobMarks[3])
            || !ReadMarkDrop("Bloodforged.MarksOfWar.HiddenCache", options.hiddenCacheMarks[0])
            || !ReadMarkDrop("Bloodforged.MarksOfWar.RareHiddenCache", options.hiddenCacheMarks[1])
            || !ReadMarkDrop("Bloodforged.MarksOfWar.EpicHiddenCache", options.hiddenCacheMarks[2]))
        {
            LOG_ERROR("server.loading", "Bloodforged disabled: invalid drop rates or Marks of War settings");
            return;
        }

        options.mobTokens = { sConfigMgr->GetOption<uint32>("Bloodforged.BazaarTokens.HighRiskElite", DefaultMobBazaarTokens[0]),
            sConfigMgr->GetOption<uint32>("Bloodforged.BazaarTokens.RareMob", DefaultMobBazaarTokens[1]),
            sConfigMgr->GetOption<uint32>("Bloodforged.BazaarTokens.RareEliteMob", DefaultMobBazaarTokens[2]) };
        options.hiddenCacheTokens = {
            sConfigMgr->GetOption<uint32>("Bloodforged.BazaarTokens.HiddenCache", DefaultHiddenCacheBazaarTokens[0]),
            sConfigMgr->GetOption<uint32>("Bloodforged.BazaarTokens.RareHiddenCache", DefaultHiddenCacheBazaarTokens[1]),
            sConfigMgr->GetOption<uint32>("Bloodforged.BazaarTokens.EpicHiddenCache", DefaultHiddenCacheBazaarTokens[2]) };

        std::unordered_map<uint32, uint32> const raidItems = RaidItemMaps();
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
            if (RequiresReputation(entry, item) || RaidMapOf(entry, item, raidItems))
                continue;
            next->catalogue.push_back({ entry, quality, requiredLevel, itemLevel, IsHeroicCopy(item) });
        } while (catalogue->NextRow());
        if (next->catalogue.empty())
        {
            LOG_ERROR("server.loading", "Bloodforged disabled: empty or incomplete catalogue");
            return;
        }
        next->raidGear = LoadRaidGear(raidItems);
        if (!BuildPools(*next, highRiskStage.load()))
            return;
        next->enabled = true;
        std::atomic_store(&settings, std::shared_ptr<Settings const>(next));
        LOG_INFO("server.loading", "Bloodforged world drops ready: {} catalogue entries, {} raid items for rare mobs "
            "once their raid is released", next->catalogue.size(), next->raidGear.size());
    }
};

uint32 PickRaidGear(Settings const& current, bool heroic, unsigned level, bool endgame, unsigned minRequiredLevel,
    unsigned percent, uint32 quality = 0)
{
    if (!roll_chance_i(int(percent)))
        return 0;
    std::vector<uint32> candidates;
    for (RaidGearEntry const& gear : current.raidGear)
        if (gear.heroic == heroic && (!quality || gear.quality == quality)
            && RaidRelease::RaidLootStage(gear.mapId) <= current.stage
            && gear.requiredLevel <= level && gear.requiredLevel >= minRequiredLevel
            && AllowedInZone(gear.requiredLevel, endgame, current.options.level60EndgameOnly))
            candidates.push_back(gear.entry);
    return candidates.empty() ? 0 : Acore::Containers::SelectRandomContainerElement(candidates);
}

uint32 PickFrom(std::vector<uint32> const& pool, unsigned minRequiredLevel)
{
    std::vector<uint32> candidates;
    for (uint32 entry : pool)
        if (sObjectMgr->GetItemTemplate(entry)->RequiredLevel >= minRequiredLevel)
            candidates.push_back(entry);
    return candidates.empty() ? 0 : Acore::Containers::SelectRandomContainerElement(candidates);
}

uint32 PickBestQuality(LevelPools const& pools, unsigned minRequiredLevel)
{
    for (unsigned index = 3; index-- > 0;)
        if (uint32 entry = PickFrom(pools.normal[index], minRequiredLevel))
            return entry;
    return 0;
}

void AddRareMobItem(Loot& loot, uint32 entry, uint32 count = 1)
{
    if (!entry || !count)
        return;
    LootStoreItem item(entry, 0, 100.0f, false, LOOT_MODE_DEFAULT, 0, int32(count), uint8(count));
    item.conditions = { &riskCondition, &levelCondition };
    loot.AddItem(item);
}

void AddExtraBlue(Loot& loot, Settings const& current, unsigned level, bool endgame, unsigned minRequiredLevel,
    LevelPools const& pools)
{
    if (!roll_chance_i(int(current.options.extraBluePercent)))
        return;
    uint32 const raid = PickRaidGear(current, false, level, endgame, minRequiredLevel,
        current.options.extraBlueRaidItemPercent, ITEM_QUALITY_RARE);
    AddRareMobItem(loot, raid ? raid : PickFrom(pools.normal[1], minRequiredLevel));
}

void AddMarks(Loot& loot, MarkDrop const& marks, Options const& options)
{
    AddRareMobItem(loot, SilverMarkOfWar, marks.silver
        + (roll_chance_f(ScaledPercent(marks.extraSilverPercent, options.silverMarkRate)) ? 1 : 0));
    AddRareMobItem(loot, GoldenMarkOfWar, marks.gold
        + (roll_chance_f(ScaledPercent(marks.extraGoldPercent, options.goldenMarkRate)) ? 1 : 0));
}

int HiddenCacheTier(LootTemplate const* loot)
{
    for (std::size_t tier = 0; tier < HiddenCacheLoot.size(); ++tier)
        if (loot && loot == LootTemplates_Gameobject.GetLootFor(HiddenCacheLoot[tier]))
            return int(tier);
    return -1;
}

void FillHiddenCache(Settings const& current, Loot& loot, int tier, Player* opener)
{
    AscensionBazaarTokenCap::Give(opener, current.options.hiddenCacheTokens[tier]);
    AddMarks(loot, current.options.hiddenCacheMarks[tier], current.options);
    LevelPools const& pools = current.pools[60][1];
    unsigned const level = 60;
    if (tier == 0)
    {
        AddRareMobItem(loot, PickFrom(pools.normal[1], level));
        return;
    }
    uint32 const epic = PickFrom(pools.normal[2], level);
    uint32 const normalEpic = epic ? epic : PickFrom(pools.normal[1], level);
    if (tier == 1)
    {
        AddRareMobItem(loot, normalEpic);
        if (roll_chance_i(int(current.options.rareHiddenCache.first)))
            AddRareMobItem(loot, PickFrom(pools.heroic, level));
        AddRareMobItem(loot, PickRaidGear(current, false, level, true, level, current.options.rareHiddenCache.second));
        return;
    }
    uint32 raid = PickRaidGear(current, true, level, true, level, current.options.epicHiddenCache.first);
    if (!raid)
        raid = PickRaidGear(current, false, level, true, level, 100);
    AddRareMobItem(loot, raid ? raid : normalEpic);
    uint32 const heroic = roll_chance_i(int(current.options.epicHiddenCache.second)) ? PickFrom(pools.heroic, level) : 0;
    AddRareMobItem(loot, heroic ? heroic : PickFrom(pools.normal[2], level));
}

class WorldDrops : public MiscScript
{
public:
    WorldDrops() : MiscScript("BloodforgedWorldDrops", { MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS }) { }

    void OnAfterLootTemplateProcess(Loot* loot, LootTemplate const* lootTemplate, LootStore const& store,
        Player* owner, bool personal, bool, uint16 lootMode) override
    {
        auto current = CurrentSettings();
        if (current && current->enabled && loot && &store == &LootTemplates_Gameobject)
        {
            if (int tier = HiddenCacheTier(lootTemplate); tier >= 0)
                FillHiddenCache(*current, *loot, tier, owner);
            return;
        }
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
        bool const endgame = IsEndgameZone(creature->GetZoneId());
        LevelPools const& pools = current->pools[targetLevel][endgame];
        uint32 const rank = creature->GetCreatureTemplate()->rank;
        bool const highRiskElite = current->options.highRiskElites.contains(creature->GetEntry());
        uint32 keys = roll_chance_f(current->options.ephemeralKeyPercent[rank == CREATURE_ELITE_RAREELITE ? 3
            : rank == CREATURE_ELITE_RARE ? 2 : highRiskElite ? 1 : 0]) ? 1 : 0;
        if (keys && highRiskElite && !IsRare(rank) && roll_chance_f(current->options.highRiskEliteExtraKeyPercent))
            ++keys;
        AddRareMobItem(*loot, EphemeralKey, keys);
        Options const& options = current->options;
        AddMarks(*loot, options.mobMarks[rank == CREATURE_ELITE_RAREELITE ? 3 : rank == CREATURE_ELITE_RARE ? 2
            : highRiskElite ? 1 : 0], options);
        if (rank == CREATURE_ELITE_RAREELITE || rank == CREATURE_ELITE_RARE || highRiskElite)
        {
            uint32 const tokens = options.mobTokens[rank == CREATURE_ELITE_RAREELITE ? 2 : rank == CREATURE_ELITE_RARE ? 1 : 0];
            if (Group* group = owner->GetGroup())
            {
                for (auto* reference = group->GetFirstMember(); reference; reference = reference->next())
                    if (EligiblePlayer(reference->GetSource(), creature))
                        AscensionBazaarTokenCap::Give(reference->GetSource(), tokens);
            }
            else
                AscensionBazaarTokenCap::Give(eligibleOwner, tokens);
        }
        if (highRiskElite && !IsRare(rank))
        {
            pools.eliteLoot->Process(*loot, store, lootMode, eligibleOwner);
            AddExtraBlue(*loot, *current, targetLevel, endgame, 0, pools);
            if (pools.normal[2].empty()
                || !roll_chance_f(ScaledPercent(float(options.eliteEpicPercent), options.epicRate)))
                return;
            bool const upgrade = !pools.heroic.empty() && roll_chance_f(options.eliteHeroicUpgradePercent);
            AddRareMobItem(*loot, Acore::Containers::SelectRandomContainerElement(upgrade ? pools.heroic
                : pools.normal[2]));
            return;
        }
        if (!IsRare(rank))
        {
            pools.loot->Process(*loot, store, lootMode, eligibleOwner);
            return;
        }

        RareDrop const& drop = rank == CREATURE_ELITE_RARE ? current->options.rare : current->options.rareElite;
        unsigned const minRequiredLevel = endgame ? current->options.endgameRareMinRequiredLevel : 0;
        unsigned const rareLevel = endgame && minRequiredLevel ? 60 : targetLevel;
        LevelPools const& rarePools = current->pools[rareLevel][endgame];
        uint32 normal = PickRaidGear(*current, false, rareLevel, endgame, minRequiredLevel, drop.raidPercent,
            ITEM_QUALITY_EPIC);
        AddRareMobItem(*loot, normal ? normal : PickBestQuality(rarePools, minRequiredLevel));
        uint32 heroic = PickRaidGear(*current, true, rareLevel, endgame, minRequiredLevel, drop.heroicRaidPercent,
            ITEM_QUALITY_EPIC);
        AddRareMobItem(*loot, heroic ? heroic : PickFrom(rarePools.heroic, minRequiredLevel));
        AddExtraBlue(*loot, *current, rareLevel, endgame, minRequiredLevel, rarePools);
    }
};

class EndgameRareRespawn : public UnitScript
{
public:
    EndgameRareRespawn() : UnitScript("BloodforgedEndgameRareRespawn", true, { UNITHOOK_ON_UNIT_DEATH }) { }

    void OnUnitDeath(Unit* unit, Unit* killer) override
    {
        Creature* creature = unit ? unit->ToCreature() : nullptr;
        if (!creature || !creature->GetSpawnId() || !creature->GetMap() || creature->GetMap()->Instanceable())
            return;
        CreatureTemplate const* data = creature->GetCreatureTemplate();
        auto current = std::atomic_load(&settings);
        if (!current || !current->enabled)
            return;
        if (current->options.highRiskElites.contains(creature->GetEntry()))
        {
            std::array<unsigned, 2> const& minutes = current->options.highRiskEliteRespawn;
            if (minutes[1])
                Reschedule(creature, urand(minutes[0] * MINUTE, minutes[1] * MINUTE));
            return;
        }
        if (!IsEndgameZone(creature->GetZoneId()))
            return;
        if (data->rank == CREATURE_ELITE_ELITE)
        {
            std::array<unsigned, 2> const& minutes = current->options.eliteHighRiskRespawn;
            if (minutes[1] && KilledInHighRisk(creature, killer) && creature->GetRespawnDelay() < minutes[0] * MINUTE)
                Reschedule(creature, urand(minutes[0] * MINUTE, minutes[1] * MINUTE));
            return;
        }
        if (!IsRare(data->rank) || data->minlevel < current->options.respawnMinLevel)
            return;
        RareDrop const& drop = data->rank == CREATURE_ELITE_RARE ? current->options.rare : current->options.rareElite;
        if (drop.respawnMaxMinutes)
            Reschedule(creature, urand(drop.respawnMinMinutes * MINUTE, drop.respawnMaxMinutes * MINUTE));
    }

private:
    static bool KilledInHighRisk(Creature const* creature, Unit* killer)
    {
        Player const* player = killer ? killer->GetAffectingPlayer() : nullptr;
        if (!player && killer)
            if (TempSummon const* summon = killer->ToTempSummon())
                if (Unit* summoner = summon->GetSummonerUnit())
                    player = summoner->GetAffectingPlayer();
        if (player && player->HasAura(HighRiskAura))
            return true;
        Player const* recipient = creature->GetLootRecipient();
        return recipient && recipient->HasAura(HighRiskAura);
    }

    static void Reschedule(Creature* creature, uint32 delay)
    {
        time_t const remaining = creature->GetRespawnTime() - GameTime::GetGameTime().count();
        if (remaining < time_t(creature->GetRespawnDelay()))
            return;
        creature->SetRespawnTime(delay + uint32(remaining - creature->GetRespawnDelay()));
        creature->SaveRespawnTime();
    }
};

class EphemeralKeyOrder : public PlayerScript
{
public:
    EphemeralKeyOrder() : PlayerScript("BloodforgedEphemeralKeyOrder", { PLAYERHOOK_CAN_CAST_ITEM_USE_SPELL }) { }

    bool OnPlayerCanCastItemUseSpell(Player* player, Item* item, SpellCastTargets const&, uint8, uint32) override
    {
        if (std::find(EphemeralKeys.begin(), EphemeralKeys.end(), item->GetEntry()) == EphemeralKeys.end())
            return true;
        Item* shortest = item;
        auto consider = [item, &shortest](Item* other)
        {
            if (other && other->GetEntry() == item->GetEntry() && other->GetUInt32Value(ITEM_FIELD_DURATION)
                && other->GetUInt32Value(ITEM_FIELD_DURATION) < shortest->GetUInt32Value(ITEM_FIELD_DURATION))
                shortest = other;
        };
        for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
            consider(player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
        for (uint8 bag = INVENTORY_SLOT_BAG_START; bag < INVENTORY_SLOT_BAG_END; ++bag)
            if (Bag* container = player->GetBagByPos(bag))
                for (uint32 slot = 0; slot < container->GetBagSize(); ++slot)
                    consider(container->GetItemByPos(slot));
        if (shortest == item)
            return true;
        uint32 const used = item->GetUInt32Value(ITEM_FIELD_DURATION);
        item->SetUInt32Value(ITEM_FIELD_DURATION, shortest->GetUInt32Value(ITEM_FIELD_DURATION));
        shortest->SetUInt32Value(ITEM_FIELD_DURATION, used);
        item->SetState(ITEM_CHANGED, player);
        shortest->SetState(ITEM_CHANGED, player);
        return true;
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
        auto current = std::atomic_load(&settings);
        if (!proto || !current)
            return true;
        if (proto->Quality == ITEM_QUALITY_RARE)
            chance *= current->options.rareRate;
        else if (proto->Quality == ITEM_QUALITY_EPIC)
            chance *= current->options.epicRate;
        return true;
    }
};

constexpr uint32 DebugCacheSeconds = 3600;
constexpr std::array<char const*, 3> HiddenCacheTierNames = { "Green", "Rare", "Epic" };
std::vector<std::pair<uint32, ObjectGuid>> debugCaches;

struct CacheSpawn
{
    GameObjectData const* data;
    int tier;
    uint32 zone;
    Map* map;
};

std::vector<CacheSpawn> HiddenCacheSpawns(ChatHandler* handler, char const* scope, int minimumTier)
{
    bool const all = scope && std::string_view(scope) == "all";
    Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    uint32 const zone = player ? player->GetZoneId() : 0;
    std::vector<CacheSpawn> spawns;
    for (auto const& [spawnId, data] : sObjectMgr->GetAllGOData())
    {
        GameObjectTemplate const* info = sObjectMgr->GetGameObjectTemplate(data.id);
        if (!info || info->type != GAMEOBJECT_TYPE_CHEST)
            continue;
        auto const tier = std::find(HiddenCacheLoot.begin(), HiddenCacheLoot.end(), info->GetLootId());
        if (tier == HiddenCacheLoot.end() || tier - HiddenCacheLoot.begin() < minimumTier)
            continue;
        Map* map = sMapMgr->CreateBaseMap(data.mapid);
        if (!map || map->Instanceable())
            continue;
        map->LoadGrid(data.posX, data.posY);
        uint32 const cacheZone = map->GetZoneId(data.phaseMask, data.posX, data.posY, data.posZ);
        if (!all && cacheZone != zone)
            continue;
        spawns.push_back({ &data, int(tier - HiddenCacheLoot.begin()), cacheZone, map });
    }
    std::sort(spawns.begin(), spawns.end(), [](CacheSpawn const& a, CacheSpawn const& b)
    {
        return std::tie(a.zone, b.tier, a.data->spawnId) < std::tie(b.zone, a.tier, b.data->spawnId);
    });
    return spawns;
}

GameObject* LiveCache(CacheSpawn const& spawn)
{
    auto const range = spawn.map->GetGameObjectBySpawnIdStore().equal_range(spawn.data->spawnId);
    return range.first == range.second ? nullptr : range.first->second;
}

std::string ZoneName(uint32 zone)
{
    AreaTableEntry const* area = sAreaTableStore.LookupEntry(zone);
    return area ? area->area_name[0] : std::to_string(zone);
}

class HiddenCacheCommands : public CommandScript
{
public:
    HiddenCacheCommands() : CommandScript("BloodforgedHiddenCacheCommands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable hiddenCacheTable =
        {
            { "list", HandleList, SEC_GAMEMASTER, Console::Yes },
            { "spawn", HandleSpawn, SEC_GAMEMASTER, Console::No },
            { "despawn", HandleDespawn, SEC_GAMEMASTER, Console::Yes },
        };
        static ChatCommandTable stageTable =
        {
            { "", HandleStageStatus, SEC_GAMEMASTER, Console::Yes },
            { "set", HandleStageSet, SEC_ADMINISTRATOR, Console::Yes },
            { "clear", HandleStageClear, SEC_ADMINISTRATOR, Console::Yes },
        };
        static ChatCommandTable highRiskTable =
        {
            { "stage", stageTable },
        };
        static ChatCommandTable commandTable =
        {
            { "hiddencache", hiddenCacheTable },
            { "hr", highRiskTable },
        };
        return commandTable;
    }

    static bool HandleList(ChatHandler* handler, Optional<std::string> scope)
    {
        std::vector<CacheSpawn> const spawns = HiddenCacheSpawns(handler, scope ? scope->c_str() : nullptr, 1);
        time_t const now = GameTime::GetGameTime().count();
        for (CacheSpawn const& spawn : spawns)
        {
            GameObject const* go = LiveCache(spawn);
            time_t const respawn = spawn.map->GetGORespawnTime(spawn.data->spawnId);
            std::string const state = go && go->isSpawned() ? "up"
                : respawn > now ? Acore::StringFormat("opened, back in {} min", (respawn - now + 59) / 60) : "not loaded";
            handler->PSendSysMessage("{} {} - {} - .go gameobject {} ({:.1f} {:.1f} {:.1f})",
                HiddenCacheTierNames[spawn.tier], ZoneName(spawn.zone), state, spawn.data->spawnId,
                spawn.data->posX, spawn.data->posY, spawn.data->posZ);
        }
        handler->PSendSysMessage("{} Rare and Epic Hidden Caches{}.", spawns.size(), scope ? "" : " in this zone");
        return true;
    }

    static bool HandleSpawn(ChatHandler* handler, Optional<std::string> scope)
    {
        uint32 alreadyUp = 0, respawned = 0, spawned = 0;
        for (CacheSpawn const& spawn : HiddenCacheSpawns(handler, scope ? scope->c_str() : nullptr, 0))
        {
            if (GameObject* go = LiveCache(spawn))
            {
                if (go->isSpawned())
                    ++alreadyUp;
                else
                {
                    go->Respawn();
                    ++respawned;
                }
                continue;
            }
            GameObjectData const& data = *spawn.data;
            auto* go = new GameObject();
            if (!go->Create(spawn.map->GenerateLowGuid<HighGuid::GameObject>(), data.id, spawn.map, data.phaseMask,
                data.posX, data.posY, data.posZ, data.orientation, data.rotation, 100, GO_STATE_READY))
            {
                delete go;
                continue;
            }
            go->SetRespawnTime(DebugCacheSeconds);
            go->SetSpawnedByDefault(false);
            go->setActive(true);
            spawn.map->AddToMap(go);
            debugCaches.emplace_back(data.mapid, go->GetGUID());
            ++spawned;
        }
        handler->PSendSysMessage("Hidden Caches{}: {} already up, {} respawned, {} extra spawned for {} min "
            "(.hiddencache despawn removes them).", scope ? "" : " in this zone", alreadyUp, respawned, spawned,
            DebugCacheSeconds / 60);
        return true;
    }

    static bool HandleDespawn(ChatHandler* handler)
    {
        uint32 removed = 0;
        for (auto const& [mapId, guid] : debugCaches)
            if (Map* map = sMapMgr->FindBaseNonInstanceMap(mapId))
                if (GameObject* go = map->GetGameObject(guid))
                {
                    go->DespawnOrUnsummon();
                    ++removed;
                }
        debugCaches.clear();
        handler->PSendSysMessage("Removed {} debug Hidden Caches.", removed);
        return true;
    }

    static bool HandleStageStatus(ChatHandler* handler)
    {
        uint32 const stageOverride = uint32(sWorldState->getWorldState(WorldStateHighRiskStageOverride));
        handler->PSendSysMessage("High-Risk stage {}. Config {}, override {}.", highRiskStage.load(),
            configuredHighRiskStage.load(), stageOverride ? std::to_string(stageOverride - 1) : std::string("none"));
        return true;
    }

    static bool HandleStageSet(ChatHandler* handler, uint32 stage)
    {
        if (stage < 1 || stage > RaidRelease::AllReleased)
        {
            handler->PSendSysMessage("High-Risk stage must be 1-{}.", RaidRelease::AllReleased);
            return false;
        }
        sWorldState->setWorldState(WorldStateHighRiskStageOverride, stage + 1);
        highRiskStage = stage;
        handler->PSendSysMessage("High-Risk stage set to {}.", stage);
        return true;
    }

    static bool HandleStageClear(ChatHandler* handler)
    {
        sWorldState->setWorldState(WorldStateHighRiskStageOverride, 0);
        highRiskStage = configuredHighRiskStage.load();
        handler->PSendSysMessage("High-Risk stage override cleared; now {}.", highRiskStage.load());
        return true;
    }
};
}

std::vector<uint32> Bloodforged::NewestReleasedHeroicGear()
{
    std::vector<uint32> gear;
    auto current = CurrentSettings();
    if (!current || !current->enabled)
        return gear;
    uint32 newest = 0;
    for (RaidGearEntry const& item : current->raidGear)
        if (uint32 stage = RaidRelease::RaidLootStage(item.mapId); item.heroic && stage <= current->stage)
            newest = std::max(newest, stage);
    for (RaidGearEntry const& item : current->raidGear)
        if (item.heroic && newest && RaidRelease::RaidLootStage(item.mapId) == newest && item.requiredLevel == 60)
            gear.push_back(item.entry);
    if (gear.empty())
        for (uint32 entry : current->pools[60][1].heroic)
            if (sObjectMgr->GetItemTemplate(entry)->RequiredLevel == 60)
                gear.push_back(entry);
    return gear;
}

uint32 Bloodforged::HighRiskStage()
{
    return highRiskStage.load();
}

std::vector<uint32> Bloodforged::ReleasedHeroicGear()
{
    std::vector<uint32> gear;
    auto current = CurrentSettings();
    if (!current || !current->enabled)
        return gear;
    for (RaidGearEntry const& item : current->raidGear)
        if (item.heroic && item.requiredLevel == 60 && RaidRelease::RaidLootStage(item.mapId) <= current->stage)
            gear.push_back(item.entry);
    for (uint32 entry : current->pools[60][1].heroic)
        if (sObjectMgr->GetItemTemplate(entry)->RequiredLevel == 60)
            gear.push_back(entry);
    return gear;
}

void AddSC_AscensionBloodforged()
{
    new Bloodforged::Configuration();
    new Bloodforged::WorldDrops();
    new Bloodforged::EndgameRareRespawn();
    new Bloodforged::NativeRates();
    new Bloodforged::EphemeralKeyOrder();
    new Bloodforged::HiddenCacheCommands();
}
