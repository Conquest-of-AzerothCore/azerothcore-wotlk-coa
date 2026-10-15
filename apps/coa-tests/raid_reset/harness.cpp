#include "InstanceResetSchedule.h"
#include <array>
#include <cassert>
#include <ctime>
#include <list>
#include <map>
#include <memory>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

#define LOG_ERROR(...) ++loggedErrors
#define LOG_INFO(...) ((void)0)

int loggedErrors = 0;
time_t clockNow = 0;

namespace GameTime
{
    struct Seconds
    {
        time_t value;
        time_t count() const { return value; }
    };

    Seconds GetGameTime() { return { clockNow }; }
}

enum WorldIntConfigs { CONFIG_INSTANCE_RESET_TIME_HOUR };
enum Rates { RATE_INSTANCE_RESET_TIME };

struct World
{
    uint32 resetHour = 0;
    uint32 getIntConfig(WorldIntConfigs) const { return resetHour; }
    float getRate(Rates) const { return 1.0f; }
} world;
World* sWorld = &world;

uint32 MAKE_PAIR32(uint16 l, uint16 h) { return uint32(l | (h << 16)); }
uint16 PAIR32_HIPART(uint32 x) { return uint16((x >> 16) & 0x0000FFFF); }
uint16 PAIR32_LOPART(uint32 x) { return uint16(x & 0x0000FFFF); }

struct MapEntry
{
    uint32 map_type;
    bool Instanceable() const
    {
        return map_type == MAP_INSTANCE || map_type == MAP_RAID || map_type == MAP_BATTLEGROUND ||
            map_type == MAP_ARENA;
    }
};

struct MapStore
{
    std::map<uint32, MapEntry> entries;
    MapEntry const* LookupEntry(uint32 id) const
    {
        auto itr = entries.find(id);
        return itr == entries.end() ? nullptr : &itr->second;
    }
} sMapStore;

// ACTUAL_MAP_DIFFICULTY
typedef std::map<uint32, MapDifficulty> MapDifficultyMap;
MapDifficultyMap sMapDifficultyMap;
// ACTUAL_DIFFICULTY_LOOKUP

struct Field
{
    uint64 value;
    template <class T> T Get() const { return T(value); }
};

struct ResultSet
{
    std::vector<std::array<Field, 3>> rows;
    std::size_t row = 0;
    Field* Fetch() { return rows[row].data(); }
    bool NextRow() { return ++row < rows.size(); }
};
using QueryResult = std::shared_ptr<ResultSet>;

enum CharacterDatabaseStatements { CHAR_UPD_GLOBAL_INSTANCE_RESETTIME };

struct PreparedStatement
{
    std::array<uint64, 3> data{};
    template <class T> void SetData(uint8 index, T value) { data[index] = uint64(value); }
};
using CharacterDatabasePreparedStatement = PreparedStatement;

using ResetKey = std::pair<uint32, uint32>;
using ResetRows = std::map<ResetKey, time_t>;

ResetKey Key(uint64 mapId, uint64 difficulty) { return { uint32(mapId), uint32(difficulty) }; }

struct CharacterDatabaseStub
{
    ResetRows instanceReset;
    PreparedStatement statement;

    QueryResult Query(std::string_view sql)
    {
        assert(sql == "SELECT mapid, difficulty, resettime FROM instance_reset");
        if (instanceReset.empty())
            return nullptr;

        auto result = std::make_shared<ResultSet>();
        for (auto const& [key, time] : instanceReset)
            result->rows.push_back({ Field{ key.first }, Field{ key.second }, Field{ uint64(time) } });
        return result;
    }

    template <class... Args> void DirectExecute(std::string_view sql, Args... args)
    {
        std::vector<uint64> values{ uint64(args)... };
        if (sql.starts_with("INSERT INTO instance_reset VALUES"))
        {
            assert(values.size() == 3 && !instanceReset.contains(Key(values[0], values[1])));
            instanceReset[Key(values[0], values[1])] = time_t(values[2]);
        }
        else if (sql.starts_with("UPDATE instance_reset SET resettime"))
        {
            assert(values.size() == 3 && instanceReset.contains(Key(values[1], values[2])));
            instanceReset[Key(values[1], values[2])] = time_t(values[0]);
        }
        else
        {
            assert(sql.starts_with("DELETE FROM instance_reset WHERE") && values.size() == 2);
            instanceReset.erase(Key(values[0], values[1]));
        }
    }

    PreparedStatement* GetPreparedStatement(CharacterDatabaseStatements)
    {
        statement = {};
        return &statement;
    }

    void Execute(PreparedStatement* stmt)
    {
        assert(instanceReset.contains(Key(stmt->data[1], stmt->data[2])));
        instanceReset[Key(stmt->data[1], stmt->data[2])] = time_t(stmt->data[0]);
    }
} CharacterDatabase;

