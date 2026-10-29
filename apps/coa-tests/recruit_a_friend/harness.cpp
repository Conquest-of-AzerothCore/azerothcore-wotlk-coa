#include <algorithm>
#include <cstdint>
#include <ctime>
#include <iostream>
#include <unordered_map>
#include <vector>
using uint8 = uint8_t;
using uint32 = uint32_t;
using uint64 = uint64_t;
using int32 = int32_t;
#define LOG_DEBUG(...) ((void)0)
constexpr int PLAYER_FIELD_BYTES=0, PLAYER_FIELD_MAX_LEVEL=1;
constexpr int CONFIG_MAX_RECRUIT_A_FRIEND_BONUS_PLAYER_LEVEL=0;
constexpr int CONFIG_MAX_RECRUIT_A_FRIEND_BONUS_PLAYER_LEVEL_DIFFERENCE=1;
constexpr int SMSG_REFER_A_FRIEND_FAILURE=1, SMSG_PROPOSE_LEVEL_GRANT=2;
enum ReputationSource { REPUTATION_SOURCE_KILL, REPUTATION_SOURCE_QUEST, REPUTATION_SOURCE_DAILY_QUEST,
    REPUTATION_SOURCE_WEEKLY_QUEST, REPUTATION_SOURCE_MONTHLY_QUEST, REPUTATION_SOURCE_REPEATABLE_QUEST,
    REPUTATION_SOURCE_SPELL };
