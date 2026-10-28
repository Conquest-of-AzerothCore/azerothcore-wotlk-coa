#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <map>
#include <string>

using namespace std::chrono_literals;
using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using Milliseconds = std::chrono::milliseconds;
using Seconds = std::chrono::seconds;
#define LOG_DEBUG(...) ((void)0)

// NATIVE_CLOCK

namespace GameTime
{
inline time_t Now = 0;
inline Seconds GetGameTime() { return Seconds(Now); }
}

enum class DeathState : uint8 { Alive, JustDied, Corpse, Dead, JustRespawned };
enum ServerConfigs { CONFIG_RESPAWN_TIMER_STARTS_AT_DEATH };
enum Rates { RATE_CORPSE_DECAY_LOOTED };
enum LootType { LOOT_CORPSE = 1, LOOT_SKINNING = 6 };
enum UnitFlags : uint32 { UNIT_FLAG_SKINNABLE = 0x04000000 };
enum NPCFlags : uint32 { UNIT_NPC_FLAG_NONE = 0 };
enum ObjectFields { OBJECT_FIELD_ENTRY = 3 };
constexpr uint32 CREATURE_ELITE_ELITE = 1;
inline constexpr uint32 IN_MILLISECONDS = 1000;

struct World
{
    bool timerFromDeath = true;
    float lootedRate = 0.5f;
    bool getBoolConfig(ServerConfigs) const { return timerFromDeath; }
    float getRate(Rates) const { return lootedRate; }
} world;
World* sWorld = &world;

struct Creature;
struct Map
{
    uint32 divisor = 1;
    bool dungeon = false;
    time_t saved = 0;
    int saves = 0;
    uint32 ApplyDynamicModeRespawnScaling(Creature const*, uint32 delay) const { return delay / divisor; }
    bool IsDungeon() const { return dungeon; }
    void SaveCreatureRespawnTime(uint32, time_t& respawnTime) { saved = respawnTime; ++saves; }
    void ScheduleCreatureRespawn(uint64, Seconds) { }
} map;

struct Position { void Relocate(float, float, float, float) { } };
struct Loot { LootType loot_type = LOOT_CORPSE; void clear() { } };
struct CreatureAI { void CorpseRemoved(uint32&) { } };
struct CreatureTemplate { uint32 rank = 0; uint32 SkinLootId = 0; };
struct CreatureData { bool dbData = true; };
struct MotionMaster { void MoveFall(uint32, bool) { } };
struct CreatureGroup { Creature* GetLeader() { return nullptr; } void FormationReset(bool, bool) { } };
struct Group { void EndRoll(Loot*) { } };
struct GroupMgr { Group group; Group* GetGroupByGUID(uint32) { return &group; } } groupMgr;
GroupMgr* sGroupMgr = &groupMgr;
struct LootStore { bool HaveLootFor(uint32) const { return false; } } LootTemplates_Skinning;
struct BasicEvent { virtual ~BasicEvent() = default; };
struct ForcedDespawnDelayEvent : BasicEvent { ForcedDespawnDelayEvent(Creature&, Seconds) { } };
struct EventProcessor { void AddEventAtOffset(BasicEvent* event, Milliseconds) { delete event; } };

struct Unit
{
    DeathState m_deathState = DeathState::Alive;
    EventProcessor m_Events;
    Position m_last_notify_position;
    void setDeathState(DeathState state, bool) { m_deathState = state; }
    void Update(uint32) { }
};

struct Creature : Unit
{
    time_t m_corpseRemoveTime = 0;
    time_t m_respawnTime = 0;
    uint32 m_respawnDelay = 300;
    uint32 m_corpseDelay = 60;
    uint32 m_spawnId = 1;
    CreatureData data;
    CreatureData const* m_creatureData = &data;
    CreatureTemplate cinfo;
    bool _respawnCompatibilityMode = true;
    bool summon = false;
    bool namedQuestTarget = false;
    bool worldBoss = false;
    bool IsAIEnabled = true;
    CreatureAI ai;
    MotionMaster motion;
    CreatureGroup* m_formation = nullptr;
    Loot loot;
    uint32 m_groupLootTimer = 0;
    uint32 lootingGroupLowGUID = 0;
    bool removed = false;
    time_t respawnedAt = -1;

    DeathState getDeathState() const { return m_deathState; }
    bool IsAlive() const { return m_deathState == DeathState::Alive; }
    bool IsSharedQuestTarget() const { return namedQuestTarget && !map.dungeon; }
    bool IsSummon() const { return summon; }
    bool IsPet() const { return false; }
    bool isWorldBoss() const { return worldBoss; }
    bool hasLootRecipient() const { return true; }
    bool HasSearchedAssistance() const { return false; }
    bool IsFlying() const { return false; }
    bool IsHovering() const { return false; }
    bool IsUnderWater() const { return false; }
    bool IsFalling() const { return false; }
    Map* GetMap() const { return &map; }
    CreatureTemplate const* GetCreatureTemplate() const { return &cinfo; }
    CreatureAI* AI() { return &ai; }
    MotionMaster* GetMotionMaster() { return &motion; }
    uint64 GetGUID() const { return 1; }
    uint32 GetUInt32Value(ObjectFields) const { return 0; }
    void SetTarget() { }
    void ReplaceAllNpcFlags(NPCFlags) { }
    void Dismount() { }
    void SetNoSearchAssistance(bool) { }
    void SetHover(bool) { }
    void SetDisableGravity(bool) { }
    void SetUnitFlag(UnitFlags) { }
    void RemoveAllAuras() { }
    void DestroyForVisiblePlayers() { }
    void GetRespawnPosition(float& x, float& y, float& z, float* o) const { x = y = z = *o = 0; }
    void SetHomePosition(float, float, float, float) { }
    void SetPosition(float, float, float, float) { }
    void StopMoving() { }
    void AddObjectToRemoveList() { removed = true; }
    void Respawn(bool = false)
    {
        respawnedAt = GameTime::Now;
        m_respawnTime = 0;
        m_deathState = DeathState::Alive;
    }

