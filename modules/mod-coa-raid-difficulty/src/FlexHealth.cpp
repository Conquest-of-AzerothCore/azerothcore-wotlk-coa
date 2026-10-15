/*
 * Flex health: a boss's health follows the number of players in the instance.
 *
 * The difficulty labels read "(10-25 Players)", and the combat logs show what
 * that meant. Garr had 30.8 million health on Ascended with 13 players and
 * 43.1 million in another raid; divided by the player count, every boss lands
 * on the same ratio between difficulties. coa_boss_flex holds health PER
 * PLAYER, per difficulty, and this file multiplies it out.
 *
 * When:
 *  - at spawn, so a boss standing idle shows a sensible number, and
 *  - at the pull, which is the one that counts. The count is taken once and
 *    holds for the fight; someone who zones in halfway does not change it.
 *
 * Who counts: every player in the instance who is not a game master. That
 * includes bots, which are players to the core.
 *
 * The count is clamped to 10..25. The 25 is in the label. The 10 is an
 * assumption read off the same label - the logs only hold raids of 13 to 18,
 * so neither end was ever observed.
 *
 * A column of 0 means no flex for that difficulty: the boss keeps the health
 * its template gives it. Normal is 0 for every boss, because Normal appears in
 * no log.
 *
 * This hangs off a general combat hook rather than the boss AI on purpose, so
 * it applies equally to bosses that keep their stock script, like Ragnaros.
 */

#include "FlexHealth.h"

#include "Creature.h"
#include "DBCEnums.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"

#include <algorithm>
#include <limits>
#include <unordered_map>

namespace
{
    constexpr uint32 FLEX_MIN_PLAYERS = 10;
    constexpr uint32 FLEX_MAX_PLAYERS = 25;
}

namespace coa_flex
{
    uint32 CountPlayers(Map* map)
    {
        uint32 count = 0;
        map->DoForAllPlayers([&count](Player* player)
        {
            if (!player->IsGameMaster())
                ++count;
        });
        return std::clamp(count, FLEX_MIN_PLAYERS, FLEX_MAX_PLAYERS);
    }
}

namespace
{
    struct FlexRow
    {
        // Positive: health per player, multiplied by the instance's actual
        // player count (clamped 10..25) as usual. Negative: health per
        // player, but always multiplied by FLEX_MAX_PLAYERS (25) regardless
        // of how many players are actually there (e.g. Basalthane's Mythic/
        // Ascended, which are 25-man-locked difficulties, not dynamic flex).
        int32 perPlayer[MAX_RAID_DIFFICULTY];
    };

    std::unordered_map<uint32, FlexRow> g_flex;

    uint32 BaseEntry(uint32 entry)
    {
        return entry % 100000;
    }

    void LoadFlex()
    {
        g_flex.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT entry, hp_d0, hp_d1, hp_d2, hp_d3 FROM coa_boss_flex"))
        {
            do
            {
                Field* f = result->Fetch();
                FlexRow& row = g_flex[f[0].Get<uint32>()];
                for (uint8 i = 0; i < MAX_RAID_DIFFICULTY; ++i)
                    row.perPlayer[i] = f[1 + i].Get<int32>();
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded flex health for {} bosses", uint32(g_flex.size()));
    }

    // Scales health and keeps the current percentage, so a boss that is
    // already hurt stays exactly as hurt.
    // CONFIRMED 2026-10-02: entry 310189 (Basalthane's Molten Blood ooze, Onyxia's
    // Lair) is not a difficulty-variant of anything - it's an unrelated creature whose
    // own entry number happens to equal 10189 + 300000, which BaseEntry's "+N*100000
    // per difficulty" convention misreads as the 25-man (D3) variant of Basalthane
    // (entry 10189). That made this ooze silently get Basalthane's own per-player HP
    // applied to it. The ooze has its own real per-player flex logic (measured from
    // combat logs, see MoltenBloodHpPerPlayerFor in spell_basalthane.cpp) applied
    // directly at spawn time instead of through this shared table - skip it here so a
    // later OnUnitEnterCombat call doesn't silently undo that with Basalthane's values.
    constexpr uint32 ENTRY_BASALTHANE_MOLTEN_BLOOD_OOZE = 310189;

    void ApplyFlex(Creature* creature)
    {
        if (!creature || !creature->GetMap() || !creature->GetMap()->IsRaid())
            return;

        if (creature->GetEntry() == ENTRY_BASALTHANE_MOLTEN_BLOOD_OOZE)
            return;

        auto it = g_flex.find(BaseEntry(creature->GetEntry()));
        if (it == g_flex.end())
            return;

        uint8 const mode = uint8(creature->GetMap()->GetSpawnMode());
        if (mode >= MAX_RAID_DIFFICULTY || !it->second.perPlayer[mode])
            return;

        int32 const configured = it->second.perPlayer[mode];
        uint32 const players = configured < 0 ? FLEX_MAX_PLAYERS : coa_flex::CountPlayers(creature->GetMap());
        uint64 const wanted = uint64(configured < 0 ? uint32(-configured) : uint32(configured)) * players;
        uint32 const health = uint32(std::min<uint64>(wanted, std::numeric_limits<uint32>::max()));

        float const pct = creature->GetMaxHealth() ? creature->GetHealthPct() : 100.0f;

        creature->SetCreateHealth(health);
        creature->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
        creature->UpdateMaxHealth();
        creature->SetHealth(std::max<uint32>(1, uint32(creature->GetMaxHealth() * pct / 100.0f)));

        LOG_DEBUG("scripts", "coa flex: {} on difficulty {} with {} players -> {} health",
                  creature->GetEntry(), mode, players, creature->GetMaxHealth());
    }

    class coa_flex_health_creature : public AllCreatureScript
    {
    public:
        coa_flex_health_creature() : AllCreatureScript("coa_flex_health_creature") { }

        void OnCreatureSelectLevel(CreatureTemplate const* /*cinfo*/, Creature* creature) override
        {
            ApplyFlex(creature);
        }
    };

    class coa_flex_health_unit : public UnitScript
    {
    public:
        coa_flex_health_unit() : UnitScript("coa_flex_health_unit", true, { UNITHOOK_ON_UNIT_ENTER_COMBAT }) { }

        void OnUnitEnterCombat(Unit* unit, Unit* /*victim*/) override
        {
            if (Creature* creature = unit->ToCreature())
                ApplyFlex(creature);
        }
    };

    class coa_flex_health_loader : public WorldScript
    {
    public:
        coa_flex_health_loader() : WorldScript("coa_flex_health_loader") { }

        void OnAfterConfigLoad(bool /*reload*/) override
        {
            LoadFlex();
        }
    };
}

void AddCoaFlexHealthScripts()
{
    new coa_flex_health_creature();
    new coa_flex_health_unit();
    new coa_flex_health_loader();
}
