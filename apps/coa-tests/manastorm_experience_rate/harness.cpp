#include "Define.h"
#include "Config.h"
#include "Log.h"
#include "CoA.Prestige.API.h"
#include "CoA.Challenges.Review.h"
#include "destiny_weaver.h"
#include "ManastormExperienceFormula.h"
#include "ManastormModuleConfig.h"
#include "ManastormRun.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <memory>
#include <set>
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
constexpr uint32 SPELL_AURA_MOD_XP_PCT = 200;
enum ConfigIndex { CONFIG_MAX_PLAYER_LEVEL };
enum StatementIndex { CHAR_SEL_MANASTORM_XP_LEVEL, CHAR_ADD_MANASTORM_FLOOR_XP };

struct Map
{
    uint32 id = 43;
    uint32 instanceId = 9;
    bool scriptedPrivate = true;
    uint32 GetId() const { return id; }
    uint32 GetInstanceId() const { return instanceId; }
    bool IsScriptedPrivateInstance() const { return scriptedPrivate; }
};

struct AuraEffect
{
    uint32 id = 0;
    int32 miscValue = 1;
    int32 amount = 0;
    uint32 GetId() const { return id; }
    int32 GetMiscValue() const { return miscValue; }
    int32 GetAmount() const { return amount; }
};

struct PlayerSetting
{
    uint32 value = 0;
};

struct Creature;
struct Player;

struct Unit
{
    Creature* creature = nullptr;
    Player* playerSelf = nullptr;
    Player* ownerPlayer = nullptr;
    Map const* map = nullptr;
    uint32 maxHealth = 1000;
    Creature* ToCreature() { return creature; }
    Player const* ToPlayer() const { return playerSelf; }
    Player const* GetCharmerOrOwnerPlayerOrPlayerItself() const { return ownerPlayer; }
    Map const* FindMap() const { return map; }
    uint32 GetMaxHealth() const { return maxHealth; }
};

struct Creature : Unit
{
    ObjectGuid guid{ 900 };
    uint32 entry = 1;
    uint32 mapId = 0;
    uint32 instanceId = 0;
    float x = 0.0f;
    bool trigger = false;
    bool pet = false;
    bool controlled = false;
    Creature() { creature = this; }
    ObjectGuid GetGUID() const { return guid; }
    uint32 GetEntry() const { return entry; }
    bool IsTrigger() const { return trigger; }
    bool IsPet() const { return pet; }
    uint32 GetMapId() const { return mapId; }
    uint32 GetInstanceId() const { return instanceId; }
};

bool IsPlayerControlledCreature(Creature const* creature) { return creature->controlled; }

bool IsObjectiveBoss(Creature const* creature, ManastormRun const& run)
{
    return creature && !run.GetObjectiveCreatureGuid().IsEmpty() &&
        creature->GetGUID() == run.GetObjectiveCreatureGuid();
}

struct Player : Unit
{
    ObjectGuid guid;
    uint8 level = 30;
    uint32 flags = 0;
    uint32 mapId = 0;
    uint32 instanceId = 0;
    float x = 0.0f;
    bool raf = false;
    uint32 bonusControlSetting = 0;
    std::set<uint32> activeAuras;
    std::vector<AuraEffect> xpAuras;
    Player(ObjectGuid g, uint8 lvl, uint32 f, uint32 m, uint32 inst, Map const* mp = nullptr)
        : guid(g), level(lvl), flags(f), mapId(m), instanceId(inst)
    {
        playerSelf = this;
        ownerPlayer = this;
        map = mp;
    }
    ObjectGuid GetGUID() const { return guid; }
    uint8 GetLevel() const { return level; }
    bool HasPlayerFlag(uint32 flag) const { return (flags & flag) != 0; }
    bool HasAura(uint32 spellId) const { return activeAuras.count(spellId) != 0; }
    PlayerSetting GetPlayerSetting(char const*, uint32 index) const
    {
        return { index == 1 ? bonusControlSetting : 0u };
    }
    uint32 GetMapId() const { return mapId; }
    uint32 GetInstanceId() const { return instanceId; }
    bool GetsRecruitAFriendBonus(bool) const { return raf; }
    bool IsWithinDistInMap(Creature const* target, float dist) const
    {
        return target && target->mapId == mapId && std::fabs(x - target->x) <= dist;
    }
    template <class Predicate>
    float GetTotalAuraMultiplier(uint32, Predicate predicate) const
    {
        float multiplier = 1.0f;
        for (AuraEffect const& effect : xpAuras)
            if (predicate(&effect))
                multiplier *= 1.0f + (float(effect.amount) / 100.0f);
        return multiplier;
    }
};

