/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "CoAZoneScaling.h"
#include "CoADungeonRescale.h"
#include "CoAZoneScalingPolicy.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "Item.h"
#include "Map.h"
#include "QueryResult.h"
#include "TemporarySummon.h"
#include <map>
#include <utility>
#include <unordered_set>

namespace
{
char const* const RuntimeKey = "CoA.ZoneScaling";

struct Runtime : DataMap::Base
{
    std::uint32_t entry = 0;
    ZoneScaling::Definition zone;
    ZoneScaling::Budget budget;
};

std::map<std::uint32_t, ZoneScaling::Definition> Zones;
std::map<std::pair<std::uint32_t, std::uint32_t>, ZoneScaling::Budget> Budgets;
std::map<std::uint32_t, std::pair<std::uint32_t, std::uint32_t>> Items;
std::unordered_set<std::uint32_t> Maps;
std::map<std::pair<std::uint32_t, std::int32_t>, std::int32_t> Properties;

bool Eligible(Creature const* creature)
{
    if (!creature || !Maps.count(creature->GetMapId()))
        return false;
    if (TempSummon const* summon = creature ? creature->ToTempSummon() : nullptr)
        if (summon->GetSummonerGUID().IsPlayer() && creature->HasUnitTypeMask(UNIT_MASK_MINION))
            return false;
    return creature && creature->FindMap() && !creature->FindMap()->IsDungeon() &&
        !creature->FindMap()->IsBattlegroundOrArena() && !creature->FindMap()->IsScriptedPrivateInstance() &&
        !creature->IsPet() && !creature->IsTotem() && !creature->IsTrigger() && !creature->IsCritter() &&
        !creature->IsControlledByPlayer() && !creature->GetCharmerOrOwnerPlayerOrPlayerItself();
}

Runtime const* State(Unit const* attacker)
{
    Creature const* creature = attacker ? attacker->ToCreature() : nullptr;
    return Eligible(creature) ? creature->CustomData.Get<Runtime>(RuntimeKey) : nullptr;
}
}

void ZoneScaling::Load()
{
    Zones.clear();
    Budgets.clear();
    Items.clear();
    Maps.clear();
    Properties.clear();
    if (!WorldDatabase.Query("SHOW TABLES LIKE 'coa_zone_scaling'"))
        return;
    if (QueryResult result = WorldDatabase.Query(
        "SELECT zone_id,map_id,zone_order,health_step,damage_step FROM coa_zone_scaling WHERE enabled=1"))
        do
        {
            Field* row = result->Fetch();
            Definition zone{ row[0].Get<std::uint32_t>(), row[1].Get<std::uint32_t>(),
                row[2].Get<std::uint32_t>(), row[3].Get<float>(), row[4].Get<float>() };
            if (Valid(zone))
            {
                Zones.emplace(zone.zone, zone);
                Maps.insert(zone.map);
            }
            else
                LOG_ERROR("server.loading", "Invalid outdoor scaling definition for zone {}", zone.zone);
        } while (result->NextRow());
    if (QueryResult result = WorldDatabase.Query(
        "SELECT zone_id,entry,level,health,melee_multiplier,spell_multiplier FROM coa_zone_creature_budget"))
        do
        {
            Field* row = result->Fetch();
            Budget budget{ row[2].Get<std::uint8_t>(), row[3].Get<std::uint32_t>(),
                row[4].Get<float>(), row[5].Get<float>() };
            if (Valid(budget) && Zones.count(row[0].Get<std::uint32_t>()))
                Budgets.emplace(std::make_pair(row[0].Get<std::uint32_t>(), row[1].Get<std::uint32_t>()), budget);
            else
                LOG_ERROR("server.loading", "Invalid outdoor creature budget for zone {}, entry {}",
                    row[0].Get<std::uint32_t>(), row[1].Get<std::uint32_t>());
        } while (result->NextRow());
    if (QueryResult result = WorldDatabase.Query("SELECT zone_id,entry,pve_power,pvp_power FROM coa_zone_item_budget"))
        do
        {
            Field* row = result->Fetch();
            if (Zones.count(row[0].Get<std::uint32_t>()))
                Items.emplace(row[1].Get<std::uint32_t>(),
                    std::make_pair(row[2].Get<std::uint32_t>(), row[3].Get<std::uint32_t>()));
        } while (result->NextRow());
    if (QueryResult result = WorldDatabase.Query(
        "SELECT zone_id,entry,original_property,scaled_property FROM coa_zone_property_mapping"))
        do
        {
            Field* row = result->Fetch();
            std::uint32_t const entry = row[1].Get<std::uint32_t>();
            if (Zones.count(row[0].Get<std::uint32_t>()))
                Properties.emplace(std::make_pair(entry, row[2].Get<std::int32_t>()), row[3].Get<std::int32_t>());
        } while (result->NextRow());
    LOG_INFO("server.loading", "Loaded {} outdoor zones, {} creatures, {} items and {} property mappings",
        Zones.size(), Budgets.size(), Items.size(), Properties.size());
}

