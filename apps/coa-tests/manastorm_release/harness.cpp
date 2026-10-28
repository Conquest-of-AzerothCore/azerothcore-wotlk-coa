#include <algorithm>
#include <chrono>
#include <ctime>
#include <array>
#include <cstdint>
#include <iostream>
#include <limits>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>
using uint8 = uint8_t;
using uint32 = uint32_t;
using uint64 = uint64_t;
using Guid = uint32;
struct ObjectGuid { using LowType = uint32; uint32 value; uint32 GetCounter() const { return value; } operator uint32() const { return value; } };
namespace ManastormModuleConfig { bool enabled = true; uint32 cap = 5; bool WeeklyCacheLockoutEnabled() { return enabled; } uint32 WeeklyCacheLockoutLimit() { return cap; } }
namespace ManastormLimits { constexpr uint32 MaxMembers = 5; }
constexpr uint32 CONFIG_MAX_PLAYER_LEVEL = 0;
using Seconds = std::chrono::seconds;
namespace GameTime { Seconds now{1000}; Seconds GetGameTime() { return now; } }
namespace Acore::Time { std::time_t GetNextTimeWithDayAndHour(int, int, std::time_t) { return 2000; } }
struct World {
    Seconds reset{2000};
    uint32 getIntConfig(uint32) { return 80; }
    Seconds GetNextWeeklyQuestsResetTime() const { return reset; }
} world;
auto* sWorld = &world;
struct Map { } map;
struct Item { uint32 entry; uint32 GetEntry() const { return entry; } };
struct Group;
struct Player {
    Guid guid = 1;
    uint32 level = 60, worldMap = 0, best = 100, team = 0;
    bool online = true, alive = true, teleport = false, flight = false, battleground = false;
    bool arena = false, combat = false, cooldown = false, challenge = false, active = false;
    void* duel = nullptr;
    Group* group = nullptr;
    uint32 notices = 0;
    ObjectGuid GetGUID() const { return {guid}; }
    Group* GetGroup() const { return group; }
    uint32 GetLevel() const { return level; }
    bool IsInWorld() const { return online; }
    Map* FindMap() const { return &map; }
    bool IsAlive() const { return alive; }
    bool IsBeingTeleported() const { return teleport; }
    bool IsInFlight() const { return flight; }
    bool InBattleground() const { return battleground; }
    bool InArena() const { return arena; }
    bool IsInCombat() const { return combat; }
    bool HasAura(uint32) const { return cooldown; }
    bool IsWithinDistInMap(Player const* other, float) const { return worldMap == other->worldMap; }
    void SendSystemMessage(char const*) { ++notices; }
};
struct Group {
    struct MemberSlot { Guid guid; };
    Guid leader = 1;
    std::vector<MemberSlot> members;
    bool IsLeader(Guid guid) const { return leader == guid; }
    uint32 GetMembersCount() const { return uint32(members.size()); }
    auto const& GetMemberSlots() const { return members; }
};
std::unordered_map<Guid, Player*> players;
namespace ObjectAccessor { Player* FindConnectedPlayer(Guid guid) { auto i = players.find(guid); return i == players.end() ? nullptr : i->second; } }
struct ScriptMgr { bool OnPlayerCanEnterManastorm(Player* player) { return !player->challenge; } } scripts;
auto* sScriptMgr = &scripts;
struct ManastormMgr {
    static ManastormMgr& Instance() { static ManastormMgr value; return value; }
    bool GetRunFor(Player* player) const { return player && player->active; }
};
uint8 ManastormModeForMemberCount(uint32 n) { return uint8(std::min(n, 4u)); }
uint8 ManastormGetTrackBit(bool endgame) { return endgame ? 2 : 1; }
struct ManastormProgressionSnapshot { uint32 best = 0; };
namespace ManastormProgression {
    bool LoadSnapshot(Guid guid, uint8, bool, ManastormProgressionSnapshot& value, std::string&) {
        Player* player = ObjectAccessor::FindConnectedPlayer(guid);
        if (!player) return false;
        value.best = player->best;
        return true;
    }
    bool IsDepthEnterable(ManastormProgressionSnapshot const& value, uint32 depth) { return depth == 1 || depth <= value.best; }
}
struct Field { uint32 value = 0; template<class T> T Get() const { return T(value); } };
struct Result { std::array<Field,2> fields; Field* Fetch() { return fields.data(); } };
using PreparedQueryResult = std::shared_ptr<Result>;
enum { CHAR_SEL_MANASTORM_WEEKLY_CACHE, CHAR_INS_MANASTORM_WEEKLY_CACHE };
struct Statement {
    uint32 id = 0;
    std::array<uint32,5> values{};
    void SetData(uint32 index, uint32 value) { values[index] = value; }
};
struct Transaction {
    std::vector<Statement> statements;
    void Append(Statement* statement) { statements.push_back(*statement); }
};
using CharacterDatabaseTransaction = std::shared_ptr<Transaction>;
struct Database {
    bool available = true;
    uint32 earned = 0, savedReset = 2000, queries = 0;
    Statement statement;
    Statement* GetPreparedStatement(uint32 id) { statement = {}; statement.id = id; return &statement; }
    PreparedQueryResult Query(Statement*) { ++queries; return available ? std::make_shared<Result>(Result{{Field{savedReset},Field{earned}}}) : nullptr; }
} CharacterDatabase;
uint32 roll = 1;
uint32 urand(uint32, uint32) { return roll; }
constexpr uint32 CACHE_PITY_STEP_PCT = 13;
struct ManastormRewardStateSnapshot { uint32 CacheChancePct = 0; };
struct ManastormWeeklyCacheAllowance;
constexpr uint32 GAME_MODE_WILDCARD = 0x0040;
struct ManastormRewards {
    struct CacheBracket { uint32 CacheItemEntry; };
    std::vector<CacheBracket> _cacheBrackets = {{1278050},{1278050},{1278079}};
    struct PotentialReward { uint32 ItemEntry; bool Enabled = true; };
    std::vector<PotentialReward> _potentialRewards = {{97884,true},{1478052,true}};
    uint32 GetActiveGameModeMask(uint32) const { return 0; }
    std::vector<ManastormRewardVisibilityRecord> BuildVisibilityRecords(ObjectGuid::LowType,bool,uint32 = 0) const;
    bool LoadWeeklyCacheAllowance(ObjectGuid::LowType, ManastormWeeklyCacheAllowance&) const;
    bool PrepareNormalCacheReward(ObjectGuid::LowType,bool, ManastormRewardStateSnapshot const&,
        CharacterDatabaseTransaction const&, bool&, uint32&, ManastormWeeklyCacheAllowance&, std::string&) const;
};
// ACTUAL_METHODS
uint32 checks = 0, failures = 0;
void check(bool condition, char const* label) { ++checks; if (!condition) { ++failures; std::cerr << label << '\n'; } }
int main() {
    Player leader;
    Group group;
    leader.group = &group;
    std::array<Player,4> others;
    players[1] = &leader;
    group.members.push_back({1});
    for (uint32 i = 0; i < others.size(); ++i) {
        others[i].guid = i + 2;
        others[i].worldMap = i + 1;
        others[i].team = 1;
        others[i].group = &group;
        players[i + 2] = &others[i];
        group.members.push_back({i + 2});
        check(ValidateEnter(&leader,1) == nullptr, "Remote mixed-faction group must enter without proximity restriction");
    }
    others[0].best = 1;
    check(ValidateEnter(&leader,1) == nullptr, "Leader 100/member 1 can enter depth 1");
    check(ValidateEnter(&leader,100) != nullptr, "Leader cannot bypass the least-progressed member");
    others[0].online = false;
    check(ValidateEnter(&leader,1) != nullptr, "Offline member blocked");
    others[0].online = true; others[0].combat = true;
    check(ValidateEnter(&leader,1) != nullptr, "Combat member blocked");
    others[0].combat = false; others[0].challenge = true;
    check(ValidateEnter(&leader,1) != nullptr, "Challenge restriction retained");
    others[0].challenge = false; others[0].active = true;
    check(ValidateEnter(&leader,1) != nullptr, "Existing member run blocked");
    others[0].active = false; group.leader = 2;
    check(ValidateEnter(&leader,1) != nullptr, "Nonleader blocked");
    group.leader = 1;
    check(ValidateEnter(&leader,0) != nullptr, "Zero depth blocked");
    group.members.push_back({6});
    check(ValidateEnter(&leader,1) != nullptr, "Oversized group blocked");
    ManastormRewards rewards;
    ManastormRewardStateSnapshot state;
    ManastormWeeklyCacheAllowance allowance;
    bool won = false;
    uint32 next = 0;
    std::string error;
    for (uint32 earned = 0; earned < 5; ++earned) {
        CharacterDatabase.earned = earned;
        state.CacheChancePct = 100;
        auto transaction = std::make_shared<Transaction>();
        check(rewards.PrepareNormalCacheReward(1,true,state,transaction,won,next,allowance,error), "Allowance readable");
        check(won && next == 0 && allowance.Earned == earned + 1, "Available normal cache awarded and pity reset");
        check(transaction->statements.size() == 1 && transaction->statements[0].values[2] == earned + 1,
            "Counter updated in caller transaction");
    }
    CharacterDatabase.earned = 5;
    auto transaction = std::make_shared<Transaction>();
    check(rewards.PrepareNormalCacheReward(1,true,state,transaction,won,next,allowance,error), "Capped completion remains allowed");
    check(!won && next == 100 && transaction->statements.empty(), "Cap preserves pity without spending another slot");
    CharacterDatabase.earned = 0;
    state.CacheChancePct = 13;
    roll = 100;
    check(rewards.PrepareNormalCacheReward(1,true,state,transaction,won,next,allowance,error), "Missed roll completes");
    check(!won && next == 26 && transaction->statements.empty(), "Miss increases pity without spending allowance");
    CharacterDatabase.available = false;
    check(!rewards.PrepareNormalCacheReward(1,true,state,transaction,won,next,allowance,error), "Database error cannot bypass cap");
    uint32 const queriesBeforeNormal = CharacterDatabase.queries;
    state.CacheChancePct = 100;
    check(rewards.PrepareNormalCacheReward(1,false,state,transaction,won,next,allowance,error) && won,
        "Normal track stays exempt at any player level even if weekly database is unavailable");
    check(CharacterDatabase.queries == queriesBeforeNormal && transaction->statements.empty(),
        "Normal track neither reads nor consumes weekly quota");
    ManastormModuleConfig::enabled = false;
    ManastormModuleConfig::cap = 0;
    state.CacheChancePct = 100;
    check(rewards.PrepareNormalCacheReward(1,true,state,transaction,won,next,allowance,error) && won,
        "Disabled lockout preserves uncapped behavior");
    check(transaction->statements.empty(), "Disabled cap reserves no allowance slot");
    ManastormModuleConfig::enabled = true;
    CharacterDatabase.available = true;
    check(rewards.PrepareNormalCacheReward(1,true,state,transaction,won,next,allowance,error) && !won,
        "Enabled zero limit blocks every regular endgame cache");
    check(next == 100 && transaction->statements.empty(), "Enabled zero limit preserves pity");
    ManastormModuleConfig::cap = 5;
    world.reset = Seconds(900);
    check(rewards.LoadWeeklyCacheAllowance(1,allowance) && allowance.ResetTime == 2000,
        "Expired core schedule advances to the next core reset boundary");
    world.reset = Seconds(3000);
    check(rewards.LoadWeeklyCacheAllowance(1,allowance) && allowance.ResetTime == 3000,
        "Future persisted core reset retained");
    CharacterDatabase.savedReset = 3000;
    CharacterDatabase.earned = 4;
    auto records = rewards.BuildVisibilityRecords(1,true);
    check(records.size() == 4 && records[2].ItemEntry == 1278050 && records[3].ItemEntry == 1278079,
        "Configured physical cache IDs receive one allowance record each");
    check(records[2].EarnedQuantity == 4 && records[2].RemainingQuantity == 1,
        "Active tracker sees allowance under its physical cache item ID");
    check(records[0].Action == 0 && records[0].RemainingQuantity == 1 && records[0].MaxQuantity == 5,
        "Native icon shows remaining allowance before cap");
    CharacterDatabase.earned = 5;
    records = rewards.BuildVisibilityRecords(1,true);
    check(records[0].Action == 2 && records[0].RemainingQuantity == 0 && records[0].LockEndTimestamp == 3000,
        "Native normal-cache icon locks until reset at cap");
    check(records[2].Action == 2 && records[3].Action == 2 && records[2].MaxQuantity == 5,
        "All configured cache tiers share the native exhausted state");
    check(records[1].Action == 0 && records[1].MaxQuantity == 0, "Bonus reward visibility remains exempt");
    CharacterDatabase.available = false;
    records = rewards.BuildVisibilityRecords(1,true);
    check(records[0].Action == 2 && records[0].RemainingQuantity == 0, "Database failure cannot display earnable caches");
    ManastormModuleConfig::enabled = false;
    records = rewards.BuildVisibilityRecords(1,true);
    check(records[0].Action == 0 && records[0].MaxQuantity == 0, "Disabled cap clears native lock state");
    ManastormModuleConfig::enabled = true;
    CharacterDatabase.available = true;
    CharacterDatabase.earned = 5;
    records = rewards.BuildVisibilityRecords(1,false);
    check(records[0].Action == 0 && records[2].Action == 0 && records[0].MaxQuantity == 0,
        "Normal-track UI stays unlocked even when endgame quota is exhausted");
    records = rewards.BuildVisibilityRecords(1,true,1);
    check(records[0].Action == 2 && records[2].Action == 0 && records[2].EarnedQuantity == 5,
        "Regular queue cache stays locked while guaranteed bonus tracker remains available");
    CharacterDatabase.savedReset = 2000;
    check(rewards.LoadWeeklyCacheAllowance(1,allowance) && allowance.Earned == 0 && allowance.SavedEarned == 5,
        "Expired counter reads as zero without discarding saved compare-and-swap state");
    check(rewards.PrepareNormalCacheReward(1,true,state,transaction,won,next,allowance,error) && won,
        "New week restores regular endgame eligibility");
    check(transaction->statements.back().values[1] == 3000 && transaction->statements.back().values[2] == 1 &&
        transaction->statements.back().values[3] == 2000 && transaction->statements.back().values[4] == 5,
        "New-period counter includes the prior state for concurrency protection");
    std::cout << checks << " production Manastorm checks, " << failures << " failures\n";
    return failures ? 1 : 0;
}
