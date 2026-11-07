/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBloodforgedPolicy.h"
#include "AscensionRaidGearData.h"
#include "AscensionRaidReleasePolicy.h"
#include "ConditionMgr.h"
#include "Config.h"
#include "Containers.h"
#include "Creature.h"
#include "Formulas.h"
#include "GameTime.h"
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
    unsigned blueCap = DefaultBlueMaxItemLevel;
    std::array<unsigned, 9> epicCaps = DefaultEpicMaxItemLevelByStage;
    bool level60EndgameOnly = true;
    RareDrop rare = DefaultRare;
    RareDrop rareElite = DefaultRareElite;
    unsigned respawnMinLevel = DefaultEndgameRespawnMinLevel;
    unsigned eliteEpicPercent = DefaultEliteEpicPercent;
    float eliteHeroicUpgradePercent = DefaultEliteHeroicUpgradePercent;
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

bool IsElite(uint32 rank)
{
    return rank == CREATURE_ELITE_ELITE || rank == CREATURE_ELITE_WORLDBOSS;
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
            gear.push_back({ entry, mapId, item.RequiredLevel, IsHeroicCopy(&item) });
    }
    std::sort(gear.begin(), gear.end(), [](RaidGearEntry const& a, RaidGearEntry const& b) { return a.entry < b.entry; });
    return gear;
}

