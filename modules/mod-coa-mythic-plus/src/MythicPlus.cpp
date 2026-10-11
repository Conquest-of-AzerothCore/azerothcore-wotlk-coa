/*
 * Mythic+ keystone runs, spoken in Ascension's own protocol so the client's
 * Ascension_MythicPlus addon (tracker, timer, banner, keystone socket) runs
 * unchanged. The wire format was read out of the client's Extensions.dll; see
 * mythic-plus-recherche/protokoll-20260926.md.
 *
 * A run, in order:
 *  1. The group leader uses a keystone anywhere inside its dungeon (Mythic
 *     difficulty). Only then the socket window opens (SMSG 0x0906, window 5);
 *     "Start Keystone" sends CMSG 0x0527 and starts exactly that key.
 *  2. Everybody is put at the wing's start point, the dungeon's creatures are
 *     scaled to the key level, the week's affixes go on (creature affixes on the
 *     enemies, Pack Tactics on the players) and a 10 s countdown runs (the 10 is
 *     fixed in the client).
 *  3. Timer, enemy forces and encounters go out as the run goes on. Creatures
 *     drop no loot while a run is active.
 *  4. Done when the required encounters, the final boss and 100 % enemy
 *     forces are down. Finishing within 40 % / 55 % / 100 % of the limit gives
 *     +3 / +2 / +1 and that many caches; the new key points at a random
 *     dungeon.
 *  5. The key drops one level the moment a run starts and gets its new level
 *     at the end, so a run that is abandoned leaves a key one level lower.
 *
 * The first key: killing the final boss of a Mythic dungeon hands every
 * player without a keystone a random +1 key.
 *
 * Affixes: the week is the day of the year / 7, the same count the client uses
 * to show them (Extensions.dll 0x102bb0c0), and MythicAffixes.dbc gives the
 * affixes for week and level. The logged runs (week 33 of 2026) match it.
 *
 * Numbers come from the client tables (MythicPlusData.h). What the client does
 * not hold and the logs cannot tell (enemy forces per creature, cache
 * contents) sits in coa_mythic_forces and coa_mythic_reward.
 */

#include "MythicPlusData.h"

#include "Chat.h"
#include "ChatCommand.h"
#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "GameTime.h"
#include "GlobalScript.h"
#include "DungeonHealth.h"
#include "ItemScript.h"
#include "ScriptedGossip.h"
#include <cmath>
#include "Group.h"
#include "InstanceScript.h"
#include "Item.h"
#include "LFGMgr.h"
#include "Log.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QueryResult.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include "AscensionCompatOpcodes.h"
#include "AscensionDungeonRelease.h"
#include "AscensionSpecLoot.h"
#include "CoADungeonCompletion.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include "Timer.h"

#include <algorithm>
#include <array>
#include <map>
#include <mutex>
#include <optional>
#include <set>
#include <sstream>
#include <cstring>
#include <iterator>
#include <tuple>
#include <unordered_map>

using namespace Acore::ChatCommands;

namespace
{
    using namespace CoaMythicPlus;

    // Ascension opcodes (live client numbering, same table the core uses).
    constexpr uint16 CMSG_CUSTOM_MYTHIC_PLUS_ACTIVATE = 0x0527;
    constexpr uint16 SMSG_CUSTOM_WINDOW_SET_VISIBILITY = 0x0906;
    constexpr uint16 SMSG_MYTHIC_PLUS_DUNGEON_STATE_CHANGED = 0x0908;
    constexpr uint16 SMSG_MYTHIC_PLUS_PROGRESS_UPDATE = 0x0909;
    constexpr uint16 SMSG_MYTHIC_PLUS_TIMER_UPDATE = 0x090A;
    constexpr uint16 SMSG_INSTANCE_INFO = 0x09C1;

    constexpr uint16 SMSG_PATCH_MYTHIC_AFFIXES = 0x056C;
    constexpr uint16 SMSG_PATCH_TIMED_DUNGEON = 0x0572;
    constexpr uint16 SMSG_PATCH_GLOBAL_STRINGS = 0x0676;

    constexpr uint8 WINDOW_KEYSTONE_ACTIVATION = 5;

    // SMSG_PATCH_GLOBAL_STRINGS: u32 id, u32 flags, 8 bytes unused, key and value as C strings; the client sets the
    // Lua global at once when the flag for its current screen is set.
    constexpr uint32 GLOBAL_STRING_IN_GAME = 0x1;
    constexpr uint32 GLOBAL_STRING_AT_LOGIN = 0x2;
    // MapDifficulty.dbc names DUNGEON_DIFFICULTY_5PLAYER_EPIC for Mythic, which the client's GlobalStrings.dbc lacks;
    // without it the welcome message reads "Deadmines ()".
    constexpr std::array<std::tuple<uint32, char const*, char const*>, 1> CLIENT_STRINGS = { {
        { 9700001, "DUNGEON_DIFFICULTY_5PLAYER_EPIC", "5 Player (Mythic)" },
    } };

    enum RunState : uint8
    {
        STATE_NONE      = 0,
        STATE_COUNTDOWN = 1,
        STATE_INACTIVE  = 2,
        STATE_RUNNING   = 3,
        STATE_TIMED     = 4,
        STATE_OVERTIME  = 5,
    };

    constexpr uint32 COUNTDOWN_MS = 10 * IN_MILLISECONDS;
    constexpr uint32 TIMER_PACKET_MS = IN_MILLISECONDS;
    constexpr uint32 BASE_ENTRY_STEP = 100000;   // E, E+100000 Heroic, E+200000 Mythic, ...
    constexpr uint32 MYTHIC_DIFFICULTY = 2;      // DungeonEncounter.dbc difficulty of Mythic
    constexpr uint32 SPELL_ACTIVATE_KEYSTONE = 161;

    // Affix spells as MythicAffixes.dbc names them. Most go on the enemies as
    // they are. Pack Tactics is a player affix (its tooltip says so). Avenger
    // shows as 80044, but the live server runs it through its own tiered
    // spells (Rallying Cry 250 / 500 / 1000 by expansion); the logs of vanilla
    // dungeons show 2191077's Rallying Cry 2191074 and 2191080.
    constexpr uint32 AFFIX_AVENGER = 80044;
    constexpr uint32 AFFIX_PACK_TACTICS = 80054;
    constexpr std::array<uint32, 3> AVENGER_BY_EXPANSION = { 2191077, 2191078, 2191079 };

    struct Run
    {
        uint32 instanceId = 0;
        uint32 mapId = 0;
        uint32 keystoneItem = 0;
        uint32 lfgId = 0;
        uint32 level = 0;
        ObjectGuid owner;

        TimedDungeon dungeon;
        Scaling scaling;

        uint8 state = STATE_NONE;
        uint32 countdownMs = 0;
        uint32 elapsedMs = 0;
        uint32 timerPacketMs = 0;

        uint32 rotation = 0;
        std::vector<uint32> affixes;    // MythicAffixes.dbc ids for this week and level

        uint32 forces = 0;
        double forcesExact = 0.0;       // kills x forcesScale, forces is the whole part
        float forcesScale = 1.0f;       // see ScaleForces
        uint32 forcesAvailable = 0;
        std::set<uint32> encounters;    // client encounter ids (DungeonEncounterExtra.dbc)
        bool finalKilled = false;
        uint32 champions = 0;           // Mythic Champions killed
        uint32 championsPlaced = 0;
        uint32 championsRequired = 0;

        bool Active() const { return state == STATE_COUNTDOWN || state == STATE_RUNNING; }
        bool Scaled() const { return state != STATE_NONE && state != STATE_INACTIVE; }
        uint32 TimeLeftMs() const { return elapsedMs >= dungeon.timeLimitMs ? 0 : dungeon.timeLimitMs - elapsedMs; }
    };

    struct Reward
    {
        uint32 levelMin;
        uint32 levelMax;
        uint32 item;
        uint32 count;
    };

    std::recursive_mutex g_lock;
    std::unordered_map<uint32, Run> g_runs;             // by instance id
    std::unordered_map<uint32, uint32> g_forces;        // creature entry -> enemy forces
    std::vector<Reward> g_rewards;
    std::unordered_map<ObjectGuid, uint32> g_socketed;   // player -> keystone item used, waiting for Start

    // ---------------------------------------------------------------- config

    bool Enabled() { return sConfigMgr->GetOption<bool>("MythicPlus.Enable", true); }
    int32 RequiredDifficulty() { return sConfigMgr->GetOption<int32>("MythicPlus.RequiredDifficulty", 2); }
    uint32 MaxExpansion() { return sConfigMgr->GetOption<uint32>("MythicPlus.MaxExpansion", 0); }

    // ---------------------------------------------------------------- packets

    void SendWindow(Player* player, bool visible)
    {
        LOG_INFO("module", "Mythic+: keystone socket window {} for {} on map {}", visible ? "shown" : "hidden",
            player->GetName(), player->GetMapId());
        WorldPacket data(SMSG_CUSTOM_WINDOW_SET_VISIBILITY, 2);
        data << uint8(WINDOW_KEYSTONE_ACTIVATION) << uint8(visible ? 1 : 0);
        player->SendDirectMessage(&data);
    }

    void SendInstanceInfo(Player* player, uint32 instanceId)
    {
        WorldPacket data(SMSG_INSTANCE_INFO, 4);
        data << uint32(instanceId);
        player->SendDirectMessage(&data);
    }

    void SendState(Player* player, Run const& run, uint8 state)
    {
        WorldPacket data(SMSG_MYTHIC_PLUS_DUNGEON_STATE_CHANGED, 17);
        data << uint64(0);                  // skipped by the client
        data << uint8(state);
        data << uint32(run.keystoneItem);
        data << uint32(run.instanceId);     // must match SMSG_INSTANCE_INFO
        player->SendDirectMessage(&data);
    }

    void SendProgress(Player* player, Run const& run)
    {
        WorldPacket data(SMSG_MYTHIC_PLUS_PROGRESS_UPDATE, 12 + 4 * run.encounters.size());
        data << uint32(run.encounters.size());
        for (uint32 id : run.encounters)
            data << uint32(id);
        data << uint32(std::min(run.forces, run.dungeon.forcesTotal ? run.dungeon.forcesTotal : run.forces));
        data << uint32(run.champions);
        player->SendDirectMessage(&data);
    }

    void SendTimer(Player* player, Run const& run)
    {
        WorldPacket data(SMSG_MYTHIC_PLUS_TIMER_UPDATE, 4);
        data << uint32(run.TimeLeftMs());
        player->SendDirectMessage(&data);
    }

    // Everything a client needs to show a run it joins in the middle.
    void SendFullRun(Player* player, Run const& run)
    {
        SendInstanceInfo(player, run.instanceId);
        SendState(player, run, run.state == STATE_COUNTDOWN ? STATE_RUNNING : run.state);
        SendProgress(player, run);
        SendTimer(player, run);
    }

    template<class F>
    void ForEachPlayer(Map* map, F&& f)
    {
        map->DoForAllPlayers([&f](Player* player)
        {
            if (player->IsInWorld() && player->GetSession())
                f(player);
        });
    }

    // ---------------------------------------------------------------- items

    bool HasAnyKeystone(Player* player)
    {
        for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
            if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                if (Data::Instance().IsKeystone(item->GetEntry()))
                    return true;
        for (uint8 bag = INVENTORY_SLOT_BAG_START; bag < INVENTORY_SLOT_BAG_END; ++bag)
            if (Bag* container = player->GetBagByPos(bag))
                for (uint32 slot = 0; slot < container->GetBagSize(); ++slot)
                    if (Item* item = container->GetItemByPos(slot))
                        if (Data::Instance().IsKeystone(item->GetEntry()))
                            return true;
        for (uint8 slot = BANK_SLOT_ITEM_START; slot < BANK_SLOT_ITEM_END; ++slot)
            if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                if (Data::Instance().IsKeystone(item->GetEntry()))
                    return true;
        return false;
    }

