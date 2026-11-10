/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "Creature.h"
#include "DatabaseEnv.h"
#include "DungeonLoot.h"
#include "MiscScript.h"
#include "Item.h"
#include "ItemEnchantmentMgr.h"
#include "Log.h"
#include "LootMgr.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "WorldScript.h"
#include <algorithm>
#include <mutex>
#include <set>
#include <shared_mutex>
#include <tuple>
#include <unordered_map>
#include <vector>

namespace
{
    constexpr uint8 MaxReferenceDepth = 4;
    constexpr int32 ConditionSourceCreatureLoot = 1;
    constexpr int32 ConditionSourceReferenceLoot = 10;

    struct GearRow
    {
        uint32 item;
        int32 reference;
    };

    using GearTable = std::unordered_map<uint32, std::vector<GearRow>>;

    DungeonLoot::Variants Variants;
    GearTable CreatureGear;
    GearTable ReferenceGear;
    std::unordered_map<uint32, std::vector<uint32>> Pools;
    std::shared_mutex PoolLock;

    bool IsBossGear(ItemTemplate const* proto)
    {
        return proto && (proto->Class == ITEM_CLASS_WEAPON || proto->Class == ITEM_CLASS_ARMOR)
            && proto->Quality >= ITEM_QUALITY_UNCOMMON && !proto->StartQuest && proto->Bonding != BIND_QUEST_ITEM;
    }

    bool IsBossGear(LootItem const& item)
    {
        return !item.needs_quest && IsBossGear(sObjectMgr->GetItemTemplate(item.itemid));
    }

    bool SameLootVisibility(ItemTemplate const* base, ItemTemplate const* target)
    {
        return base->HasFlag(ITEM_FLAG_MULTI_DROP) == target->HasFlag(ITEM_FLAG_MULTI_DROP)
            && base->HasFlagCu(ITEM_FLAGS_CU_FOLLOW_LOOT_RULES) == target->HasFlagCu(ITEM_FLAGS_CU_FOLLOW_LOOT_RULES)
            && base->HasFlag2(ITEM_FLAG2_FACTION_HORDE) == target->HasFlag2(ITEM_FLAG2_FACTION_HORDE)
            && base->HasFlag2(ITEM_FLAG2_FACTION_ALLIANCE) == target->HasFlag2(ITEM_FLAG2_FACTION_ALLIANCE);
    }

    void LoadVariants()
    {
        Variants.clear();
        QueryResult result = WorldDatabase.Query("SELECT base_item, heroic_item, mythic_item FROM coa_dungeon_loot_variant");
        if (result)
        {
            do
            {
                Field* fields = result->Fetch();
                uint32 const base = fields[0].Get<uint32>();
                ItemTemplate const* original = sObjectMgr->GetItemTemplate(base);
                if (!original || (original->Class != ITEM_CLASS_WEAPON && original->Class != ITEM_CLASS_ARMOR)
                    || original->StartQuest || original->Bonding == BIND_QUEST_ITEM)
                    continue;

                std::array<uint32, 2> variants{};
                for (uint8 tier = 0; tier < 2; ++tier)
                {
                    uint32 const entry = fields[tier + 1].Get<uint32>();
                    if (!entry)
                        continue;

                    ItemTemplate const* target = sObjectMgr->GetItemTemplate(entry);
                    if (!target || target->Class != original->Class || target->SubClass != original->SubClass
                        || target->InventoryType != original->InventoryType || target->StartQuest
                        || target->Bonding == BIND_QUEST_ITEM || !SameLootVisibility(original, target))
                    {
                        LOG_ERROR("sql.sql", "Invalid dungeon loot variant {} -> {} (difficulty {})", base, entry, tier + 1);
                        continue;
                    }

                    variants[tier] = entry;
                }

                if (variants[0] || variants[1])
                    Variants.emplace(base, variants);
            } while (result->NextRow());
        }

        LOG_INFO("server.loading", ">> Loaded {} dungeon loot variant families", Variants.size());
    }

    std::set<std::tuple<int32, uint32, uint32>> LoadLootConditions()
    {
        std::set<std::tuple<int32, uint32, uint32>> conditions;
        QueryResult result = WorldDatabase.Query("SELECT SourceTypeOrReferenceId, SourceGroup, SourceEntry FROM conditions "
            "WHERE SourceTypeOrReferenceId IN ({}, {})", ConditionSourceCreatureLoot, ConditionSourceReferenceLoot);
        if (result)
        {
            do
            {
                Field* fields = result->Fetch();
                conditions.emplace(fields[0].Get<int32>(), fields[1].Get<uint32>(), fields[2].Get<uint32>());
            } while (result->NextRow());
        }
        return conditions;
    }

    void LoadGear(GearTable& table, char const* name, int32 conditionSource,
        std::set<std::tuple<int32, uint32, uint32>> const& conditions)
    {
        table.clear();
        QueryResult result = WorldDatabase.Query("SELECT Entry, Item, Reference, QuestRequired FROM {}", name);
        if (!result)
            return;

        do
        {
            Field* fields = result->Fetch();
            uint32 const entry = fields[0].Get<uint32>();
            uint32 const item = fields[1].Get<uint32>();
            int32 const reference = fields[2].Get<int32>();
            if (reference > 0)
                table[entry].push_back({ 0, reference });
            else if (!fields[3].Get<bool>() && IsBossGear(sObjectMgr->GetItemTemplate(item))
                && !conditions.count({ conditionSource, entry, item }))
                table[entry].push_back({ item, 0 });
        } while (result->NextRow());
    }