void ZoneScaling::SelectLevel(Creature* creature, std::uint8_t& level)
{
    if (!Eligible(creature))
        return;
    Runtime const* previous = creature->CustomData.Get<Runtime>(RuntimeKey);
    if (previous && previous->entry == creature->GetEntry())
    {
        level = previous->budget.level;
        return;
    }
    std::uint32_t zoneId = previous ? previous->zone.zone : creature->GetZoneId();
    if (TempSummon const* summon = creature->ToTempSummon())
    {
        Unit const* summoner = summon->GetSummonerUnit();
        if (Runtime const* state = State(summoner))
            zoneId = state->zone.zone;
    }
    auto const zone = Zones.find(zoneId);
    if (zone == Zones.end() || zone->second.map != creature->GetMapId())
        return;
    auto const budget = Budgets.find({ zoneId, creature->GetEntry() });
    if (budget == Budgets.end())
    {
        creature->CustomData.Erase(RuntimeKey);
        return;
    }
    Runtime& state = *creature->CustomData.GetDefault<Runtime>(RuntimeKey);
    state.entry = creature->GetEntry();
    state.zone = zone->second;
    state.budget = budget->second;
    level = state.budget.level;
}

std::optional<std::uint32_t> ZoneScaling::Health(Creature const* creature)
{
    if (Runtime const* state = State(creature))
        return Health(state->zone, state->budget);
    return std::nullopt;
}

float ZoneScaling::MeleeMultiplier(Unit const* attacker)
{
    if (Runtime const* state = State(attacker))
        return Melee(state->zone, state->budget);
    return 1.0f;
}

float ZoneScaling::SpellMultiplier(Unit const* attacker)
{
    if (Runtime const* state = State(attacker))
        return Spell(state->zone, state->budget);
    return 1.0f;
}

bool ZoneScaling::OwnsItem(std::uint32_t entry)
{
    return Items.count(entry) != 0 || DungeonRescale::OwnsItem(entry);
}

std::optional<std::uint32_t> ZoneScaling::ItemPower(std::uint32_t entry, bool pvp)
{
    if (auto const power = DungeonRescale::ItemPower(entry, pvp))
        return power;
    auto const item = Items.find(entry);
    return item == Items.end() ? std::nullopt :
        std::optional<std::uint32_t>(pvp ? item->second.second : item->second.first);
}

void ZoneScaling::NormalizeProperty(Item* item)
{
    DungeonRescale::NormalizeProperty(item);
    if (item && DungeonRescale::OwnsItem(item->GetEntry()))
        return;
    if (!item || item->GetItemRandomPropertyId() <= 0)
        return;
    auto const property = Properties.find({ item->GetEntry(), item->GetItemRandomPropertyId() });
    if (property != Properties.end() && property->second != item->GetItemRandomPropertyId())
        item->SetItemRandomProperties(property->second);
}