    // Every keystone the player carries, in bags or bank.
    std::vector<uint32> CarriedKeystones(Player* player)
    {
        std::vector<uint32> found;
        auto check = [&found](Item* item)
        {
            if (item && Data::Instance().IsKeystone(item->GetEntry()))
                found.push_back(item->GetEntry());
        };
        for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
            check(player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
        for (uint8 bag = INVENTORY_SLOT_BAG_START; bag < INVENTORY_SLOT_BAG_END; ++bag)
            if (Bag* container = player->GetBagByPos(bag))
                for (uint32 slot = 0; slot < container->GetBagSize(); ++slot)
                    check(container->GetItemByPos(slot));
        for (uint8 slot = BANK_SLOT_ITEM_START; slot < BANK_SLOT_ITEM_END; ++slot)
            check(player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
        for (uint8 bag = BANK_SLOT_BAG_START; bag < BANK_SLOT_BAG_END; ++bag)
            if (Bag* container = player->GetBagByPos(bag))
                for (uint32 slot = 0; slot < container->GetBagSize(); ++slot)
                    check(container->GetItemByPos(slot));
        return found;
    }

    uint32 DestroyKeystones(Player* player)
    {
        uint32 count = 0;
        for (uint32 entry : CarriedKeystones(player))
        {
            player->DestroyItemCount(entry, 1, true, false);
            ++count;
        }
        return count;
    }

    void Give(Player* player, uint32 item, uint32 count)
    {
        if (!item || !count || !sObjectMgr->GetItemTemplate(item))
        {
            LOG_ERROR("module", "Mythic+: item {} x{} for {} has no item template", item, count, player->GetName());
            return;
        }
        if (Data::Instance().IsKeystone(item))
            DestroyKeystones(player);
        if (!player->AddItem(item, count))
            ChatHandler(player->GetSession()).PSendSysMessage("Mythic+: your bags are full, {} x item {} was lost.", count, item);
    }

    // LFG dungeons new keys never point at (MythicPlus.ExcludedDungeons), e.g.
    // Blackrock Caverns (2045, 2046), which is not restored yet.
    std::set<uint32> ExcludedDungeons()
    {
        std::string list = sConfigMgr->GetOption<std::string>("MythicPlus.ExcludedDungeons", "2045 2046");
        std::replace(list.begin(), list.end(), ',', ' ');
        std::istringstream in(list);
        std::set<uint32> out;
        for (uint32 id; in >> id;)
            out.insert(id);
        return out;
    }

    // A random keystone at this level. 0 when no dungeon has a key for it.
    uint32 RandomKeystone(uint32 level)
    {
        std::vector<uint32> pool = Data::Instance().GetKeyPool(level, MaxExpansion());
        std::set<uint32> const excluded = ExcludedDungeons();
        std::erase_if(pool, [&excluded](uint32 lfgId) { return excluded.count(lfgId) != 0; });
        if (pool.empty())
            return 0;
        return Data::Instance().GetKeystoneItem(pool[urand(0, uint32(pool.size()) - 1)], level);
    }

    // A player holds one keystone at a time, as on the live server; with
    // several the client shows the run of whichever it finds first.
    void ReplaceKeystone(Player* player, uint32 /*oldItem*/, uint32 newItem)
    {
        Give(player, newItem, 1);
    }

    // ---------------------------------------------------------------- creatures

    uint32 BaseEntry(uint32 entry)
    {
        return entry % BASE_ENTRY_STEP;
    }

    // The encounter a kill completes, as the client numbers it: the Mythic row
    // of DungeonEncounter.dbc for the same map and encounter index. Credit is
    // matched on the kill credit in instance_encounters, for the instance's
    // difficulty or, where that has none, Normal.
    DungeonEncounter const* FindEncounter(Creature* creature, uint32& clientId)
    {
        Map* map = creature->GetMap();
        DungeonEncounterList const* list = sObjectMgr->GetDungeonEncounterList(map->GetId(), map->GetDifficulty());
        if (!list)
            list = sObjectMgr->GetDungeonEncounterList(map->GetId(), REGULAR_DIFFICULTY);
        if (!list)
            return nullptr;

        uint32 entry = creature->GetEntry();
        uint32 base = BaseEntry(entry);
        // Ring of Law ends with one of six arena bosses. Their own encounters
        // (2981-2986) are dropped at load because Ring of Law (credit High
        // Justice Grimstone) is already the final one; any of them clears it.
        if (map->GetId() == 230 && base >= 9027 && base <= 9032)
            entry = base = 10096;
        for (DungeonEncounter const* encounter : *list)
        {
            if (encounter->creditType != ENCOUNTER_CREDIT_KILL_CREATURE)
                continue;
            if (encounter->creditEntry != entry && encounter->creditEntry != base)
                continue;

            clientId = encounter->dbcEntry->id;
            for (DungeonEncounterEntry const* e : sDungeonEncounterStore)
                if (e->mapId == encounter->dbcEntry->mapId && e->difficulty == MYTHIC_DIFFICULTY
                    && e->encounterIndex == encounter->dbcEntry->encounterIndex)
                {
                    clientId = e->id;
                    break;
                }
            return encounter;
        }
        return nullptr;
    }

    // Enemy forces for a kill. coa_mythic_forces wins; otherwise creatures
    // placed in the database count 1, elites 2 (an assumption: the logs only
    // give per-dungeon totals). Summons count only through the table, which
    // keeps affix adds like Standard of Valiance out.
    uint32 ForcesFor(Creature* creature)
    {
        auto itr = g_forces.find(creature->GetEntry());
        if (itr == g_forces.end())
            itr = g_forces.find(BaseEntry(creature->GetEntry()));
        if (itr != g_forces.end())
            return itr->second;

        if (!creature->GetSpawnId() || creature->IsCritter() || creature->IsTotem() || creature->IsCivilian())
            return 0;
        if (creature->IsControlledByPlayer())
            return 0;
        return creature->isElite() ? sConfigMgr->GetOption<uint32>("MythicPlus.DefaultForces.Elite", 2)
                                   : sConfigMgr->GetOption<uint32>("MythicPlus.DefaultForces.Normal", 1);
    }

    // The boss of the run's wing this kill completes, as the client lists it
    // in DungeonEncounterExtra.dbc, or nullptr. The Ring of Law ends with one
    // of six arena bosses, and the client lists each with its own encounter
    // (2981-2986 for Blackrock Depths - Prison), final like Ring of Law itself;
    // the progress packet carries the killed boss's own id, as on Ascension.
    WingEncounter const* FindWingEncounter(Run const& run, Creature* creature)
    {
        std::vector<WingEncounter> const* list = Data::Instance().GetWingEncounters(run.lfgId);
        if (!list)
            return nullptr;
        uint32 const base = BaseEntry(creature->GetEntry());
        for (WingEncounter const& encounter : *list)
            if (encounter.creature == base || encounter.creature == creature->GetEntry())
                return &encounter;
        return nullptr;
    }

    // ForcesFor for a spawn that is not loaded yet.
    uint32 ForcesForSpawn(CreatureData const& data)
    {
        auto itr = g_forces.find(data.id);
        if (itr != g_forces.end())
            return itr->second;
        CreatureTemplate const* info = sObjectMgr->GetCreatureTemplate(data.id);
        if (!info || info->type == CREATURE_TYPE_CRITTER
            || (info->flags_extra & (CREATURE_FLAG_EXTRA_TRIGGER | CREATURE_FLAG_EXTRA_CIVILIAN)))
            return 0;
        FactionTemplateEntry const* faction = sFactionTemplateStore.LookupEntry(info->faction);
        if (!faction || !faction->IsHostileToPlayers())
            return 0;
        return info->rank ? sConfigMgr->GetOption<uint32>("MythicPlus.DefaultForces.Elite", 2)
                          : sConfigMgr->GetOption<uint32>("MythicPlus.DefaultForces.Normal", 1);
    }

    // TimedDungeons.dbc sets the forces a wing needs, but not what each
    // creature is worth; with 1 per creature and 2 per elite some wings ran
    // out before the end (Shadowfang Keep - Halls of the Damned at 70 % by
    // Odo) and others needed a full clear (The Stockade). Every kill is
    // scaled up so that killing MythicPlus.Forces.ClearShare of the trash the
    // wing has (by default 58 %: the usual route through Halls of the Damned)
    // reaches 100 %. Wings with far more trash than needed (Blackrock Depths
    // - Prison, whose list reaches into optional halls) are not scaled down.
    // A creature belongs to the wing of the nearest boss the client lists for
    // the map's wings.
    // MythicPlus.Forces.WingFactor: "lfgId:factor" pairs that correct single wings to what live runs showed.
    float WingForcesFactor(uint32 lfgId)
    {
        std::istringstream in(sConfigMgr->GetOption<std::string>("MythicPlus.Forces.WingFactor", "3320:0.626"));
        std::string pair;
        while (in >> pair)
        {
            std::size_t const colon = pair.find(':');
            if (colon != std::string::npos && std::strtoul(pair.c_str(), nullptr, 10) == lfgId)
                return std::max(0.01f, std::strtof(pair.c_str() + colon + 1, nullptr));
        }
        return 1.0f;
    }

    void ScaleForces(uint32 mapId, uint32 difficulty, Run& run, std::string* missingBosses = nullptr)
    {
        std::map<uint32, std::set<uint32>> wingsOfBoss;   // boss entry -> LFG dungeons listing it
        for (auto const& [lfgId, dungeon] : Data::Instance().Dungeons())
            if (dungeon.mapId == mapId)
                if (std::vector<WingEncounter> const* list = Data::Instance().GetWingEncounters(lfgId))
                    for (WingEncounter const& encounter : *list)
                        wingsOfBoss[encounter.creature].insert(lfgId);

        // Spawns from the database: far parts of the instance may not be
        // loaded yet when the key starts.
        uint32 const spawnBit = 1u << difficulty;
        std::set<uint32> spawnedBosses;
        std::vector<std::pair<Position, std::set<uint32> const*>> bosses;
        std::vector<std::pair<Position, uint32>> trash;
        for (auto const& [spawnId, data] : sObjectMgr->GetAllCreatureData())
        {
            if (data.mapid != mapId || !(data.spawnMask & spawnBit))
                continue;
            Position const pos(data.posX, data.posY, data.posZ);
            uint32 credit = data.id;
            if (mapId == 230 && credit >= 9027 && credit <= 9032)
                credit = 10096;
            auto boss = wingsOfBoss.find(credit);
            if (boss != wingsOfBoss.end())
            {
                bosses.emplace_back(pos, &boss->second);
                spawnedBosses.insert(credit);
            }
            else if (uint32 forces = ForcesForSpawn(data))
                trash.emplace_back(pos, forces);
        }

        uint32 available = 0;
        for (auto const& [pos, forces] : trash)
        {
            std::set<uint32> const* wings = nullptr;
            float best = 0.0f;
            for (auto const& [bossPos, bossWings] : bosses)
            {
                float const dist = pos.GetExactDistSq(&bossPos);
                if (!wings || dist < best)
                {
                    wings = bossWings;
                    best = dist;
                }
            }
            if (!wings || wings->count(run.lfgId))
                available += forces;
        }

        float const share = sConfigMgr->GetOption<float>("MythicPlus.Forces.ClearShare", 0.58f);
        run.forcesAvailable = available;
        run.forcesScale = available && run.dungeon.forcesTotal && share > 0.0f
            ? std::max(1.0f, float(run.dungeon.forcesTotal) / (available * share)) : 1.0f;
        run.forcesScale *= WingForcesFactor(run.lfgId);
        if (missingBosses)
            if (std::vector<WingEncounter> const* list = Data::Instance().GetWingEncounters(run.lfgId))
                for (WingEncounter const& encounter : *list)
                    if (!spawnedBosses.count(encounter.creature))
                        *missingBosses += Acore::StringFormat(" {}{}", encounter.creature, encounter.final ? "(final)" : "");
        LOG_INFO("module", "Mythic+: lfg {} on map {}: {} forces in the wing, {} needed, each kill x{:.2f}",
            run.lfgId, mapId, available, run.dungeon.forcesTotal, run.forcesScale);
    }

    bool IsScalable(Creature* creature)
    {
        return creature && !creature->IsPet() && !creature->IsControlledByPlayer() && !creature->IsTotem();
    }

    void ScaleHealthBy(Creature* creature, float factor)
    {
        if (!IsScalable(creature) || factor <= 0.0f || factor == 1.0f)
            return;
        float pct = creature->GetMaxHealth() ? float(creature->GetHealth()) / creature->GetMaxHealth() : 1.0f;
        uint32 health = std::max<uint32>(1, uint32(creature->GetCreateHealth() * factor));
        creature->SetCreateHealth(health);
        creature->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
        creature->UpdateMaxHealth();
        if (creature->IsAlive())
            creature->SetHealth(std::max<uint32>(1, uint32(creature->GetMaxHealth() * pct)));
    }

    void ScaleHealth(Creature* creature, Scaling const& scaling)
    {
        if (scaling.health > 1.0f)
            ScaleHealthBy(creature, scaling.health);
    }

    Run* RunFor(Map* map)
    {
        if (!map || !map->IsDungeon())
            return nullptr;
        auto itr = g_runs.find(map->GetInstanceId());
        return itr != g_runs.end() ? &itr->second : nullptr;
    }

    // ---------------------------------------------------------------- affixes

    int32 g_weekOverride = -1;      // .mythic week; -1 follows the calendar

    uint32 CurrentRotation()
    {
        int32 forced = g_weekOverride >= 0 ? g_weekOverride : sConfigMgr->GetOption<int32>("MythicPlus.Week", -1);
        if (forced >= 0)
            return uint32(forced) % 53;
        return uint32(Acore::Time::TimeBreakdown().tm_yday / 7);
    }

    uint32 CreatureAffixSpell(uint32 affix, uint32 expansion)
    {
        if (affix == AFFIX_PACK_TACTICS)
            return 0;
        if (affix == AFFIX_AVENGER)
            return AVENGER_BY_EXPANSION[std::min<uint32>(expansion, AVENGER_BY_EXPANSION.size() - 1)];
        return affix;
    }

    uint32 PlayerAffixSpell(uint32 affix)
    {
        return affix == AFFIX_PACK_TACTICS ? affix : 0;
    }

    std::string AffixNames(std::vector<uint32> const& affixes)
    {
        std::string out;
        for (uint32 id : affixes)
        {
            SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
            if (!out.empty())
                out += ", ";
            std::string name = info && info->SpellName[0] ? info->SpellName[0] : std::to_string(id);
            while (!name.empty() && name.back() == ' ')
                name.pop_back();
            out += name;
        }
        return out.empty() ? "none" : out;
    }

    bool TakesAffixes(Creature* creature)
    {
        return IsScalable(creature) && creature->IsAlive() && !creature->IsCritter() && !creature->IsTrigger()
            && !creature->IsCivilian() && creature->IsHostileToPlayers();
    }

    void ApplyCreatureAffixes(Creature* creature, Run const& run)
    {
        if (!creature->IsInWorld() || !TakesAffixes(creature))
            return;
        for (uint32 affix : run.affixes)
            if (uint32 spell = CreatureAffixSpell(affix, run.dungeon.expansion))
                if (!creature->HasAura(spell) && sSpellMgr->GetSpellInfo(spell))
                    creature->AddAura(spell, creature);
    }

    void ApplyPlayerAffixes(Player* player, Run const& run)
    {
        for (uint32 affix : run.affixes)
            if (uint32 spell = PlayerAffixSpell(affix))
                if (!player->HasAura(spell))
                    player->AddAura(spell, player);
    }

    void RemovePlayerAffixes(Player* player, Run const& run)
    {
        for (uint32 affix : run.affixes)
            if (uint32 spell = PlayerAffixSpell(affix))
                player->RemoveAurasDueToSpell(spell);
    }

    // ---------------------------------------------------------------- wings

    std::string DungeonName(uint32 lfgId)
    {
        LFGDungeonEntry const* entry = sLFGDungeonStore.LookupEntry(lfgId);
        return entry && entry->Name[0] ? entry->Name[0] : std::to_string(lfgId);
    }

    // Whether this keystone can be started here and now. Returns an error for
    // the player, or nullptr.
    char const* CheckKeystone(Player* player, uint32 item, Keystone const*& key, TimedDungeon const*& dungeon,
        std::string& detail)
    {
        Map* map = player->GetMap();
        key = Data::Instance().GetKeystone(item);
        dungeon = key ? Data::Instance().GetDungeon(key->lfgId) : nullptr;
        if (!key || !dungeon)
            return "This is not a keystone.";
        if (!map || !map->IsDungeon() || map->IsRaid())
            return "Use your keystone inside its dungeon.";
        if (dungeon->mapId != map->GetId())
        {
            detail = DungeonName(key->lfgId);
            return "This keystone is for another dungeon:";
        }
        if (RequiredDifficulty() >= 0 && int32(map->GetDifficulty()) != RequiredDifficulty())
            return "Keystones only work on Mythic difficulty.";
        if (Group* group = player->GetGroup())
        {
            if (!group->IsLeader(player->GetGUID()))
                return "Only the group leader can start the keystone.";
            if (group->isLFGGroup() && !sConfigMgr->GetOption<bool>("MythicPlus.AllowInDungeonFinder", true))
                return "Keystones cannot be used in a Dungeon Finder group.";
        }
        if (Run* existing = RunFor(map); existing && existing->state != STATE_INACTIVE)
            return "A keystone was already used in this instance.";
        if (InstanceScript* script = map->ToInstanceMap()->GetInstanceScript())
            if (script->GetCompletedEncounterMask())
                return "A boss in this instance is already dead. Reset the instance first.";
        return nullptr;
    }

    // ---------------------------------------------------------------- rewards

    constexpr uint32 ITEM_MARK_OF_TRIUMPH = 1414502;
    constexpr uint32 ITEM_SPOILS_HEROIC = 1202039;
    constexpr uint32 ITEM_SPOILS_MYTHIC = 1027965;
    // "Mythical Cache" for Mythic 1 to 12 (item description @Mythic N@).
    constexpr std::array<uint32, 12> MYTHICAL_CACHES = { 2093952, 2093963, 2093964, 2093965, 2093966, 2093967,
        2093968, 2093995, 2093996, 2093997, 2093998, 2093999 };

    uint32 CacheForLevel(uint32 level)
    {
        return MYTHICAL_CACHES[std::clamp<uint32>(level, 1, MYTHICAL_CACHES.size()) - 1];
    }

    // Weeks start on Tuesday 00:00 UTC (1970-01-06 was one).
    uint32 CurrentWeek()
    {
        return uint32((GameTime::GetGameTime().count() - 5 * 86400) / (7 * 86400));
    }

    struct Weekly
    {
        uint32 coins = 0;
        uint32 caches = 0;
    };

    Weekly GetWeekly(ObjectGuid guid)
    {
        Weekly weekly;
        if (QueryResult result = CharacterDatabase.Query("SELECT coins, caches FROM coa_mythic_weekly WHERE guid = {} AND week = {}",
            guid.GetCounter(), CurrentWeek()))
        {
            weekly.coins = (*result)[0].Get<uint32>();
            weekly.caches = (*result)[1].Get<uint32>();
        }
        return weekly;
    }

    void AddWeekly(ObjectGuid guid, uint32 coins, uint32 caches)
    {
        CharacterDatabase.DirectExecute("INSERT INTO coa_mythic_weekly (guid, week, coins, caches) VALUES ({}, {}, {}, {}) "
            "ON DUPLICATE KEY UPDATE coins = coins + VALUES(coins), caches = caches + VALUES(caches)",
            guid.GetCounter(), CurrentWeek(), coins, caches);
    }

    uint32 WeeklyCoinCap() { return sConfigMgr->GetOption<uint32>("MythicPlus.Coins.WeeklyCap", 5500); }
    uint32 WeeklyCacheCap() { return sConfigMgr->GetOption<uint32>("MythicPlus.Caches.WeeklyCap", 80); }

    // Highest keystone level a character finished in time.
    uint32 GetBestLevel(ObjectGuid guid)
    {
        if (QueryResult result = CharacterDatabase.Query("SELECT level FROM coa_mythic_best WHERE guid = {}", guid.GetCounter()))
            return (*result)[0].Get<uint32>();
        return 0;
    }

    void SetBestLevel(ObjectGuid guid, uint32 level)
    {
        CharacterDatabase.DirectExecute("INSERT INTO coa_mythic_best (guid, level) VALUES ({}, {}) "
            "ON DUPLICATE KEY UPDATE level = GREATEST(level, VALUES(level))", guid.GetCounter(), level);
    }

    // Bonus share of the coins when the keystone holder finishes a level for the first time. The live server
    // gave such a bonus, but its formula could not be worked out from the screenshots (20, 149, 311 and 328
    // coins); this is an estimate by remaining time: under 40 % 10-40 %, 40-55 % 40-55 %, over 55 % 55-100 %.
    uint32 FirstTimeBonusPercent(float timeLeft)
    {
        if (timeLeft >= 0.55f)
            return urand(55, 100);
        if (timeLeft >= 0.40f)
            return urand(40, 55);
        return urand(10, 40);
    }

    // 50 Mythic Coins per keystone level, plus the first-time bonus, up to the weekly cap. Each expansion has its own
    // coin: Mythic Coin, Mythic Coin (TBC), Mythic Coin (WOTLK).
    void GiveCoins(Player* player, uint32 level, uint32 bonusPercent, uint32 expansion)
    {
        uint32 const coinItem = expansion >= 2 ? sConfigMgr->GetOption<uint32>("MythicPlus.CoinItem.WotLK", 1414530)
            : expansion == 1 ? sConfigMgr->GetOption<uint32>("MythicPlus.CoinItem.TBC", 1414529)
            : sConfigMgr->GetOption<uint32>("MythicPlus.CoinItem", 1414500);
        uint32 const perLevel = sConfigMgr->GetOption<uint32>("MythicPlus.CoinsPerLevel", 50);
        Weekly const weekly = GetWeekly(player->GetGUID());
        uint32 const cap = WeeklyCoinCap();
        uint32 const base = perLevel * level;
        uint32 const bonus = base * bonusPercent / 100;
        if (bonus)
            ChatHandler(player->GetSession()).PSendSysMessage("You have received {} Bonus Mythic Coins for first time "
                "completion, because the Keystone holder has unlocked a new highest Mythic Level for the first time.", bonus);
        uint32 const amount = std::min(base + bonus, cap > weekly.coins ? cap - weekly.coins : 0);
        if (amount)
        {
            Give(player, coinItem, amount);
            AddWeekly(player->GetGUID(), amount, 0);
        }
        ChatHandler(player->GetSession()).PSendSysMessage("You've obtained {} out of {} mythic coins.",
            weekly.coins + amount, cap);
    }


    // Item pools the caches and spoils draw from: the Mythic+ levels of the vanilla dungeon items (level 60 armor and
    // weapons whose description is @Mythic N@ and whose name and slot match a Mythic dungeon item, as the upgrade
    // chains pair them), and the Heroic and Mythic versions of the vanilla dungeon items. Other @Mythic N@ items are
    // raid, quest or placeholder items ("Ahn'Qiraj Wand [PH]") that no dungeon drops.
    std::map<uint32, std::vector<uint32>> g_mythicItems;
    std::vector<uint32> g_heroicItems;
    std::vector<uint32> g_mythicDungeonItems;

    void LoadItemPools()
    {
        g_mythicItems.clear();
        g_heroicItems.clear();
        g_mythicDungeonItems.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT MIN(p.entry), p.description FROM item_template p "
            "JOIN (SELECT DISTINCT i.name, i.InventoryType FROM coa_dungeon_loot_variant v JOIN item_template i ON i.entry = v.mythic_item) d "
            "ON d.name = p.name AND d.InventoryType = p.InventoryType "
            "WHERE p.description LIKE '@Mythic %@' AND p.RequiredLevel = 60 AND p.class IN (2, 4) AND p.Quality >= 3 "
            "GROUP BY p.name, p.InventoryType, p.description"))
            do
            {
                std::string const text = (*result)[1].Get<std::string>();
                uint32 const level = uint32(std::strtoul(text.c_str() + 8, nullptr, 10));
                if (level)
                    g_mythicItems[level].push_back((*result)[0].Get<uint32>());
            } while (result->NextRow());
        if (QueryResult result = WorldDatabase.Query("SELECT DISTINCT v.heroic_item, v.mythic_item FROM coa_dungeon_loot_variant v "
            "JOIN item_template h ON h.entry = v.heroic_item JOIN item_template m ON m.entry = v.mythic_item"))
            do
            {
                g_heroicItems.push_back((*result)[0].Get<uint32>());
                g_mythicDungeonItems.push_back((*result)[1].Get<uint32>());
            } while (result->NextRow());
        LOG_INFO("server.loading", ">> Mythic+: {} Mythic+ item levels, {} Heroic and {} Mythic dungeon items for caches and spoils",
            uint32(g_mythicItems.size()), uint32(g_heroicItems.size()), uint32(g_mythicDungeonItems.size()));
    }

