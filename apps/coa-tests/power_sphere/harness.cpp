#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <initializer_list>
#include <list>
#include <map>
#include <memory>
#include <vector>
using uint32=std::uint32_t;using int32=std::int32_t;using uint8=std::uint8_t;
constexpr uint32 CLASS_STORMBRINGER=16,SPELL_SCHOOL_MASK_ARCANE=64,SPELL_SCHOOL_MASK_NATURE=8,
    SPELLVALUE_BASE_POINT0=0,EFFECT_0=0,TRIGGERED_FULL_MASK=1,REACT_PASSIVE=0,
    UNIT_FLAG_NON_ATTACKABLE=2,UNIT_FLAG_NOT_SELECTABLE=4,ALLSPELLHOOK_ON_HIT_RESULT=1,
    GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR=2,SPELL_MISS_NONE=0;
constexpr float CONTACT_DISTANCE=0.5f;
using EvadeReason=int;
struct ObjectGuid {uint32 value=0;auto operator<=>(ObjectGuid const&)const=default;};
struct Position {float x=0;};
struct Player;struct Unit;struct Creature;struct TempSummon;struct ScriptedAI;struct SummonPropertiesEntry {};
struct Map {TempSummon* SummonCreature(uint32,Position const&,SummonPropertiesEntry const*,uint32,Player*,uint32);};
std::map<ObjectGuid,Unit*> objects;
struct Unit : Position
{
    virtual ~Unit()=default;virtual Player* ToPlayer(){return nullptr;}
    ObjectGuid guid;Map* map=nullptr;bool alive=true,world=true,phase=true,friendly=false;
    ObjectGuid GetGUID()const{return guid;}Map* GetMap()const{return map;}
    bool IsAlive()const{return alive;}bool IsInWorld()const{return world;}
    bool InSamePhase(Unit* unit)const{return phase && unit->phase;}
    bool IsValidAttackTarget(Unit* unit)const{return unit!=this && !unit->friendly;}
    Position GetPosition()const{return *this;}
};
using WorldObject=Unit;
struct SpellInfo
{
    uint32 Id=706433,SpellFamilyName=22,ProcChance=25,DmgClass=1;
    struct Effect {float BonusMultiplier=1.0f;int32 CalcValue(Unit*)const{return 997;}} Effects[3];
};
struct SpellMgr
{
    SpellInfo info;
    SpellInfo const* GetSpellInfo(uint32)const{return &info;}
    uint32 GetFirstSpellInChain(uint32 id)const{return id>=572861 && id<=572867?567555:id;}
} mgr;
SpellMgr* sSpellMgr=&mgr;
struct Store {SummonPropertiesEntry props;SummonPropertiesEntry const* LookupEntry(uint32 id){assert(id==61);return &props;}}
    sSummonPropertiesStore;