bool BuildPools(Settings& next, uint32 stage)
{
    next.stage = stage;
    Options const& options = next.options;
    unsigned const epicCap = options.epicCaps[std::min<std::size_t>(stage, options.epicCaps.size() - 1)];
    for (unsigned level = 15; level <= 60; ++level)
        for (unsigned endgame = 0; endgame < 2; ++endgame)
        {
            LevelPools& pools = next.pools[level][endgame];
            for (CatalogueEntry const& item : next.catalogue)
            {
                if (!EligibleItem(item.requiredLevel, item.itemLevel, level)
                    || !WithinItemLevelCap(item.quality, item.itemLevel, options.blueCap, epicCap)
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
            if ((rates[0] && pools.normal[0].empty()) || pools.normal[1].empty())
            {
                LOG_ERROR("server.loading", "Bloodforged disabled: green/blue pool missing at level {}", level);
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
    uint32 const stage = RaidRelease::ReleasedStage();
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

template <std::size_t Count>
bool ReadNumbers(std::string const& key, std::array<unsigned, Count>& values)
{
    std::string value = sConfigMgr->GetOption<std::string>(key, "");
    if (value.empty())
        return true;
    std::istringstream input(value);
    std::array<unsigned, Count> parsed;
    for (unsigned& number : parsed)
        if (!(input >> number))
            return false;
    std::string extra;
    if (input >> extra)
        return false;
    values = parsed;
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
        options.blueCap = sConfigMgr->GetOption<uint32>("Bloodforged.BlueMaxItemLevel", DefaultBlueMaxItemLevel);
        options.level60EndgameOnly = sConfigMgr->GetOption<bool>("Bloodforged.Level60EndgameZonesOnly", true);
        options.respawnMinLevel = sConfigMgr->GetOption<uint32>("Bloodforged.EndgameRareRespawnMinLevel",
            DefaultEndgameRespawnMinLevel);
        options.eliteEpicPercent = sConfigMgr->GetOption<uint32>("Bloodforged.EliteEpicPercent",
            DefaultEliteEpicPercent);
        options.eliteHeroicUpgradePercent = sConfigMgr->GetOption<float>("Bloodforged.EliteHeroicUpgradePercent",
            DefaultEliteHeroicUpgradePercent);
        if (!ReadNumbers("Bloodforged.EpicMaxItemLevelByStage", options.epicCaps)
            || !ReadRareDrop("Rare", options.rare) || !ReadRareDrop("RareElite", options.rareElite)
            || options.eliteEpicPercent > 100 || !(options.eliteHeroicUpgradePercent >= 0.0f)
            || options.eliteHeroicUpgradePercent > 100.0f)
        {
            LOG_ERROR("server.loading", "Bloodforged disabled: invalid item level caps or rare mob settings");
            return;
        }

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
        if (!BuildPools(*next, RaidRelease::ReleasedStage()))
            return;
        next->enabled = true;
        std::atomic_store(&settings, std::shared_ptr<Settings const>(next));
        LOG_INFO("server.loading", "Bloodforged world drops ready: {} catalogue entries, {} raid items for rare mobs "
            "once their raid is released", next->catalogue.size(), next->raidGear.size());
    }
};

uint32 PickRaidGear(Settings const& current, bool heroic, unsigned level, bool endgame, unsigned percent)
{
    if (!roll_chance_i(int(percent)))
        return 0;
    std::vector<uint32> candidates;
    for (RaidGearEntry const& gear : current.raidGear)
        if (gear.heroic == heroic && RaidRelease::RaidLootStage(gear.mapId) <= current.stage
            && gear.requiredLevel <= level
            && AllowedInZone(gear.requiredLevel, endgame, current.options.level60EndgameOnly))
            candidates.push_back(gear.entry);
    return candidates.empty() ? 0 : Acore::Containers::SelectRandomContainerElement(candidates);
}

uint32 PickBestQuality(LevelPools const& pools)
{
    for (unsigned index = 3; index-- > 0;)
        if (!pools.normal[index].empty())
            return Acore::Containers::SelectRandomContainerElement(pools.normal[index]);
    return 0;
}

void AddRareMobItem(Loot& loot, uint32 entry)
{
    if (!entry)
        return;
    LootStoreItem item(entry, 0, 100.0f, false, LOOT_MODE_DEFAULT, 0, 1, 1);
    item.conditions = { &riskCondition, &levelCondition };
    loot.AddItem(item);
}

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
        bool const endgame = IsEndgameZone(creature->GetZoneId());
        LevelPools const& pools = current->pools[targetLevel][endgame];
        uint32 const rank = creature->GetCreatureTemplate()->rank;
        if (IsElite(rank))
        {
            pools.eliteLoot->Process(*loot, store, lootMode, eligibleOwner);
            Options const& options = current->options;
            if (pools.normal[2].empty()
                || !roll_chance_f(float(options.eliteEpicPercent) * sWorld->getRate(RATE_DROP_ITEM_EPIC)))
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
        uint32 normal = PickRaidGear(*current, false, targetLevel, endgame, drop.raidPercent);
        AddRareMobItem(*loot, normal ? normal : PickBestQuality(pools));
        uint32 heroic = PickRaidGear(*current, true, targetLevel, endgame, drop.heroicRaidPercent);
        if (!heroic && !pools.heroic.empty())
            heroic = Acore::Containers::SelectRandomContainerElement(pools.heroic);
        AddRareMobItem(*loot, heroic);
    }
};

class EndgameRareRespawn : public UnitScript
{
public:
    EndgameRareRespawn() : UnitScript("BloodforgedEndgameRareRespawn", true, { UNITHOOK_ON_UNIT_DEATH }) { }

    void OnUnitDeath(Unit* unit, Unit*) override
    {
        Creature* creature = unit ? unit->ToCreature() : nullptr;
        if (!creature || !creature->GetSpawnId() || !creature->GetMap() || creature->GetMap()->Instanceable())
            return;
        CreatureTemplate const* data = creature->GetCreatureTemplate();
        auto current = std::atomic_load(&settings);
        if (!current || !current->enabled || !IsRare(data->rank)
            || data->minlevel < current->options.respawnMinLevel || !IsEndgameZone(creature->GetZoneId()))
            return;
        RareDrop const& drop = data->rank == CREATURE_ELITE_RARE ? current->options.rare : current->options.rareElite;
        if (!drop.respawnMaxMinutes)
            return;
        time_t const remaining = creature->GetRespawnTime() - GameTime::GetGameTime().count();
        if (remaining < time_t(creature->GetRespawnDelay()))
            return;
        uint32 const delay = urand(drop.respawnMinMinutes * MINUTE, drop.respawnMaxMinutes * MINUTE);
        creature->SetRespawnTime(delay + uint32(remaining - creature->GetRespawnDelay()));
        creature->SaveRespawnTime();
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
    new Bloodforged::EndgameRareRespawn();
    new Bloodforged::NativeRates();
}