using GuidList = std::list<uint64>;

struct InstanceSave
{
    uint32 mapId;
    Difficulty difficulty;
    GuidList m_playerList;
    uint32 GetMapId() const { return mapId; }
    Difficulty GetDifficulty() const { return difficulty; }
};

enum InstanceResetMethod { INSTANCE_RESET_GLOBAL = 2 };

struct InstanceMap;

struct Map
{
    uint32 instanceId = 0;
    Difficulty difficulty = DUNGEON_DIFFICULTY_NORMAL;
    bool IsDungeon() const { return true; }
    Difficulty GetDifficulty() const { return difficulty; }
    uint32 GetInstanceId() const { return instanceId; }
    InstanceMap* ToInstanceMap();
};

struct InstanceMap : Map
{
    std::vector<uint32> warnings;
    std::vector<time_t> resets;
    void SendResetWarnings(uint32 timeLeft) { warnings.push_back(timeLeft); }
    bool Reset(uint8 method, GuidList*)
    {
        assert(method == INSTANCE_RESET_GLOBAL);
        resets.push_back(clockNow);
        return true;
    }
};

InstanceMap* Map::ToInstanceMap() { return static_cast<InstanceMap*>(this); }

struct MapInstanced : Map
{
    typedef std::unordered_map<uint32, Map*> InstancedMaps;
    InstancedMaps maps;
    InstancedMaps& GetInstancedMaps() { return maps; }
};

struct MapMgr
{
    std::map<uint32, MapInstanced> bases;
    Map* CreateBaseMap(uint32 id) { return &bases[id]; }
} mapMgr;
MapMgr* sMapMgr = &mapMgr;

struct WorldPacket { };
struct Player { void SendRaidInfo() { } };

struct WorldSession
{
    Player* GetPlayer() { return nullptr; }
    void HandleCalendarGetCalendar(WorldPacket&) { }
};

struct WorldSessionMgr
{
    typedef std::unordered_map<uint32, WorldSession*> SessionMap;
    SessionMap sessions;
    SessionMap const& GetAllSessions() const { return sessions; }
} sessionMgr;
WorldSessionMgr* sWorldSessionMgr = &sessionMgr;

// ACTUAL_RESET_TIME_MAP

class InstanceSaveMgr
{
public:
    typedef std::unordered_map<uint32, InstanceSave*> InstanceSaveHashMap;

// ACTUAL_EVENT

// ACTUAL_ACCESSORS

    static uint32 GetResetDelayFor(uint32 mapid, Difficulty d);
    void LoadResetTimes();
    void ScheduleReset(time_t time, InstResetEvent event);
    void Update();
    void _ResetOrWarnAll(uint32 mapid, Difficulty difficulty, bool warn, time_t resetTime);

    void _ResetSave(InstanceSaveHashMap::iterator& itr)
    {
        resetSaves.emplace_back(itr->first, clockNow);
        m_instanceSaveById.erase(itr);
    }

    InstanceSave* GetInstanceSave(uint32 id)
    {
        auto itr = m_instanceSaveById.find(id);
        return itr == m_instanceSaveById.end() ? nullptr : itr->second;
    }

    static uint16 ResetTimeDelay[];
    InstanceSaveHashMap m_instanceSaveById;
    ResetTimeByMapDifficultyMap m_resetTimeByMapDifficulty;
    ResetTimeByMapDifficultyMap m_resetExtendedTimeByMapDifficulty;
    ResetTimeQueue m_resetTimeQueue;
    std::vector<std::pair<uint32, time_t>> resetSaves;
};

// ACTUAL_METHODS

struct DifficultyRow
{
    uint32 mapId;
    uint32 difficulty;
    uint32 raidDuration;
};

struct MapRow
{
    uint32 mapId;
    uint32 mapType;
};

struct FallbackCase
{
    uint32 raidDuration;
    uint32 mapId;
    MapTypes mapType;
    Difficulty difficulty;
    uint32 expected;
};

struct Scenario
{
    uint32 resetHour;
    time_t now;
    std::vector<MapRow> maps;
    std::vector<DifficultyRow> difficulties;
    ResetRows stored;
    ResetRows expected;
};

#include "expected.h"

void Load(Scenario const& scenario)
{
    sMapStore.entries.clear();
    sMapDifficultyMap.clear();
    for (MapRow const& row : scenario.maps)
        sMapStore.entries[row.mapId] = MapEntry{ row.mapType };
    for (DifficultyRow const& row : scenario.difficulties)
    {
        uint32 key = MAKE_PAIR32(uint16(row.mapId), uint16(row.difficulty));
        sMapDifficultyMap[key] = MapDifficulty(row.raidDuration, 25, false);
    }
    CharacterDatabase.instanceReset = scenario.stored;
    world.resetHour = scenario.resetHour;
    clockNow = scenario.now;
    loggedErrors = 0;
}