    uint32 RandomOf(std::vector<uint32> const& pool)
    {
        return pool.empty() ? 0 : pool[urand(0, uint32(pool.size()) - 1)];
    }

    // A random item the player can wear, preferring the active specialization's
    // primary stats like Dungeon Spoils and Callboard Caches do.
    uint32 RandomForSpecialization(Player const* player, std::vector<uint32> const& pool)
    {
        std::vector<uint32> wearable;
        std::copy_if(pool.begin(), pool.end(), std::back_inserter(wearable), [player](uint32 entry)
        {
            ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry);
            return item && player->CanUseItem(item) == EQUIP_ERR_OK &&
                (!item->GetSkill() || player->GetSkillValue(item->GetSkill()));
        });
        return RandomOf(AscensionSpecLoot::PreferSpecialization(player, wearable.empty() ? pool : wearable,
            [](uint32 entry) { return sObjectMgr->GetItemTemplate(entry); }));
    }

    // ---------------------------------------------------------------- champions

    // Mythic Champions (80227 vanilla, 80228 TBC, 80229 WotLK): from MythicPlus.Champion.MinLevel (14 on the live
    // server) one walks every path set with .mythic setchampionpos, neutral until harmed.
    constexpr uint32 NPC_MYTHIC_CHAMPION = 80227;

    struct ChampionPath
    {
        Position a;
        Position b;
    };
    std::unordered_map<ObjectGuid, ChampionPath> g_championPaths;

    bool IsChampion(uint32 entry)
    {
        return entry >= NPC_MYTHIC_CHAMPION && entry < NPC_MYTHIC_CHAMPION + 3;
    }

    uint32 ChampionMinLevel()
    {
        return sConfigMgr->GetOption<uint32>("MythicPlus.Champion.MinLevel", 14);
    }

    // Champions a key from MinLevel on must kill to finish (MythicPlus.Champion.Required), shown by the tracker.
    uint32 ChampionsRequired()
    {
        return sConfigMgr->GetOption<bool>("MythicPlus.Champion.Required", true)
            ? sConfigMgr->GetOption<uint32>("MythicPlus.Champion.RequiredCount", 1) : 0;
    }

    // The median health of the elite trash in this instance, as scaled for the key.
    uint32 TrashHealth(Map* map)
    {
        std::vector<uint32> health;
        for (auto const& [spawnId, creature] : map->GetCreatureBySpawnIdStore())
        {
            uint32 clientId = 0;
            if (creature->IsAlive() && creature->isElite() && !creature->isWorldBoss() && TakesAffixes(creature)
                && !FindEncounter(creature, clientId))
                health.push_back(creature->GetMaxHealth());
        }
        if (health.empty())
            return 0;
        std::nth_element(health.begin(), health.begin() + health.size() / 2, health.end());
        return health[health.size() / 2];
    }

    uint32 SpawnChampions(Map* map, uint32 expansion, uint32 level)
    {
        QueryResult result = WorldDatabase.Query("SELECT a_x, a_y, a_z, a_o, b_x, b_y, b_z FROM coa_mythic_champion_path "
            "WHERE map = {}", map->GetId());
        if (!result)
            return 0;
        uint32 const trash = TrashHealth(map);
        float const factor = sConfigMgr->GetOption<float>("MythicPlus.Champion.HealthTrashFactor", 10.0f);
        uint32 count = 0;
        do
        {
            Field* f = result->Fetch();
            ChampionPath path { Position(f[0].Get<float>(), f[1].Get<float>(), f[2].Get<float>(), f[3].Get<float>()),
                Position(f[4].Get<float>(), f[5].Get<float>(), f[6].Get<float>()) };
            TempSummon* champion = map->SummonCreature(NPC_MYTHIC_CHAMPION + std::min<uint32>(expansion, 2), path.a);
            if (!champion)
                continue;
            g_championPaths[champion->GetGUID()] = path;
            champion->SetHomePosition(path.a);
            if (level)
                champion->SetLevel(level);
            if (trash && champion->GetCreateHealth())
                ScaleHealthBy(champion, trash * factor / champion->GetCreateHealth());
            ++count;
        } while (result->NextRow());
        LOG_INFO("module", "Mythic+: {} champions on map {} instance {} (trash health {}, x{:.1f})", count, map->GetId(),
            map->GetInstanceId(), trash, factor);
        return count;
    }

    // ---------------------------------------------------------------- run flow

    void Complete(Map* map, Run& run)
    {
        uint32 limit = run.dungeon.timeLimitMs;
        bool timed = run.elapsedMs <= limit;
        uint32 upgrade = 0;
        // As the live server announced it: at least 55 % of the time left
        // +3 (chests +200 %), at least 40 % +2 (+100 %), otherwise +1.
        if (timed)
        {
            float const left = limit ? float(limit - run.elapsedMs) / limit : 0.0f;
            upgrade = left >= 0.55f ? 3 : left >= 0.40f ? 2 : 1;
        }

        run.state = timed ? STATE_TIMED : STATE_OVERTIME;
        // Out of time: still one cache, but no coins.
        uint32 caches = timed ? upgrade : sConfigMgr->GetOption<uint32>("MythicPlus.OvertimeCaches", 1);
        uint32 newLevel = run.level + upgrade;
        float const timeLeft = limit && timed ? float(limit - run.elapsedMs) / limit : 0.0f;
        bool const firstTime = timed && run.level > GetBestLevel(run.owner);
        uint32 const bonusPercent = firstTime ? FirstTimeBonusPercent(timeLeft) : 0;
        if (timed)
            SetBestLevel(run.owner, run.level);

        LOG_INFO("module", "Mythic+: instance {} map {} +{} done in {} s of {} s, upgrade +{}",
            run.instanceId, run.mapId, run.level, run.elapsedMs / 1000, limit / 1000, upgrade);

        CoAResurrectDeadPlayers(map);
        for (auto const& [spawnId, creature] : map->GetCreatureBySpawnIdStore())
            if (creature->GetEntry() == 80215)
                creature->SetVisible(false);
        std::vector<Creature*> champions;
        for (auto const& [guid, path] : g_championPaths)
            if (Creature* champion = map->GetCreature(guid))
                champions.push_back(champion);
        for (Creature* champion : champions)
        {
            g_championPaths.erase(champion->GetGUID());
            if (champion->IsAlive())
                champion->DespawnOrUnsummon();
        }

        ForEachPlayer(map, [&](Player* player)
        {
            RemovePlayerAffixes(player, run);
            SendTimer(player, run);
            SendState(player, run, run.state);

            for (uint32 i = 0; i < caches; ++i)
                for (Reward const& r : g_rewards)
                    if (run.level >= r.levelMin && run.level <= r.levelMax)
                        Give(player, r.item, r.count);
            if (caches)
                Give(player, CacheForLevel(run.level), caches);
            if (timed)
                GiveCoins(player, run.level, bonusPercent, run.dungeon.expansion);

            if (player->GetGUID() == run.owner)
            {
                // The key went down one level at the start; replace it with
                // the new one, pointing at a random dungeon.
                uint32 depleted = Data::Instance().GetKeystoneItem(run.lfgId, std::max<uint32>(1, run.level - 1));
                uint32 next = RandomKeystone(newLevel);
                if (next)
                    ReplaceKeystone(player, depleted, next);
                ChatHandler(player->GetSession()).PSendSysMessage(timed
                    ? "Mythic+: keystone upgraded +{}, now level {}."
                    : "Mythic+: out of time, keystone stays at level {}.", timed ? upgrade : newLevel, newLevel);
            }
        });
    }

    void CheckComplete(Map* map, Run& run)
    {
        if (run.state != STATE_RUNNING)
            return;
        if (run.encounters.size() < run.dungeon.encountersRequired || !run.finalKilled)
            return;
        if (run.dungeon.forcesTotal && run.forces < run.dungeon.forcesTotal)
            return;
        if (run.champions < run.championsRequired)
            return;
        Complete(map, run);
    }

    // Returns an error for the player, or nullptr when the run started.
    char const* TryStart(Player* player, std::string& detail)
    {
        Map* map = player->GetMap();
        auto socketed = g_socketed.find(player->GetGUID());
        if (socketed == g_socketed.end() || !player->HasItemCount(socketed->second, 1, true))
            return "Use your keystone first.";
        uint32 item = socketed->second;

        Keystone const* key = nullptr;
        TimedDungeon const* dungeon = nullptr;
        if (char const* error = CheckKeystone(player, item, key, dungeon, detail))
            return error;

        char const* error = nullptr;
        map->DoForAllPlayers([&error](Player* p)
        {
            if (p->IsInCombat())
                error = "Somebody is in combat.";
        });
        if (error)
            return error;
        g_socketed.erase(socketed);

        Run& run = g_runs[map->GetInstanceId()];
        run = Run {};
        run.instanceId = map->GetInstanceId();
        run.mapId = map->GetId();
        run.keystoneItem = item;
        run.lfgId = key->lfgId;
        run.level = key->level;
        run.owner = player->GetGUID();
        run.dungeon = *dungeon;
        run.scaling = Data::Instance().GetScaling(key->level);
        run.rotation = CurrentRotation();
        run.affixes = Data::Instance().GetAffixes(run.rotation, key->level);
        run.state = STATE_COUNTDOWN;
        run.countdownMs = COUNTDOWN_MS;
        ScaleForces(map->GetId(), uint32(map->GetDifficulty()), run);

        // The key loses a level now and gets its real new level at the end.
        ReplaceKeystone(player, item, Data::Instance().GetKeystoneItem(run.lfgId, std::max<uint32>(1, run.level - 1)));

        for (auto const& [spawnId, creature] : map->GetCreatureBySpawnIdStore())
        {
            ScaleHealth(creature, run.scaling);
            ApplyCreatureAffixes(creature, run);
            if (creature->GetEntry() == 80215)
                creature->SetVisible(true);
        }

        if (run.level >= ChampionMinLevel())
        {
            LFGDungeonEntry const* lfg = sLFGDungeonStore.LookupEntry(run.lfgId);
            run.championsPlaced = SpawnChampions(map, run.dungeon.expansion, lfg ? lfg->MaxLevel + 2 : 0);
            run.championsRequired = std::min(ChampionsRequired(), run.championsPlaced);
        }

        // Start at the wing's Dungeon Finder point; the map entrance would put
        // a Scarlet Monastery group into the wrong wing.
        lfg::LFGDungeonData const* start = sLFGMgr->GetLFGDungeon(run.lfgId);
        AreaTriggerTeleport const* entrance = sObjectMgr->GetMapEntranceTrigger(map->GetId());
        std::string const affixText = AffixNames(run.affixes);
        // A player who dies during the key is revived here too (AscensionDungeonRelease).
        std::optional<Position> wingStart;
        if (start && (start->x || start->y || start->z))
            wingStart = Position(start->x, start->y, start->z, start->o);
        else if (entrance && entrance->target_mapId == map->GetId())
            wingStart = Position(entrance->target_X, entrance->target_Y, entrance->target_Z, entrance->target_Orientation);
        if (wingStart)
            CoASetDungeonReleaseStart(map, *wingStart);
        ForEachPlayer(map, [&](Player* p)
        {
            SendWindow(p, false);
            if (wingStart)
                p->NearTeleportTo(wingStart->GetPositionX(), wingStart->GetPositionY(), wingStart->GetPositionZ(),
                    wingStart->GetOrientation());
            ApplyPlayerAffixes(p, run);
            p->SetControlled(true, UNIT_STATE_ROOT);
            SendInstanceInfo(p, run.instanceId);
            SendState(p, run, STATE_COUNTDOWN);
            SendProgress(p, run);
            SendTimer(p, run);
            ChatHandler(p->GetSession()).PSendSysMessage("Mythic+ {} +{}: affixes {}.", DungeonName(run.lfgId), run.level, affixText);
        });

        LOG_INFO("module", "Mythic+: {} started +{} (lfg {}) in instance {} map {}, week {}, affixes {}",
            player->GetName(), run.level, run.lfgId, run.instanceId, run.mapId, run.rotation, affixText);
        return nullptr;
    }

    bool HandleActivate(WorldSession* session, WorldPacket const& /*packet*/)
    {
        Player* player = session->GetPlayer();
        if (!player || !Enabled())
            return true;
        LOG_INFO("module", "Mythic+: {} pressed Start Keystone (CMSG 0x0527) on map {}", player->GetName(), player->GetMapId());

        std::lock_guard<std::recursive_mutex> guard(g_lock);
        std::string detail;
        if (char const* error = TryStart(player, detail))
            ChatHandler(session).PSendSysMessage("Mythic+: {}{}{}", error, detail.empty() ? "" : " ", detail);
        return true;
    }

    void LoadTables()
    {
        g_forces.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT entry, forces FROM coa_mythic_forces"))
            do
                g_forces[result->Fetch()[0].Get<uint32>()] = result->Fetch()[1].Get<uint32>();
            while (result->NextRow());

        g_rewards.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT level_min, level_max, item, count FROM coa_mythic_reward"))
            do
            {
                Field* f = result->Fetch();
                g_rewards.push_back({ f[0].Get<uint32>(), f[1].Get<uint32>(), f[2].Get<uint32>(), f[3].Get<uint32>() });
            } while (result->NextRow());

        LOG_INFO("server.loading", ">> Mythic+: {} enemy forces values, {} cache rows",
            uint32(g_forces.size()), uint32(g_rewards.size()));
    }
}