struct CustomSpellValues {int32 amount=0;void AddSpellMod(uint32 key,int32 value){assert(key==0);amount=value;}};
struct SpellCastTargets
{
    Unit* target=nullptr;Position destination;
    void SetUnitTarget(Unit* unit){target=unit;}void SetDst(Position const& point){destination=point;}
};
struct MotionMaster {Unit* target=nullptr;void MoveChase(Unit* unit,float distance){assert(distance==0);target=unit;}};
struct Creature : Unit
{
    Player* owner=nullptr;ScriptedAI* ai=nullptr;MotionMaster motion;uint32 flags=0;
    uint32 entry=503201;
    Player* GetCharmerOrOwnerPlayerOrPlayerItself(){return owner;}
    void SetReactState(uint32 state){assert(state==REACT_PASSIVE);}void SetUnitFlag(uint32 value){flags|=value;}
    void DespawnOrUnsummon(){world=false;}ScriptedAI* AI(){return ai;}
    MotionMaster* GetMotionMaster(){return &motion;}
    bool IsWithinDistInMap(Unit* unit,float range)const{return map==unit->map && std::abs(x-unit->x)<=range;}
};
struct TempSummon : Creature {};
struct Player : Unit
{
    uint32 cls=16;bool talent=true;int32 arcane=1000,nature=2000;
    std::vector<Creature*> minions;
    struct Explosion {Unit* target;Position destination;int32 amount;};std::vector<Explosion> explosions;
    Player* ToPlayer()override{return this;}uint32 getClass()const{return cls;}
    bool HasAura(uint32 id)const{assert(id==706434);return talent;}
    int32 SpellBaseDamageBonusDone(uint32 school)const{return school==64?arcane:nature;}
    void GetAllMinionsByEntry(std::list<Creature*>& result,uint32 id)
    {for(Creature* summon:minions)if (summon->entry==id)result.push_back(summon);}
    void CastSpell(SpellCastTargets const& targets,SpellInfo const*,CustomSpellValues* values,uint32 mask)
    {assert(mask==1);explosions.push_back({targets.target,targets.destination,values->amount});}
};
struct ScriptedAI
{
    Creature* me;explicit ScriptedAI(Creature* unit):me(unit){}virtual ~ScriptedAI()=default;
    virtual void AttackStart(Unit*){}virtual void MoveInLineOfSight(Unit*){}virtual void EnterEvadeMode(EvadeReason){}
    virtual void IsSummonedBy(WorldObject*){}virtual void SetGUID(ObjectGuid const&,int32=0){}virtual void UpdateAI(uint32){}
};
namespace ObjectAccessor {Unit* GetUnit(Unit&,ObjectGuid const& guid){auto it=objects.find(guid);return it==objects.end()?nullptr:it->second;}}
struct Spell
{
    Player* owner;SpellInfo info;Player* GetCaster()const{return owner;}SpellInfo const* GetSpellInfo()const{return &info;}
};
struct AllSpellScript
{
    AllSpellScript(char const*,std::initializer_list<uint32>){}
    virtual void OnSpellHitResult(Spell*,Unit*,uint8,uint32,uint32,bool){}
};
struct GlobalScript
{GlobalScript(char const*,std::initializer_list<uint32>){}virtual void OnLoadSpellCustomAttr(SpellInfo*){}};
uint32 nextRoll=0,rolls=0;
bool roll_chance_i(uint32 chance){++rolls;return nextRoll<chance;}
#define RegisterCreatureAI(name)
// SOURCE
std::vector<std::unique_ptr<TempSummon>> creatures;
std::vector<std::unique_ptr<ScriptedAI>> scripts;
TempSummon* Map::SummonCreature(uint32 entry,Position const& position,SummonPropertiesEntry const*,uint32 duration,
    Player* owner,uint32 spell)
{
    assert(entry==503201 && duration==0 && spell==706434);
    auto summon=std::make_unique<TempSummon>();summon->owner=owner;summon->map=this;summon->x=position.x;
    summon->guid={100+uint32(creatures.size())};objects[summon->guid]=summon.get();
    auto ai=std::make_unique<npc_ascension_power_sphere>(summon.get());summon->ai=ai.get();ai->IsSummonedBy(owner);
    summon->motion.target=owner;
    owner->minions.push_back(summon.get());TempSummon* result=summon.get();
    scripts.push_back(std::move(ai));creatures.push_back(std::move(summon));return result;
}
int main()
{
    Map map,otherMap;Player owner,otherOwner;Unit target,second;
    owner.guid={1};otherOwner.guid={2};target.guid={3};second.guid={4};
    owner.map=otherOwner.map=target.map=second.map=&map;target.x=10;second.x=20;
    for(Unit* unit:{static_cast<Unit*>(&owner),static_cast<Unit*>(&otherOwner),&target,&second})objects[unit->guid]=unit;
    Spell spell{&owner};spell.info.Id=804020;stormbringer_sphere_hits hook;
    nextRoll=25;hook.OnSpellHitResult(&spell,&target,0,100,0,false);assert(!FindSphere(&owner));
    nextRoll=0;hook.OnSpellHitResult(&spell,&target,1,100,0,false);assert(rolls==1);
    hook.OnSpellHitResult(&spell,&target,0,0,0,false);assert(!FindSphere(&owner));
    target.friendly=true;hook.OnSpellHitResult(&spell,&target,0,100,0,false);target.friendly=false;
    owner.talent=false;hook.OnSpellHitResult(&spell,&target,0,100,0,false);owner.talent=true;
    owner.cls=1;hook.OnSpellHitResult(&spell,&target,0,100,0,false);owner.cls=16;
    spell.info.SpellFamilyName=3;hook.OnSpellHitResult(&spell,&target,0,100,0,false);spell.info.SpellFamilyName=22;
    assert(!FindSphere(&owner));
    hook.OnSpellHitResult(&spell,&target,0,100,0,false);
    Creature* sphere=FindSphere(&owner);assert(sphere && sphere->motion.target==&target && creatures.size()==1);
    hook.OnSpellHitResult(&spell,&second,0,100,0,true);assert(creatures.size()==1);
    assert(!FindSphere(&otherOwner));
    for(uint32 id:{567555u,572861u,572862u,572863u,572864u,572865u,572866u,572867u})
    {
        spell.info.Id=id;hook.OnSpellHitResult(&spell,&second,0,0,0,false);assert(sphere->motion.target==&second);
        hook.OnSpellHitResult(&spell,&target,0,0,0,false);assert(sphere->motion.target==&target);
    }
    sphere->AI()->UpdateAI(100);assert(owner.explosions.empty());
    sphere->x=target.x;sphere->AI()->UpdateAI(100);
    assert(owner.explosions.size()==1 && owner.explosions[0].amount==1967);
    assert(owner.explosions[0].target==&target && owner.explosions[0].destination.x==target.x);
    sphere->AI()->UpdateAI(100);assert(owner.explosions.size()==1 && !FindSphere(&owner));
    spell.info.Id=706433;hook.OnSpellHitResult(&spell,&second,0,1967,0,false);assert(creatures.size()==1);
    spell.info.Id=804020;owner.arcane=3000;owner.nature=500;
    hook.OnSpellHitResult(&spell,&target,0,100,0,false);sphere=FindSphere(&owner);sphere->x=target.x;
    sphere->AI()->UpdateAI(100);assert(owner.explosions.back().amount==2452);
    for(int failure=0;failure<7;++failure)
    {
        hook.OnSpellHitResult(&spell,&target,0,100,0,false);sphere=FindSphere(&owner);assert(sphere);
        if (failure==0)owner.alive=false;
        if (failure==1)owner.talent=false;
        if (failure==2)target.alive=false;
        if (failure==3)target.friendly=true;
        if (failure==4)target.phase=false;
        if (failure==5)target.map=&otherMap;
        if (failure==6)objects.erase(target.guid);
        sphere->AI()->UpdateAI(100);assert(!FindSphere(&owner) && owner.explosions.size()==2);
        owner.alive=owner.talent=target.alive=target.phase=true;target.friendly=false;target.map=&map;objects[target.guid]=&target;
    }
    stormbringer_sphere_contracts contracts;SpellInfo info;contracts.OnLoadSpellCustomAttr(&info);
    assert(!info.Effects[0].BonusMultiplier && info.DmgClass==1);
    info=SpellInfo{};info.SpellFamilyName=3;contracts.OnLoadSpellCustomAttr(&info);assert(info.Effects[0].BonusMultiplier==1);
}