void CheckSchedule(InstanceSaveMgr const& mgr, ResetRows const& expected)
{
    assert(CharacterDatabase.instanceReset == expected);
    assert(mgr.m_resetTimeQueue.size() == expected.size());
    for (auto const& [key, time] : expected)
    {
        Difficulty difficulty = Difficulty(key.second);
        assert(mgr.GetResetTimeFor(key.first, difficulty) == time);
        std::size_t events = 0;
        for (auto const& [eventTime, event] : mgr.m_resetTimeQueue)
        {
            if (event.mapid != key.first || event.difficulty != difficulty)
                continue;

            assert(eventTime == time - 3600 && event.type == 1);
            ++events;
        }
        assert(events == 1);
    }
}

void AdvanceTo(InstanceSaveMgr& mgr, time_t target)
{
    while (!mgr.m_resetTimeQueue.empty() && mgr.m_resetTimeQueue.begin()->first < target)
    {
        clockNow = mgr.m_resetTimeQueue.begin()->first + 1;
        mgr.Update();
    }
    clockNow = target;
    mgr.Update();
}

std::vector<time_t> Reset(uint32 instanceId, InstanceSaveMgr const& mgr)
{
    std::vector<time_t> times;
    for (auto const& [id, time] : mgr.resetSaves)
        if (id == instanceId)
            times.push_back(time);
    return times;
}

int main()
{
    for (FallbackCase const& c : FallbackCases)
        assert(InstanceResetSchedule::GetResetDelay(c.raidDuration, c.mapId, c.mapType, c.difficulty) == c.expected);

    InstanceSaveMgr mgr;
    Load(StaleRows);
    mgr.LoadResetTimes();
    assert(loggedErrors == 1);
    InstanceSave expired{ MoltenCore.first, Difficulty(MoltenCore.second), {} };
    mgr.m_instanceSaveById[100] = &expired;
    clockNow = StaleRows.now + 1;
    mgr.Update();
    assert(Reset(100, mgr) == std::vector<time_t>{ StaleRows.now + 1 } && !mgr.GetInstanceSave(100));
    CheckSchedule(mgr, StaleRows.expected);

    std::array<InstanceSave, 4> saves{ {
        { MoltenCore.first, Difficulty(MoltenCore.second), {} },
        { ZulGurub.first, Difficulty(ZulGurub.second), {} },
        { HeroicDungeon.first, Difficulty(HeroicDungeon.second), {} },
        { ConfiguredRaid.first, Difficulty(ConfiguredRaid.second), {} },
    } };
    std::array<InstanceMap, 4> maps;
    for (uint32 i = 0; i < saves.size(); ++i)
    {
        uint32 instanceId = 101 + i;
        mgr.m_instanceSaveById[instanceId] = &saves[i];
        maps[i].instanceId = instanceId;
        maps[i].difficulty = saves[i].difficulty;
        mapMgr.bases[saves[i].mapId].maps[instanceId] = &maps[i];
    }

    AdvanceTo(mgr, SimulationEnd);

    std::vector<uint32> const warnings{ 3599, 899, 299, 59 };
    assert(maps[0].warnings == warnings && maps[0].resets == std::vector<time_t>{ MoltenCoreReset + 1 });
    assert(Reset(101, mgr) == std::vector<time_t>{ MoltenCoreReset + 1 });
    assert(maps[1].warnings == warnings && maps[1].resets == std::vector<time_t>{ ZulGurubReset + 1 });
    assert(Reset(102, mgr) == std::vector<time_t>{ ZulGurubReset + 1 });
    std::vector<time_t> heroicResets;
    for (time_t reset : HeroicDungeonResets)
        heroicResets.push_back(reset + 1);
    assert(maps[2].resets == heroicResets && maps[2].warnings.size() == 4 * heroicResets.size());
    assert(Reset(103, mgr) == std::vector<time_t>{ heroicResets.front() });
    assert(maps[3].warnings.empty() && maps[3].resets.empty() && Reset(104, mgr).empty());
    assert(loggedErrors == 1);
    CheckSchedule(mgr, AfterSimulation);
    assert(mgr.GetExtendedResetTimeFor(MoltenCore.first, Difficulty(MoltenCore.second)) == MoltenCoreExtendedReset);

    for (Scenario const& scenario : ClientDbc)
    {
        InstanceSaveMgr client;
        Load(scenario);
        client.LoadResetTimes();
        assert(loggedErrors == 0);
        CheckSchedule(client, scenario.expected);
    }
    return 0;
}
