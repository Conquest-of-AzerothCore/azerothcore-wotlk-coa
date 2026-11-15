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
#include <array>
#include <functional>
using uint8 = uint8_t;
using uint32 = uint32_t;
using uint64 = uint64_t;
using int32 = int32_t;
using Milliseconds = std::chrono::milliseconds;
#define LOG_INFO(...) ((void)0)
constexpr uint32 SPELL_SAFETY_BUBBLE_HELPER = 93307;
constexpr uint32 SPELL_SAFETY_BUBBLE = 93306;
constexpr uint32 NPC_STAGE_PORTAL = 80910;
constexpr uint32 NPC_MANASTORM_HEART = 900025;
constexpr uint32 SPELL_MANASTORM_HEART_HEALING = 991510;
constexpr uint32 UNIT_CREATED_BY_SPELL = 1;
constexpr uint8 MAX_SPELL_EFFECTS = 3;
constexpr uint32 POWER_MANA = 0;
constexpr uint32 SPELL_AURA_MOUNTED = 78;
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
bool IsEmpty() const { return value == 0; }
 template<class T> static ObjectGuid Create(uint32 id){return {id};}
};
namespace HighGuid {struct Player {};}
struct Unit;
struct AuraEffect
{
    int32 amount = 0, base = 0;
    bool recalculate = false;
    int32 GetAmount() const { return amount; }
    int32 GetBaseAmount() const { return base; }
    bool CanBeRecalculated() const { return recalculate; }
};
struct Aura
{
    int32 maximum = 0, duration = 0;
    uint32 spell = 0;
    Unit* owner = nullptr;
    ObjectGuid caster{1}, item;
    bool passive = false, area = false, savable = true, mounted = false;
    uint8 mask = 1, stacks = 1, charges = 0;
    std::array<AuraEffect, 3> effects;
    void SetMaxDuration(int32 value) { maximum = value; }
    void SetDuration(int32 value) { duration = value; }
    int32 GetMaxDuration() const { return maximum; }
    uint32 GetId() const { return spell; }
    Unit* GetOwner() const { return owner; }
    ObjectGuid GetCasterGUID() const { return caster; }
    ObjectGuid GetCastItemGUID() const { return item; }
    bool IsPassive() const { return passive; }
    bool IsArea() const { return area; }
    bool CanBeSaved() const { return savable; }
    bool HasEffectType(uint32 type) const { return type == SPELL_AURA_MOUNTED && mounted; }
    uint8 GetStackAmount() const { return stacks; }
    uint8 GetCharges() const { return charges; }
    AuraEffect const* GetEffect(uint8 index) const { return mask & (1 << index) ? &effects[index] : nullptr; }
    void SetLoadedState(int32 max, int32 remaining, int32 count, uint8 stack, uint8 recalculate, int32* amounts)
    {
        maximum = max;
        duration = remaining;
        charges = uint8(count);
        stacks = stack;
        for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
        {
            effects[index].amount = amounts[index];
            effects[index].recalculate = (recalculate & (1 << index)) != 0;
        }
    }
    static Aura* TryCreate(SpellInfo const*, uint8, Unit*, Unit*, int32*, void*, ObjectGuid, ObjectGuid);
    void ApplyForTargets();
};
struct AuraApplication
{
    Aura* aura;
    bool positive = true;
    Aura* GetBase() const { return aura; }
    bool IsPositive() const { return positive; }
    uint8 GetEffectMask() const { return aura->mask; }
};
struct Creature; struct Pet; struct TempSummon; struct Map; struct Player;
struct Unit {
 virtual ~Unit()=default; Map* map=nullptr; bool alive=true,inworld=true; ObjectGuid owner{1},charmer{};
 bool playerControlled=false,attackStopped=false; bool IsPlayer()const{return playerControlled;} void AttackStop(){attackStopped=true;}
bool teleporting = false;
bool IsBeingTeleported() const { return teleporting; }
bool mounted = false, inFlight = false;
bool IsInFlight() const { return inFlight; }
 Aura aura, bubbleAura; bool shield=false, bubble=false; uint32 casts=0,heals=0,bubbleAdds=0;
 virtual ObjectGuid GetGUID() const { return {}; }
 virtual Creature* ToCreature(){return nullptr;}
 bool IsAlive() const{return alive;} bool IsInWorld() const{return inworld;}
 uint32 GetMapId() const; uint32 GetInstanceId() const;
Map* FindMap() const { return map; }
 ObjectGuid GetOwnerGUID() const{return owner;}ObjectGuid GetCharmerGUID() const{return charmer;}
 bool HasAura(uint32 spell) const{return spell == SPELL_SAFETY_BUBBLE ? bubble : shield;}
 virtual void CastSpell(Unit*,uint32 spell,bool){++casts;if (spell==93307)shield=true;else if (spell==991510)++heals;}
 Aura* GetAura(uint32 spell, ObjectGuid caster = {})
 {
     if (spell == SPELL_SAFETY_BUBBLE)
         return bubble && (!caster || caster == bubbleAura.caster) ? &bubbleAura : nullptr;
     return shield ? &aura : nullptr;
 }
 Aura* AddAura(uint32 spell, Unit* target)
 {
     assert(spell == SPELL_SAFETY_BUBBLE && target == this);
     ++bubbleAdds;
     bubble = true;
     bubbleAura.caster = GetGUID();
     return &bubbleAura;
 }
 void RemoveAurasDueToSpell(uint32 spell)
 {
     if (spell == SPELL_SAFETY_BUBBLE_HELPER)
         shield = false;
     if (spell == SPELL_SAFETY_BUBBLE)
         bubble = false;
 }
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
bool scriptedPrivate = true;
bool IsScriptedPrivateInstance() const { return scriptedPrivate; }
 uint32 GetId()const{return id;}uint32 GetInstanceId()const{return instance;}
 Creature* GetCreature(ObjectGuid guid){auto i=creatures.find(guid.value);return i==creatures.end()?nullptr:i->second;}
 TempSummon* SummonCreature(uint32 entry,int,SummonPropertiesEntry const* props,uint32 duration,Player*,uint32 spell){
  auto creature=std::make_unique<TempSummon>();creature->entry=entry;creature->m_Properties=props;creature->map=this;
  creature->timer=duration;creature->spell=spell;creature->guardian=true;auto* result=creature.get();summons.push_back(std::move(creature));return result;
 }
};
uint32 Unit::GetMapId()const{return map?map->id:0;}uint32 Unit::GetInstanceId()const{return map?map->instance:0;}
struct GameTele
{
    float position_x = 0, position_y = 0, position_z = 0;
};
struct Player:Unit {
 Player() { playerControlled = true; }
 ObjectGuid guid{1};bool teleporting=false;float distance=0;std::vector<Unit*>m_Controlled;Pet* pet=nullptr;uint32 pendingPet=0;
 Map* FindMap()const{return map;}Map* GetMap()const{return map;}bool IsBeingTeleported()const{return teleporting;}
 ObjectGuid GetGUID()const{return guid;}float GetExactDist(Creature*)const{return distance;}
 bool IsWithinDistInMap(Creature*,float r)const{return distance<r+10;}
mutable uint32 entranceDistanceReads = 0;
float GetExactDist(float, float, float) const { ++entranceDistanceReads; return distance; }
 int GetPosition()const{return 0;}Pet* GetPet(){return pet;}uint32 GetTemporaryUnsummonedPetNumber()const{return pendingPet;}
std::vector<uint32> removedDynamicObjects;
void RemoveDynObject(uint32 spell) { removedDynamicObjects.push_back(spell); }
using Unit::GetAura;
std::map<uint32, AuraApplication*> applications;
std::vector<std::unique_ptr<Aura>> ownedAuras;
std::vector<std::unique_ptr<AuraApplication>> ownedApplications;
uint32 health = 40, mana = 30, resurrections = 0, corpseBones = 0;
bool resurrectionAllowed = true;
auto const& GetAppliedAuras() const { return applications; }
Aura* GetAura(uint32 spell, ObjectGuid caster, ObjectGuid item)
{
    auto found = applications.find(spell);
    if (found == applications.end())
        return nullptr;
    Aura* aura = found->second->aura;
    return aura->caster == caster && aura->item == item ? aura : nullptr;
}
void RemoveAppliedAuras(std::function<bool(AuraApplication const*)> const& predicate)
{
    auto saved = applications;
    for (auto const& [spell, application] : saved)
        if (predicate(application))
            applications.erase(spell);
}
void SetFullHealth() { health = 100; }
uint32 GetMaxPower(uint32) const { return 100; }
void SetPower(uint32, uint32 value) { mana = value; }
void ResurrectPlayer(float, bool)
{
    ++resurrections;
    if (resurrectionAllowed)
        alive = true;
}
void SpawnCorpseBones() { ++corpseBones; }
};
Aura* Aura::TryCreate(SpellInfo const* info, uint8 mask, Unit* owner, Unit*, int32* base,
    void*, ObjectGuid caster, ObjectGuid item)
{
    auto aura = std::make_unique<Aura>();
    aura->spell = info->Id;
    aura->mask = mask;
    aura->owner = owner;
    aura->caster = caster;
    aura->item = item;
    for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
        aura->effects[index].base = base[index];
    Aura* result = aura.get();
    static_cast<Player*>(owner)->ownedAuras.push_back(std::move(aura));
    return result;
}
void Aura::ApplyForTargets()
{
    auto application = std::make_unique<AuraApplication>();
    application->aura = this;
    Player* player = static_cast<Player*>(owner);
    player->applications[spell] = application.get();
    player->ownedApplications.push_back(std::move(application));
}
struct Segment{uint32 MapId=1;};
enum class ManastormRunState{Preparing,Active,StageComplete,Transitioning,Failed,Finished,Created,AwaitingExit};
struct ManastormRun {
 struct CompanionTransfer {uint32 Entry=0,Spell=0,Properties=0,RemainingMs=0,CapturedMs=0,SummonType=0;float HealthPct=100;uint32 Power=0;uint8 ReactState=0;bool TemporaryPet=false;};
 std::unordered_map<ObjectGuid::LowType,std::vector<CompanionTransfer>> CompanionTransfers;
// ACTUAL_STAGE_BUFF
// ACTUAL_STAGE_RECOVERY
std::unordered_map<ObjectGuid::LowType, StageRecovery> StageRecoveries;
 uint8 level=60;uint32 depth=1,selections=0;
 ManastormRunState state=ManastormRunState::Preparing;Segment segment;uint32 remaining=120000;
 std::map<ObjectGuid,uint32> hearts;std::vector<uint32>members{1};
 void ClearStageAffixState(){selections=0;}uint8 GetCreatureLevel()const{return level;}uint32 GetDepth()const{return depth;}
 uint32 GetRunId()const{return 1;}ManastormRunState GetState()const{return state;}
Segment const&GetSegment()const{return segment;}uint32 GetInstanceId()const{return instanceId;}
uint32 instanceId = 2;
bool previousStage = false;
Segment previousSegment;
uint32 previousInstanceId = 0;
std::unordered_set<uint32> pendingTransfers;
std::unordered_map<uint32, uint32> _cooldownResetInstances;
uint32 ownerGuid = 1;
std::unordered_map<uint32, int> _returnLocations;
std::unordered_map<uint32, int> _memberGadgetLoadouts;
// ACTUAL_COOLDOWN_RESET
// ACTUAL_REMOVE_MEMBER
bool HasPreviousStage() const { return previousStage; }
Segment const& GetPreviousSegment() const { return previousSegment; }
uint32 GetPreviousInstanceId() const { return previousInstanceId; }
bool IsPendingStageTransfer(uint32 guid) const { return pendingTransfers.count(guid) != 0; }
 uint32 GetPreparationProtectionRemainingMs()const{return remaining;}
 auto&GetActiveHeartGuids(){return hearts;}auto const&GetMembers()const{return members;}
};
struct MapMgr {Map* map=nullptr;Map*FindMap(uint32,uint32){return map;}} mapMgr;
auto* sMapMgr=&mapMgr;
namespace ObjectAccessor{Player* player=nullptr;Player*FindConnectedPlayer(ObjectGuid){return player;}}
struct SpellMgr
{
    SpellInfo info;
    SpellInfo const* GetSpellInfo(uint32 id)
    {
        info.Id = id;
        return id ? &info : nullptr;
    }
} spellMgr;
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
// ACTUAL_RECOVERABLE_BUFF
// ACTUAL_CLEAR_DEBUFFS
// ACTUAL_CAPTURE_RECOVERY
// ACTUAL_RESTORE_RECOVERY
// ACTUAL_PREPARE_MEMBER_TRANSFER
// ACTUAL_PROTECTED_PORTAL
// ACTUAL_LEFT_ENTRANCE
struct ManastormMgr {
 ManastormRun const*run=nullptr;std::map<uint64,std::unique_ptr<ManastormRun>>_runs;
ManastormRun const* GetRunFor(Player const* player) const
{
    return run && player && std::find(run->members.begin(), run->members.end(),
        player->GetGUID().GetCounter()) != run->members.end() ? run : nullptr;
}
 bool IsPlayerInUsableEndlessStage(Player const*)const;
bool IsPlayerProtectedDuringTransition(Player const*) const;
 void UpdateHeartPickups(uint32);
};
// ACTUAL_USABLE
// ACTUAL_HEARTS
// ACTUAL_TRANSITION_PROTECTION
void CheckTransitionProtection()
{
    Map completed;
    Map destination;
    destination.instance = 3;
    Player waiting;
    waiting.map = &completed;
    Player arrived;
    arrived.guid = {2};
    arrived.map = &destination;
    Player outsider;
    outsider.guid = {3};
    outsider.map = &completed;
    ManastormRun run;
    run.members = {1, 2};
    ManastormMgr manager;
    manager.run = &run;

    for (auto state : {ManastormRunState::Created, ManastormRunState::Preparing,
        ManastormRunState::Active, ManastormRunState::AwaitingExit,
        ManastormRunState::Failed, ManastormRunState::Finished})
    {
        run.state = state;
        assert(!manager.IsPlayerProtectedDuringTransition(&waiting));
    }

    run.state = ManastormRunState::StageComplete;
    assert(manager.IsPlayerProtectedDuringTransition(&waiting));
    assert(!manager.IsPlayerProtectedDuringTransition(&arrived));
    assert(!manager.IsPlayerProtectedDuringTransition(&outsider));
    assert(!manager.IsPlayerProtectedDuringTransition(nullptr));
    completed.id = 9;
    assert(!manager.IsPlayerProtectedDuringTransition(&waiting));
    completed.id = 1;

    run.previousStage = true;
    run.previousInstanceId = 2;
    run.instanceId = 3;
    run.pendingTransfers = {1, 2};
    for (auto state : {ManastormRunState::Transitioning, ManastormRunState::Preparing,
        ManastormRunState::Active})
    {
        run.state = state;
        assert(manager.IsPlayerProtectedDuringTransition(&waiting));
        assert(!manager.IsPlayerProtectedDuringTransition(&arrived));
    }
    run.state = ManastormRunState::StageComplete;
    assert(manager.IsPlayerProtectedDuringTransition(&waiting));
    assert(manager.IsPlayerProtectedDuringTransition(&arrived));
    run.state = ManastormRunState::Active;
    waiting.map = &destination;
    assert(!manager.IsPlayerProtectedDuringTransition(&waiting));
    waiting.map = nullptr;
    assert(!manager.IsPlayerProtectedDuringTransition(&waiting));
    waiting.map = &completed;
    run.pendingTransfers.erase(1);
    assert(!manager.IsPlayerProtectedDuringTransition(&waiting));
    run.pendingTransfers.insert(1);
    run.state = ManastormRunState::Failed;
    assert(!manager.IsPlayerProtectedDuringTransition(&waiting));
    manager.run = nullptr;
    assert(!manager.IsPlayerProtectedDuringTransition(&waiting));
}
Aura* AddRecoveryAura(Player& player, uint32 spell, bool positive = true)
{
    SpellInfo info;
    info.Id = spell;
    int32 base[3] = {21, 0, 0};
    Aura* aura = Aura::TryCreate(&info, 1, &player, &player, base, nullptr, {1}, {});
    aura->maximum = 30000;
    aura->duration = 3000;
    aura->effects[0].amount = 42;
    aura->ApplyForTargets();
    player.applications[spell]->positive = positive;
    return aura;
}
void CheckStageRecovery()
{
    Map source;
    Map destination;
    destination.instance = 3;
    Player player;
    player.map = &source;
    ManastormRun run;
    run.instanceId = 3;
    CaptureStageRecovery(&player, run);
    assert(run.StageRecoveries.empty());
    run.previousStage = true;
    run.previousInstanceId = 2;
    run.pendingTransfers = {1};

    Aura* buff = AddRecoveryAura(player, 1001);
    buff->stacks = 2;
    buff->charges = 3;
    buff->item = {77};
    Aura* foreign = AddRecoveryAura(player, 1002);
    foreign->caster = {9};
    AddRecoveryAura(player, 2001, false);
    AddRecoveryAura(player, 1003)->passive = true;
    AddRecoveryAura(player, 1004)->area = true;
    AddRecoveryAura(player, 1005)->savable = false;
    AddRecoveryAura(player, 1007)->mounted = true;
    AddRecoveryAura(player, 93307);
    ClearStageDebuffs(&player);
    assert(!player.applications.count(2001));
    assert(player.applications.count(1001));
    CaptureStageRecovery(&player, run);
    assert(run.StageRecoveries.at(1).Buffs.size() == 2);

    player.applications.erase(1001);
    player.map = &destination;
    AddRecoveryAura(player, 2002, false);
    AddRecoveryAura(player, 1006);
    RestoreStageRecovery(&player, run);
    Aura* restored = player.GetAura(1001, {1}, {77});
    assert(restored && restored->stacks == 2 && restored->charges == 3);
    assert(restored->effects[0].amount == 42 && restored->effects[0].base == 21);
    assert(restored->duration == 30000 && foreign->duration == 30000);
    assert(player.applications.at(1006)->aura->duration == 30000);
    assert(!player.applications.count(2002));
    assert(player.health == 100 && player.mana == 100 && run.StageRecoveries.empty());

    player.health = 20;
    player.mana = 10;
    restored->duration = 1000;
    RestoreStageRecovery(&player, run);
    assert(player.health == 20 && player.mana == 10 && restored->duration == 1000);
    run.StageRecoveries[1].DestinationInstanceId = 4;
    RestoreStageRecovery(&player, run);
    assert(player.health == 20 && player.mana == 10);
    run.StageRecoveries[1].DestinationInstanceId = 3;
    player.alive = false;
    RestoreStageRecovery(&player, run);
    assert(player.alive && player.resurrections == 1 && player.corpseBones == 1);
    assert(player.health == 100 && player.mana == 100);
}
void CheckStageRepairPolicies()
{
    Map source;
    Player follower;
    follower.guid = {2};
    follower.map = &source;
    TempSummon guardian;
    guardian.owner = {2};
    guardian.map = &source;
    guardian.guardian = true;
    guardian.m_Properties = &sSummonPropertiesStore.entry;
    guardian.spell = 42;
    follower.m_Controlled = {&guardian};
    ManastormRun run;
    run.members = {1, 2};
    run.previousStage = true;
    run.previousInstanceId = 2;
    run.instanceId = 3;
    run.pendingTransfers = {1, 2};
    assert(PrepareStageMemberTransfer(&follower, run));
    assert(run.CompanionTransfers.at(2).size() == 1);
    assert(run.StageRecoveries.at(2).DestinationInstanceId == 3);

    Player dead;
    dead.map = &source;
    dead.alive = false;
    assert(PrepareStageMemberTransfer(&dead, run));
    assert(dead.alive && dead.corpseBones == 1);
    dead.alive = false;
    dead.resurrectionAllowed = false;
    assert(!PrepareStageMemberTransfer(&dead, run));
    assert(!dead.alive && dead.corpseBones == 1);

    Player entrance;
    entrance.shield = true;
    ClearSafetyBubble(&entrance, true);
    assert(!entrance.shield);
    assert(std::find(entrance.removedDynamicObjects.begin(), entrance.removedDynamicObjects.end(),
        SPELL_SAFETY_BUBBLE) == entrance.removedDynamicObjects.end());
    ClearSafetyBubble(&entrance);
    assert(std::find(entrance.removedDynamicObjects.begin(), entrance.removedDynamicObjects.end(),
        SPELL_SAFETY_BUBBLE) != entrance.removedDynamicObjects.end());

    Creature portal;
    portal.entry = NPC_STAGE_PORTAL;
    portal.map = &source;
    assert(IsProtectedStagePortal(&portal));
    source.scriptedPrivate = false;
    assert(!IsProtectedStagePortal(&portal));
    source.scriptedPrivate = true;
    portal.entry = 123;
    assert(!IsProtectedStagePortal(&portal));
    assert(!IsProtectedStagePortal(nullptr));

    assert(run.MarkStageCooldownsReset(1));
    assert(!run.MarkStageCooldownsReset(1));
    assert(run.MarkStageCooldownsReset(2));
    run.depth = 1;
    run.instanceId = 4;
    assert(run.MarkStageCooldownsReset(1));
    assert(run.MarkStageCooldownsReset(2));
    assert(!run.MarkStageCooldownsReset(2));
}
void CheckEntranceStartReadiness()
{
    Map stage;
    Map previous;
    previous.instance = 9;
    GameTele entrance;
    Player member;
    member.map = &stage;
    member.distance = 8.0f;
    assert(!HasPlayerLeftStageEntrance(&member, &stage, entrance));
    member.distance = 8.1f;
    assert(HasPlayerLeftStageEntrance(&member, &stage, entrance));
    member.mounted = true;
    assert(HasPlayerLeftStageEntrance(&member, &stage, entrance));
    member.entranceDistanceReads = 0;

    member.inFlight = true;
    assert(!HasPlayerLeftStageEntrance(&member, &stage, entrance));
    member.inFlight = false;

    member.map = &previous;
    assert(!HasPlayerLeftStageEntrance(&member, &stage, entrance));
    previous.id = 7;
    assert(!HasPlayerLeftStageEntrance(&member, &stage, entrance));
    member.map = &stage;
    member.teleporting = true;
    assert(!HasPlayerLeftStageEntrance(&member, &stage, entrance));
    member.teleporting = false;
    member.inworld = false;
    assert(!HasPlayerLeftStageEntrance(&member, &stage, entrance));
    member.inworld = true;
    member.alive = false;
    assert(!HasPlayerLeftStageEntrance(&member, &stage, entrance));
    member.alive = true;
    member.map = nullptr;
    assert(!HasPlayerLeftStageEntrance(&member, &stage, entrance));
    assert(!HasPlayerLeftStageEntrance(&member, nullptr, entrance));
    assert(!HasPlayerLeftStageEntrance(nullptr, &stage, entrance));
    assert(member.entranceDistanceReads == 0);
}
void CheckIndividualDeparture()
{
    ManastormRun run;
    run.members = {1, 2, 3};
    run.state = ManastormRunState::Active;
    run.depth = 12;
    run.pendingTransfers = {1, 2, 3};
    run._returnLocations = {{1, 5}, {2, 6}};
    run._memberGadgetLoadouts = {{1, 10}, {2, 20}};
    run._cooldownResetInstances = {{1, 3}, {2, 3}};
    run.CompanionTransfers[1] = {{}};
    run.CompanionTransfers[2] = {{}};
    run.StageRecoveries[1].DestinationInstanceId = 4;
    run.StageRecoveries[2].DestinationInstanceId = 4;
    assert(!run.RemoveMember(9));
    assert(run.members.size() == 3 && run.ownerGuid == 1);
    assert(run.RemoveMember(1));
    assert((run.members == std::vector<uint32>{2, 3}));
    assert(run.ownerGuid == 2 && run.state == ManastormRunState::Active && run.depth == 12);
    assert(!run.pendingTransfers.count(1) && run.pendingTransfers.count(2));
    assert(!run._returnLocations.count(1) && run._returnLocations.at(2) == 6);
    assert(!run._memberGadgetLoadouts.count(1) && run._memberGadgetLoadouts.at(2) == 20);
    assert(!run._cooldownResetInstances.count(1) && run._cooldownResetInstances.at(2) == 3);
    assert(!run.CompanionTransfers.count(1) && run.CompanionTransfers.count(2));
    assert(!run.StageRecoveries.count(1) && run.StageRecoveries.count(2));
    assert(!run.RemoveMember(1));
    assert(run.RemoveMember(3) && run.ownerGuid == 2 && run.members.size() == 1);
    assert(run.RemoveMember(2) && run.ownerGuid == 0 && run.members.empty());
}
int main(){
    CheckIndividualDeparture();
    CheckEntranceStartReadiness();
    CheckStageRepairPolicies();
    CheckStageRecovery();
    CheckTransitionProtection();
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
 assert(player.shield&&player.aura.duration==120000);
 assert(player.bubble && player.bubbleAura.maximum == 120000 && player.bubbleAura.duration == 120000);
 run.remaining=70000;ApplySafetyBubbleProtection(&player,run);
 assert(player.casts==1&&player.aura.duration==70000);
 assert(player.bubbleAdds == 1 && player.bubbleAura.maximum == 70000 && player.bubbleAura.duration == 70000);
 Player follower;
 follower.guid = {2};
 follower.map = &map;
 follower.distance = 7.0f;
 ApplySafetyBubbleProtection(&follower, run);
 assert(follower.bubble && follower.bubbleAura.caster == follower.GetGUID());
 assert(follower.bubbleAura.duration == 70000 && !HasPlayerLeftStageEntrance(&follower, &map, {}));
 ClearSafetyBubble(&follower, true);
 assert(!follower.bubble && !follower.shield);
 assert(std::find(follower.removedDynamicObjects.begin(), follower.removedDynamicObjects.end(),
     SPELL_SAFETY_BUBBLE) == follower.removedDynamicObjects.end());
 run.state = ManastormRunState::Active;
 ApplySafetyBubbleProtection(&follower, run);
 assert(!follower.bubble && !follower.shield);
 run.state = ManastormRunState::Preparing;
 follower.alive = false;
 ApplySafetyBubbleProtection(&follower, run);
 assert(!follower.bubble && !follower.shield);
 follower.alive = true;
 follower.map = nullptr;
 ApplySafetyBubbleProtection(&follower, run);
 assert(!follower.bubble && !follower.shield);
 TempSummon guardian;guardian.map=&map;guardian.guardian=true;guardian.m_Properties=&sSummonPropertiesStore.entry;
 guardian.spell=42;guardian.entry=99;guardian.health=35;guardian.power=20;player.m_Controlled={&guardian};
 CaptureStageCompanions(&player,run);assert(run.CompanionTransfers[1].size()==1);
 clockMs+=3000;player.m_Controlled.clear();RestoreStageCompanions(&player,run);
 assert(map.summons.size()==1&&map.summons[0]->GetTimer()==17000);
 assert(map.summons[0]->health==35&&map.summons[0]->power==20&&map.summons[0]->shield);
 assert(!map.summons[0]->bubble);
 RestoreStageCompanions(&player,run);assert(map.summons.size()==1);
 player.m_Controlled={map.summons[0].get()};ClearSafetyBubble(&player);
 assert(!player.shield&&!player.bubble&&!map.summons[0]->shield);
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
