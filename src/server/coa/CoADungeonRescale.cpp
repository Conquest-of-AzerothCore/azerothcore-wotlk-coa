/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "CoADungeonRescale.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "SpellMgr.h"
#include "Field.h"
#include "Log.h"
#include "Map.h"
#include "Item.h"
#include "ItemEnchantmentMgr.h"
#include "LootMgr.h"
#include "QueryResult.h"
#include "SpellInfo.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <cmath>
#include <map>
#include <tuple>
#include <unordered_set>

namespace
{
struct Budget
{
    std::uint8_t level;
    std::uint32_t health;
    float melee;
    float spell;
    std::uint32_t attackTime;
    std::uint32_t rangedAttackTime;
};
std::map<std::tuple<std::uint32_t, std::uint8_t, std::uint32_t>, Budget> Budgets;
std::unordered_set<std::uint32_t> Maps;
std::map<std::pair<std::uint32_t, std::int32_t>, std::int32_t> Properties;
std::map<std::uint32_t, std::pair<std::uint32_t, std::uint32_t>> Items;
std::map<std::tuple<std::uint32_t, std::uint8_t, std::uint32_t>, std::uint32_t> LootItems;

Budget const* Find(Unit const* unit)
{
    Creature const* creature = unit ? unit->ToCreature() : nullptr;
    if (!creature || !Maps.count(creature->GetMapId()) || creature->IsPet() || creature->IsTotem() ||
        creature->IsTrigger() || creature->IsCritter() || creature->IsControlledByPlayer() ||
        creature->GetCharmerOrOwnerPlayerOrPlayerItself())
        return nullptr;
    Map const* map = creature->FindMap();
    if (!map || !map->IsNonRaidDungeon() || map->IsScriptedPrivateInstance())
        return nullptr;
    auto const found = Budgets.find({map->GetId(), std::uint8_t(map->GetSpawnMode()), creature->GetEntry()});
    return found == Budgets.end() ? nullptr : &found->second;
}
}

void DungeonRescale::Load()
{
    Budgets.clear();
    Maps.clear();
    Items.clear();
    LootItems.clear();
    Properties.clear();
    if (!WorldDatabase.Query("SHOW TABLES LIKE 'coa_dungeon_rescale_budget'"))
        return;
    if (QueryResult result = WorldDatabase.Query(
        "SELECT map_id,difficulty,entry,level,health,melee_multiplier,spell_multiplier,attack_time,"
        "ranged_attack_time FROM coa_dungeon_rescale_budget"))
        do
        {
            Field* row = result->Fetch();
            Budget budget{row[3].Get<std::uint8_t>(), row[4].Get<std::uint32_t>(),
                row[5].Get<float>(), row[6].Get<float>(), row[7].Get<std::uint32_t>(), row[8].Get<std::uint32_t>()};
            if ((budget.level != 60 && budget.level != 63) || !budget.health ||
                !budget.attackTime || !budget.rangedAttackTime ||
                !std::isfinite(budget.melee) || budget.melee <= 0 ||
                !std::isfinite(budget.spell) || budget.spell <= 0 || row[1].Get<std::uint8_t>() > 2)
            {
                LOG_ERROR("server.loading", "Invalid fixed dungeon budget for entry {}", row[2].Get<std::uint32_t>());
                continue;
            }
            std::uint32_t const map = row[0].Get<std::uint32_t>();
            Maps.insert(map);
            Budgets.emplace(std::make_tuple(map, row[1].Get<std::uint8_t>(), row[2].Get<std::uint32_t>()), budget);
        } while (result->NextRow());
    if (WorldDatabase.Query("SHOW TABLES LIKE 'coa_dungeon_rescale_item'"))
        if (QueryResult result = WorldDatabase.Query("SELECT entry,pve_power,pvp_power FROM coa_dungeon_rescale_item"))
            do
            {
                Field* row = result->Fetch();
                Items.emplace(row[0].Get<std::uint32_t>(),
                    std::make_pair(row[1].Get<std::uint32_t>(), row[2].Get<std::uint32_t>()));
            } while (result->NextRow());
    if (WorldDatabase.Query("SHOW TABLES LIKE 'coa_dungeon_rescale_loot'"))
        if (QueryResult result = WorldDatabase.Query(
            "SELECT map_id,difficulty,source_item,target_item FROM coa_dungeon_rescale_loot"))
            do
            {
                Field* row = result->Fetch();
                LootItems.emplace(std::make_tuple(row[0].Get<std::uint32_t>(), row[1].Get<std::uint8_t>(),
                    row[2].Get<std::uint32_t>()), row[3].Get<std::uint32_t>());
            } while (result->NextRow());
    if (WorldDatabase.Query("SHOW TABLES LIKE 'coa_dungeon_rescale_property'"))
        if (QueryResult result = WorldDatabase.Query(
            "SELECT entry,original_property,scaled_property FROM coa_dungeon_rescale_property"))
            do
            {
                Field* row = result->Fetch();
                Properties.emplace(std::make_pair(row[0].Get<std::uint32_t>(), row[1].Get<std::int32_t>()),
                    row[2].Get<std::int32_t>());
            } while (result->NextRow());
    LOG_INFO("server.loading", "Loaded {} fixed dungeon budgets across {} maps and {} equipment budgets",
        Budgets.size(), Maps.size(), Items.size());
}