    void Collect(GearTable const& table, uint32 lootId, uint8 depth, std::vector<uint32>& pool)
    {
        if (depth > MaxReferenceDepth)
            return;

        auto const found = table.find(lootId);
        if (found == table.end())
            return;

        for (GearRow const& row : found->second)
        {
            if (row.reference > 0)
                Collect(ReferenceGear, uint32(row.reference), depth + 1, pool);
            else if (std::find(pool.begin(), pool.end(), row.item) == pool.end())
                pool.push_back(row.item);
        }
    }

    std::vector<uint32> PoolFor(uint32 lootId)
    {
        {
            std::shared_lock lock(PoolLock);
            if (auto const found = Pools.find(lootId); found != Pools.end())
                return found->second;
        }

        std::vector<uint32> pool;
        Collect(CreatureGear, lootId, 0, pool);
        std::unique_lock lock(PoolLock);
        return Pools.emplace(lootId, std::move(pool)).first->second;
    }

    void ApplyVariants(Loot& loot, uint8 difficulty)
    {
        for (LootItem& item : loot.items)
        {
            uint32 const target = DungeonLoot::Resolve(Variants, item.itemid, difficulty, item.needs_quest);
            if (target == item.itemid)
                continue;

            item.itemid = target;
            item.randomSuffix = GenerateEnchSuffixFactor(target);
            item.randomPropertyId = Item::GenerateItemRandomPropertyId(target);
        }
    }

    void GuaranteeOneGearDrop(Loot& loot, uint32 lootId, uint8 difficulty)
    {
        std::vector<size_t> rolled;
        for (size_t i = 0; i < loot.items.size(); ++i)
            if (IsBossGear(loot.items[i]))
                rolled.push_back(i);

        if (rolled.size() == 1)
            return;

        if (!rolled.empty())
        {
            size_t const keep = rolled[urand(0, uint32(rolled.size() - 1))];
            std::vector<LootItem> kept;
            kept.reserve(loot.items.size());
            for (size_t i = 0; i < loot.items.size(); ++i)
            {
                if (i != keep && IsBossGear(loot.items[i]))
                {
                    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(loot.items[i].itemid);
                    if (loot.items[i].conditions.empty() && !proto->HasFlag(ITEM_FLAG_MULTI_DROP) && loot.unlootedCount)
                        --loot.unlootedCount;
                    continue;
                }
                kept.push_back(loot.items[i]);
            }
            loot.items.swap(kept);
            for (size_t i = 0; i < loot.items.size(); ++i)
                loot.items[i].itemIndex = uint32(i);
            return;
        }

        std::vector<uint32> const pool = PoolFor(lootId);
        if (pool.empty())
            return;

        uint32 const chosen = DungeonLoot::Resolve(Variants, pool[urand(0, uint32(pool.size() - 1))], difficulty, false);
        loot.AddItem(LootStoreItem(chosen, 0, 100.0f, false, LOOT_MODE_DEFAULT, 0, 1, 1));
    }
}

class CoADungeonLootLoad final : public WorldScript
{
public:
    CoADungeonLootLoad() : WorldScript("CoADungeonLootLoad", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        LoadVariants();
        auto const conditions = LoadLootConditions();
        LoadGear(CreatureGear, "creature_loot_template", ConditionSourceCreatureLoot, conditions);
        LoadGear(ReferenceGear, "reference_loot_template", ConditionSourceReferenceLoot, conditions);
        std::unique_lock lock(PoolLock);
        Pools.clear();
    }
};

class CoADungeonLoot final : public MiscScript
{
public:
    CoADungeonLoot() : MiscScript("CoADungeonLoot", { MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS }) { }

    void OnAfterLootTemplateProcess(Loot* loot, LootTemplate const*, LootStore const& store, Player* owner, bool, bool,
        uint16) override
    {
        if (!loot || !owner || (&store != &LootTemplates_Creature && &store != &LootTemplates_Gameobject))
            return;

        Map* map = owner->FindMap();
        if (!map)
            return;

        ObjectGuid const source = loot->sourceWorldObjectGUID;
        Creature* creature = source.IsCreatureOrVehicle() ? map->GetCreature(source) : nullptr;
        if (!creature && !(source.IsGameObject() && map->GetGameObject(source)))
            return;

        uint8 const difficulty = DungeonLoot::Difficulty(map->GetId(), uint8(map->GetSpawnMode()), true);
        if (!difficulty)
            return;

        ApplyVariants(*loot, difficulty);

        if (&store == &LootTemplates_Creature && creature &&
            (creature->IsDungeonBoss() || creature->GetCreatureTemplate()->rank == CREATURE_ELITE_WORLDBOSS))
            GuaranteeOneGearDrop(*loot, creature->GetCreatureTemplate()->lootid, difficulty);
    }
};

void AddSC_CoADungeonLoot()
{
    new CoADungeonLootLoad();
    new CoADungeonLoot();
}