// A creature that evades drops its auras, and with them the affixes. The live
// server keeps them on after a wipe, so every affix spell (and Avenger's tiers)
// ignores evade.
static void KeepAffixesThroughEvade()
{
    std::set<uint32> spells(AVENGER_BY_EXPANSION.begin(), AVENGER_BY_EXPANSION.end());
    for (uint32 rotation = 0; rotation < 53; ++rotation)
        for (uint32 level = 2; level <= 254; ++level)
            for (uint32 affix : Data::Instance().GetAffixes(rotation, level))
                spells.insert(affix);
    uint32 count = 0;
    for (uint32 id : spells)
        if (SpellInfo const* info = sSpellMgr->GetSpellInfo(id))
        {
            const_cast<SpellInfo*>(info)->AttributesCu |= SPELL_ATTR0_CU_IGNORE_EVADE;
            ++count;
        }
    LOG_INFO("server.loading", ">> Mythic+: {} affix spells kept through evade", count);
}

class coa_mythic_plus_world : public WorldScript
{
public:
    coa_mythic_plus_world() : WorldScript("coa_mythic_plus_world", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        Data::Instance().Load();
        LoadTables();
        LoadItemPools();
        CharacterDatabase.DirectExecute("CREATE TABLE IF NOT EXISTS coa_mythic_weekly (guid INT UNSIGNED NOT NULL, "
            "week INT UNSIGNED NOT NULL, coins INT UNSIGNED NOT NULL DEFAULT 0, caches INT UNSIGNED NOT NULL DEFAULT 0, "
            "PRIMARY KEY (guid, week))");
        CharacterDatabase.DirectExecute("CREATE TABLE IF NOT EXISTS coa_mythic_best (guid INT UNSIGNED NOT NULL PRIMARY KEY, "
            "level INT UNSIGNED NOT NULL DEFAULT 0)");
        WorldDatabase.DirectExecute("CREATE TABLE IF NOT EXISTS coa_mythic_champion_path (id INT UNSIGNED NOT NULL AUTO_INCREMENT, "
            "map SMALLINT UNSIGNED NOT NULL, a_x FLOAT NOT NULL, a_y FLOAT NOT NULL, a_z FLOAT NOT NULL, a_o FLOAT NOT NULL DEFAULT 0, "
            "b_x FLOAT NOT NULL, b_y FLOAT NOT NULL, b_z FLOAT NOT NULL, comment VARCHAR(255) NOT NULL DEFAULT '', "
            "PRIMARY KEY (id), KEY map (map))");
        KeepAffixesThroughEvade();
        AscensionCompatOpcodes::Claim(CMSG_CUSTOM_MYTHIC_PLUS_ACTIVATE, &HandleActivate);
    }
};

class coa_mythic_plus_map : public AllMapScript
{
public:
    coa_mythic_plus_map() : AllMapScript("coa_mythic_plus_map",
        { ALLMAPHOOK_ON_PLAYER_ENTER_ALL, ALLMAPHOOK_ON_PLAYER_LEAVE_ALL, ALLMAPHOOK_ON_MAP_UPDATE, ALLMAPHOOK_ON_DESTROY_INSTANCE }) { }

    void OnPlayerEnterAll(Map* map, Player* player) override
    {
        if (!Enabled())
            return;
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        Run* run = map->IsDungeon() && !map->IsRaid() ? RunFor(map) : nullptr;
        if (!run || run->state == STATE_INACTIVE)
        {
            // The client keeps the last run as active while its run id equals the
            // instance id it knows, and its tracker comes back with that old run
            // on the next loading screen. The new instance id ends that run.
            SendInstanceInfo(player, map->GetInstanceId());
            return;
        }
        SendFullRun(player, *run);
        if (run->Active())
            ApplyPlayerAffixes(player, *run);
        if (run->state == STATE_COUNTDOWN)
            player->SetControlled(true, UNIT_STATE_ROOT);
    }

    void OnPlayerLeaveAll(Map* map, Player* player) override
    {
        if (!map->IsDungeon())
            return;
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        g_socketed.erase(player->GetGUID());
        if (Run* run = RunFor(map))
        {
            if (run->state == STATE_COUNTDOWN)
                player->SetControlled(false, UNIT_STATE_ROOT);
            RemovePlayerAffixes(player, *run);
            SendState(player, *run, STATE_INACTIVE);
        }
    }

    void OnMapUpdate(Map* map, uint32 diff) override
    {
        if (!map->IsDungeon())
            return;
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        Run* run = RunFor(map);
        if (!run || !run->Active())
            return;

        if (run->state == STATE_COUNTDOWN)
        {
            if (run->countdownMs > diff)
            {
                run->countdownMs -= diff;
                return;
            }
            run->state = STATE_RUNNING;
            ForEachPlayer(map, [run](Player* p)
            {
                p->SetControlled(false, UNIT_STATE_ROOT);
                SendState(p, *run, STATE_RUNNING);
                SendTimer(p, *run);
            });
            return;
        }

        run->elapsedMs += diff;
        run->timerPacketMs += diff;
        if (run->timerPacketMs >= TIMER_PACKET_MS)
        {
            run->timerPacketMs = 0;
            ForEachPlayer(map, [run](Player* p) { SendTimer(p, *run); });
        }
    }

    void OnDestroyInstance(MapInstanced* /*mapInstanced*/, Map* map) override
    {
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        g_runs.erase(map->GetInstanceId());    }
};

// Death takes the player affixes; a resurrection inside a running key brings them back.
class coa_mythic_plus_player : public PlayerScript
{
public:
    coa_mythic_plus_player() : PlayerScript("coa_mythic_plus_player", { PLAYERHOOK_ON_PLAYER_RESURRECT, PLAYERHOOK_ON_LOGIN }) { }

    // What Ascension's server told the client and this one would not otherwise: the strings for Mythic its
    // GlobalStrings lack, the champion count per dungeon, and the affix rows this realm changed
    // (MythicPlus.DisabledAffixes), for this week and the next. The Dungeon Finder unlocks come from
    // AscensionDifficultyRelease.
    void OnPlayerLogin(Player* player) override
    {
        for (auto const& [id, key, text] : CLIENT_STRINGS)
        {
            WorldPacket data(SMSG_PATCH_GLOBAL_STRINGS, 32 + std::strlen(key) + std::strlen(text));
            data << uint32(id) << uint32(GLOBAL_STRING_IN_GAME | GLOBAL_STRING_AT_LOGIN) << uint32(0) << uint32(0);
            data << key << text;
            player->SendDirectMessage(&data);
        }
        // TimedDungeons.dbc has no champions anywhere; the tracker shows "Defeat Champions" from +14 with this count.
        for (auto const& [lfgId, dungeon] : Data::Instance().Dungeons())
        {
            WorldPacket data(SMSG_PATCH_TIMED_DUNGEON, 24);
            data << uint32(dungeon.lfgId) << uint32(dungeon.forcesTotal) << uint32(dungeon.encountersRequired)
                 << uint32(ChampionsRequired()) << uint32(dungeon.timeLimitMs) << float(dungeon.rewardMultiplier);
            player->SendDirectMessage(&data);
        }
        uint32 const week = CurrentRotation();
        for (std::array<uint32, 16> const& row : Data::Instance().SwappedAffixRows())
        {
            if (row[1] != week && row[1] != (week + 1) % 53)
                continue;
            WorldPacket data(SMSG_PATCH_MYTHIC_AFFIXES, sizeof(row));
            for (uint32 field : row)
                data << field;
            player->SendDirectMessage(&data);
        }
    }

    void OnPlayerResurrect(Player* player, float /*restorePercent*/, bool& /*applySickness*/) override
    {
        Map* map = player->FindMap();
        if (!map || !map->IsDungeon())
            return;
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        if (Run* run = RunFor(map); run && run->Active())
            ApplyPlayerAffixes(player, *run);
    }
};

class coa_mythic_plus_creature : public AllCreatureScript
{
public:
    coa_mythic_plus_creature() : AllCreatureScript("coa_mythic_plus_creature") { }

    // Respawns and new spawns go through SelectLevel, which resets health;
    // scale them again here.
    void OnCreatureSelectLevel(CreatureTemplate const* /*cinfo*/, Creature* creature) override
    {
        Map* map = creature->FindMap();
        if (!map || !map->IsDungeon())
            return;
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        if (Run* run = RunFor(map); run && run->Scaled())
        {
            ScaleHealth(creature, run->scaling);
            if (run->Active())
                ApplyCreatureAffixes(creature, *run);
        }
    }

    // Summons and creatures spawned during a run get the week's affixes too.
    void OnCreatureAddWorld(Creature* creature) override
    {
        Map* map = creature->FindMap();
        if (!map || !map->IsDungeon())
            return;
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        Run* run = RunFor(map);
        // Mythical Boons (80215) exist only for a keystone.
        if (creature->GetEntry() == 80215)
            creature->SetVisible(run && run->Active());
        if (run && run->Active())
            ApplyCreatureAffixes(creature, *run);
    }
};

class coa_mythic_plus_unit : public UnitScript
{
public:
    coa_mythic_plus_unit() : UnitScript("coa_mythic_plus_unit", true,
        { UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_ON_UNIT_DEATH }) { }

    void ModifyMeleeDamage(Unit* /*target*/, Unit* attacker, uint32& damage) override
    {
        if (float f = Factor(attacker, true); f != 1.0f)
            damage = uint32(damage * f);
    }

    void ModifySpellDamageTaken(Unit* /*target*/, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (IsHealthShare(spellInfo))
            return;
        if (float f = Factor(attacker, IsPhysical(spellInfo)); f != 1.0f)
            damage = int32(damage * f);
    }

    void ModifyPeriodicDamageAurasTick(Unit* /*target*/, Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (float f = Factor(attacker, IsPhysical(spellInfo)); f != 1.0f)
            damage = uint32(damage * f);
    }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Creature* creature = unit->ToCreature();
        if (!creature || !Enabled())
            return;
        Map* map = creature->GetMap();
        if (!map->IsDungeon() || map->IsRaid())
            return;

        std::lock_guard<std::recursive_mutex> guard(g_lock);
        Run* run = RunFor(map);
        uint32 clientId = 0;
        DungeonEncounter const* encounter = FindEncounter(creature, clientId);

        if (!run || !run->Scaled())
        {
            FirstKey(map, encounter);
            return;
        }
        if (run->state != STATE_RUNNING)
            return;

        if (sConfigMgr->GetOption<bool>("MythicPlus.NoCreatureLoot", true))
        {
            creature->loot.clear();
            creature->RemoveDynamicFlag(UNIT_DYNFLAG_LOOTABLE);
        }

        if (IsChampion(creature->GetEntry()))
            ++run->champions;
        else if (WingEncounter const* boss = FindWingEncounter(*run, creature))
        {
            run->encounters.insert(boss->id);
            if (boss->final)
                run->finalKilled = true;
        }
        else if (!encounter)
        {
            run->forcesExact += ForcesFor(creature) * run->forcesScale;
            run->forces = uint32(run->forcesExact + 0.0001);
        }

        ForEachPlayer(map, [run](Player* p) { SendProgress(p, *run); });
        CheckComplete(map, *run);
    }

