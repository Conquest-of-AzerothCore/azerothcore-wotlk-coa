#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <initializer_list>
#include <limits>
#include <list>
#include <map>
#include <set>
#include <vector>
using uint32=std::uint32_t;using int32=std::int32_t;using uint8=std::uint8_t;using uint64=std::uint64_t;
using ObjectGuid=uint32;
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif
constexpr uint32 CLASS_SON_OF_ARUGAL=20,SPELLVALUE_BASE_POINT0=0,EFFECT_0=0,POWER_RAGE=1,
    AURA_STATE_BLEEDING=1,SPELL_MISS_NONE=0,ALLSPELLHOOK_ON_CAST=1,ALLSPELLHOOK_ON_CALCULATED_TARGET=2,
    ALLSPELLHOOK_ON_CRIT_CHANCE=3,ALLSPELLHOOK_ON_HIT_RESULT=4,UNITHOOK_ON_PERIODIC_DAMAGE_RESULT=5,
    GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR=6,SPELL_ATTR2_CANT_CRIT=1,
    SPELL_ATTR3_IGNORE_CASTER_MODIFIERS=2,SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS=4,
    TARGET_UNIT_SRC_AREA_ENTRY=7,SPELL_EFFECT_DUMMY=3;
using SpellEffIndex=uint32;
// POOLED_HEADER
struct Unit;struct Player;
struct SpellInfo
{
    uint32 Id=504260,SpellFamilyName=26,PowerType=1,AttributesEx2=0,AttributesEx3=0,AttributesEx4=0;
    bool AscensionInheritsResolvedAmount=false;
    struct Effect{float BonusMultiplier=1.0f;}Effects[3];
};
struct SpellMgr
{
    std::map<uint32,uint32> roots;
    uint32 GetFirstSpellInChain(uint32 id)const{auto it=roots.find(id);return it==roots.end()?id:it->second;}
} manager;
SpellMgr* sSpellMgr=&manager;
struct Aura {uint32 id=0;ObjectGuid caster=0;uint32 GetId()const{return id;}ObjectGuid GetCasterGUID()const{return caster;}};
struct AuraApplication{Aura aura;Aura* GetBase(){return &aura;}};
std::map<ObjectGuid,Unit*> world;
struct Unit
{
    virtual ~Unit()=default;virtual Player* ToPlayer(){return nullptr;}
    ObjectGuid guid=1;bool alive=true,inWorld=true,phase=true,friendly=false,bleeding=false,front=true,combat=false;
    Unit* ToUnit(){return this;}bool IsInCombat()const{return combat;}
    uint32 health=50;
    std::map<uint32,AuraApplication*> applied;
    bool IsAlive()const{return alive;}bool IsInWorld()const{return inWorld;}
    bool InSamePhase(Unit* unit)const{return phase && unit->phase;}
    bool HasAuraState(uint32 state)const{assert(state==1);return bleeding;}
    bool HealthBelowPct(uint32 pct)const{return health<pct;}
    bool HasInArc(float,Unit*)const{return front;}
    auto const& GetAppliedAuras()const{return applied;}
    bool IsValidAttackTarget(Unit* unit)const{return unit!=this && !unit->friendly;}
    bool IsFriendlyTo(Unit* unit)const{return unit->friendly;}
};
using WorldObject=Unit;
struct Player : Unit
{
    uint32 cls=20;std::map<uint32,uint32> auras;std::set<uint32> removedCooldowns;
    int32 rage=0;bool killOnCopy=false;
    struct Cast{uint32 id;Unit* target;int32 amount;};std::vector<Cast> casts;
    Player* ToPlayer()override{return this;}uint32 getClass()const{return cls;}
    bool HasAura(uint32 id)const{return auras.contains(id);}
    void RemoveAurasDueToSpell(uint32 id){auras.erase(id);}
    void RemoveSpellCooldown(uint32 id,bool update){assert(update);removedCooldowns.insert(id);}
    void ModifyPower(uint32 type,int32 amount){assert(type==1);rage+=amount;}
    void CastCustomSpell(uint32 id,uint32 key,int32 amount,Unit* target,bool triggered)
    {assert(key==0 && triggered);casts.push_back({id,target,amount});if(killOnCopy)target->alive=false;}
    void CastSpell(Unit* target,uint32 id,bool triggered)
    {assert(target==this && triggered);auras[id]=std::min(2u,auras[id]+1);casts.push_back({id,target,0});}
};
namespace ObjectAccessor {Unit* GetUnit(Unit&,ObjectGuid guid){auto it=world.find(guid);return it==world.end()?nullptr:it->second;}}
struct TargetInfo{int32 damage=100,damageBeforeTakenMods=80;uint8 missCondition=0;};
struct Spell
{
    Player* caster=nullptr;SpellInfo info;bool triggered=false;int32 cost=240;std::map<uint32,uint64> markers;
    Player* GetCaster()const{return caster;}SpellInfo const* GetSpellInfo()const{return &info;}
    bool IsTriggered()const{return triggered;}int32 GetPowerCost()const{return cost;}
    uint64 GetScriptValue(uint32 id)const{auto it=markers.find(id);return it==markers.end()?0:it->second;}
    void SetScriptValue(uint32 id,uint64 value){markers[id]=value;}
};
struct AllSpellScript
{
    AllSpellScript(char const*,std::initializer_list<uint32>){}
    virtual void OnSpellCast(Spell*,Unit*,SpellInfo const*,bool){}
    virtual void OnSpellCritChance(Spell*,Unit*,float&){}
    virtual void OnSpellCalculatedTarget(Spell*,Unit*,TargetInfo&){}
    virtual void OnSpellHitResult(Spell*,Unit*,uint8,uint32,uint32,bool){}
};
struct UnitScript
{UnitScript(char const*,bool,std::initializer_list<uint32>){}virtual void OnPeriodicDamageResult(Unit*,Unit*,uint32,SpellInfo const*){}};
struct GlobalScript
{GlobalScript(char const*,std::initializer_list<uint32>){}virtual void OnLoadSpellCustomAttr(SpellInfo*){}};
uint32 nextRoll=0,rolls=0;
bool roll_chance_i(uint32 chance){++rolls;return nextRoll<chance;}
struct Hook {template<class T>void operator+=(T){}};
struct SpellScript
{
    Unit* fixtureCaster=nullptr;Unit* fixtureTarget=nullptr;Hook OnObjectAreaTargetSelect,OnEffectHitTarget;
    virtual bool Validate(SpellInfo const*){return true;}virtual void Register(){}
    Unit* GetCaster(){return fixtureCaster;}Unit* GetHitUnit(){return fixtureTarget;}
    bool ValidateSpellInfo(std::initializer_list<uint32>){return true;}
};
#define PrepareSpellScript(name)
#define SpellObjectAreaTargetSelectFn(...) 0
#define SpellEffectFn(...) 0
#define RegisterSpellScript(name)
// SOURCE
int main()
{
    Player player,ally;player.guid=1;ally.guid=3;Unit enemy;enemy.guid=2;
    world[player.guid]=&player;world[ally.guid]=&ally;world[enemy.guid]=&enemy;
    Spell spell;spell.caster=&player;bloodmage_secondary_casts hook;
    for(uint32 id:{504260u,504813u,504814u,504815u,504816u,504817u,504818u,504819u,504820u})
    {
        manager.roots[id]=504260;spell.info.Id=id;
        TargetInfo hit;enemy.bleeding=false;hook.OnSpellCalculatedTarget(&spell,&enemy,hit);assert(hit.damage==100);
        enemy.bleeding=true;hook.OnSpellCalculatedTarget(&spell,&enemy,hit);assert(hit.damage==125 && hit.damageBeforeTakenMods==100);
    }
    spell.info.Id=572855;float chance=17;
    hook.OnSpellCritChance(&spell,&enemy,chance);assert(chance==100);
    enemy.bleeding=false;chance=17;hook.OnSpellCritChance(&spell,&enemy,chance);assert(chance==17);
    for(uint32 mask=0;mask<8;++mask)
    {
        spell.info.Id=800490;spell.markers.clear();player.casts.clear();
        enemy.bleeding=mask&1;enemy.health=mask&2?34:50;enemy.front=!(mask&4);
        TargetInfo hit;hook.OnSpellCalculatedTarget(&spell,&enemy,hit);
        enemy.health=10;
        hook.OnSpellHitResult(&spell,&enemy,0,100,0,false);
        auto count=player.casts.size();assert(count==uint32(bool(mask&1)+bool(mask&2)+bool(mask&4)));
        for(auto const& cast:player.casts)assert(cast.target==&enemy && cast.amount==100);
        hook.OnSpellHitResult(&spell,&enemy,0,100,0,false);assert(player.casts.size()==count);
    }
    player.casts.clear();spell.info.Id=572855;
    for(int n=0;n<3;++n){spell.markers.clear();hook.OnSpellHitResult(&spell,&enemy,0,100,0,false);}
    assert(player.auras[572856]==2);
    for(uint32 id:{562720u,562572u})
    {
        player.auras[572856]=2;spell.info.Id=id;
        hook.OnSpellHitResult(&spell,&player,1,0,0,false);assert(player.auras[572856]==2);
        hook.OnSpellHitResult(&spell,&player,0,0,0,false);assert(!player.HasAura(572856));
    }
    player.casts.clear();spell.info.Id=572855;spell.markers.clear();spell.triggered=true;
    hook.OnSpellHitResult(&spell,&enemy,0,100,0,false);assert(player.casts.empty());spell.triggered=false;
    hook.OnSpellHitResult(&spell,&enemy,1,100,0,false);assert(player.casts.empty());
    hook.OnSpellHitResult(&spell,&enemy,0,0,0,false);assert(player.casts.size()==1 && player.casts.back().id==572856);
    spell.info.Id=504260;hook.OnSpellCast(&spell,&player,&spell.info,false);assert(player.removedCooldowns.empty());
    player.auras[704659]=1;nextRoll=40;hook.OnSpellCast(&spell,&player,&spell.info,false);assert(player.removedCooldowns.empty());
    nextRoll=39;hook.OnSpellCast(&spell,&player,&spell.info,false);assert(player.removedCooldowns.contains(504260));
    for(uint32 id:{804685u,578304u,578305u,806928u,806929u,806930u,806931u,806932u})
    {
        spell.info.Id=id;spell.cost=136;player.rage=0;hook.OnSpellCast(&spell,&player,&spell.info,false);assert(player.rage==68);
        spell.cost=0;hook.OnSpellCast(&spell,&player,&spell.info,false);assert(player.rage==68);
    }
    spell.cost=240;spell.triggered=true;hook.OnSpellCast(&spell,&player,&spell.info,false);assert(player.rage==68);
    spell.triggered=false;spell.info.PowerType=0;hook.OnSpellCast(&spell,&player,&spell.info,false);assert(player.rage==68);
    bloodmage_kiss_periodic periodic;player.casts.clear();ally.casts.clear();enemy.alive=true;enemy.friendly=false;
    periodic.OnPeriodicDamageResult(&enemy,&ally,400,&spell.info);assert(player.casts.empty());
    AuraApplication curse{{504275,player.guid}},rank{{504276,player.guid}},foreign{{504275,ally.guid}};
    manager.roots[504276]=504275;enemy.applied={{1,&curse},{2,&rank},{3,&foreign}};
    periodic.OnPeriodicDamageResult(&enemy,&ally,400,&spell.info);
    assert(player.casts.size()==1 && ally.casts.size()==1 && player.casts[0].id==504785 && player.casts[0].amount==100);
    periodic.OnPeriodicDamageResult(&enemy,&ally,0,&spell.info);assert(player.casts.size()==1);
    player.killOnCopy=true;periodic.OnPeriodicDamageResult(&enemy,&ally,400,&spell.info);
    assert(player.casts.size()==2 && ally.casts.size()==1);player.killOnCopy=false;enemy.alive=true;
    player.cls=1;ally.phase=false;periodic.OnPeriodicDamageResult(&enemy,&ally,400,&spell.info);assert(player.casts.size()==2);
    bloodmage_secondary_contracts contracts;
    for(uint32 id:{802883u,802884u,805612u,504785u})
    {
        SpellInfo info;info.Id=id;contracts.OnLoadSpellCustomAttr(&info);
        assert(info.AscensionInheritsResolvedAmount && !info.Effects[0].BonusMultiplier);
        assert(info.AttributesEx2 && info.AttributesEx3 && info.AttributesEx4);
    }
    player.cls=20;player.casts.clear();enemy.alive=false;enemy.friendly=false;
    Unit living, friendly;friendly.alive=false;friendly.friendly=true;
    std::list<WorldObject*> corpses{&living,&friendly,&enemy,&player,nullptr};
    spell_ascension_blood_feast_corpses selection;selection.fixtureCaster=&player;selection.Select(corpses);
    assert(corpses.size()==1 && corpses.front()==&enemy);
    spell_ascension_blood_feast_drain drain;drain.fixtureCaster=&player;drain.fixtureTarget=&enemy;
    drain.Drain(0);assert(player.casts.size()==1 && player.casts.back().id==706608);
    player.combat=true;drain.Drain(0);player.combat=false;
    enemy.alive=true;drain.Drain(0);enemy.alive=false;
    enemy.friendly=true;drain.Drain(0);enemy.friendly=false;
    player.alive=false;drain.Drain(0);player.alive=true;
    player.cls=1;drain.Drain(0);player.cls=20;
    assert(player.casts.size()==1);
    SpellInfo info;info.Id=42;contracts.OnLoadSpellCustomAttr(&info);assert(!info.AscensionInheritsResolvedAmount);
}
