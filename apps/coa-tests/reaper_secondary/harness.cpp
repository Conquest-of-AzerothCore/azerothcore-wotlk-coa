#include <algorithm>
#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <limits>
#include <map>
#include <vector>
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using uint8 = std::uint8_t;
using int32 = std::int32_t;
using AuraRemoveMode = uint32;
using AuraEffectHandleModes = uint32;
constexpr uint32 CLASS_REAPER=30, EFFECT_0=0, SPELLVALUE_BASE_POINT0=0,
    UNITHOOK_ON_AURA_APPLY=1, UNITHOOK_ON_AURA_REMOVE=2,
    ALLSPELLHOOK_ON_BEFORE_EFFECTS=3, ALLSPELLHOOK_ON_CAST=4, ALLSPELLHOOK_ON_HIT_RESULT=5,
    GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR=6, SPELL_MISS_NONE=0,
    SPELL_AURA_PROC_TRIGGER_SPELL=42, SPELL_AURA_DUMMY=4, SPELL_SCHOOL_MASK_NORMAL=1,
    AURA_EFFECT_HANDLE_REAL=1, SPELL_DAMAGE_CLASS_NONE=0;
constexpr bool TRIGGERED_FULL_MASK=true;
// ENUMS
struct Unit;
struct Player;
struct SpellInfo
{
    uint32 Id=0, SpellFamilyName=36, ProcFlags=123, DmgClass=1, AttributesCu=SPELL_ATTR0_CU_FORCE_AURA_SAVING;
    struct Effect
    {
        int32 value=0;
        uint32 ApplyAuraName=42;
        int32 CalcValue(Unit*) const { return value; }
    } Effects[3];
};
struct SpellMgr
{
    std::map<uint32, SpellInfo> rows;
    std::map<uint32, uint32> roots;
    SpellInfo const* GetSpellInfo(uint32 id)
    { auto it=rows.find(id); return it==rows.end()?nullptr:&it->second; }
    uint32 GetFirstSpellInChain(uint32 id)
    { auto it=roots.find(id); return it==roots.end()?id:it->second; }
} manager;
SpellMgr* sSpellMgr=&manager;
struct Aura
{
    uint32 id=0, caster=0;
    uint8 stacks=1;
    uint32 GetId() const { return id; }
    uint32 GetCasterGUID() const { return caster; }
    uint8 GetStackAmount() const { return stacks; }
};
struct AuraApplication { Aura* aura=nullptr; Aura* GetBase() const { return aura; } };
struct AuraEffect {};
struct Unit
{
    virtual ~Unit()=default;
    virtual Player* ToPlayer() { return nullptr; }
    virtual bool IsPlayer() const { return false; }
    virtual uint32 getClass() const { return 0; }
    uint32 guid=1;
    bool alive=true, inWorld=true, friendly=false;
    std::map<std::pair<uint32,uint32>,Aura> auras;
    struct Cast { uint32 id; Unit* target; int32 amount; };
    std::vector<Cast> casts;
    uint32 GetGUID() const { return guid; }
    bool IsAlive() const { return alive; }
    bool IsInWorld() const { return inWorld; }
    bool IsFriendlyTo(Unit* target) const { return target==this || target->friendly; }
    Aura* GetAura(uint32 id,uint32 owner)
    { auto it=auras.find({id,owner}); return it==auras.end()?nullptr:&it->second; }
    bool HasAura(uint32 id,uint32 owner) { return GetAura(id,owner)!=nullptr; }
    Aura* AddAura(uint32 id,Unit* target)
    { auto& aura=target->auras[{id,guid}]; aura.id=id; aura.caster=guid; return &aura; }
    void RemoveAurasDueToSpell(uint32 id,uint32 owner) { auras.erase({id,owner}); }
    void CastSpell(Unit* target,uint32 id,bool triggered)
    {
        assert(target && triggered); casts.push_back({id,target,0});
        if (id==561093) AddAura(id,target);
        if (id==807416)
        {
            if (auto* aura=GetAura(id,guid)) aura->stacks=std::min(uint8(5),uint8(aura->stacks+1));
            else AddAura(id,target);
        }
    }
    void CastCustomSpell(uint32 id,uint32 key,int32 amount,Unit* target,bool triggered)
    { assert(key==0 && triggered); casts.push_back({id,target,amount}); }
};
struct Player : Unit
{
    uint32 cls=30, resources=0, resourceCalls=0;
    Player* ToPlayer() override { return this; }
    bool IsPlayer() const override { return true; }
    uint32 getClass() const override { return cls; }
};
bool HandleAscensionReaperResource(Player* player,uint32 id,int32 amount)
{
    assert(id==500363 && amount==1);
    player->resources=std::min(3u,player->resources+1); ++player->resourceCalls; return true;
}
struct DamageInfo
{
    uint32 amount=100, school=1;
    uint32 GetDamage() const { return amount; }
    uint32 GetSchoolMask() const { return school; }
};
struct ProcEventInfo
{
    Unit* actor=nullptr;
    Unit* target=nullptr;
    DamageInfo* damage=nullptr;
    Unit* GetActor() const { return actor; }
    Unit* GetActionTarget() const { return target; }
    DamageInfo* GetDamageInfo() const { return damage; }
};
struct Spell
{
    Unit* caster=nullptr;
    SpellInfo info;
    bool triggered=false;
    std::map<uint32,uint64> values;
    Unit* GetCaster() const { return caster; }
    SpellInfo const* GetSpellInfo() const { return &info; }
    bool IsTriggered() const { return triggered; }
    uint64 GetScriptValue(uint32 key) { return values[key]; }
    void SetScriptValue(uint32 key,uint64 value) { values[key]=value; }
};
struct Hook { template<class T> void operator+=(T) {} };
struct AuraScript
{
    Unit* fixtureCaster=nullptr;
    Unit* fixtureTarget=nullptr;
    Hook DoCheckProc, OnEffectProc, AfterEffectRemove;
    bool prevented=false;
    virtual void Register() {}
    Unit* GetCaster() const { return fixtureCaster; }
    Unit* GetTarget() const { return fixtureTarget; }
    void PreventDefaultAction() { prevented=true; }
};
struct UnitScript
{
    UnitScript(char const*,bool,std::initializer_list<uint32>) {}
    virtual void OnAuraApply(Unit*,Aura*) {}
    virtual void OnAuraRemove(Unit*,AuraApplication*,AuraRemoveMode) {}
};
struct AllSpellScript
{
    AllSpellScript(char const*,std::initializer_list<uint32>) {}
    virtual void OnSpellBeforeEffects(Spell*,Unit*,SpellInfo const*) {}
    virtual void OnSpellCast(Spell*,Unit*,SpellInfo const*,bool) {}
    virtual void OnSpellHitResult(Spell*,Unit*,uint8,uint32,uint32,bool) {}
};
struct GlobalScript
{
    GlobalScript(char const*,std::initializer_list<uint32>) {}
    virtual void OnLoadSpellCustomAttr(SpellInfo*) {}
};
#define PrepareAuraScript(name)
#define AuraCheckProcFn(...) 0
#define AuraEffectProcFn(...) 0
#define AuraEffectRemoveFn(...) 0
#define RegisterSpellScript(name)
// SOURCE
int main()
{
    Player player, other; other.guid=2;
    Unit enemy; enemy.guid=3;
    reaper_ghost_speed ghost;
    auto* talent=player.AddAura(561082,&player);
    ghost.OnAuraApply(&player,talent); assert(player.casts.empty());
    auto* dead=player.AddAura(8326,&player); player.alive=false;
    ghost.OnAuraApply(&player,dead); assert(player.HasAura(561093,1));
    ghost.OnAuraApply(&player,dead); assert(player.casts.size()==1);
    AuraApplication removed{dead}; ghost.OnAuraRemove(&player,&removed,1);
    assert(!player.HasAura(561093,1));
    ghost.OnAuraApply(&player,talent); assert(player.HasAura(561093,1));
    removed.aura=talent; ghost.OnAuraRemove(&player,&removed,1); assert(!player.HasAura(561093,1));
    other.AddAura(561093,&player); ghost.OnAuraRemove(&player,&removed,1); assert(player.HasAura(561093,2));
    player.alive=true; player.casts.clear();
    manager.rows[801341].Effects[0].value=75;
    manager.rows[807417].Effects[0].value=50;
    reaper_secondary_hits hits;
    Spell spell; spell.caster=&player; spell.info.Id=801311; spell.triggered=true;
    hits.OnSpellHitResult(&spell,&enemy,0,101,0,false); assert(player.casts.empty());
    player.AddAura(800922,&player);
    hits.OnSpellHitResult(&spell,&enemy,0,101,0,false);
    assert(player.casts.back().id==520419 && player.casts.back().amount==75);
    spell.info.Id=803742; hits.OnSpellHitResult(&spell,&enemy,0,0,0,false);
    assert(player.casts.back().id==803942);
    auto size=player.casts.size(); enemy.alive=false;
    hits.OnSpellHitResult(&spell,&enemy,0,100,0,false); assert(player.casts.size()==size);
    spell.info.Id=801328; spell.triggered=false;
    hits.OnSpellHitResult(&spell,&enemy,0,0,0,false);
    hits.OnSpellHitResult(&spell,&enemy,0,0,0,false);
    assert(player.resources==3 && player.resourceCalls==3);
    enemy.alive=true;
    aura_ascension_crimson_thirst crimson; crimson.fixtureCaster=crimson.fixtureTarget=&player;
    DamageInfo damage; ProcEventInfo event{&player,&enemy,&damage};
    for (int i=0;i<8;++i) { assert(crimson.Check(event)); crimson.Proc(nullptr,event); }
    assert(player.GetAura(807416,1)->stacks==5 && crimson.prevented);
    for (uint32 rank : {500376u,502679u,502680u,502681u,502682u,502683u,502684u})
    {
        manager.roots[rank]=500376; player.AddAura(807416,&player)->stacks=5;
        spell.info.Id=rank; spell.values.clear();
        hits.OnSpellBeforeEffects(&spell,&player,&spell.info);
        hits.OnSpellCast(&spell,&player,&spell.info,false); assert(!player.HasAura(807416,1));
        hits.OnSpellHitResult(&spell,&enemy,0,301,0,false);
        assert(player.casts.back().id==807545 && player.casts.back().amount==150);
    }
    for (int guard=0;guard<6;++guard)
    {
        player.cls=guard==0?1:30; player.alive=guard!=1;
        event.actor=guard==2?&other:&player; enemy.friendly=guard==3;
        damage.amount=guard==4?0:100; damage.school=guard==5?32:1;
        assert(!crimson.Check(event));
    }
    player.cls=30; player.alive=true; enemy.friendly=false;
    reaper_secondary_metadata metadata; SpellInfo info; info.Id=800922;
    metadata.OnLoadSpellCustomAttr(&info); assert(info.Effects[0].ApplyAuraName==4 && info.ProcFlags==0);
    info.Id=561093; metadata.OnLoadSpellCustomAttr(&info);
    assert(info.AttributesCu & SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED);
    info.Id=520419; metadata.OnLoadSpellCustomAttr(&info); assert(info.DmgClass==0);
}
