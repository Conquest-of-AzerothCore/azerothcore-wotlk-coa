#include <algorithm>
#include <array>
#include <atomic>
#include <cassert>
#include <chrono>
#include <compare>
#include <cstdint>
#include <iostream>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>

using uint8 = uint8_t;
using uint32 = uint32_t;
using int32 = int32_t;
using int64 = int64_t;
constexpr uint32 GOLD = 10000;
constexpr uint32 MAX_MONEY_AMOUNT = 0x7FFFFFFE;
constexpr uint8 MAX_RAID_DIFFICULTY = 4;
enum Difficulty : uint8 { Normal, Heroic, Mythic, Ascended };
enum { GOSSIP_ICON_CHAT, GOSSIP_SENDER_MAIN, WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD };

struct ObjectGuid
{
    uint32 id = 0;
    auto operator<=>(ObjectGuid const&) const = default;
    uint32 GetCounter() const { return id; }
    static ObjectGuid const Empty;
};
ObjectGuid const ObjectGuid::Empty{};
template<> struct std::hash<ObjectGuid>
{
    std::size_t operator()(ObjectGuid guid) const { return guid.id; }
};

struct Statement
{
    std::array<uint32, 2> data{};
    void SetData(uint32 index, uint32 value) { data.at(index) = value; }
};
struct Transaction
{
    std::vector<std::unique_ptr<Statement>> deletions;
    std::pair<uint32, uint32> money{};
    void Append(Statement* statement) { deletions.emplace_back(statement); }
};
using CharacterDatabaseTransaction = std::shared_ptr<Transaction>;
constexpr int CHAR_DEL_CHAR_INSTANCE_BY_INSTANCE_GUID = 1;
struct Database
{
    std::set<std::pair<uint32, uint32>> bindings;
    std::map<uint32, uint32> balances;
    int commits = 0;
    auto BeginTransaction() { return std::make_shared<Transaction>(); }
    Statement* GetPreparedStatement(int) { return new Statement; }
    void CommitTransaction(CharacterDatabaseTransaction transaction)
    {
        for (auto const& statement : transaction->deletions)
            bindings.erase({statement->data[0], statement->data[1]});
        balances[transaction->money.first] = transaction->money.second;
        ++commits;
    }
} CharacterDatabase;

struct Map
{
    bool instance = false;
    bool Instanceable() const { return instance; }
};
struct MapEntry
{
    bool raid = false;
    bool IsRaid() const { return raid; }
};
struct MapStore
{
    std::map<uint32, MapEntry> rows{{409, {true}}, {469, {true}}, {229, {false}}};
    MapEntry const* LookupEntry(uint32 id) const
    {
        auto found = rows.find(id);
        return found == rows.end() ? nullptr : &found->second;
    }
} sMapStore;
struct WorldSession
{
    bool bot = false;
    std::vector<std::string> messages;
    bool IsBot() const { return bot; }
};
struct TalkClass
{
    std::vector<uint32> actions;
    uint32 GetGossipOptionAction(uint32 index) const { return actions.at(index); }
};
struct Group
{
    struct MemberSlot { ObjectGuid guid; };
    ObjectGuid guid{70};
    ObjectGuid leader{1};
    bool raid = true;
    std::vector<MemberSlot> members;
    bool isRaidGroup() const { return raid; }
    bool IsLeader(ObjectGuid value) const { return value == leader; }
    ObjectGuid GetGUID() const { return guid; }
    auto const& GetMemberSlots() const { return members; }
};
struct Player
{
    ObjectGuid guid{1};
    WorldSession session;
    TalkClass talk;
    TalkClass* PlayerTalkClass = &talk;
    Map map;
    Group* group = nullptr;
    uint32 money = 500000;
    bool online = true, alive = true, combat = false, teleport = false;
    bool IsInWorld() const { return online; }
    bool IsAlive() const { return alive; }
    bool IsInCombat() const { return combat; }
    bool IsBeingTeleported() const { return teleport; }
    Map* FindMap() { return &map; }
    Map* GetMap() { return &map; }
    Group* GetGroup() { return group; }
    WorldSession* GetSession() { return &session; }
    ObjectGuid GetGUID() const { return guid; }
    uint32 GetMoney() const { return money; }
    bool ModifyMoney(int32 amount) { money += amount; return true; }
    void SaveGoldToDB(CharacterDatabaseTransaction transaction) { transaction->money = {guid.id, money}; }
};
namespace ObjectAccessor
{
std::map<ObjectGuid, Player*> players;
Player* FindConnectedPlayer(ObjectGuid guid)
{
    auto found = players.find(guid);
    return found == players.end() || !found->second->online ? nullptr : found->second;
}
}
struct InstanceSave
{
    uint32 id;
    uint32 encounters = 3;
    uint32 GetInstanceId() const { return id; }
};
struct InstancePlayerBind { InstanceSave* save; };
using BoundInstancesMap = std::unordered_map<uint32, InstancePlayerBind>;
struct InstanceSaveMgr
{
    std::map<ObjectGuid, std::array<BoundInstancesMap, 4>> binds;
    std::vector<std::unique_ptr<InstanceSave>> saves;
    std::vector<ObjectGuid> calendarUpdates;
    auto const& PlayerGetBoundInstances(ObjectGuid guid, Difficulty mode) { return binds[guid][mode]; }
    void PlayerUnbindInstance(ObjectGuid guid, uint32 map, Difficulty mode, bool deleteFromDB, Player* player)
    {
        assert(!deleteFromDB && player && !player->map.instance);
        binds[guid][mode].erase(map);
        calendarUpdates.push_back(guid);
    }
} manager;
InstanceSaveMgr* sInstanceSaveMgr = &manager;

struct Config
{
    int64 gold = 10;
    template<class T> T GetOption(char const*, T) { return T(gold); }
} config;
Config* sConfigMgr = &config;
struct WorldScript
{
    WorldScript(char const*, std::initializer_list<int>) { }
    virtual ~WorldScript() = default;
    virtual void OnStartup() { }
    virtual void OnAfterConfigLoad(bool) { }
};
struct Creature { ObjectGuid GetGUID() const { return {9990501}; } };
struct ScriptedAI
{
    Creature* me;
    explicit ScriptedAI(Creature* creature) : me(creature) { }
    virtual ~ScriptedAI() = default;
    virtual void sGossipHello(Player*) { }
    virtual void sGossipSelect(Player*, uint32, uint32) { }
};
struct ChatHandler
{
    WorldSession* session;
    explicit ChatHandler(WorldSession* value) : session(value) { }
    void SendSysMessage(char const* message) { session->messages.emplace_back(message); }
};
namespace Acore
{
template<class... T> std::string StringFormat(char const* value, T const&...) { return value; }
}
void ClearGossipMenuFor(Player* player) { player->talk.actions.clear(); }
void CloseGossipMenuFor(Player*) { }
void SendGossipMenuFor(Player*, uint32, ObjectGuid) { }
void AddGossipItemFor(Player* player, int, std::string const&, int, uint32 action,
                     std::string const& = "", uint32 = 0, bool = false)
{
    player->talk.actions.push_back(action);
}
#define RegisterCreatureAI(name) static_cast<void>(sizeof(name))
