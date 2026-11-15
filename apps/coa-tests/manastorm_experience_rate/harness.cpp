#include "Define.h"
#include "Config.h"
#include "Log.h"
#include "ManastormModuleConfig.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <memory>
#include <string>
#include <utility>
#include <vector>

void Check(bool passed, int line, char const* condition)
{
    if (passed)
        return;

    std::cout << "FAIL line " << line << ": " << condition << std::endl;
    std::exit(1);
}

#define CHECK(condition) Check((condition), __LINE__, #condition)

constexpr char const* LOG_FILTER = "module.manastorm.endless";
constexpr uint32 NPC_MANASTORM_HEART = 900025;
constexpr uint32 PLAYER_FLAGS_NO_XP_GAIN = 0x02000000;
constexpr uint32 PLAYER_FLAGS_NO_PLAY_TIME = 0x00400000;
enum ConfigIndex { CONFIG_MAX_PLAYER_LEVEL };
enum StatementIndex { CHAR_SEL_MANASTORM_XP_LEVEL, CHAR_ADD_MANASTORM_FLOOR_XP };
enum class HighGuid { Player };

struct ObjectGuid
{
    using LowType = uint32;
    uint64 raw = 0;
    template <HighGuid> static ObjectGuid Create(LowType low) { return { low }; }
    uint64 GetRawValue() const { return raw; }
    LowType GetCounter() const { return LowType(raw); }
};

struct Creature;

struct Unit
{
    Creature* creature = nullptr;
    Creature* ToCreature() { return creature; }
};

struct Creature : Unit
{
    uint32 entry = 1;
    uint32 mapId = 0;
    uint32 instanceId = 0;
    bool trigger = false;
    bool pet = false;
    bool controlled = false;
    Creature() { creature = this; }
    uint32 GetEntry() const { return entry; }
    bool IsTrigger() const { return trigger; }
    bool IsPet() const { return pet; }
    uint32 GetMapId() const { return mapId; }
    uint32 GetInstanceId() const { return instanceId; }
};

bool IsPlayerControlledCreature(Creature const* creature) { return creature->controlled; }

struct Player
{
    ObjectGuid guid;
    uint8 level = 30;
    uint32 flags = 0;
    uint32 mapId = 0;
    uint32 instanceId = 0;
    ObjectGuid GetGUID() const { return guid; }
    uint8 GetLevel() const { return level; }
    bool HasPlayerFlag(uint32 flag) const { return (flags & flag) != 0; }
    uint32 GetMapId() const { return mapId; }
    uint32 GetInstanceId() const { return instanceId; }
};

struct ManastormSegment
{
    uint32 SegmentId = 7;
    uint32 MapId = 43;
    float NativeExperienceFactor1 = 1.0f;
};

enum class ManastormRunState { Active, StageComplete, Finished };

struct ManastormRun
{
    ManastormRunState state = ManastormRunState::Active;
    ManastormSegment segment;
    uint32 depth = 1;
    uint32 instanceId = 9;
    std::vector<ObjectGuid::LowType> members;
    ManastormRunState GetState() const { return state; }
    ManastormSegment const& GetSegment() const { return segment; }
    uint32 GetDepth() const { return depth; }
    uint32 GetInstanceId() const { return instanceId; }
    uint32 GetRunId() const { return 1; }
    std::vector<ObjectGuid::LowType> const& GetMembers() const { return members; }
};

struct ManastormMgr
{
    ManastormRun* run = nullptr;
    ManastormRun* GetRunFor(Player*) { return run; }
    void OnPlayerGiveXP(Player* player, uint32& amount, Unit* victim, uint8 xpSource);
};

struct Field
{
    uint64 value = 0;
    template <class T> T Get() const { return T(value); }
};

struct ResultSet
{
    Field fields[2];
    Field* Fetch() { return fields; }
};

using PreparedQueryResult = std::shared_ptr<ResultSet>;

struct CharacterDatabasePreparedStatement
{
    uint32 index = 0;
    std::vector<uint64> data;
    template <class T> void SetData(uint8 position, T value)
    {
        data.resize(std::max<std::size_t>(data.size(), position + 1));
        data[position] = uint64(value);
    }
};

struct Transaction
{
    std::vector<CharacterDatabasePreparedStatement*> statements;
    void Append(CharacterDatabasePreparedStatement* statement) { statements.push_back(statement); }
};

using CharacterDatabaseTransaction = std::shared_ptr<Transaction>;

struct CharacterDatabaseStub
{
    std::vector<std::unique_ptr<CharacterDatabasePreparedStatement>> owned;
    CharacterDatabasePreparedStatement* GetPreparedStatement(uint32 index)
    {
        owned.push_back(std::make_unique<CharacterDatabasePreparedStatement>());
        owned.back()->index = index;
        return owned.back().get();
    }
    PreparedQueryResult Query(CharacterDatabasePreparedStatement*) { return nullptr; }
} CharacterDatabase;

std::vector<Player*> connectedPlayers;

namespace ObjectAccessor
{
    Player* FindConnectedPlayer(ObjectGuid guid)
    {
        for (Player* player : connectedPlayers)
            if (player->guid.raw == guid.raw)
                return player;
        return nullptr;
    }
}

struct WorldStub
{
    uint32 getIntConfig(ConfigIndex) const { return 60; }
} worldStub;
#define sWorld (&worldStub)

struct ScriptMgrStub
{
    void OnPlayerBeforeGetLevelForXPGain(Player*, uint8&) {}
} scriptMgrStub;
#define sScriptMgr (&scriptMgrStub)

struct Quest
{
    uint32 xp = 0;
    uint32 XPValue(uint8) const { return xp; }
};