bool DungeonRescale::Contains(std::uint32_t map)
{
    return Maps.count(map);
}

bool DungeonRescale::FixedMap(Map const* map)
{
    return map && Contains(map->GetId()) && map->GetSpawnMode() <= 2 &&
        map->IsNonRaidDungeon() && !map->IsScriptedPrivateInstance();
}

bool DungeonRescale::Owns(Unit const* unit)
{
    return Find(unit);
}

std::optional<std::uint32_t> DungeonRescale::Health(Creature const* creature)
{
    Budget const* budget = Find(creature);
    return budget ? std::optional<std::uint32_t>(budget->health) : std::nullopt;
}

void DungeonRescale::SelectLevel(Creature* creature, std::uint8_t& level)
{
    if (Budget const* budget = Find(creature))
    {
        level = budget->level;
        creature->SetAttackTime(BASE_ATTACK, budget->attackTime);
        creature->SetAttackTime(OFF_ATTACK, budget->attackTime);
        creature->SetAttackTime(RANGED_ATTACK, budget->rangedAttackTime);
    }
}

float DungeonRescale::MeleeMultiplier(Unit const* attacker)
{
    Budget const* budget = Find(attacker);
    return budget ? budget->melee : 1.0f;
}

float DungeonRescale::SpellMultiplier(Unit const* attacker, SpellInfo const* spell, bool)
{
    Budget const* budget = Find(attacker);
    if (!budget)
        return 1.0f;
    bool const weapon = spell && (spell->DmgClass == SPELL_DAMAGE_CLASS_MELEE ||
        spell->DmgClass == SPELL_DAMAGE_CLASS_RANGED);
    float factor = weapon ? budget->melee : budget->spell;
    if (!spell)
        return factor;
    SpellDifficultyEntry const* family = sSpellDifficultyStore.LookupEntry(sSpellMgr->GetSpellDifficultyId(spell->Id));
    SpellInfo const* normal = family && family->SpellID[0] > 0 ?
        sSpellMgr->GetSpellInfo(family->SpellID[0]) : nullptr;
    if (!normal || normal->Id == spell->Id)
        return factor;
    auto magnitude = [attacker](SpellInfo const* info)
    {
        float value = 0;
        for (SpellEffectInfo const& effect : info->Effects)
            if (effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE || effect.Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE ||
                effect.Effect == SPELL_EFFECT_WEAPON_DAMAGE || effect.Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG ||
                effect.IsAura(SPELL_AURA_PERIODIC_DAMAGE) || effect.IsAura(SPELL_AURA_PERIODIC_LEECH))
            {
                int32 level = attacker->GetLevel();
                if (info->MaxLevel)
                    level = std::min<int32>(level, info->MaxLevel);
                level = std::max<int32>(level, info->BaseLevel);
                float const die = effect.DieSides ? (1.0f + effect.DieSides) / 2.0f : 0.0f;
                value += std::max(0.0f, effect.BasePoints + die +
                    (level - int32(std::max(info->BaseLevel, info->SpellLevel))) * effect.RealPointsPerLevel);
            }
        return value;
    };
    float const current = magnitude(spell);
    float const baseline = magnitude(normal);
    return current > 0 && baseline > 0 ? factor * baseline / current : factor;
}

bool DungeonRescale::OwnsItem(std::uint32_t entry)
{
    return Items.count(entry);
}

std::optional<std::uint32_t> DungeonRescale::ItemPower(std::uint32_t entry, bool pvp)
{
    auto const found = Items.find(entry);
    return found == Items.end() ? std::nullopt :
        std::optional<std::uint32_t>(pvp ? found->second.second : found->second.first);
}

bool DungeonRescale::ApplyLoot(Loot& loot, Map const* map)
{
    if (!FixedMap(map))
        return false;
    for (LootItem& item : loot.items)
    {
        if (item.needs_quest)
            continue;
        auto const found = LootItems.find({map->GetId(), std::uint8_t(map->GetSpawnMode()), item.itemid});
        if (found == LootItems.end() || found->second == item.itemid)
            continue;
        item.itemid = found->second;
        item.randomSuffix = GenerateEnchSuffixFactor(item.itemid);
        item.randomPropertyId = Item::GenerateItemRandomPropertyId(item.itemid);
    }
    return true;
}

void DungeonRescale::NormalizeProperty(Item* item)
{
    if (!item || item->GetItemRandomPropertyId() <= 0)
        return;
    auto const found = Properties.find({item->GetEntry(), item->GetItemRandomPropertyId()});
    if (found != Properties.end() && found->second != item->GetItemRandomPropertyId())
        item->SetItemRandomProperties(found->second);
}
