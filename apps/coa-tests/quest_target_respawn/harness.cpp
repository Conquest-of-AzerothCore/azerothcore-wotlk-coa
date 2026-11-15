#include <cstdint>
#include <cstdio>
#include <initializer_list>
#include <map>
#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

using uint8 = std::uint8_t;
using int32 = std::int32_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;

template <typename... Args> void LOG_INFO(Args const&...) { }
inline uint32 getMSTime() { return 0; }
inline uint32 GetMSTimeDiffToNow(uint32) { return 0; }

constexpr uint32 CREATURE_ELITE_NORMAL = 0;
constexpr uint32 CREATURE_ELITE_ELITE = 1;
constexpr uint32 CREATURE_ELITE_RAREELITE = 2;
constexpr uint32 CREATURE_ELITE_RARE = 4;
constexpr uint32 CREATURE_TYPE_FLAG_QUEST_BOSS = 0x80000000;
#define QUEST_OBJECTIVES_COUNT 4
#define MAX_KILL_CREDIT 2

enum class QuestTargetRespawn : uint8 { None, General, Named };

struct Field
{
    uint32 value;
    template <typename T> T Get() const { return T(value); }
};

struct ResultSet
{
    std::vector<uint32> rows;
    std::size_t index = 0;
    Field field{};
    Field* Fetch() { field.value = rows[index]; return &field; }
    bool NextRow() { return ++index < rows.size(); }
};
using QueryResult = std::shared_ptr<ResultSet>;

struct WorldDatabaseStub
{
    std::vector<uint32> questLootIds;
    std::string lastQuery;
    QueryResult Query(char const* sql)
    {
        lastQuery = sql;
        if (questLootIds.empty())
            return nullptr;
        auto result = std::make_shared<ResultSet>();
        result->rows = questLootIds;
        return result;
    }
} WorldDatabase;

struct MapEntry
{
    bool world;
    bool IsWorldMap() const { return world; }
};

struct MapStore
{
    std::map<uint32, MapEntry> maps;
    MapEntry const* LookupEntry(uint32 id) const
    {
        auto itr = maps.find(id);
        return itr == maps.end() ? nullptr : &itr->second;
    }
} sMapStore;

struct Creature;
struct PoolMgrStub
{
    std::unordered_map<uint32, uint32> creaturePools;
    template <typename T> uint32 IsPartOfAPool(uint32 spawnId) const
    {
        auto itr = creaturePools.find(spawnId);
        return itr == creaturePools.end() ? 0 : itr->second;
    }
} poolMgr;
PoolMgrStub* sPoolMgr = &poolMgr;

struct Quest
{
    int32 RequiredNpcOrGo[QUEST_OBJECTIVES_COUNT] = {};
};

struct CreatureData
{
    uint32 id = 0;
    uint32 id2 = 0;
    uint32 id3 = 0;
    uint32 mapid = 0;
};

struct CreatureTemplate
{
    uint32 rank = CREATURE_ELITE_NORMAL;
    uint32 type_flags = 0;
    uint32 KillCredit[MAX_KILL_CREDIT] = {};
    uint32 lootid = 0;
};

using CreatureQuestItemList = std::vector<uint32>;

struct ObjectMgr
{
    std::unordered_map<uint32, QuestTargetRespawn> _questTargetRespawnStore;
    std::unordered_map<uint32, Quest*> _questTemplates;
    std::unordered_map<uint32, CreatureData> _creatureDataStore;
    std::unordered_map<uint32, CreatureTemplate> _creatureTemplateStore;
    std::unordered_map<uint32, CreatureQuestItemList> _creatureQuestItemStore;

    CreatureQuestItemList const* GetCreatureQuestItemList(uint32 id) const
    {
        auto itr = _creatureQuestItemStore.find(id);
        return itr == _creatureQuestItemStore.end() ? nullptr : &itr->second;
    }

    QuestTargetRespawn GetQuestTargetRespawn(uint32 entry) const
    {
        auto itr = _questTargetRespawnStore.find(entry);
        return itr != _questTargetRespawnStore.end() ? itr->second : QuestTargetRespawn::None;
    }

    void LoadQuestTargetRespawns();
};

LOAD_QUEST_TARGET_RESPAWNS