private:
    static bool IsPhysical(SpellInfo const* spellInfo)
    {
        return !spellInfo || (spellInfo->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL);
    }

    // Ascension effect 174 with MiscValue other than 1 deals a share of the
    // target's maximum health (Life Steal: 2 %); that share must not grow with
    // the key level. MiscValue 1 is a share of the caster's melee damage and
    // scales like melee.
    static bool IsHealthShare(SpellInfo const* spellInfo)
    {
        if (!spellInfo)
            return false;
        for (SpellEffectInfo const& effect : spellInfo->Effects)
            if (effect.Effect == 174 && effect.MiscValue != 1)
                return true;
        return false;
    }

    // Damage done BY the dungeon's creatures during a run.
    static float Factor(Unit* attacker, bool physical)
    {
        if (!attacker || attacker->IsControlledByPlayer() || attacker->GetTypeId() != TYPEID_UNIT)
            return 1.0f;
        Map* map = attacker->GetMap();
        if (!map || !map->IsDungeon())
            return 1.0f;
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        Run* run = RunFor(map);
        if (!run || !run->Scaled())
            return 1.0f;
        return physical ? run->scaling.physical : run->scaling.magic;
    }

    // The final boss of a Mythic dungeon gives a +1 key to those without one.
    static void FirstKey(Map* map, DungeonEncounter const* encounter)
    {
        if (!encounter || !encounter->lastEncounterDungeon)
            return;
        if (!sConfigMgr->GetOption<bool>("MythicPlus.FirstKey.Enable", true))
        {
            LOG_INFO("module", "Mythic+ first key: map {} final boss down, first keys are disabled", map->GetId());
            return;
        }
        int32 const wanted = sConfigMgr->GetOption<int32>("MythicPlus.FirstKey.Difficulty", 2);
        if (int32(map->GetDifficulty()) != wanted)
        {
            LOG_INFO("module", "Mythic+ first key: map {} final boss down on difficulty {}, keys only on {}",
                map->GetId(), int32(map->GetDifficulty()), wanted);
            return;
        }

        uint32 const mapId = map->GetId();
        ForEachPlayer(map, [mapId](Player* p)
        {
            if (HasAnyKeystone(p))
            {
                LOG_INFO("module", "Mythic+ first key: map {}: {} already carries a keystone", mapId, p->GetName());
                return;
            }
            uint32 const item = RandomKeystone(1);
            if (!item)
            {
                LOG_ERROR("module", "Mythic+ first key: map {}: no +1 keystone in the key pool for {}", mapId, p->GetName());
                return;
            }
            Give(p, item, 1);
            LOG_INFO("module", "Mythic+ first key: map {}: {} received keystone {}", mapId, p->GetName(), item);
            ChatHandler(p->GetSession()).SendSysMessage("Mythic+: you received a Mythic Keystone.");
        });
    }
};

// Mechanics check: every spell a boss of a vanilla dungeon casts on Heroic or Mythic is written once per
// instance to Server.log ("BOSSCAST ..."), boss deaths as "BOSSKILL ...". mechanik_abgleich.py compares
// these lines with the boss kits of the Exiles export after the dungeons have been played through.
class coa_mythic_plus_boss_casts : public AllSpellScript
{
public:
    coa_mythic_plus_boss_casts() : AllSpellScript("coa_mythic_plus_boss_casts", { ALLSPELLHOOK_ON_CAST }) { }

    static bool Recorded(Creature const* creature)
    {
        if (!creature || creature->IsPet() || !sConfigMgr->GetOption<bool>("MythicPlus.BossCastLog", true))
            return false;
        Map const* map = creature->GetMap();
        if (!map || !map->IsNonRaidDungeon() || map->GetSpawnMode() < 1 || map->GetSpawnMode() > 2)
            return false;
        CreatureTemplate const* info = creature->GetCreatureTemplate();
        return creature->IsDungeonBoss() || (info && info->rank == CREATURE_ELITE_WORLDBOSS);
    }

    void OnSpellCast(Spell* /*spell*/, Unit* caster, SpellInfo const* spellInfo, bool /*skipCheck*/) override
    {
        Creature* creature = caster ? caster->ToCreature() : nullptr;
        if (!spellInfo || !Recorded(creature))
            return;
        Map const* map = creature->GetMap();
        {
            static std::mutex lock;
            static std::set<std::tuple<uint32, uint32, uint32>> seen;
            std::lock_guard<std::mutex> guard(lock);
            if (!seen.emplace(map->GetInstanceId(), creature->GetEntry(), spellInfo->Id).second)
                return;
        }
        LOG_INFO("module", "BOSSCAST map={} mode={} instance={} entry={} boss=\"{}\" spell={} name=\"{}\"",
            map->GetId(), uint32(map->GetSpawnMode()), map->GetInstanceId(), creature->GetEntry(),
            creature->GetName(), spellInfo->Id, spellInfo->SpellName[0] ? spellInfo->SpellName[0] : "");
    }
};

// Using a keystone casts "Activate Keystone" (161). The client does not open the socket by itself; the
// server opens it only when this very key can be started here: its dungeon (any wing), Mythic difficulty,
// the group leader, no run and no dead boss in the instance yet.
class coa_mythic_plus_keystone_use : public AllSpellScript
{
public:
    coa_mythic_plus_keystone_use() : AllSpellScript("coa_mythic_plus_keystone_use", { ALLSPELLHOOK_ON_CAST }) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* spellInfo, bool /*skipCheck*/) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || !spellInfo || spellInfo->Id != SPELL_ACTIVATE_KEYSTONE || !Enabled())
            return;
        uint32 item = spell && spell->m_CastItem ? spell->m_CastItem->GetEntry() : 0;
        if (!item)
            return;

        std::lock_guard<std::recursive_mutex> guard(g_lock);
        Keystone const* key = nullptr;
        TimedDungeon const* dungeon = nullptr;
        std::string detail;
        if (char const* error = CheckKeystone(player, item, key, dungeon, detail))
        {
            g_socketed.erase(player->GetGUID());
            ChatHandler(player->GetSession()).PSendSysMessage("Mythic+: {}{}{}", error, detail.empty() ? "" : " ", detail);
            LOG_INFO("module", "Mythic+: {} used keystone {} on map {}: {} {}", player->GetName(), item,
                player->GetMapId(), error, detail);
            return;
        }
        g_socketed[player->GetGUID()] = item;
        SendWindow(player, true);
    }
};

class coa_mythic_plus_boss_kills : public UnitScript
{
public:
    coa_mythic_plus_boss_kills() : UnitScript("coa_mythic_plus_boss_kills", true, { UNITHOOK_ON_UNIT_DEATH }) { }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Creature* creature = unit ? unit->ToCreature() : nullptr;
        if (!coa_mythic_plus_boss_casts::Recorded(creature))
            return;
        Map const* map = creature->GetMap();
        LOG_INFO("module", "BOSSKILL map={} mode={} instance={} entry={} boss=\"{}\"",
            map->GetId(), uint32(map->GetSpawnMode()), map->GetInstanceId(), creature->GetEntry(), creature->GetName());
    }
};

// Mythical Cache (Mythic 1-12): one random Mythic+ item of that level from any
// dungeon, favouring the opener's specialization, at most
// MythicPlus.Caches.WeeklyCap opened per week. Dungeon Spoils
// (Heroic/Mythic): one or two random Heroic/Mythic dungeon items.
class coa_mythic_plus_cache : public ItemScript
{
public:
    coa_mythic_plus_cache() : ItemScript("item_coa_mythic_cache") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        uint32 const entry = item->GetEntry();
        std::vector<uint32> rewards;
        bool const spoils = entry == ITEM_SPOILS_HEROIC || entry == ITEM_SPOILS_MYTHIC;
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        if (spoils)
        {
            std::vector<uint32> const& pool = entry == ITEM_SPOILS_HEROIC ? g_heroicItems : g_mythicDungeonItems;
            for (uint32 i = urand(1, 2); i; --i)
                rewards.push_back(RandomOf(pool));
        }
        else
        {
            auto itr = std::find(MYTHICAL_CACHES.begin(), MYTHICAL_CACHES.end(), entry);
            if (itr == MYTHICAL_CACHES.end())
                return false;
            Weekly const weekly = GetWeekly(player->GetGUID());
            if (weekly.caches >= WeeklyCacheCap())
            {
                ChatHandler(player->GetSession()).PSendSysMessage("You have opened {} of {} Mythical Caches this week.",
                    weekly.caches, WeeklyCacheCap());
                return true;
            }
            rewards.push_back(RandomForSpecialization(player, g_mythicItems[uint32(itr - MYTHICAL_CACHES.begin()) + 1]));
        }

        std::erase(rewards, 0u);
        if (rewards.empty())
        {
            ChatHandler(player->GetSession()).SendSysMessage("The cache is empty.");
            return true;
        }
        for (uint32 reward : rewards)
        {
            ItemPosCountVec dest;
            if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, reward, 1) != EQUIP_ERR_OK)
            {
                player->SendEquipError(EQUIP_ERR_INVENTORY_FULL, item, nullptr);
                return true;
            }
        }

        uint32 one = 1;
        player->DestroyItemCount(item, one, true);
        for (uint32 reward : rewards)
            Give(player, reward, 1);
        if (!spoils)
        {
            AddWeekly(player->GetGUID(), 0, 1);
            ChatHandler(player->GetSession()).PSendSysMessage("Mythical Caches opened this week: {} / {}.",
                GetWeekly(player->GetGUID()).caches, WeeklyCacheCap());
        }
        return true;
    }
};

// Finishing a vanilla dungeon on Heroic outside a random Dungeon Finder run gives
// Dungeon Spoils (Heroic). Random runs get theirs from the reward quest; the
// final boss Mark of Triumph comes from CoADungeonSpoils in the core.
class coa_mythic_plus_spoils : public GlobalScript
{
public:
    coa_mythic_plus_spoils() : GlobalScript("coa_mythic_plus_spoils", { GLOBALHOOK_ON_AFTER_UPDATE_ENCOUNTER_STATE }) { }

    void OnAfterUpdateEncounterState(Map* map, EncounterCreditType /*type*/, uint32 /*creditEntry*/, Unit* /*source*/,
        Difficulty /*difficulty*/, std::list<DungeonEncounter const*> const* /*encounters*/, uint32 dungeonCompleted,
        bool /*updated*/) override
    {
        if (!dungeonCompleted || !map || !map->IsNonRaidDungeon() || !DungeonHealth::IsVanillaDungeon(map->GetId()))
            return;
        uint32 const difficulty = uint32(map->GetDifficulty());
        if (difficulty != 1 && difficulty != 2)
            return;
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        if (Run* run = RunFor(map); run && run->Scaled())
            return;
        // Random Classic Dungeon Heroic/Mythic runs get the spoils from their
        // Dungeon Finder reward quest; Mythic spoils come only from there.
        ForEachPlayer(map, [&](Player* player)
        {
            if (difficulty == 2 || sLFGMgr->selectedRandomLfgDungeon(player->GetGUID()))
                return;
            Give(player, ITEM_SPOILS_HEROIC, 1);
        });
        LOG_INFO("module", "Dungeon spoils: map {} difficulty {} instance {} completed (dungeon {})", map->GetId(),
            difficulty, map->GetInstanceId(), dungeonCompleted);
    }
};

// ---------------------------------------------------------------- vendors

namespace
{
    constexpr uint32 NPC_EDRIM = 416000;
    constexpr uint32 EDRIM_VENDOR_BASE = 9416000;     // + slot group, see rev_20261006_40_mythic_vendors_local.sql
    constexpr uint32 MARK_VENDOR = 9414500;           // Mark of Triumph items; + slot group: Heroic Dungeon items
    constexpr uint32 TEXT_EDRIM = 9416000;
    constexpr uint32 TEXT_MARKUS = 9414500;
    constexpr uint32 RANDOMIZE_COST = 10 * GOLD;

    char const* const SLOT_NAMES[17] = { "", "Head", "Neck", "Shoulders", "Back", "Chest", "Wrists", "Main Hand",
        "Two-Hand", "Off Hand", "Ranged", "Gloves", "Belt", "Pants", "Boots", "Rings", "Trinkets" };
    char const* const SLOT_ICONS[17] = { "", "INV_Helmet_03", "INV_Jewelry_Necklace_07", "INV_Shoulder_02", "INV_Misc_Cape_02",
        "INV_Chest_Chain_05", "INV_Bracer_07", "INV_Sword_04", "INV_Axe_09", "INV_Shield_06", "INV_Weapon_Bow_07",
        "INV_Gauntlets_04", "INV_Belt_03", "INV_Pants_03", "INV_Boots_05", "INV_Jewelry_Ring_03", "INV_Jewelry_Talisman_07" };

    // Ascension menus paint their own icon into the option text, hanging over the row's left edge (as the Destiny
    // Weaver menus do): |TInterface/ICONS/<icon>:<size>:<size>:<shift>:0|t|r<label>.
    std::string Opt(char const* icon, std::string const& label, uint32 size = 40)
    {
        return Acore::StringFormat("|TInterface/ICONS/{}:{}:{}:-{}:0|t|r{}", icon, size, size, size / 2 + 2, label);
    }

    std::string ItemOpt(ItemTemplate const* proto, std::string const& label)
    {
        ItemDisplayInfoEntry const* display = sItemDisplayInfoStore.LookupEntry(proto->DisplayInfoID);
        return Opt(display && display->inventoryIcon && *display->inventoryIcon ? display->inventoryIcon : "INV_Misc_QuestionMark", label);
    }

    // Upgrade chains: index 0 is the Mythic Dungeon item as the bosses drop it, 1-40 its Mythic N versions
    // (same name and slot, description @Mythic N@).
    std::vector<std::vector<uint32>> g_chains;
    std::unordered_map<uint32, std::pair<uint32, uint32>> g_chainOf;   // item -> chain, level

    void LoadUpgradeChains()
    {
        g_chains.clear();
        g_chainOf.clear();
        std::unordered_map<std::string, uint32> byKey;
        if (QueryResult result = WorldDatabase.Query("SELECT DISTINCT i.entry, i.name, i.InventoryType FROM coa_dungeon_loot_variant v "
            "JOIN item_template i ON i.entry = v.mythic_item ORDER BY i.entry"))
            do
            {
                std::string const key = (*result)[1].Get<std::string>() + "|" + std::to_string((*result)[2].Get<uint32>());
                if (byKey.count(key))
                    continue;
                byKey[key] = uint32(g_chains.size());
                g_chainOf[(*result)[0].Get<uint32>()] = { uint32(g_chains.size()), 0 };
                g_chains.push_back({ (*result)[0].Get<uint32>() });
            } while (result->NextRow());
        if (QueryResult result = WorldDatabase.Query("SELECT entry, name, InventoryType, description FROM item_template "
            "WHERE RequiredLevel = 60 AND class IN (2, 4) AND description LIKE '@Mythic %@' ORDER BY entry"))
            do
            {
                std::string const text = (*result)[3].Get<std::string>();
                uint32 const level = uint32(std::strtoul(text.c_str() + 8, nullptr, 10));
                auto chain = byKey.find((*result)[1].Get<std::string>() + "|" + std::to_string((*result)[2].Get<uint32>()));
                if (!level || chain == byKey.end())
                    continue;
                std::vector<uint32>& levels = g_chains[chain->second];
                if (levels.size() <= level)
                    levels.resize(level + 1, 0);
                if (levels[level])
                    continue;
                levels[level] = (*result)[0].Get<uint32>();
                g_chainOf[levels[level]] = { chain->second, level };
            } while (result->NextRow());
        LOG_INFO("server.loading", ">> Mythic+: {} item upgrade chains", uint32(g_chains.size()));
    }