constexpr int SPELL_AURA_MOD_REPUTATION_GAIN=1, SPELL_AURA_MOD_FACTION_REPUTATION_GAIN=2;
constexpr int RATE_REPUTATION_LOWLEVEL_KILL=1, RATE_REPUTATION_LOWLEVEL_QUEST=2, RATE_REPUTATION_RECRUIT_A_FRIEND_BONUS=3;
struct RepRewardRate { float creatureRate=1,questRate=1,questDailyRate=1,questWeeklyRate=1,questMonthlyRate=1,questRepeatableRate=1,spellRate=1; };
struct ObjectMgr { RepRewardRate* GetRepRewardRate(int) { return nullptr; } } objectMgr;
auto* sObjectMgr=&objectMgr;
namespace Acore::XP { int GetGrayLevel(uint8) { return 1; } }
float CalculatePct(float value,float percent) { return value*percent/100; }
enum SpellCastResult { SPELL_CAST_OK, SPELL_FAILED_BAD_TARGETS, SPELL_FAILED_HIGHLEVEL, SPELL_FAILED_NOT_HERE };
// ACTUAL_ERRORS
struct ObjectGuid {
    uint64 value=0;
    bool operator==(ObjectGuid const&) const = default;
    ObjectGuid& ReadAsPacked() { return *this; }
    void Clear() { value=0; }
    bool IsEmpty() const { return value==0; }
};
struct WorldPacket {
    ObjectGuid guid;
    WorldPacket(ObjectGuid g):guid(g) {}
    WorldPacket(int, int) {}
    WorldPacket& operator>>(ObjectGuid& g) { g=guid; return *this; }
    template<class T> WorldPacket& operator<<(T const&) { return *this; }
};
struct Player;
struct GroupReference {
    Player* player=nullptr;
    GroupReference* following=nullptr;
    Player* GetSource() { return player; }
    GroupReference* next() { return following; }
};
struct Group {
    GroupReference first,second;
    GroupReference* GetFirstMember() { return &first; }
};
struct Map { bool instance=false; bool Instanceable() const { return instance; } };
struct World { uint32 cap=60; float getRate(int key) { return key==3 ? 0.1f : 1.f; } uint32 getIntConfig(int key) { return key==0 ? cap : 4; } } world;
auto* sWorld=&world;
struct ScriptMgr { uint8 cap=0; uint8 GetMaxAllowedLevel(Player*) { return cap; } } scripts;
auto* sScriptMgr=&scripts;
namespace GameTime { int now=1000; struct Time { int count() const { return now; } }; Time GetGameTime() { return {}; } }
struct Database {
    int commits=0;
    int BeginTransaction() { return 1; }
    void CommitTransaction(int) { ++commits; }
} CharacterDatabase;
using CharacterDatabaseTransaction=int;
struct WorldSession {
    Player* _player=nullptr;
    uint32 account=0, recruiterId=0;
    bool recruits=false;
    ObjectGuid _rafGrantFrom, _rafGrantRecipient, _rafSummoner;
    uint8 _rafGrantLevel=0, _rafGrantDonorLevel=0;
    time_t _rafGrantExpiry=0;
    int packets=0;
    uint32 GetAccountId() const { return account; }
    uint32 GetRecruiterId() const { return recruiterId; }
    bool IsARecruiter() const { return recruits; }
    void SendPacket(WorldPacket*) { ++packets; }
    void HandleGrantLevel(WorldPacket&);
    void HandleAcceptGrantLevel(WorldPacket&);
    SpellCastResult CheckRecruitAFriendSummon(Player const*) const;
    bool ValidateRecruitAFriendSummon(ObjectGuid,bool);
};
struct PlayerSetting {uint32 value=0;};
using PlayerSettingVector=std::vector<PlayerSetting>;
struct Player {
    PlayerSettingVector prestige;
    PlayerSettingVector const* FindPlayerSettings(char const*)const{return prestige.empty()?nullptr:&prestige;}
    ObjectGuid guid;
    ObjectGuid selected{999};
    WorldSession session;
    Group* group=nullptr;
    Map map;
    uint8 level=1, team=0, m_grantableLevels=0, flags=0x80;
    bool near=true, sameMap=true, alive=true, combat=false, teleport=false, flight=false, reject=false, inworld=true;
    uint32 maxLevel=80, instance=0;
    int saved=0;
    time_t summonExpiry=1100;
    Player(uint64 id,uint32 account,uint32 recruiter,uint8 lvl):guid{id},level(lvl) {
        session._player=this; session.account=account; session.recruiterId=recruiter;
    }
    WorldSession* GetSession() const { return const_cast<WorldSession*>(&session); }
    uint8 GetGrantableLevels() const { return m_grantableLevels; }
    void SetGrantableLevels(uint8);
    uint8 GetLevel() const { return level; }
    ObjectGuid GetGUID() const { return guid; }
    ObjectGuid GetTarget() const { return selected; }
    bool IsPlayer() const { return true; }
    Player* ToPlayer() { return this; }
    ObjectGuid GetPackGUID() const { return guid; }
    uint8 GetTeamId() const { return team; }
    uint32 GetUInt32Value(int) const { return maxLevel; }
    Group* GetGroup() const { return group; }
    bool IsInMap(Player*) const { return sameMap; }
    bool IsAtRecruitAFriendDistance(Player*, bool = false) const { return near; }
    bool IsAlive() const { return alive; }
    bool IsInCombat() const { return combat; }
    bool IsBeingTeleported() const { return teleport; }
    bool IsInFlight() const { return flight; }
    bool IsInWorld() const { return inworld; }
    void* GetVehicle() const { return nullptr; }
    Map const* FindMap() const { return &map; }
    uint32 GetInstanceId() const { return instance; }
    char const* GetName() const { return "friend"; }
    void SendDirectMessage(WorldPacket* p) { session.SendPacket(p); }
    void GiveLevel(uint8 v) { if (!reject) level=v; }
    void SaveToDB(int, bool, bool) { ++saved; }
    time_t GetSummonExpireTimer() const { return summonExpiry; }
    void SummonIfPossible(bool agree,ObjectGuid) { if (!agree) summonExpiry=0; }
    void SetByteFlag(int,int,uint8 f) { flags|=f; }
    void RemoveByteFlag(int,int,uint8 f) { flags&=~f; }
    bool HasByteFlag(int,int,uint8 f) const { return (flags&f)!=0; }
    bool GetsRecruitAFriendBonus(bool);
    float CalculateReputationGain(ReputationSource,uint32,float,int32_t,bool);
    int GetTotalAuraModifier(int) { return 0; }
    int GetTotalAuraModifierByMiscValue(int,int32_t) { return 0; }
    void Earn(uint8 oldLevel,uint8 level) {
        // ACTUAL_CREDITS
    }
};
std::unordered_map<uint64,Player*> players;
namespace ObjectAccessor {
    Player* FindPlayer(ObjectGuid g) { auto i=players.find(g.value); return i==players.end()?nullptr:i->second; }
    Player* GetPlayer(Player&,ObjectGuid g) { auto i=players.find(g.value); return i==players.end()?nullptr:i->second; }
}
constexpr int SPELL_EFFECT_SUMMON_RAF_FRIEND=152;
struct SpellCastTargets {
    ObjectGuid object;
    ObjectGuid GetObjectTargetGUID() const { return object; }
    void RemoveObjectTarget() { object.Clear(); }
};
struct SpellInfoFixture { bool HasEffect(int) const { return true; } } spellInfo;
struct Spell {
    SpellCastTargets m_targets;
    ObjectGuid m_originalTargetGUID;
    Player* m_caster;
    SpellInfoFixture* m_spellInfo=&spellInfo;
    void InitExplicitTargets(SpellCastTargets const&);
};
// ACTUAL_TARGET_CAPTURE
// ACTUAL_SETTER
// ACTUAL_GRANTS
// ACTUAL_BONUS
// ACTUAL_SUMMON
// ACTUAL_REPUTATION
// ACTUAL_CONFIRMATION
// ACTUAL_AVAILABILITY
int failures=0, checks=0;
void check(bool okay,char const* name) {
    ++checks;
    if (!okay) { ++failures; std::cerr<<"FAIL: "<<name<<"\n"; }
}
struct Fixture {
    Player donor{1,11,22,40}, target{2,22,0,10};
    Group group;
    Fixture() {
        GameTime::now=1000; scripts.cap=0; world.cap=60; CharacterDatabase.commits=0;
        players={{1,&donor},{2,&target}};
        donor.group=&group; target.group=&group;
        group.first={&donor,&group.second}; group.second={&target,nullptr};
        donor.SetGrantableLevels(1); donor.flags=0x81;
    }
    void propose() { WorldPacket p(target.guid); donor.session.HandleGrantLevel(p); }
    void accept() { WorldPacket p(donor.guid); target.session.HandleAcceptGrantLevel(p); }
    void unchanged(char const* name) { check(target.level==10 && donor.m_grantableLevels==1,name); }
};
int main() {
    { Fixture f; f.target.prestige={{3},{1}}; f.propose(); f.accept(); f.unchanged("active Prestige recipient cannot receive a grant"); }
    { Fixture f; f.propose(); f.target.prestige={{3},{1}}; f.accept(); f.unchanged("Prestige activated after proposal blocks acceptance without spending credit"); }
    { Fixture f; f.target.prestige={{3},{0}}; f.propose(); f.accept(); check(f.target.level==11 && f.donor.m_grantableLevels==0,"completed Prestige history alone does not block grants"); }
    { Fixture f; f.donor.prestige={{3},{1}}; f.propose(); f.accept(); check(f.target.level==11,"Prestige donor may still grant to an eligible recipient"); }

    { Fixture f; f.accept(); f.unchanged("forged acceptance has no proposal"); }
    { Fixture f; f.propose(); f.accept(); check(f.target.level==11 && f.donor.m_grantableLevels==0,"valid grant");
      check(f.donor.flags==0x80,"last credit clears only RAF flag");
      check(f.donor.saved==1 && f.target.saved==1 && CharacterDatabase.commits==1,"paired character persistence");
      f.accept(); check(f.target.level==11,"acceptance replay"); }
    { Fixture f; f.donor.group=nullptr; f.target.group=nullptr; f.propose(); f.accept(); f.unchanged("two ungrouped players"); }
    { Fixture f; f.propose(); f.target.group=nullptr; f.accept(); f.unchanged("group changed after proposal"); }
    { Fixture f; f.propose(); f.donor.near=false; f.accept(); f.unchanged("distance changed after proposal"); }
    { Fixture f; f.target.team=1; f.propose(); f.accept();
      check(f.target.level==11 && f.donor.m_grantableLevels==0,"cross-faction grant"); }
    { Fixture f; f.propose(); f.target.team=1; f.accept();
      check(f.target.level==11 && f.donor.m_grantableLevels==0,"faction change does not invalidate grant"); }
    { Fixture f; f.propose(); f.donor.session.recruiterId=33; f.accept(); f.unchanged("link changed after proposal"); }
    { Fixture f; f.propose(); GameTime::now+=61; f.accept(); f.unchanged("expired proposal"); }
    { Fixture f; f.propose(); f.target.reject=true; f.accept(); f.unchanged("GiveLevel rejection does not spend credit"); }
    { Fixture f; f.propose(); scripts.cap=10; f.accept(); f.unchanged("CoA progression cap rechecked"); }
    { Fixture f; f.propose(); f.donor.m_grantableLevels=0; f.accept(); check(f.target.level==10,"credit exhausted before accept"); }
    { Fixture f; f.propose(); f.target.level=11; f.accept(); check(f.target.level==11 && f.donor.m_grantableLevels==1,"recipient level changed"); }
    { Fixture f; f.propose(); f.target.combat=true; f.accept(); f.unchanged("combat changed after proposal"); }
    { Fixture f; f.propose(); f.target.teleport=true; f.accept(); f.unchanged("teleport changed after proposal"); }
    { Fixture f; f.donor.SetGrantableLevels(0); for(uint8 n=2;n<=60;++n) f.donor.Earn(n-1,n);
      check(f.donor.m_grantableLevels==30,"levels 2 through 60 award 30 credits");
      check(f.donor.flags==0x81,"earning updates native flag"); f.donor.Earn(60,62);
      check(f.donor.m_grantableLevels==30,"no credits above configured cap"); }
    { Fixture f; f.donor.SetGrantableLevels(0); f.donor.Earn(1,60); check(f.donor.m_grantableLevels==30,"multi-level increase"); }
    { Fixture f; f.donor.level=10; check(f.donor.GetsRecruitAFriendBonus(true),"linked grouped XP");
      check(f.target.GetsRecruitAFriendBonus(true),"XP in both relationship directions");
      f.donor.near=false; check(!f.target.GetsRecruitAFriendBonus(true),"XP distance restriction"); }
    { Fixture f; f.donor.group=nullptr; check(!f.donor.GetsRecruitAFriendBonus(true),"ungrouped XP restriction"); }
    { Fixture f; f.donor.level=61; f.target.level=61; check(!f.donor.GetsRecruitAFriendBonus(true),"XP level cap");
      check(f.donor.GetsRecruitAFriendBonus(false),"reputation does not inherit XP level cap"); }
    { Fixture f; f.donor.level=10;
      check(f.donor.CalculateReputationGain(REPUTATION_SOURCE_QUEST,10,100,1,false)==110,"positive reputation bonus");
      check(f.donor.CalculateReputationGain(REPUTATION_SOURCE_QUEST,10,-100,1,false)==-100,"RAF never amplifies reputation losses");
      check(f.donor.CalculateReputationGain(REPUTATION_SOURCE_SPELL,10,100,1,false)==100,"spell reputation excluded");
      f.target.near=false;
      check(f.donor.CalculateReputationGain(REPUTATION_SOURCE_KILL,10,100,1,false)==100,"reputation requires nearby linked member"); }
#if SUMMON_AVAILABLE
    { Fixture f; Spell spell; spell.m_caster=&f.donor;
      spell.InitExplicitTargets({f.target.guid});
      check(spell.m_originalTargetGUID==f.target.guid,"packet target wins over current selection");
      check(spell.m_targets.GetObjectTargetGUID().IsEmpty(),"cross-map target kept out of local pointer resolver");
      spell.InitExplicitTargets({{}});
      check(spell.m_originalTargetGUID==f.donor.selected,"selection fallback captured at cast start");
      spell.InitExplicitTargets({{888}});
      check(spell.m_originalTargetGUID==ObjectGuid{888},"missing explicit target never falls back to unrelated selection"); }
    { Fixture f; f.target.level=39; f.donor.sameMap=false; f.target.sameMap=false;
      check(f.donor.session.CheckRecruitAFriendSummon(&f.target)==SPELL_CAST_OK,"cross-map linked summon");
      check(f.target.session.CheckRecruitAFriendSummon(&f.donor)==SPELL_CAST_OK,"summon relationship reverse direction");
      f.donor.session.recruiterId=0; f.donor.session.recruits=true; f.target.session.recruits=true;
      check(f.donor.session.CheckRecruitAFriendSummon(&f.target)!=SPELL_CAST_OK,"unrelated recruiter accounts rejected"); }
    { Fixture f; f.target.level=60; check(f.donor.session.CheckRecruitAFriendSummon(&f.target)!=SPELL_CAST_OK,"summon level restriction"); }
    { Fixture f; f.target.combat=true; check(f.donor.session.CheckRecruitAFriendSummon(&f.target)!=SPELL_CAST_OK,"summon combat restriction"); }
    { Fixture f; f.target.instance=7; check(f.donor.session.CheckRecruitAFriendSummon(&f.target)!=SPELL_CAST_OK,"private stage cannot be bypassed"); }
    { Fixture f; f.target.session._rafSummoner=f.donor.guid;
      check(!f.target.session.ValidateRecruitAFriendSummon({999},true),"forged summon confirmation");
      check(f.target.session._rafSummoner==f.donor.guid,"forged confirmation preserves genuine request");
      check(f.target.session.ValidateRecruitAFriendSummon(f.donor.guid,false),"native summon decline");
      check(f.target.session._rafSummoner.IsEmpty(),"summon decline clears RAF marker"); }
    { Fixture f; f.target.session._rafSummoner=f.donor.guid; f.target.combat=true;
      check(!f.target.session.ValidateRecruitAFriendSummon(f.donor.guid,true),"summon acceptance rechecks eligibility");
      check(f.target.summonExpiry==0,"invalid summon acceptance cancels pending request"); }
    { Fixture f; f.target.session._rafSummoner=f.donor.guid; f.target.summonExpiry=999;
      check(!f.target.session.ValidateRecruitAFriendSummon(f.donor.guid,true),"expired summon request"); }
    { Fixture f; f.target.session._rafSummoner=f.donor.guid;
      check(f.target.session.ValidateRecruitAFriendSummon(f.donor.guid,true),"linked summon accepted"); }
    { Fixture f; f.target.inworld=false; check(f.donor.session.CheckRecruitAFriendSummon(&f.target)!=SPELL_CAST_OK,"offline target rejected"); }
#endif
    { Fixture f; f.donor.session.recruiterId=0; f.donor.session.recruits=true; f.target.session.recruiterId=11;
      f.propose(); f.accept();
      check(f.target.level==11 && f.donor.m_grantableLevels==0,"recruiter grants earned level to direct recruit");
      f.accept(); check(f.target.level==11,"reverse grant acceptance replay rejected"); }
    { Fixture f; f.donor.session.recruiterId=0; f.donor.session.recruits=true; f.target.session.recruiterId=11;
      f.propose(); f.target.session.recruiterId=33; f.accept(); f.unchanged("reverse link rechecked at acceptance"); }
    { Fixture f; f.donor.session.recruiterId=0; f.target.session.recruiterId=0;
      f.donor.session.recruits=true; f.target.session.recruits=true;
      f.propose(); f.accept(); f.unchanged("unrelated recruiter accounts cannot grant"); }
    { Fixture f; f.donor.session.recruiterId=33; f.target.session.recruiterId=33;
      f.propose(); f.accept(); f.unchanged("sibling recruits cannot grant"); }
    { Fixture f; f.donor.session.recruiterId=0; f.donor.session.recruits=true; f.target.session.recruiterId=11;
      f.target.session.account=11; f.propose(); f.accept(); f.unchanged("same-account reverse grant rejected"); }
    { Fixture f; f.donor.session.recruiterId=0; f.donor.session.recruits=true; f.donor.SetGrantableLevels(0);
      f.donor.Earn(1,10); check(f.donor.m_grantableLevels==5,"recruiter earns one credit per two levels");
      check(f.donor.flags==0x81,"recruiter credit native flag set"); }
    { Fixture f; f.donor.session.recruiterId=0; f.donor.session.recruits=false; f.donor.SetGrantableLevels(0);
      f.donor.Earn(1,10); check(f.donor.m_grantableLevels==0,"unlinked accounts earn no grant credits"); }
    { Fixture f; f.donor.session.recruiterId=0; f.donor.session.recruits=true; f.donor.SetGrantableLevels(254);
      f.donor.Earn(1,10); check(f.donor.m_grantableLevels==255,"recruiter credit balance saturates"); }
    std::cout<<checks<<" production RAF checks, "<<failures<<" failures\n";
    return failures ? 1 : 0;
}