int main()
{
    constexpr uint32 Kalimdor = 1;
    constexpr uint32 Dungeon = 33;
    sMapStore.maps = { { 0, { true } }, { Kalimdor, { true } }, { Dungeon, { false } } };

    ObjectMgr mgr;
    uint32 nextSpawn = 1;
    auto creature = [&](uint32 entry, uint32 rank, bool flagged) -> CreatureTemplate&
    {
        CreatureTemplate& cinfo = mgr._creatureTemplateStore[entry];
        cinfo.rank = rank;
        cinfo.type_flags = flagged ? CREATURE_TYPE_FLAG_QUEST_BOSS : 0;
        return cinfo;
    };
    auto spawn = [&](uint32 entry, uint32 map, uint32 pool = 0, uint32 id2 = 0)
    {
        uint32 const spawnId = nextSpawn++;
        CreatureData& data = mgr._creatureDataStore[spawnId];
        data.id = entry;
        data.id2 = id2;
        data.mapid = map;
        if (pool)
            poolMgr.creaturePools[spawnId] = pool;
    };
    std::vector<std::unique_ptr<Quest>> quests;
    auto killQuest = [&](int32 target)
    {
        quests.push_back(std::make_unique<Quest>());
        quests.back()->RequiredNpcOrGo[2] = target;
        mgr._questTemplates[uint32(quests.size())] = quests.back().get();
    };

    creature(101, CREATURE_ELITE_NORMAL, true);
    spawn(101, Kalimdor);

    creature(102, CREATURE_ELITE_NORMAL, true);
    for (int i = 0; i < 3; ++i)
        spawn(102, 0, 500);

    creature(103, CREATURE_ELITE_NORMAL, true);
    spawn(103, 0, 501);
    spawn(103, 0, 502);

    creature(104, CREATURE_ELITE_NORMAL, true);
    for (int i = 0; i < 44; ++i)
        spawn(104, Kalimdor);

    creature(105, CREATURE_ELITE_RARE, true);
    spawn(105, 0);

    creature(106, CREATURE_ELITE_RAREELITE, true);
    spawn(106, Kalimdor);

    creature(107, CREATURE_ELITE_RARE, false);
    for (int i = 0; i < 3; ++i)
        spawn(107, 0);
    killQuest(107);

    creature(108, CREATURE_ELITE_NORMAL, true);
    spawn(108, Kalimdor);
    for (int i = 0; i < 5; ++i)
        spawn(108, Dungeon);

    creature(109, CREATURE_ELITE_NORMAL, true);

    creature(110, CREATURE_ELITE_NORMAL, true);
    spawn(110, 0);
    spawn(999, 0, 0, 110);

    creature(111, CREATURE_ELITE_NORMAL, false);
    spawn(111, 0);
    killQuest(111);

    creature(112, CREATURE_ELITE_NORMAL, false).KillCredit[1] = 912;
    spawn(112, 0);
    killQuest(912);

    creature(113, CREATURE_ELITE_NORMAL, false).lootid = 7113;
    spawn(113, 0);

    creature(114, CREATURE_ELITE_NORMAL, false).lootid = 7114;
    spawn(114, 0);

    creature(115, CREATURE_ELITE_NORMAL, false);
    spawn(115, 0);
    mgr._creatureQuestItemStore[115] = { 5115 };

    creature(116, CREATURE_ELITE_NORMAL, false);
    spawn(116, 0);

    creature(117, CREATURE_ELITE_ELITE, true);
    spawn(117, 0);

    creature(118, CREATURE_ELITE_NORMAL, false);
    spawn(118, 0);
    killQuest(-118);

    creature(119, CREATURE_ELITE_NORMAL, false);
    spawn(119, 0);
    mgr._creatureQuestItemStore[119] = {};

    creature(999, CREATURE_ELITE_NORMAL, false);

    WorldDatabase.questLootIds = { 7113 };
    mgr.LoadQuestTargetRespawns();

    std::printf("query=%s\n", WorldDatabase.lastQuery.c_str());
    for (uint32 entry = 101; entry <= 119; ++entry)
        std::printf("%u=%u\n", entry, uint32(mgr.GetQuestTargetRespawn(entry)));

    mgr._questTargetRespawnStore[555] = QuestTargetRespawn::Named;
    WorldDatabase.questLootIds.clear();
    mgr.LoadQuestTargetRespawns();
    std::printf("reload_stale=%u\n", uint32(mgr.GetQuestTargetRespawn(555)));
    std::printf("reload_no_loot_113=%u\n", uint32(mgr.GetQuestTargetRespawn(113)));
}