    // Coins to bring an item to this level. Ascension's prices are not known; testers recall about 1346 coins
    // from Mythic 1 to 8, getting dearer per level: 129 x 1.1^(level - 1), in steps of 5 (1 to 8: 1345).
    uint32 UpgradeCost(uint32 level)
    {
        return uint32(std::lround(129.0 * std::pow(1.1, double(level) - 1.0) / 5.0)) * 5;
    }

    uint32 RecycleValue(uint32 level)
    {
        return 45 + level;
    }

    std::string LevelName(uint32 level)
    {
        return level ? Acore::StringFormat("Mythic {}", level) : "Mythic Dungeon";
    }

    uint32 NextLevelItem(uint32 entry, uint32& nextLevel)
    {
        auto itr = g_chainOf.find(entry);
        if (itr == g_chainOf.end())
            return 0;
        std::vector<uint32> const& levels = g_chains[itr->second.first];
        nextLevel = itr->second.second + 1;
        return nextLevel < levels.size() ? levels[nextLevel] : 0;
    }

    template<class F>
    void ForEachOwnedItem(Player* player, bool equipped, F&& f)
    {
        if (equipped)
            for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
                if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                    f(item);
        for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
            if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                f(item);
        for (uint8 bag = INVENTORY_SLOT_BAG_START; bag < INVENTORY_SLOT_BAG_END; ++bag)
            if (Bag* container = player->GetBagByPos(bag))
                for (uint32 slot = 0; slot < container->GetBagSize(); ++slot)
                    if (Item* item = container->GetItemByPos(slot))
                        f(item);
    }

    uint32 HighestOwnedLevel(Player* player)
    {
        uint32 highest = 0;
        ForEachOwnedItem(player, true, [&highest](Item* item)
        {
            auto itr = g_chainOf.find(item->GetEntry());
            if (itr != g_chainOf.end())
                highest = std::max(highest, itr->second.second);
        });
        return highest;
    }

    Item* FindOwnedItem(Player* player, uint32 lowGuid)
    {
        return player->GetItemByGuid(ObjectGuid::Create<HighGuid::Item>(lowGuid));
    }

    // Swaps the item for its next version in the same place.
    void ReplaceItem(Player* player, Item* item, uint32 newEntry)
    {
        uint8 const bag = item->GetBagSlot();
        uint8 const slot = item->GetSlot();
        bool const equipped = item->IsEquipped();
        player->DestroyItem(bag, slot, true);
        if (equipped)
        {
            player->EquipNewItem(slot, newEntry, true);
            return;
        }
        ItemPosCountVec dest;
        if (player->CanStoreNewItem(bag, slot, dest, newEntry, 1) == EQUIP_ERR_OK)
            player->StoreNewItem(dest, newEntry, true);
        else
            Give(player, newEntry, 1);
    }

    bool PayCoins(Player* player, uint32 coins)
    {
        uint32 const coinItem = sConfigMgr->GetOption<uint32>("MythicPlus.CoinItem", 1414500);
        if (!player->HasItemCount(coinItem, coins))
        {
            ChatHandler(player->GetSession()).PSendSysMessage("You need {} Mythic Coins.", coins);
            return false;
        }
        player->DestroyItemCount(coinItem, coins, true);
        return true;
    }

    // Recycling gives 45 + level coins and counts towards the weekly coin cap.
    bool Recycle(Player* player, Item* item)
    {
        auto itr = g_chainOf.find(item->GetEntry());
        if (itr == g_chainOf.end())
            return false;
        uint32 const value = RecycleValue(itr->second.second);
        Weekly const weekly = GetWeekly(player->GetGUID());
        if (weekly.coins + value > WeeklyCoinCap())
        {
            ChatHandler(player->GetSession()).PSendSysMessage("You have reached the weekly cap of {} Mythic Coins.", WeeklyCoinCap());
            return false;
        }
        player->DestroyItem(item->GetBagSlot(), item->GetSlot(), true);
        Give(player, sConfigMgr->GetOption<uint32>("MythicPlus.CoinItem", 1414500), value);
        AddWeekly(player->GetGUID(), value, 0);
        return true;
    }

    uint32 CarriedKeystone(Player* player)
    {
        std::vector<uint32> keys = CarriedKeystones(player);
        return keys.empty() ? 0 : keys.front();
    }
}

class npc_coa_mythic_items : public CreatureScript
{
public:
    npc_coa_mythic_items() : CreatureScript("npc_coa_mythic_items") { }

    enum Menu : uint32
    {
        MENU_MAIN = 1,
        MENU_PURCHASE,
        MENU_UPGRADE,
        MENU_UPGRADE_ALL,
        MENU_RANDOMIZE,
        MENU_DOWNGRADE,
        MENU_RECYCLE,
        DO_BUY = 10,
        DO_UPGRADE,
        DO_UPGRADE_ALL,
        DO_RECYCLE,
        DO_RANDOMIZE,
        DO_DOWNGRADE,
    };

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ShowMain(player, creature);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        ClearGossipMenuFor(player);
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        switch (sender)
        {
            case MENU_PURCHASE:   ShowPurchase(player, creature); return true;
            case MENU_UPGRADE:    ShowUpgrade(player, creature); return true;
            case MENU_RECYCLE:    ShowRecycle(player, creature); return true;
            case DO_BUY:
                CloseGossipMenuFor(player);
                player->GetSession()->SendListInventory(creature->GetGUID(), EDRIM_VENDOR_BASE + action);
                return true;
            case DO_UPGRADE:
                if (Item* item = FindOwnedItem(player, action))
                    UpgradeOne(player, item);
                ShowUpgrade(player, creature);
                return true;
            case DO_UPGRADE_ALL:
                UpgradeAll(player);
                break;
            case DO_RECYCLE:
                if (Item* item = FindOwnedItem(player, action); item && !item->IsEquipped())
                    Recycle(player, item);
                ShowRecycle(player, creature);
                return true;
            case DO_RANDOMIZE:
                Randomize(player);
                break;
            case DO_DOWNGRADE:
                Downgrade(player);
                break;
            default:
                break;
        }
        ShowMain(player, creature);
        return true;
    }

private:
    static void AddInfo(Player* player)
    {
        Weekly const weekly = GetWeekly(player->GetGUID());
        AddGossipItemFor(player, GOSSIP_ICON_MONEY_BAG, Opt("inv_legion_chest_legionfall", Acore::StringFormat("Mythical Caches Opened: {} / {}", weekly.caches,
            WeeklyCacheCap()), 30), MENU_MAIN, 0);
        AddGossipItemFor(player, GOSSIP_ICON_MONEY_BAG, Opt("timelesscoin", Acore::StringFormat("Mythic Coins Obtained: {} / {}", weekly.coins,
            WeeklyCoinCap()), 30), MENU_MAIN, 0);
        AddGossipItemFor(player, GOSSIP_ICON_BATTLE, Opt("inv_relics_hourglass", Acore::StringFormat("Highest Mythic Level Completed: {}\n",
            GetBestLevel(player->GetGUID())), 30), MENU_MAIN, 0);
    }

    static void ShowMain(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);
        AddInfo(player);
        AddGossipItemFor(player, GOSSIP_ICON_VENDOR, Opt("inv__faction_championsofazeroth", "Purchase Items"), MENU_PURCHASE, 0);
        AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, Opt("garrison_greenarmorupgrade", "Upgrade Items"), MENU_UPGRADE, 0);
        uint32 const highest = std::min(HighestOwnedLevel(player), GetBestLevel(player->GetGUID()));
        uint32 count = 0, cost = 0;
        UpgradeAllPlan(player, highest, count, cost);
        if (count)
            AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, Opt("garrison_purplearmorupgrade", Acore::StringFormat("Upgrade Items to Highest Level ({})", highest)),
                DO_UPGRADE_ALL, 0, Acore::StringFormat("Upgrade {} items to Mythic {} for {} Mythic Coins?", count, highest, cost), 0, false);
        AddGossipItemFor(player, GOSSIP_ICON_INTERACT_2, Opt("INV_Misc_Dice_01", "Randomize your Mythic Keystone"), DO_RANDOMIZE, 0,
            "Randomize the dungeon of your Mythic Keystone?", RANDOMIZE_COST, false);
        AddGossipItemFor(player, GOSSIP_ICON_INTERACT_2, Opt("misc_arrowdown", "Downgrade Keystone"), DO_DOWNGRADE, 0,
            "Lower your Mythic Keystone by one level?", 0, false);
        AddGossipItemFor(player, GOSSIP_ICON_TRAINER, Opt("inv_enchant_alchemistcauldron", "Recycle Items"), MENU_RECYCLE, 0);
        SendGossipMenuFor(player, TEXT_EDRIM, creature->GetGUID());
    }

    static void ShowPurchase(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);
        for (uint32 slot = 1; slot <= 16; ++slot)
            if (VendorItemData const* items = sObjectMgr->GetNpcVendorItemList(EDRIM_VENDOR_BASE + slot); items && !items->Empty())
                AddGossipItemFor(player, GOSSIP_ICON_VENDOR, Opt(SLOT_ICONS[slot], SLOT_NAMES[slot]), DO_BUY, slot);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, Opt("Spell_Shadow_Teleport", "Back"), MENU_MAIN, 0);
        SendGossipMenuFor(player, TEXT_EDRIM, creature->GetGUID());
    }

    static void ShowUpgrade(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);
        AddInfo(player);
        uint32 const cap = GetBestLevel(player->GetGUID());
        ForEachOwnedItem(player, true, [&](Item* item)
        {
            uint32 nextLevel = 0;
            uint32 const next = NextLevelItem(item->GetEntry(), nextLevel);
            if (!next || nextLevel > cap)
                return;
            std::string const name = item->GetTemplate()->Name1;
            AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, ItemOpt(item->GetTemplate(), Acore::StringFormat("{} ({})", name, LevelName(nextLevel - 1))),
                DO_UPGRADE, item->GetGUID().GetCounter(), Acore::StringFormat("Upgrade {} to {} for {} Mythic Coins?", name,
                LevelName(nextLevel), UpgradeCost(nextLevel)), 0, false);
        });
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, Opt("Spell_Shadow_Teleport", "Back"), MENU_MAIN, 0);
        SendGossipMenuFor(player, TEXT_EDRIM, creature->GetGUID());
    }

    static void ShowRecycle(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);
        AddInfo(player);
        AddGossipItemFor(player, GOSSIP_ICON_MONEY_BAG, Opt("INV_Misc_Bag_07", "You can MASS recycle items by selling them to me.", 24), MENU_RECYCLE, 0);
        ForEachOwnedItem(player, false, [&](Item* item)
        {
            auto itr = g_chainOf.find(item->GetEntry());
            if (itr == g_chainOf.end())
                return;
            std::string const name = item->GetTemplate()->Name1;
            std::string const level = LevelName(itr->second.second);
            AddGossipItemFor(player, GOSSIP_ICON_TRAINER, ItemOpt(item->GetTemplate(), Acore::StringFormat("{} ({})", name, level)), DO_RECYCLE,
                item->GetGUID().GetCounter(), Acore::StringFormat("Are you sure you would like to recycle your {} ({})? This "
                "process is irreversible, but it will reward you with {} Mythic Coin.", name, level,
                RecycleValue(itr->second.second)), 0, false);
        });
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, Opt("Spell_Shadow_Teleport", "Back"), MENU_MAIN, 0);
        SendGossipMenuFor(player, TEXT_EDRIM, creature->GetGUID());
    }

    static void UpgradeOne(Player* player, Item* item)
    {
        uint32 nextLevel = 0;
        uint32 const next = NextLevelItem(item->GetEntry(), nextLevel);
        if (!next || nextLevel > GetBestLevel(player->GetGUID()) || !PayCoins(player, UpgradeCost(nextLevel)))
            return;
        ReplaceItem(player, item, next);
    }

    static void UpgradeAllPlan(Player* player, uint32 target, uint32& count, uint32& cost)
    {
        ForEachOwnedItem(player, true, [&](Item* item)
        {
            auto itr = g_chainOf.find(item->GetEntry());
            if (itr == g_chainOf.end())
                return;
            std::vector<uint32> const& levels = g_chains[itr->second.first];
            if (itr->second.second >= target || target >= levels.size() || !levels[target])
                return;
            ++count;
            for (uint32 level = itr->second.second + 1; level <= target; ++level)
                cost += UpgradeCost(level);
        });
    }

    static void UpgradeAll(Player* player)
    {
        uint32 const target = std::min(HighestOwnedLevel(player), GetBestLevel(player->GetGUID()));
        uint32 count = 0, cost = 0;
        UpgradeAllPlan(player, target, count, cost);
        if (!count || !PayCoins(player, cost))
            return;
        std::vector<Item*> items;
        ForEachOwnedItem(player, true, [&](Item* item)
        {
            auto itr = g_chainOf.find(item->GetEntry());
            if (itr != g_chainOf.end() && itr->second.second < target && target < g_chains[itr->second.first].size()
                && g_chains[itr->second.first][target])
                items.push_back(item);
        });
        for (Item* item : items)
            ReplaceItem(player, item, g_chains[g_chainOf[item->GetEntry()].first][target]);
    }

    static void Randomize(Player* player)
    {
        uint32 const key = CarriedKeystone(player);
        Keystone const* info = key ? Data::Instance().GetKeystone(key) : nullptr;
        if (!info)
        {
            ChatHandler(player->GetSession()).SendSysMessage("You have no Mythic Keystone.");
            return;
        }
        if (!player->HasEnoughMoney(RANDOMIZE_COST))
        {
            player->SendBuyError(BUY_ERR_NOT_ENOUGHT_MONEY, nullptr, 0, 0);
            return;
        }
        if (uint32 next = RandomKeystone(info->level))
        {
            player->ModifyMoney(-int32(RANDOMIZE_COST));
            Give(player, next, 1);
        }
    }

    static void Downgrade(Player* player)
    {
        uint32 const key = CarriedKeystone(player);
        Keystone const* info = key ? Data::Instance().GetKeystone(key) : nullptr;
        if (!info || info->level <= 1)
        {
            ChatHandler(player->GetSession()).SendSysMessage("You have no Mythic Keystone above level 1.");
            return;
        }
        if (uint32 lower = Data::Instance().GetKeystoneItem(info->lfgId, info->level - 1))
            Give(player, lower, 1);
    }
};

// Markus / Mar'toge <Mark of Triumph Exchange>: the Mark of Triumph items, and the Heroic Dungeon items by slot.
class npc_coa_mark_exchange : public CreatureScript
{
public:
    npc_coa_mark_exchange() : CreatureScript("npc_coa_mark_exchange") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ClearGossipMenuFor(player);
        AddGossipItemFor(player, GOSSIP_ICON_VENDOR, Opt("pvecurrency-valor", "Mark of Triumph"), 2, 0);
        AddGossipItemFor(player, GOSSIP_ICON_VENDOR, Opt("pvecurrency-valor", "Heroic Dungeon Items"), 1, 0);
        SendGossipMenuFor(player, TEXT_MARKUS, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        ClearGossipMenuFor(player);
        if (sender == 1)
        {
            for (uint32 slot = 1; slot <= 16; ++slot)
                if (VendorItemData const* items = sObjectMgr->GetNpcVendorItemList(MARK_VENDOR + slot); items && !items->Empty())
                    AddGossipItemFor(player, GOSSIP_ICON_VENDOR, Opt(SLOT_ICONS[slot], SLOT_NAMES[slot]), 2, slot);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, Opt("Spell_Shadow_Teleport", "Back"), 3, 0);
            SendGossipMenuFor(player, TEXT_MARKUS, creature->GetGUID());
            return true;
        }
        if (sender == 2)
        {
            CloseGossipMenuFor(player);
            player->GetSession()->SendListInventory(creature->GetGUID(), MARK_VENDOR + action);
            return true;
        }
        return OnGossipHello(player, creature);
    }
};

