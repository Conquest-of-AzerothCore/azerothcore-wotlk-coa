#include <algorithm>
#include <cassert>
#include <chrono>
#include <cstdint>
#include <map>
#include <limits>
#include <unordered_set>
#include <memory>
#include <unordered_map>
#include <vector>
using uint8 = uint8_t;
using uint32 = uint32_t;
using uint64 = uint64_t;
using int32 = int32_t;
using Milliseconds = std::chrono::milliseconds;
#define LOG_INFO(...) ((void)0)
constexpr uint32 SPELL_SAFETY_BUBBLE_HELPER = 93307;
constexpr uint32 NPC_MANASTORM_HEART = 900025;
constexpr uint32 SPELL_MANASTORM_HEART_HEALING = 991510;
constexpr uint32 UNIT_CREATED_BY_SPELL = 1;
constexpr uint32 EFFECT_0=0, EFFECT_1=1, SPELL_EFFECT_APPLY_AURA=6;
constexpr uint32 SPELL_AURA_SCHOOL_IMMUNITY=39, SPELL_AURA_MOD_UNATTACKABLE=93;
constexpr uint32 SPELL_SCHOOL_MASK_ALL=127, SPELL_ATTR0_NO_AURA_CANCEL=1;
constexpr uint32 SPELL_ATTR3_ONLY_ON_PLAYER=256, SPELL_ATTR0_CU_POSITIVE=1;
constexpr uint32 SAFETY_BUBBLE_CLEANUP_SPELLS[] = {93306,93307};
// ACTUAL_DISTANCE
struct SpellEffect { uint32 Effect=0,ApplyAuraName=0,MiscValue=0; int32 BasePoints=0; };
struct SpellInfo {uint32 Id=0,Attributes=0,AttributesEx3=256,AttributesCu=0,AuraInterruptFlags=1; SpellEffect Effects[3];};
namespace ManastormModuleConfig { bool enabled=true; bool Enabled(){return enabled;} uint8 AffixMinimumLevel(){return 50;} }
// ACTUAL_PATCH
struct ObjectGuid {
 using LowType=uint32; uint64 value=0; auto operator<=>(ObjectGuid const&) const = default;
 uint32 GetCounter() const {return uint32(value);} uint64 GetRawValue() const{return value;}
 explicit operator bool() const{return value!=0;}
 template<class T> static ObjectGuid Create(uint32 id){return {id};}
};
namespace HighGuid {struct Player {};}
struct Aura {int32 maximum=0,duration=0;void SetMaxDuration(int32 v){maximum=v;}void SetDuration(int32 v){duration=v;}};
struct Creature; struct Pet; struct TempSummon; struct Map; struct Player;
struct Unit {
 virtual ~Unit()=default; Map* map=nullptr; bool alive=true,inworld=true; ObjectGuid owner{1},charmer{};
 bool playerControlled=false,attackStopped=false; bool IsPlayer()const{return playerControlled;} void AttackStop(){attackStopped=true;}
 Aura aura; bool shield=false; uint32 casts=0,heals=0;
 virtual Creature* ToCreature(){return nullptr;}
 bool IsAlive() const{return alive;} bool IsInWorld() const{return inworld;}
 uint32 GetMapId() const; uint32 GetInstanceId() const;
 ObjectGuid GetOwnerGUID() const{return owner;}ObjectGuid GetCharmerGUID() const{return charmer;}
 bool HasAura(uint32) const{return shield;}
 virtual void CastSpell(Unit*,uint32 spell,bool){++casts;if (spell==93307)shield=true;else if (spell==991510)++heals;}
 Aura* GetAura(uint32){return shield?&aura:nullptr;}
 void RemoveAurasDueToSpell(uint32 spell){if (spell==93307)shield=false;}
};
struct SummonPropertiesEntry {uint32 Id=1;};
enum TempSummonType {TEMPSUMMON_MANUAL_DESPAWN,TEMPSUMMON_TIMED_DESPAWN};
enum ReactStates {REACT_PASSIVE,REACT_DEFENSIVE,REACT_AGGRESSIVE};
struct Creature:Unit {
 uint32 entry=900025,spell=0,power=40,maxpower=100,health=50,maxhealth=100;
 bool guardian=false,despawn=false; ObjectGuid guid{100}; ReactStates react=REACT_DEFENSIVE;
 Creature* ToCreature() override{return this;} virtual Pet* ToPet(){return nullptr;}
 virtual TempSummon* ToTempSummon(){return nullptr;}
 bool IsGuardian() const{return guardian;} virtual bool IsPet() const{return false;}
 uint32 GetEntry() const{return entry;} ObjectGuid GetGUID() const{return guid;}
 uint32 GetUInt32Value(uint32) const{return spell;}float GetHealthPct() const{return 100.0f*health/maxhealth;}
 int getPowerType() const{return 0;}uint32 GetPower(int) const{return power;}uint32 GetMaxPower(int) const{return maxpower;}
 ReactStates GetReactState() const{return react;}void SetReactState(ReactStates r){react=r;}
 void SetHealth(uint32 h){health=h;}void SetPower(int,uint32 p){power=p;}
 uint32 CountPctFromMaxHealth(float p) const{return uint32(maxhealth*p/100);}
 void DespawnOrUnsummon(){despawn=true;}
};
struct TempSummon:Creature {
 SummonPropertiesEntry const* m_Properties=nullptr; uint32 timer=20000; TempSummonType type=TEMPSUMMON_TIMED_DESPAWN;
 TempSummon* ToTempSummon() override{return this;}uint32 GetTimer(){return timer;}
 uint32 GetSummonType()const{return type;}void SetTempSummonType(TempSummonType t){type=t;}void SetTimer(uint32 t){timer=t;}
};
struct Pet:Creature {
 Milliseconds duration{20000};Pet* ToPet() override{return this;}bool IsPet()const override{return true;}
 bool isTemporarySummoned()const{return duration.count()>0;}Milliseconds GetDuration()const{return duration;}
 void SetDuration(Milliseconds d){duration=d;}
};
struct Map {
 uint32 id=1,instance=2;std::map<uint64,Creature*> creatures;std::vector<std::unique_ptr<TempSummon>> summons;
 uint32 GetId()const{return id;}uint32 GetInstanceId()const{return instance;}
 Creature* GetCreature(ObjectGuid guid){auto i=creatures.find(guid.value);return i==creatures.end()?nullptr:i->second;}
 TempSummon* SummonCreature(uint32 entry,int,SummonPropertiesEntry const* props,uint32 duration,Player*,uint32 spell){
  auto creature=std::make_unique<TempSummon>();creature->entry=entry;creature->m_Properties=props;creature->map=this;
  creature->timer=duration;creature->spell=spell;creature->guardian=true;auto* result=creature.get();summons.push_back(std::move(creature));return result;
 }
};
uint32 Unit::GetMapId()const{return map?map->id:0;}uint32 Unit::GetInstanceId()const{return map?map->instance:0;}
struct Player:Unit {
 ObjectGuid guid{1};bool teleporting=false;float distance=0;std::vector<Unit*>m_Controlled;Pet* pet=nullptr;uint32 pendingPet=0;
 Map* FindMap()const{return map;}Map* GetMap()const{return map;}bool IsBeingTeleported()const{return teleporting;}
 ObjectGuid GetGUID()const{return guid;}float GetExactDist(Creature*)const{return distance;}
 bool IsWithinDistInMap(Creature*,float r)const{return distance<r+10;}
 int GetPosition()const{return 0;}Pet* GetPet(){return pet;}uint32 GetTemporaryUnsummonedPetNumber()const{return pendingPet;}
 void RemoveDynObject(uint32){}
};
struct Segment{uint32 MapId=1;};
enum class ManastormRunState{Preparing,Active,StageComplete,Transitioning,Failed,Finished};
struct ManastormRun {
 struct CompanionTransfer {uint32 Entry=0,Spell=0,Properties=0,RemainingMs=0,CapturedMs=0,SummonType=0;float HealthPct=100;uint32 Power=0;uint8 ReactState=0;bool TemporaryPet=false;};
 std::unordered_map<ObjectGuid::LowType,std::vector<CompanionTransfer>> CompanionTransfers;
 uint8 level=60;uint32 depth=1,selections=0;
 ManastormRunState state=ManastormRunState::Preparing;Segment segment;uint32 remaining=120000;
 std::map<ObjectGuid,uint32> hearts;std::vector<uint32>members{1};
 void ClearStageAffixState(){selections=0;}uint8 GetCreatureLevel()const{return level;}uint32 GetDepth()const{return depth;}
 uint32 GetRunId()const{return 1;}ManastormRunState GetState()const{return state;}
 Segment const&GetSegment()const{return segment;}uint32 GetInstanceId()const{return 2;}
 uint32 GetPreparationProtectionRemainingMs()const{return remaining;}
 auto&GetActiveHeartGuids(){return hearts;}auto const&GetMembers()const{return members;}
};
struct MapMgr {Map* map=nullptr;Map*FindMap(uint32,uint32){return map;}} mapMgr;
auto* sMapMgr=&mapMgr;
namespace ObjectAccessor{Player* player=nullptr;Player*FindConnectedPlayer(ObjectGuid){return player;}}
struct SpellMgr{SpellInfo info;SpellInfo const*GetSpellInfo(uint32 id){return id?&info:nullptr;}} spellMgr;
auto* sSpellMgr=&spellMgr;
struct PropertiesStore{SummonPropertiesEntry entry;SummonPropertiesEntry const*LookupEntry(uint32 id){return id==1?&entry:nullptr;}}sSummonPropertiesStore;
uint32 clockMs=1000;uint32 getMSTime(){return clockMs;}uint32 getMSTimeDiff(uint32 a,uint32 b){return b-a;}
enum class ManastormAffixAvailabilityKind {Innate,ProgressionUnlock,ForcedOnly};
struct AffixDefinition {bool AutomaticSelection=true;ManastormAffixAvailabilityKind Availability=ManastormAffixAvailabilityKind::ProgressionUnlock;uint32 UnlockDepth=11;};
struct ManastormDataStore {
 std::map<uint32,AffixDefinition> affixes{{11,{}}};
 auto const&GetAffixes()const{return affixes;}
 static ManastormDataStore const&Instance(){static ManastormDataStore store;return store;}
};
// ACTUAL_SELECTION
// ACTUAL_COMPANION_ATTACK
// ACTUAL_PROTECT
// ACTUAL_CLEAR
// ACTUAL_CAPTURE
// ACTUAL_RESTORE
struct ManastormMgr {
 ManastormRun const*run=nullptr;std::map<uint64,std::unique_ptr<ManastormRun>>_runs;
 ManastormRun const*GetRunFor(Player const*)const{return run;}
 bool IsPlayerInUsableEndlessStage(Player const*)const;
 void UpdateHeartPickups(uint32);
};
// ACTUAL_USABLE
// ACTUAL_HEARTS
int main(){
 SpellInfo info;info.Id=93307;PatchSafetySpell(&info);assert(info.Effects[0].Effect==6);
 assert(info.Effects[0].ApplyAuraName==39&&info.Effects[0].MiscValue==127);
 assert(info.Effects[1].ApplyAuraName==93&&info.AuraInterruptFlags==0);
 SpellInfo other;other.Id=123;PatchSafetySpell(&other);assert(other.Effects[0].Effect==0);
 SpellInfo controller;controller.Id=93306;PatchSafetySpell(&controller);assert(controller.AuraInterruptFlags==0&&controller.Effects[0].Effect==0);
 Unit companionAttacker;ManastormRun preparing;uint32 damage=50;
 assert(SuppressPreparingCompanionAttack(&companionAttacker,preparing,damage));assert(damage==0&&companionAttacker.attackStopped);
 companionAttacker.playerControlled=true;damage=50;assert(!SuppressPreparingCompanionAttack(&companionAttacker,preparing,damage)&&damage==50);
 companionAttacker.playerControlled=false;preparing.state=ManastormRunState::Active;
 assert(!SuppressPreparingCompanionAttack(&companionAttacker,preparing,damage)&&damage==50);
 assert(!SuppressPreparingCompanionAttack(nullptr,preparing,damage));
 ManastormRun selection;std::unordered_set<uint32> unlocked;
 InitializeAutomaticAffixes(selection,unlocked);assert(selection.selections==0);
 selection.depth=11;InitializeAutomaticAffixes(selection,unlocked);assert(selection.selections==0);
 selection.depth=12;selection.level=49;InitializeAutomaticAffixes(selection,unlocked);assert(selection.selections==0);
 selection.level=50;InitializeAutomaticAffixes(selection,unlocked);assert(selection.selections==1);
 Map map;Player player;player.map=&map;ManastormRun run;ManastormMgr mgr;mgr.run=&run;
 assert(mgr.IsPlayerInUsableEndlessStage(&player));assert(!mgr.IsPlayerInUsableEndlessStage(nullptr));
 map.instance=3;assert(!mgr.IsPlayerInUsableEndlessStage(&player));map.instance=2;
 for (auto state:{ManastormRunState::Transitioning,ManastormRunState::Failed,ManastormRunState::Finished}){
  run.state=state;assert(!mgr.IsPlayerInUsableEndlessStage(&player));
 }
 run.state=ManastormRunState::Preparing;ApplySafetyBubbleProtection(&player,run);
 assert(player.shield&&player.aura.duration==120000);run.remaining=70000;ApplySafetyBubbleProtection(&player,run);
 assert(player.casts==1&&player.aura.duration==70000);
 TempSummon guardian;guardian.map=&map;guardian.guardian=true;guardian.m_Properties=&sSummonPropertiesStore.entry;
 guardian.spell=42;guardian.entry=99;guardian.health=35;guardian.power=20;player.m_Controlled={&guardian};
 CaptureStageCompanions(&player,run);assert(run.CompanionTransfers[1].size()==1);
 clockMs+=3000;player.m_Controlled.clear();RestoreStageCompanions(&player,run);
 assert(map.summons.size()==1&&map.summons[0]->GetTimer()==17000);
 assert(map.summons[0]->health==35&&map.summons[0]->power==20&&map.summons[0]->shield);
 RestoreStageCompanions(&player,run);assert(map.summons.size()==1);
 player.m_Controlled={map.summons[0].get()};ClearSafetyBubble(&player);
 assert(!player.shield&&!map.summons[0]->shield);
 clockMs+=1000;player.m_Controlled={&guardian};guardian.timer=500;CaptureStageCompanions(&player,run);
 clockMs+=600;RestoreStageCompanions(&player,run);assert(map.summons.size()==1);
 guardian.alive=false;CaptureStageCompanions(&player,run);assert(run.CompanionTransfers[1].empty());
 mgr._runs[1]=std::make_unique<ManastormRun>();auto& hearts=*mgr._runs[1];hearts.state=ManastormRunState::Active;
 Creature heart;heart.map=&map;map.creatures[100]=&heart;hearts.hearts[{100}]=1000;
 mapMgr.map=&map;ObjectAccessor::player=&player;player.distance=0.5f;
 mgr.UpdateHeartPickups(500);assert(player.heals==0);player.distance=1.1f;mgr.UpdateHeartPickups(500);
 assert(player.heals==0&&!heart.despawn);player.distance=0.9f;mgr.UpdateHeartPickups(500);
 assert(player.heals==1&&heart.despawn&&hearts.hearts.empty());mgr.UpdateHeartPickups(500);assert(player.heals==1);
}