    void setDeathState(DeathState state, bool despawn = false);
    void RemoveCorpse(bool setSpawnTime = true, bool skipVisibility = false);
    void AllLootRemovedFromCorpse();
    void ForcedDespawn(Milliseconds timeMSToDespawn = 0ms, Seconds forcedRespawnTimer = 0s);
    void SaveRespawnTime();
    bool IsRespawnTimerFromDeath() const;
    void Tick(uint32 diff);
};

void Creature::setDeathState(DeathState state, bool despawn)
{
    Unit::setDeathState(state, despawn);
    if (state == DeathState::JustDied)
// NATIVE_JUST_DIED
    else if (state == DeathState::JustRespawned)
        Unit::setDeathState(DeathState::Alive, despawn);
}

void Creature::Tick(uint32 diff)
{
    switch (m_deathState)
    {
// NATIVE_DEAD_AND_CORPSE
        default:
            break;
    }
}

// METHODS

int main(int argc, char** argv)
{
    std::map<std::string, long long> in;
    for (int i = 1; i < argc; ++i)
    {
        char const* equals = std::strchr(argv[i], '=');
        in[std::string(argv[i], std::size_t(equals - argv[i]))] = std::atoll(equals + 1);
    }
    auto get = [&](char const* key, long long fallback) { return in.count(key) ? in[key] : fallback; };

    world.timerFromDeath = get("config", 1) != 0;
    world.lootedRate = float(get("rate_pct", 50)) / 100.0f;
    map.divisor = uint32(get("divisor", 1));
    map.dungeon = get("dungeon", 0) != 0;
    Creature creature;
    creature._respawnCompatibilityMode = get("compat", 1) != 0;
    creature.m_spawnId = uint32(get("spawn", 1));
    creature.namedQuestTarget = get("named", 0) != 0;
    creature.worldBoss = get("worldboss", 0) != 0;
    creature.summon = get("summon", 0) != 0;
    creature.data.dbData = get("db", 1) != 0;
    creature.cinfo.rank = uint32(get("rank", 0));
    creature.m_respawnDelay = uint32(get("delay", 300));
    creature.m_corpseDelay = uint32(get("decay", 60));

    time_t const death = 1000;
    GameTime::Now = death;
    if (in.count("alive_despawn"))
        creature.ForcedDespawn(0ms, Seconds(get("alive_despawn", 0)));
    else
        creature.setDeathState(DeathState::JustDied);
    long long const deathSave = map.saves ? map.saved : -1;

    long long corpseGone = creature.m_deathState == DeathState::Corpse ? -1 : death;
    long long respawn = creature.respawnedAt;
    bool duplicate = false;
    for (long long ms = death * 1000LL; ms <= (death + 5000) * 1000LL && respawn < 0; ms += 100)
    {
        time_t const now = ms / 1000;
        GameTime::Now = now;
        bool const secondStarts = ms % 1000 == 0;
        if (secondStarts && creature.m_deathState == DeathState::Corpse && !creature.removed)
        {
            if (get("loot", -1) == now)
            {
                creature.loot.loot_type = LOOT_CORPSE;
                creature.AllLootRemovedFromCorpse();
            }
            if (get("skin", -1) == now)
            {
                creature.loot.loot_type = LOOT_SKINNING;
                creature.AllLootRemovedFromCorpse();
            }
            if (get("roll", -1) == now)
            {
                creature.m_groupLootTimer = uint32(get("roll_ms", 60000));
                creature.lootingGroupLowGUID = 1;
            }
            if (get("despawn", -1) == now)
                creature.ForcedDespawn(0ms, Seconds(get("despawn_timer", 0)));
        }
        if (!creature.removed)
            creature.Tick(100);
        if (corpseGone < 0 && (creature.removed || creature.m_deathState != DeathState::Corpse))
            corpseGone = now;
        if (!creature._respawnCompatibilityMode && creature.m_deathState == DeathState::Corpse && !creature.removed
            && map.saves && map.saved <= now)
            duplicate = true;
        if (creature._respawnCompatibilityMode)
            respawn = creature.respawnedAt;
        else if (creature.removed && map.saves && map.saved <= now)
            respawn = now;
    }
    std::printf("corpse=%lld respawn=%lld death_save=%lld duplicate=%d\n", corpseGone, respawn, deathSave,
        duplicate ? 1 : 0);
}