class coa_mythic_plus_vendors_world : public WorldScript
{
public:
    coa_mythic_plus_vendors_world() : WorldScript("coa_mythic_plus_vendors_world", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        LoadUpgradeChains();
    }
};

// Mythical Boon (80215): right-click gives a random Mythical Boon and the boon vanishes. It shows only during a
// running keystone; the boon items work only there too.
constexpr uint32 NPC_MYTHICAL_BOON = 80215;

bool InRunningKey(Map* map)
{
    Run* run = RunFor(map);
    return run && run->state == STATE_RUNNING;
}

class npc_coa_mythic_boon : public CreatureScript
{
public:
    npc_coa_mythic_boon() : CreatureScript("npc_coa_mythic_boon") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        static constexpr std::array<uint32, 13> BOONS = { 2104920, 2104921, 2104922, 2104923, 2104925, 2104926, 2104927,
            2104928, 2104929, 2104930, 2104931, 2104932, 2104935 };
        CloseGossipMenuFor(player);
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        if (!InRunningKey(creature->GetMap()))
            return true;
        Give(player, BOONS[urand(0, BOONS.size() - 1)], 1);
        creature->DespawnOrUnsummon(0ms, 7 * 24h);
        return true;
    }
};

// A boon's spell reaches only the user's party within 45 yards; on the live server it buffs every player within
// 50 yards in line of sight of the user, so the script applies it to each of them and uses up the item.
constexpr float BOON_RANGE = 50.0f;

void ApplyBoon(Player* user, uint32 spellId)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    if (!info)
        return;
    std::vector<Player*> targets;
    user->GetMap()->DoForAllPlayers([&](Player* target)
    {
        if (target->IsAlive() && (target == user || (target->IsWithinDistInMap(user, BOON_RANGE) && user->IsWithinLOSInMap(target))))
            targets.push_back(target);
    });
    for (Player* target : targets)
    {
        bool aura = false;
        for (SpellEffectInfo const& effect : info->GetEffects())
        {
            if (effect.IsAura())
                aura = true;
            else if (effect.Effect == SPELL_EFFECT_TRIGGER_SPELL)
                user->AddAura(effect.TriggerSpell, target);
            else if (effect.Effect == SPELL_EFFECT_HEAL_PCT)
                target->ModifyHealth(int32(target->CountPctFromMaxHealth(effect.CalcValue(user))));
        }
        if (aura)
            user->AddAura(spellId, target);
    }
}

class item_coa_mythic_boon : public ItemScript
{
public:
    item_coa_mythic_boon() : ItemScript("item_coa_mythic_boon") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        if (!InRunningKey(player->GetMap()))
        {
            player->SendEquipError(EQUIP_ERR_CANT_DO_RIGHT_NOW, item, nullptr);
            ChatHandler(player->GetSession()).SendSysMessage("Mythical Boons work only inside a Mythic Keystone.");
            return true;
        }
        uint32 const spellId = item->GetTemplate()->Spells[0].SpellId;
        uint32 one = 1;
        player->DestroyItemCount(item, one, true);
        ApplyBoon(player, spellId);
        return true;
    }
};
// Selling a Mythic item to Edrim recycles it instead (45 + level Mythic Coins).
class coa_mythic_plus_recycle : public PlayerScript
{
public:
    coa_mythic_plus_recycle() : PlayerScript("coa_mythic_plus_recycle", { PLAYERHOOK_CAN_SELL_ITEM }) { }

    bool OnPlayerCanSellItem(Player* player, Item* item, Creature* creature) override
    {
        if (!creature || creature->GetEntry() != NPC_EDRIM)
            return true;
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        if (!g_chainOf.count(item->GetEntry()))
        {
            ChatHandler(player->GetSession()).SendSysMessage("Edrim Skysong only takes Mythic items.");
            return false;
        }
        Recycle(player, item);
        return false;
    }
};

// Mythic Champion: walks between its two points, neutral until harmed, then fights with one Titanic Power. Its
// spells (2129000-2129181, three damage tiers by expansion) are Ascension's; the periodic and proc spells that
// pointed at other spells lost those links in the client data, so their ticks are cast from here.
class npc_coa_mythic_champion : public CreatureScript
{
public:
    npc_coa_mythic_champion() : CreatureScript("npc_coa_mythic_champion") { }

    struct npc_coa_mythic_championAI : public ScriptedAI
    {
        enum Spells : uint32
        {
            SPELL_CHAMPION          = 2129000,
            SPELL_POWER_INFERNAL    = 2129100,
            SPELL_IGNITE            = 2129104,  // + tier
            SPELL_MELT_DOWN         = 2129108,
            SPELL_FLAME_TORRENT     = 2129114,
            SPELL_MAGMA_STRIKE      = 2129120,
            SPELL_METEOR            = 2129125,
            SPELL_BURNING_GROUND    = 2129128,
            SPELL_LIVING_BOMB       = 2129132,
            SPELL_LIVING_BOMB_BLAST = 2129135,
            SPELL_POWER_GLACIAL     = 2129150,
            SPELL_FROSTBITE_SLOW    = 2129152,
            SPELL_DEEP_FREEZE       = 2129153,
            SPELL_FROSTBITE_NOVA    = 2129154,  // + tier
            SPELL_CHAINS_OF_ICE     = 2129157,
            SPELL_ICE_BARRAGE       = 2129163,  // + tier
        };

        enum Events : uint32
        {
            EVENT_MELT_DOWN = 1,
            EVENT_FLAME_TORRENT,
            EVENT_TORRENT_TICK,
            EVENT_MAGMA_STRIKE,
            EVENT_METEORS,
            EVENT_METEOR_IMPACT,
            EVENT_LIVING_BOMB,
            EVENT_LIVING_BOMB_BLAST,
            EVENT_CHAINS_OF_ICE,
            EVENT_ICE_BARRAGE,
            EVENT_BARRAGE_TICK,
            EVENT_ABSOLUTE_ZERO,
            EVENT_ZERO_TICK,
        };

        enum PathPoints : uint32
        {
            POINT_END = 1,
            POINT_WANDER = 2,
        };

        npc_coa_mythic_championAI(Creature* creature) : ScriptedAI(creature)
        {
            _tier = std::min<uint32>(creature->GetEntry() - NPC_MYTHIC_CHAMPION, 2);
            _glacial = urand(0, 1) == 1;
        }

        void Reset() override
        {
            _events.Reset();
            _meltDownMs = 15000;
            _ticks = 0;
            if (!me->HasAura(SPELL_CHAMPION))
                me->AddAura(SPELL_CHAMPION, me);
            uint32 const power = _glacial ? SPELL_POWER_GLACIAL : SPELL_POWER_INFERNAL;
            if (!me->HasAura(power))
                me->AddAura(power, me);
            me->SetWalk(true);
            _patrol = PATROL_START;
            _towardsB = false;
            _wanders = 0;
        }

        void JustReachedHome() override
        {
            _patrol = PATROL_START;
            _towardsB = false;
            _wanders = 0;
        }

        // At each end the champion stands a moment, takes a step or two around the point, then walks to the other end.
        void MovementInform(uint32 type, uint32 id) override
        {
            if (type != POINT_MOTION_TYPE || me->IsInCombat())
                return;
            if (id == POINT_END)
            {
                _wanders = urand(1, 2);
                _waitMs = urand(3000, 5000);
                _patrol = PATROL_WAITING;
            }
            else if (id == POINT_WANDER)
            {
                _waitMs = urand(1500, 3000);
                _patrol = PATROL_WAITING;
            }
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            me->SetWalk(false);
            if (_glacial)
            {
                _events.ScheduleEvent(EVENT_ICE_BARRAGE, 8s);
                _events.ScheduleEvent(EVENT_CHAINS_OF_ICE, 14s);
                _events.ScheduleEvent(EVENT_ABSOLUTE_ZERO, 30s);
            }
            else
            {
                _events.ScheduleEvent(EVENT_MAGMA_STRIKE, 6s);
                _events.ScheduleEvent(EVENT_FLAME_TORRENT, 10s);
                _events.ScheduleEvent(EVENT_MELT_DOWN, Milliseconds(_meltDownMs));
                _events.ScheduleEvent(EVENT_LIVING_BOMB, 16s);
                _events.ScheduleEvent(EVENT_METEORS, 25s);
            }
        }

        // Ignite on every fire hit, Frostbite on every frost hit (10 stacks: Deep Freeze).
        void SpellHitTarget(Unit* target, SpellInfo const* spell) override
        {
            if (!target || target == me || !target->IsAlive() || !spell)
                return;
            if (!_glacial && (spell->GetSchoolMask() & SPELL_SCHOOL_MASK_FIRE) && spell->Id != SPELL_IGNITE + _tier)
                me->CastSpell(target, SPELL_IGNITE + _tier, true);
            else if (_glacial && (spell->GetSchoolMask() & SPELL_SCHOOL_MASK_FROST) && spell->Id != SPELL_FROSTBITE_SLOW)
            {
                me->CastSpell(target, SPELL_FROSTBITE_SLOW, true);
                if (Aura* frostbite = target->GetAura(SPELL_FROSTBITE_SLOW, me->GetGUID()); frostbite && frostbite->GetStackAmount() >= 10)
                {
                    target->RemoveAurasDueToSpell(SPELL_FROSTBITE_SLOW);
                    me->CastSpell(target, SPELL_DEEP_FREEZE, true);
                }
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
            {
                UpdatePatrol(diff);
                return;
            }

            _events.Update(diff);
            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 event = _events.ExecuteEvent())
            {
                switch (event)
                {
                    case EVENT_MELT_DOWN:
                        DoCastAOE(SPELL_MELT_DOWN + _tier, true);
                        _meltDownMs = std::max<uint32>(4000, _meltDownMs * 85 / 100);
                        _events.ScheduleEvent(EVENT_MELT_DOWN, Milliseconds(_meltDownMs));
                        break;
                    case EVENT_FLAME_TORRENT:
                        _ticks = 5;
                        _events.ScheduleEvent(EVENT_TORRENT_TICK, 0ms);
                        _events.ScheduleEvent(EVENT_FLAME_TORRENT, 18s);
                        break;
                    case EVENT_TORRENT_TICK:
                        if (Unit* victim = me->GetVictim())
                        {
                            me->SetFacingToObject(victim);
                            me->CastSpell(victim, SPELL_FLAME_TORRENT + _tier, true);
                        }
                        if (--_ticks)
                            _events.ScheduleEvent(EVENT_TORRENT_TICK, 1s);
                        break;
                    case EVENT_MAGMA_STRIKE:
                        if (Unit* victim = me->GetVictim())
                            me->CastSpell(victim, SPELL_MAGMA_STRIKE + _tier, true);
                        _events.ScheduleEvent(EVENT_MAGMA_STRIKE, 9s);
                        break;
                    case EVENT_METEORS:
                        _impacts.clear();
                        for (uint32 i = 0; i < 3; ++i)
                            if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 40.0f, true))
                                _impacts.push_back(target->GetPosition());
                        _events.ScheduleEvent(EVENT_METEOR_IMPACT, 3s);
                        _events.ScheduleEvent(EVENT_METEORS, 30s);
                        break;
                    case EVENT_METEOR_IMPACT:
                        for (Position const& spot : _impacts)
                        {
                            me->CastSpell(spot.GetPositionX(), spot.GetPositionY(), spot.GetPositionZ(), SPELL_METEOR + _tier, true);
                            me->CastSpell(spot.GetPositionX(), spot.GetPositionY(), spot.GetPositionZ(), SPELL_BURNING_GROUND + _tier, true);
                        }
                        _impacts.clear();
                        break;
                    case EVENT_LIVING_BOMB:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 40.0f, true))
                        {
                            me->CastSpell(target, SPELL_LIVING_BOMB + _tier, true);
                            _bombTarget = target->GetGUID();
                            _events.ScheduleEvent(EVENT_LIVING_BOMB_BLAST, 8s);
                        }
                        _events.ScheduleEvent(EVENT_LIVING_BOMB, 20s);
                        break;
                    case EVENT_LIVING_BOMB_BLAST:
                        if (Unit* target = ObjectAccessor::GetUnit(*me, _bombTarget); target && target->IsAlive())
                        {
                            me->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(),
                                SPELL_LIVING_BOMB_BLAST + _tier, true);
                            me->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(),
                                SPELL_BURNING_GROUND + _tier, true);
                        }
                        break;
                    case EVENT_CHAINS_OF_ICE:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 1, 40.0f, true))
                            me->CastSpell(target, SPELL_CHAINS_OF_ICE, true);
                        _events.ScheduleEvent(EVENT_CHAINS_OF_ICE, 18s);
                        break;
                    case EVENT_ICE_BARRAGE:
                        _ticks = 6;
                        _barrageTarget = ObjectGuid::Empty;
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 40.0f, true))
                            _barrageTarget = target->GetGUID();
                        _events.ScheduleEvent(EVENT_BARRAGE_TICK, 0ms);
                        _events.ScheduleEvent(EVENT_ICE_BARRAGE, 12s);
                        break;
                    case EVENT_BARRAGE_TICK:
                        if (Unit* target = ObjectAccessor::GetUnit(*me, _barrageTarget); target && target->IsAlive())
                            me->CastSpell(target, SPELL_ICE_BARRAGE + _tier, true);
                        if (--_ticks)
                            _events.ScheduleEvent(EVENT_BARRAGE_TICK, 500ms);
                        break;
                    case EVENT_ABSOLUTE_ZERO:
                        _ticks = 5;
                        _events.ScheduleEvent(EVENT_ZERO_TICK, 0ms);
                        _events.ScheduleEvent(EVENT_ABSOLUTE_ZERO, 35s);
                        break;
                    case EVENT_ZERO_TICK:
                        DoCastAOE(SPELL_FROSTBITE_NOVA + _tier, true);
                        if (--_ticks)
                            _events.ScheduleEvent(EVENT_ZERO_TICK, 1s);
                        break;
                    default:
                        break;
                }
            }

            DoMeleeAttackIfReady();
        }

    private:
        enum Patrol : uint8
        {
            PATROL_START,
            PATROL_WALKING,
            PATROL_WAITING,
        };

        void UpdatePatrol(uint32 diff)
        {
            if (me->IsInEvadeMode() || !me->IsAlive())
                return;
            if (_patrol == PATROL_WALKING)
            {
                if (me->GetMotionMaster()->GetCurrentMovementGeneratorType() == POINT_MOTION_TYPE)
                    return;
                _waitMs = urand(1500, 3000);
                _patrol = PATROL_WAITING;
            }
            if (_patrol == PATROL_WAITING)
            {
                if (_waitMs > diff)
                {
                    _waitMs -= diff;
                    return;
                }
                _waitMs = 0;
            }
            ChampionPath path;
            if (!GetPath(path))
                return;
            bool const started = _patrol != PATROL_START;
            me->SetWalk(true);
            _patrol = PATROL_WALKING;
            if (started && _wanders)
            {
                --_wanders;
                Position const& end = _towardsB ? path.b : path.a;
                float const angle = frand(0.0f, 2 * float(M_PI));
                float const distance = frand(1.5f, 3.0f);
                me->GetMotionMaster()->MovePoint(POINT_WANDER, end.GetPositionX() + distance * std::cos(angle),
                    end.GetPositionY() + distance * std::sin(angle), end.GetPositionZ());
                return;
            }
            _towardsB = !_towardsB;
            me->GetMotionMaster()->MovePoint(POINT_END, _towardsB ? path.b : path.a);
        }

        bool GetPath(ChampionPath& path) const
        {
            std::lock_guard<std::recursive_mutex> guard(g_lock);
            auto itr = g_championPaths.find(me->GetGUID());
            if (itr == g_championPaths.end())
                return false;
            path = itr->second;
            return true;
        }

        EventMap _events;
        uint32 _tier = 0;
        bool _glacial = false;
        uint8 _patrol = PATROL_START;
        bool _towardsB = false;
        uint32 _waitMs = 0;
        uint32 _wanders = 0;
        uint32 _meltDownMs = 15000;
        uint32 _ticks = 0;
        std::vector<Position> _impacts;
        ObjectGuid _bombTarget;
        ObjectGuid _barrageTarget;
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_coa_mythic_championAI(creature);
    }
};