struct ManastormDataStore
{
    std::vector<ManastormGroupScalingRange> _groupScalingRanges;
    std::vector<ManastormGroupScalingRange> _endgameGroupScalingRanges;
    ManastormScalingPoint GetScalingForDepth(uint32 depth, bool = false) const
    {
        return { depth, 2.0f, 1.0f, 1.0f, 1.0f };
    }
    ManastormScalingPoint GetScalingForDepth(uint32 depth, uint32 memberCount, bool endgame = false) const;
    double GetGroupHealthMultiplier(uint32 memberCount, bool endgame = false) const;
};

struct ManastormMgr
{
    ManastormRun* run = nullptr;
    ManastormRun* stageRun = nullptr;
    std::atomic<std::size_t> _activeGroupRunCount{ 1 };
    ManastormRun* GetRunFor(Player*) { return run; }
    ManastormRun* GetRunForStage(uint32 mapId, uint32 instanceId)
    {
        ManastormRun* candidate = stageRun ? stageRun : run;
        return candidate && candidate->GetSegment().MapId == mapId && candidate->GetInstanceId() == instanceId
            ? candidate
            : nullptr;
    }
    void OnPlayerGiveXP(Player* player, uint32& amount, Unit* victim, uint8 xpSource);
    void OnHeal(Unit* healer, Unit* receiver, uint32 gain);
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
    bool noBonusExperience = false;
    bool OnPlayerHasNoBonusExperience(Player*) const { return noBonusExperience; }
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

ManastormRun MakeRun(std::vector<ObjectGuid::LowType> members, uint32 depth, uint8 creatureLevel = 30)
{
    ManastormSegment segment{};
    segment.SegmentId = 7;
    segment.MapId = 43;
    segment.ObjectiveCreatureEntry = 999;
    segment.NativeExperienceFactor1 = 1.0f;
    ManastormScalingPoint scaling{};
    ManastormRun run(
        1,
        42,
        members.front(),
        members,
        ManastormModeForMemberCount(uint32(members.size())),
        creatureLevel,
        depth,
        segment,
        scaling);
    run.SetInstanceId(9);
    run.SetState(ManastormRunState::Active);
    return run;
}

int main()
{
    ManastormModuleConfig::Load(false);
    CHECK(RateIs(0.3));
    CHECK(ManastormModuleConfig::IsNativeClientMode());
    CHECK(ManastormModuleConfig::PrestigeExperienceEnabled());
    CHECK(ManastormModuleConfig::PrestigeExperienceBonusPercent() == 300);
    CHECK(ManastormModuleConfig::ExperienceBonusControlEnabled());
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

    Map privateMap{};
    Map publicMap{};
    publicMap.scriptedPrivate = false;
    ManastormRun soloRun = MakeRun({ 11 }, 1);
    ManastormMgr mgr;
    mgr.run = &soloRun;
    Player player({ 11 }, 30, 0, 43, 9, &privateMap);
    Creature creature;
    creature.mapId = 43;
    creature.instanceId = 9;

    CHECK(std::fabs(GetEndlessExperienceMultiplier(1) - 1.0) < 1e-9);
    CHECK(std::fabs(GetEndlessExperienceMultiplier(101) - 1.5) < 1e-9);
    CHECK(KillXP(mgr, player, creature, 1000) == 300);

    player.map = &publicMap;
    CHECK(KillXP(mgr, player, creature, 1000) == 1000);
    player.map = &privateMap;

    ManastormRun solo101 = MakeRun({ 11 }, 101);
    mgr.run = &solo101;
    CHECK(KillXP(mgr, player, creature, 1000) == 450);

    ManastormRun solo1001 = MakeRun({ 11 }, 1001);
    mgr.run = &solo1001;
    CHECK(KillXP(mgr, player, creature, 1000) == 573);

    player.xpAuras = { { 818059, 1, 50 }, { 777001, 1, -50 } };
    player.activeAuras.insert(9930831);
    mgr.run = &solo101;
    CHECK(std::fabs(ResolveExternalKillXPMultiplier(&player, 60) - 4.5) < 1e-9);
    CHECK(KillXP(mgr, player, creature, 1500) * 3 == 1500);

    player.raf = true;
    CHECK(std::fabs(ResolveExternalKillXPMultiplier(&player, 60) - 4.5) < 1e-9);

    player.bonusControlSetting = 1;
    CHECK(std::fabs(ResolveExternalKillXPMultiplier(&player, 60) - 3.0) < 1e-9);

    player.activeAuras.clear();
    CHECK(std::fabs(ResolveExternalKillXPMultiplier(&player, 60) - 1.0) < 1e-9);
    player.raf = false;
    player.bonusControlSetting = 0;
    player.xpAuras.clear();

    ManastormSegment doubleSegment{};
    doubleSegment.SegmentId = 7;
    doubleSegment.MapId = 43;
    doubleSegment.ObjectiveCreatureEntry = 999;
    doubleSegment.NativeExperienceFactor1 = 2.0f;
    ManastormScalingPoint neutralScaling{};
    soloRun.PrepareNextStage(30, 1, doubleSegment, neutralScaling);
    soloRun.SetInstanceId(9);
    soloRun.SetState(ManastormRunState::Active);
    mgr.run = &soloRun;
    CHECK(KillXP(mgr, player, creature, 1000) == 600);
    doubleSegment.NativeExperienceFactor1 = 1.0f;
    soloRun.PrepareNextStage(30, 1, doubleSegment, neutralScaling);
    soloRun.SetInstanceId(9);
    soloRun.SetState(ManastormRunState::StageComplete);
    CHECK(KillXP(mgr, player, creature, 1000) == 300);
    soloRun.SetState(ManastormRunState::Active);

    uint32 questXP = 1000;
    mgr.OnPlayerGiveXP(&player, questXP, nullptr, 0);
    CHECK(questXP == 1000);
    creature.mapId = 1;
    CHECK(KillXP(mgr, player, creature, 1000) == 1000);
    creature.mapId = 43;

    soloRun.SetState(ManastormRunState::Preparing);
    CHECK(KillXP(mgr, player, creature, 1000) == 0);
    soloRun.SetState(ManastormRunState::Active);

    ManastormRun transitioningRun = MakeRun({ 11, 12 }, 10);
    transitioningRun.BeginPreviousStageTransition();
    ManastormSegment nextSegment{};
    nextSegment.SegmentId = 8;
    nextSegment.MapId = 43;
    nextSegment.ObjectiveCreatureEntry = 999;
    nextSegment.NativeExperienceFactor1 = 1.0f;
    transitioningRun.PrepareNextStage(30, 11, nextSegment, neutralScaling);
    transitioningRun.SetInstanceId(10);
    transitioningRun.SetState(ManastormRunState::Preparing);
    mgr.run = &transitioningRun;
    CHECK(KillXP(mgr, player, creature, 1000) == 0);

    mgr.run = nullptr;
    mgr.stageRun = &soloRun;
    CHECK(KillXP(mgr, player, creature, 1000) == 0);
    mgr.stageRun = nullptr;
    CHECK(KillXP(mgr, player, creature, 1000) == 1000);

    ManastormRun raidRun = MakeRun({ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 }, 1000);
    raidRun.SetMemberXPBaseline(11, 0, 30);
    raidRun.RecordMemberDamageDealt(12, 19800);
    raidRun.RecordMemberDamageDealt(11, 200);
    mgr.run = &raidRun;
    CHECK(KillXP(mgr, player, creature, 1000) == 13);

    player.x = 150.0f;
    CHECK(KillXP(mgr, player, creature, 1000) == 0);
    player.x = 0.0f;

    mgr.run = &soloRun;
    SetRate("1");
    CHECK(KillXP(mgr, player, creature, 1000) == 1000);
    SetRate("0");
    CHECK(KillXP(mgr, player, creature, 1000) == 0);
    SetRate(nullptr);
    std::cout << "PASS: stage kill XP preserves solo curve, caps boost depth, and penalizes raid/AFK carries."
        << std::endl;

    ManastormDataStore store;
    CHECK(std::fabs(store.GetGroupHealthMultiplier(5) - 1.0) < 1e-6);
    store._groupScalingRanges.push_back({ 2, 2, 1.6f, 1.05f, 1.0f, 1.0f });
    store._endgameGroupScalingRanges.push_back({ 2, 2, 1.6f, 1.15f, 1.0f, 1.0f });
    CHECK(std::fabs(store.GetGroupHealthMultiplier(1) - 1.0) < 1e-6);
    CHECK(std::fabs(store.GetGroupHealthMultiplier(2) - 1.6) < 1e-6);
    CHECK(std::fabs(store.GetGroupHealthMultiplier(15) - 9.4) < 1e-6);
    CHECK(std::fabs(store.GetScalingForDepth(10, 15, false).GlobalDamageMultiplier - 1.7) < 1e-5);
    CHECK(std::fabs(store.GetScalingForDepth(10, 15, true).GlobalDamageMultiplier - 3.1) < 1e-5);

    ManastormExperience experience;
    connectedPlayers = { &player };
    CHECK((FloorXP(experience, soloRun) == std::vector<uint64>{ 2790 }));

    ManastormRun duoRun = MakeRun({ 11, 12 }, 10);
    duoRun.SetGroupHealthMultiplier(1.6);
    Player ally({ 12 }, 30, 0, 43, 9, &privateMap);
    connectedPlayers = { &player, &ally };
    mgr.run = &duoRun;

    mgr.OnHeal(&player, &player, 500);
    CHECK(duoRun.GetMemberCreditedHeal(11) == 0);
    mgr.OnHeal(&ally, &player, 500);
    CHECK(duoRun.GetMemberCreditedHeal(12) == 0);

    duoRun.RecordMemberDamageDealt(11, 25000);
    mgr.OnHeal(&ally, &player, 500);
    CHECK(duoRun.GetMemberCreditedHeal(12) == 0);

    duoRun.RecordMemberCreatureDamageTaken(11, 4000);
    mgr._activeGroupRunCount.store(0, std::memory_order_relaxed);
    mgr.OnHeal(&ally, &player, 600);
    CHECK(duoRun.GetMemberCreditedHeal(12) == 0);
    mgr._activeGroupRunCount.store(1, std::memory_order_relaxed);
    mgr.OnHeal(&ally, &player, 600);
    CHECK(duoRun.GetMemberCreditedHeal(12) == 4000);
    mgr.OnHeal(&ally, &player, 600);
    CHECK(duoRun.GetMemberCreditedHeal(12) == 4000);

    duoRun.RecordMemberDamageDealt(12, 6000);
    duoRun.RecordMemberCreatureDamageTaken(11, 10000);
    Player extraHealer({ 13 }, 30, 0, 43, 9, &privateMap);
    ManastormRun trioDualPool = MakeRun({ 11, 12, 13 }, 10);
    trioDualPool.SetGroupHealthMultiplier(2.2);
    trioDualPool.RecordMemberDamageDealt(11, 80000);
    trioDualPool.RecordMemberDamageDealt(12, 20000);
    trioDualPool.RecordMemberCreatureDamageTaken(11, 10000);
    mgr.run = &trioDualPool;
    mgr.OnHeal(&extraHealer, &player, 900);
    CHECK(trioDualPool.GetMemberCreditedHeal(13) == 9000);
    connectedPlayers = { &player, &ally, &extraHealer };
    CHECK((FloorXP(experience, trioDualPool) == std::vector<uint64>{ 2046, 2046, 2046 }));

    connectedPlayers = { &player, &ally };
    mgr.run = &duoRun;
    CHECK((FloorXP(experience, duoRun) == std::vector<uint64>{ 2232, 2232 }));
    experience._multiplier = 2.0;
    CHECK((FloorXP(experience, duoRun) == std::vector<uint64>{ 4464, 4464 }));
    experience._multiplier = 1.0;
    SetRate("1");
    CHECK((FloorXP(experience, duoRun) == std::vector<uint64>{ 7440, 7440 }));
    SetRate("0");
    CHECK(FloorXP(experience, duoRun).empty());
    SetRate(nullptr);
    ally.flags = PLAYER_FLAGS_NO_XP_GAIN;
    ally.level = 50;
    CHECK((FloorXP(experience, duoRun) == std::vector<uint64>{ 2232 }));
    ally.level = 59;
    CHECK((FloorXP(experience, duoRun) == std::vector<uint64>{ 1307 }));
    ally.level = 30;
    CHECK((FloorXP(experience, duoRun) == std::vector<uint64>{ 2232 }));
    ally.flags = 0;
    ally.level = 60;
    CHECK(FloorXP(experience, duoRun).empty());

    ManastormRun friendsFive = MakeRun({ 201, 202, 203, 204, 205 }, 1, 50);
    friendsFive.SetGroupHealthMultiplier(3.4);
    friendsFive.SetMemberXPBaseline(201, 0, 50);
    friendsFive.SetMemberXPBaseline(202, 0, 50);
    friendsFive.SetMemberXPBaseline(203, 0, 49);
    friendsFive.SetMemberXPBaseline(204, 0, 48);
    friendsFive.SetMemberXPBaseline(205, 0, 15);
    friendsFive.RecordMemberDamageDealt(201, 10000);
    friendsFive.RecordMemberDamageDealt(202, 10000);
    friendsFive.RecordMemberDamageDealt(203, 10000);
    friendsFive.RecordMemberDamageDealt(204, 10000);
    friendsFive.RecordMemberDamageDealt(205, 10000);
    Player f1({ 201 }, 50, 0, 43, 9, &privateMap);
    Player f2({ 202 }, 50, 0, 43, 9, &privateMap);
    Player f3({ 203 }, 49, 0, 43, 9, &privateMap);
    Player f4({ 204 }, 48, 0, 43, 9, &privateMap);
    Player f5({ 205 }, 15, 0, 43, 9, &privateMap);
    connectedPlayers = { &f1, &f2, &f3, &f4, &f5 };
    std::vector<uint64> const friendsFloor = FloorXP(experience, friendsFive);
    CHECK((friendsFloor == std::vector<uint64>{ 1897, 1897, 1897, 1897, 670 }));

    ManastormRun reverseBoost = MakeRun({ 301, 302, 303, 304, 305 }, 1, 55);
    reverseBoost.SetMemberXPBaseline(301, 0, 55);
    reverseBoost.SetMemberXPBaseline(302, 0, 10);
    reverseBoost.SetMemberXPBaseline(303, 0, 10);
    reverseBoost.SetMemberXPBaseline(304, 0, 10);
    reverseBoost.SetMemberXPBaseline(305, 0, 10);
    reverseBoost.RecordMemberDamageDealt(301, 10000);
    reverseBoost.RecordMemberDamageDealt(302, 10000);
    Player highMember({ 301 }, 55, 0, 43, 9, &privateMap);
    Player lowMember({ 302 }, 10, 0, 43, 9, &privateMap);
    mgr.run = &reverseBoost;
    CHECK(KillXP(mgr, highMember, creature, 1000) == 104);
    CHECK(KillXP(mgr, lowMember, creature, 1000) == 20);

    ManastormRun carryLeave = MakeRun({ 101, 102 }, 500, 60);
    carryLeave.SetMemberXPBaseline(101, 499, 60);
    carryLeave.SetMemberXPBaseline(102, 0, 59);
    carryLeave.RecordMemberDamageDealt(101, 20000);
    carryLeave.RecordMemberDamageDealt(102, 100);
    CHECK(carryLeave.RemoveMember(101));
    CHECK(carryLeave.IsGroupRun());
    CHECK(carryLeave.GetStageMemberCount() == 2);
    CHECK(carryLeave.GetHighestMemberLevel() == 60);
    CHECK(carryLeave.GetTotalStageDamageDealt() == 20100);
    CHECK(carryLeave.GetRecordedProgressDepth(102) == 1);
    carryLeave.AdvanceMemberPersonalDepths();
    CHECK(carryLeave.GetMemberPersonalBestDepth(102) == 1);
    Player carried({ 102 }, 59, 0, 43, 9, &privateMap);
    connectedPlayers = { &carried };
    CHECK(FloorXP(experience, carryLeave).empty());
    mgr.run = &carryLeave;
    CHECK(KillXP(mgr, carried, creature, 1000) == 0);

    ManastormRun raidAfk = MakeRun({ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 }, 1000);
    raidAfk.RecordMemberDamageDealt(12, 20000);
    std::vector<Player> raidPlayers;
    raidPlayers.reserve(15);
    connectedPlayers.clear();
    for (ObjectGuid::LowType id : raidAfk.GetMembers())
        raidPlayers.emplace_back(ObjectGuid{ id }, 30, 0, 43, 9, &privateMap);
    for (Player& member : raidPlayers)
        connectedPlayers.push_back(&member);
    std::vector<uint64> const raidFloor = FloorXP(experience, raidAfk);
    CHECK(raidFloor.size() == 15);
    CHECK(raidFloor[0] == 19);
    CHECK(raidFloor[1] == 194);
    std::cout << "PASS: floor XP preserves solo reward, balances dual-pool effort, and blocks raid/twink/leave carries."
        << std::endl;
    return 0;
}