Quest floorQuest{ 9300 };

struct ObjectMgrStub
{
    Quest const* GetQuestTemplate(uint32 id) const { return id == 24893 ? &floorQuest : nullptr; }
} objectMgrStub;
#define sObjectMgr (&objectMgrStub)

namespace lfg
{
    struct LfgReward
    {
        uint32 otherQuest = 24893;
    };
}

struct LFGMgrStub
{
    lfg::LfgReward reward;
    lfg::LfgReward const* GetRandomDungeonReward(uint32, uint8) const { return &reward; }
} lfgMgrStub;
#define sLFGMgr (&lfgMgrStub)

class ManastormExperience
{
public:
    bool PrepareCompletion(ManastormRun const& run, CharacterDatabaseTransaction const& transaction,
        std::string& error) const;
    bool _loaded = true;
    bool _enabled = true;
    uint32 _dungeonId = 258;
    double _multiplier = 1.0;
};

namespace
{
// ACTUAL_HELPERS
}

// ACTUAL_METHODS

bool RateIs(double expected)
{
    return std::fabs(ManastormModuleConfig::ExperienceRate() - expected) < 1e-6;
}

void SetRate(char const* value)
{
    if (value)
        sConfigMgr->values["Manastorm.ExperienceRate"] = value;
    else
        sConfigMgr->values.erase("Manastorm.ExperienceRate");
    ManastormModuleConfig::Load(true);
}

uint32 KillXP(ManastormMgr& mgr, Player& player, Creature& creature, uint32 amount)
{
    mgr.OnPlayerGiveXP(&player, amount, &creature, 0);
    return amount;
}

std::vector<uint64> FloorXP(ManastormExperience const& experience, ManastormRun const& run)
{
    CharacterDatabaseTransaction transaction = std::make_shared<Transaction>();
    std::string error;
    CHECK(experience.PrepareCompletion(run, transaction, error));
    std::vector<uint64> grants;
    for (CharacterDatabasePreparedStatement* statement : transaction->statements)
    {
        CHECK(statement->index == CHAR_ADD_MANASTORM_FLOOR_XP);
        grants.push_back(statement->data[1]);
    }
    return grants;
}

int main()
{
    ManastormModuleConfig::Load(false);
    CHECK(RateIs(0.3));
    CHECK(ManastormModuleConfig::IsNativeClientMode());
    CHECK(LogErrors() == 0);

    SetRate("0.5");
    CHECK(RateIs(0.5));
    SetRate("-1");
    CHECK(RateIs(0.3));
    CHECK(LogErrors() == 1);
    SetRate("nan");
    CHECK(RateIs(0.3));
    CHECK(LogErrors() == 2);
    SetRate("0");
    CHECK(RateIs(0.0));
    SetRate(nullptr);
    CHECK(RateIs(0.3));
    std::cout << "PASS: Manastorm.ExperienceRate defaults to 0.3, reloads, and rejects negative or NaN values."
        << std::endl;

    ManastormRun run;
    run.members = { 11, 12 };
    ManastormMgr mgr;
    mgr.run = &run;
    Player player{ { 11 }, 30, 0, run.segment.MapId, run.instanceId };
    Creature creature;
    creature.mapId = run.segment.MapId;
    creature.instanceId = run.instanceId;

    CHECK(KillXP(mgr, player, creature, 1000) == 300);
    run.depth = 101;
    CHECK(KillXP(mgr, player, creature, 1000) == 390);
    run.depth = 1;
    run.segment.NativeExperienceFactor1 = 2.0f;
    CHECK(KillXP(mgr, player, creature, 1000) == 600);
    run.segment.NativeExperienceFactor1 = 1.0f;
    run.state = ManastormRunState::StageComplete;
    CHECK(KillXP(mgr, player, creature, 1000) == 300);
    run.state = ManastormRunState::Active;

    uint32 questXP = 1000;
    mgr.OnPlayerGiveXP(&player, questXP, nullptr, 0);
    CHECK(questXP == 1000);
    creature.mapId = 1;
    CHECK(KillXP(mgr, player, creature, 1000) == 1000);
    creature.mapId = run.segment.MapId;
    mgr.run = nullptr;
    CHECK(KillXP(mgr, player, creature, 1000) == 1000);
    mgr.run = &run;

    SetRate("1");
    CHECK(KillXP(mgr, player, creature, 1000) == 1000);
    SetRate("0");
    CHECK(KillXP(mgr, player, creature, 1000) == 0);
    SetRate(nullptr);
    std::cout << "PASS: stage kill XP is scaled by the rate after the depth and native factors; "
        "other XP is untouched." << std::endl;

    Player ally{ { 12 }, 30, 0, run.segment.MapId, run.instanceId };
    connectedPlayers = { &player, &ally };
    ManastormExperience experience;
    CHECK((FloorXP(experience, run) == std::vector<uint64>{ 2790, 2790 }));
    experience._multiplier = 2.0;
    CHECK((FloorXP(experience, run) == std::vector<uint64>{ 5580, 5580 }));
    experience._multiplier = 1.0;
    SetRate("1");
    CHECK((FloorXP(experience, run) == std::vector<uint64>{ 9300, 9300 }));
    SetRate("0");
    CHECK(FloorXP(experience, run).empty());
    SetRate(nullptr);
    ally.flags = PLAYER_FLAGS_NO_XP_GAIN;
    CHECK((FloorXP(experience, run) == std::vector<uint64>{ 2790 }));
    ally.flags = 0;
    ally.level = 60;
    CHECK(FloorXP(experience, run).empty());
    std::cout << "PASS: floor XP saved per member is the RDF reward times the DB multiplier and the rate." << std::endl;
    return 0;
}