class coa_mythic_plus_command : public CommandScript
{
public:
    coa_mythic_plus_command() : CommandScript("coa_mythic_plus_command") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable mythicTable =
        {
            { "keystone", HandleKeystone, SEC_PLAYER,        Console::No },
            { "info",     HandleInfo,     SEC_PLAYER,        Console::No },
            { "affixes",  HandleAffixes,  SEC_PLAYER,        Console::Yes },
            { "clearkeys", HandleClearKeys, SEC_PLAYER,       Console::No },
            { "week",     HandleWeek,     SEC_ADMINISTRATOR, Console::Yes },
            { "keyrandom", HandleKeyRandom, SEC_GAMEMASTER,   Console::No },
            { "setchampionpos", HandleSetChampionPos, SEC_GAMEMASTER, Console::No },
            { "champions", HandleChampions, SEC_GAMEMASTER,   Console::No },
            { "delchampion", HandleDelChampion, SEC_GAMEMASTER, Console::No },
            { "spawnchampions", HandleSpawnChampions, SEC_GAMEMASTER, Console::No },
            { "givekey",  HandleGiveKey,  SEC_ADMINISTRATOR, Console::No },
            { "forces",   HandleForces,   SEC_ADMINISTRATOR, Console::No },
            { "reload",   HandleReload,   SEC_ADMINISTRATOR, Console::Yes },
            { "wings",    HandleWings,    SEC_ADMINISTRATOR, Console::Yes },
            { "setbest",  HandleSetBest,  SEC_ADMINISTRATOR, Console::Yes },
        };
        static ChatCommandTable commandTable =
        {
            { "mythic", mythicTable },
        };
        return commandTable;
    }

    // Opens the keystone socket again, e.g. after closing it.
    static bool HandleKeystone(ChatHandler* handler)
    {
        Player* player = handler->GetSession()->GetPlayer();
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        if (!g_socketed.count(player->GetGUID()))
        {
            handler->SendSysMessage("Use your keystone first.");
            return true;
        }
        SendWindow(player, true);
        return true;
    }

    static bool HandleInfo(ChatHandler* handler)
    {
        Player* player = handler->GetSession()->GetPlayer();
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        Run* run = RunFor(player->GetMap());
        if (!run)
        {
            handler->SendSysMessage("No keystone run in this instance.");
            return true;
        }
        handler->PSendSysMessage("Mythic+ +{} lfg {} state {}: {} / {} s, forces {} / {}, encounters {} / {} (final {})",
            run->level, run->lfgId, uint32(run->state), run->elapsedMs / 1000, run->dungeon.timeLimitMs / 1000,
            run->forces, run->dungeon.forcesTotal, uint32(run->encounters.size()), run->dungeon.encountersRequired,
            run->finalKilled ? "down" : "alive");
        handler->PSendSysMessage("Week {}, affixes: {}", run->rotation, AffixNames(run->affixes));
        handler->PSendSysMessage("Forces: {} in this wing, each kill x{:.2f}", run->forcesAvailable, run->forcesScale);
        return true;
    }

    // .mythic affixes [level]: this week's affixes as the client shows them.
    static bool HandleAffixes(ChatHandler* handler, Optional<uint32> level)
    {
        uint32 const week = CurrentRotation();
        for (uint32 l : level ? std::vector<uint32> { *level } : std::vector<uint32> { 2, 4, 7, 10, 15, 20 })
            handler->PSendSysMessage("Week {} +{}: {}", week, l, AffixNames(Data::Instance().GetAffixes(week, l)));
        return true;
    }

    // .mythic week [n]: use the affixes of week n (0-52) for new runs; without
    // n back to the calendar. The client still shows the calendar week.
    static bool HandleWeek(ChatHandler* handler, Optional<int32> week)
    {
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        g_weekOverride = week ? std::clamp<int32>(*week, -1, 52) : -1;
        handler->PSendSysMessage("Mythic+ affix week: {}{}", CurrentRotation(), g_weekOverride < 0 ? " (calendar)" : " (forced)");
        return true;
    }

    // .mythic clearkeys: destroys every keystone in bags and bank.
    static bool HandleClearKeys(ChatHandler* handler)
    {
        Player* player = handler->GetSession()->GetPlayer();
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        g_socketed.erase(player->GetGUID());
        handler->PSendSysMessage("Mythic+: {} keystone(s) destroyed.", DestroyKeystones(player));
        return true;
    }

    // .mythic givekey <level> [lfgId]
    static bool HandleGiveKey(ChatHandler* handler, uint32 level, Optional<uint32> lfgId)
    {
        Player* player = handler->getSelectedPlayerOrSelf();
        uint32 item = lfgId ? Data::Instance().GetKeystoneItem(*lfgId, level) : RandomKeystone(level);
        if (!item)
        {
            handler->SendSysMessage("No keystone for that dungeon and level.");
            return true;
        }
        Give(player, item, 1);
        handler->PSendSysMessage("Gave keystone {}.", item);
        return true;
    }

    // Enemy forces of the targeted creature, and where the number comes from.
    static bool HandleForces(ChatHandler* handler)
    {
        Creature* creature = handler->getSelectedCreature();
        if (!creature)
        {
            handler->SendSysMessage("Select a creature.");
            return true;
        }
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        bool fromTable = g_forces.count(creature->GetEntry()) || g_forces.count(BaseEntry(creature->GetEntry()));
        handler->PSendSysMessage("{} ({}): {} enemy forces ({})", creature->GetName(), creature->GetEntry(),
            ForcesFor(creature), fromTable ? "coa_mythic_forces" : "default");
        return true;
    }

    // .mythic wings: for every dungeon new keys can point at, the forces its
    // wing has and needs on Mythic, the scale per kill, and the bosses the
    // client lists that have no spawn (summoned by scripts, or missing).
    static bool HandleWings(ChatHandler* handler)
    {
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        std::set<uint32> const excluded = ExcludedDungeons();
        std::vector<uint32> ids;
        for (auto const& [lfgId, dungeon] : Data::Instance().Dungeons())
            if (dungeon.expansion <= MaxExpansion() && dungeon.forcesTotal && dungeon.encountersRequired < 20 && !excluded.count(lfgId))
                ids.push_back(lfgId);
        std::sort(ids.begin(), ids.end());
        for (uint32 lfgId : ids)
        {
            Run run;
            run.lfgId = lfgId;
            run.dungeon = *Data::Instance().GetDungeon(lfgId);
            std::string missing;
            ScaleForces(run.dungeon.mapId, MYTHIC_DIFFICULTY, run, &missing);
            std::vector<WingEncounter> const* list = Data::Instance().GetWingEncounters(lfgId);
            std::string const text = Acore::StringFormat("WING {} {} map {}: forces {} of {} (x{:.2f}), bosses {} need {}, no spawn:{}",
                lfgId, DungeonName(lfgId), run.dungeon.mapId, run.forcesAvailable, run.dungeon.forcesTotal, run.forcesScale,
                list ? uint32(list->size()) : 0, run.dungeon.encountersRequired, missing.empty() ? " -" : missing);
            LOG_INFO("module", "{}", text);
            handler->SendSysMessage(text);
        }
        return true;
    }

    // .mythic setbest <level> [name]: the highest keystone level a player finished, which caps upgrades. Without a
    // name the selected player or yourself.
    static bool HandleSetBest(ChatHandler* handler, uint32 level, Optional<PlayerIdentifier> name)
    {
        Player* target = name ? name->GetConnectedPlayer() : handler->getSelectedPlayerOrSelf();
        if (!target)
            return false;
        CharacterDatabase.DirectExecute("REPLACE INTO coa_mythic_best (guid, level) VALUES ({}, {})", target->GetGUID().GetCounter(), level);
        handler->PSendSysMessage("Highest Mythic Level Completed of {}: {}", target->GetName(), level);
        return true;
    }

    // .mythic keyrandom: your keystone moves to another random dungeon at the same level, free of charge.
    static bool HandleKeyRandom(ChatHandler* handler)
    {
        Player* player = handler->GetSession()->GetPlayer();
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        uint32 const key = CarriedKeystone(player);
        Keystone const* info = key ? Data::Instance().GetKeystone(key) : nullptr;
        if (!info)
        {
            handler->SendSysMessage("You have no Mythic Keystone.");
            return true;
        }
        uint32 next = 0;
        for (uint32 tries = 0; tries < 20 && (!next || next == key); ++tries)
            next = RandomKeystone(info->level);
        Keystone const* nextInfo = next ? Data::Instance().GetKeystone(next) : nullptr;
        if (!nextInfo || next == key)
        {
            handler->SendSysMessage("No other dungeon has a keystone at this level.");
            return true;
        }
        g_socketed.erase(player->GetGUID());
        Give(player, next, 1);
        handler->PSendSysMessage("Mythic+: your keystone is now {} +{}.", DungeonName(nextInfo->lfgId), nextInfo->level);
        return true;
    }

    // .mythic setchampionpos 1 marks where a champion starts, .mythic setchampionpos 2 where it turns back; the
    // second saves the path for this map (coa_mythic_champion_path).
    static bool HandleSetChampionPos(ChatHandler* handler, uint8 point)
    {
        static std::map<ObjectGuid, std::pair<uint32, Position>> pending;
        Player* player = handler->GetSession()->GetPlayer();
        if (point == 1)
        {
            pending[player->GetGUID()] = { player->GetMapId(), player->GetPosition() };
            handler->PSendSysMessage("Champion point A set at {:.1f} {:.1f} {:.1f}. Walk to point B and use .mythic setchampionpos 2.",
                player->GetPositionX(), player->GetPositionY(), player->GetPositionZ());
            return true;
        }
        if (point != 2)
            return false;
        auto itr = pending.find(player->GetGUID());
        if (itr == pending.end() || itr->second.first != player->GetMapId())
        {
            handler->SendSysMessage("Set point A on this map first: .mythic setchampionpos 1");
            return true;
        }
        Position const& a = itr->second.second;
        std::string comment = player->GetName();
        WorldDatabase.EscapeString(comment);
        WorldDatabase.DirectExecute("INSERT INTO coa_mythic_champion_path (map, a_x, a_y, a_z, a_o, b_x, b_y, b_z, comment) "
            "VALUES ({}, {}, {}, {}, {}, {}, {}, {}, '{}')", player->GetMapId(), a.GetPositionX(), a.GetPositionY(),
            a.GetPositionZ(), a.GetOrientation(), player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), comment);
        pending.erase(itr);
        uint32 id = 0, count = 0;
        if (QueryResult result = WorldDatabase.Query("SELECT MAX(id), COUNT(*) FROM coa_mythic_champion_path WHERE map = {}", player->GetMapId()))
        {
            id = result->Fetch()[0].Get<uint32>();
            count = uint32(result->Fetch()[1].Get<uint64>());
        }
        handler->PSendSysMessage("Champion path {} saved ({:.0f} yd). Map {} now has {} champion path(s).", id,
            a.GetExactDist(player), player->GetMapId(), count);
        return true;
    }

    // .mythic champions: the champion paths on this map, nearest first.
    static bool HandleChampions(ChatHandler* handler)
    {
        Player* player = handler->GetSession()->GetPlayer();
        QueryResult result = WorldDatabase.Query("SELECT id, a_x, a_y, a_z, b_x, b_y, b_z FROM coa_mythic_champion_path WHERE map = {}",
            player->GetMapId());
        if (!result)
        {
            handler->SendSysMessage("No champion paths on this map.");
            return true;
        }
        std::vector<std::tuple<float, uint32, float>> paths;
        do
        {
            Field* f = result->Fetch();
            Position a(f[1].Get<float>(), f[2].Get<float>(), f[3].Get<float>());
            Position b(f[4].Get<float>(), f[5].Get<float>(), f[6].Get<float>());
            paths.emplace_back(std::min(player->GetExactDist(&a), player->GetExactDist(&b)), f[0].Get<uint32>(), a.GetExactDist(&b));
        } while (result->NextRow());
        std::sort(paths.begin(), paths.end());
        for (auto const& [distance, id, length] : paths)
            handler->PSendSysMessage("Champion path {}: {:.0f} yd long, {:.0f} yd away", id, length, distance);
        return true;
    }

    // .mythic spawnchampions: places the champions of this map now, without a key, to look at the paths.
    static bool HandleSpawnChampions(ChatHandler* handler)
    {
        Player* player = handler->GetSession()->GetPlayer();
        Map* map = player->GetMap();
        uint32 expansion = 0;
        for (auto const& [lfgId, dungeon] : Data::Instance().Dungeons())
            if (dungeon.mapId == map->GetId())
                expansion = dungeon.expansion;
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        handler->PSendSysMessage("Mythic+: {} champion(s) placed.", SpawnChampions(map, expansion, 0));
        return true;
    }

    // .mythic delchampion <id>
    static bool HandleDelChampion(ChatHandler* handler, uint32 id)
    {
        WorldDatabase.DirectExecute("DELETE FROM coa_mythic_champion_path WHERE id = {}", id);
        handler->PSendSysMessage("Champion path {} deleted.", id);
        return true;
    }

    static bool HandleReload(ChatHandler* handler)
    {
        std::lock_guard<std::recursive_mutex> guard(g_lock);
        Data::Instance().Load();
        LoadTables();
        handler->SendSysMessage("Mythic+ data reloaded.");
        return true;
    }
};

void AddCoaMythicPlusScripts()
{
    new coa_mythic_plus_world();
    new coa_mythic_plus_map();
    new coa_mythic_plus_creature();
    new coa_mythic_plus_player();
    new coa_mythic_plus_unit();
    new coa_mythic_plus_command();
    new coa_mythic_plus_cache();
    new coa_mythic_plus_vendors_world();
    new npc_coa_mythic_items();
    new npc_coa_mark_exchange();
    new coa_mythic_plus_recycle();
    new npc_coa_mythic_boon();
    new npc_coa_mythic_champion();
    new item_coa_mythic_boon();
    new coa_mythic_plus_spoils();
    new coa_mythic_plus_boss_casts();
    new coa_mythic_plus_boss_kills();
    new coa_mythic_plus_keystone_use();
}
