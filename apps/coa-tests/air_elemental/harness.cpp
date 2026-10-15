#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <map>
#include <set>
#include <utility>
#include <vector>
using uint8 = std::uint8_t;
using int8 = std::int8_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;
// NATIVE_ENUMS
constexpr uint32 EFFECT_0 = 0, EFFECT_1 = 1, SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN = 87,
    SPELL_SCHOOL_MASK_NATURE = 8, SPELLVALUE_BASE_POINT0 = 0,
    SPELL_DAMAGE_CLASS_NONE = 0, GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 3;
constexpr int PLAYERHOOK_ON_BEFORE_GUARDIAN_INIT_STATS_FOR_LEVEL = 1, PLAYERHOOK_ON_UPDATE = 2;
struct ObjectGuid
{
    uint32 value = 0;
    auto operator<=>(ObjectGuid const&) const = default;
};
struct Unit;
struct Pet;
struct SpellInfo
{
    uint32 StackAmount = 10, Id = 807555, SpellFamilyName = 22, DmgClass = 1;
    struct Slot
    {
        float BonusMultiplier = 1.0f;
        uint32 ApplyAuraName = 0;
        int32 BasePoints = 0, DieSides = 1;
        int32 CalcValue(Unit*) const { return 59; }
        int32 CalcBaseValue(int32 value) const { return DieSides ? value - 1 : value; }
    } Effects[3];
    uint32 ProcChance = 15;
    bool HasAttribute(SpellAttr1) const { return false; }
    int32 CalcMaxAuraStacks(Unit*) const { return int32(StackAmount); }
};
struct SpellMgr
{
    SpellInfo procInfo;
    SpellInfo const* GetSpellInfo(uint32 id) const { assert(id == 712488 || id == 807555); return &procInfo; }
} spellMgr;
SpellMgr* sSpellMgr = &spellMgr;
uint32 fixtureRoll = 0, fixtureRolls = 0;
bool roll_chance_i(uint32 chance) { ++fixtureRolls; return fixtureRoll < chance; }
struct Aura
{
    SpellInfo info;
    SpellInfo* m_spellInfo = &info;
    int32 m_stackAmount = 1, duration = 15000;
    ObjectGuid caster;
    int32 GetDuration() const { return duration; }
    void SetDuration(int32 value) { duration = value; }
    Unit* GetCaster() { return nullptr; }
    int32 GetStackAmount() const { return m_stackAmount; }
    void SetStackAmount(int32 value) { m_stackAmount = value; }
    void Remove(AuraRemoveMode) { m_stackAmount = 0; }
    void RefreshSpellMods() { }
    void RefreshTimers(bool) { duration = 15000; }
    int charges = 0;
    void SetCharges(int value) { charges = value; }
    int CalcMaxCharges() { return 0; }
    void SetNeedClientUpdateForTargets() { }
    bool ModStackAmount(int32 num, AuraRemoveMode removeMode = AURA_REMOVE_BY_DEFAULT, bool periodicReset = false);
};
// NATIVE_STACK
struct Map { };
struct Unit
{
    virtual ~Unit() = default;
    ObjectGuid guid;
    Map* map = nullptr;
    bool alive = true, inWorld = true, samePhase = true, friendly = false;
    std::map<uint32, Aura> auras;
    std::vector<uint32> casts;
    std::vector<std::pair<Unit*,int32>> flurries;
    virtual Pet* ToPet() { return nullptr; }
    ObjectGuid GetGUID() const { return guid; }
    Map* GetMap() const { return map; }
    bool IsAlive() const { return alive; }
    bool IsInWorld() const { return inWorld; }
    bool InSamePhase(Unit* target) const { return samePhase && target->samePhase; }
    bool IsFriendlyTo(Unit* target) const { return target->friendly; }
    Aura* GetAura(uint32 id, ObjectGuid caster)
    {
        auto it = auras.find(id);
        return it != auras.end() && it->second.caster == caster ? &it->second : nullptr;
    }
    bool HasAura(uint32 id, ObjectGuid caster) { return GetAura(id, caster) != nullptr; }
    void RemoveAurasDueToSpell(uint32 id, ObjectGuid caster)
    { if (HasAura(id,caster)) auras.erase(id); }
    void CastCustomSpell(uint32 id, uint32 slot, int32 amount, Unit* target, bool triggered)
    { assert(id==807555 && slot==0 && triggered);flurries.emplace_back(target,amount); }
    void CastSpell(Unit* target, uint32 id, bool triggered)
    {
        assert(triggered);
        casts.push_back(id);
        if (id == 806010)
        {
            target->auras[id].caster = guid;
            target->auras[806020].caster = target->guid;
        }
        else if (id == 500019)
        {
            assert(target == this);
            auras[id].caster = guid;
            auras[id].charges = 0;
        }
        else
            assert(id == 500348 && target == this);
    }
};
struct Guardian : Unit
{
    uint32 entry = 500941;
    uint32 GetEntry() const { return entry; }
};
struct Player;
struct Pet : Guardian
{
    Player* owner = nullptr;
    bool loading = false;
    Pet* ToPet() override { return this; }
    Player* GetOwner() const { return owner; }
    bool isBeingLoaded() const { return loading; }
};
struct Player : Unit
{
    uint32 cls = CLASS_STORMBRINGER;
    Pet* pet = nullptr;
    std::set<uint32> spells{804019};
    bool removed = false;
    int32 SpellBaseDamageBonusDone(uint32 school){assert(school==8);return 500;}
    uint32 getClass() const { return cls; }
    Pet* GetPet() const { return pet; }
    bool HasActiveSpell(uint32 id) const { return spells.contains(id); }
    void RemovePet(Pet* value, PetSaveMode mode)
    {
        assert(pet == value && mode == PET_SAVE_NOT_IN_SLOT);
        removed = true;
        pet = nullptr;
    }
};
struct CreatureTemplate { };
struct PlayerScript
{
    PlayerScript(char const*, std::initializer_list<int>) { }
    virtual void OnPlayerBeforeGuardianInitStatsForLevel(Player*, Guardian*, CreatureTemplate const*, PetType&) { }
    virtual void OnPlayerUpdate(Player*, uint32) { }
};
struct GlobalScript
{
    GlobalScript(char const*,std::initializer_list<int>){}
    virtual void OnLoadSpellCustomAttr(SpellInfo*){}
};
struct DamageInfo
{
    uint32 damage = 30;
    uint32 GetDamage() const { return damage; }
};
struct ProcEventInfo
{
    Unit* actor = nullptr;
    Unit* victim = nullptr;
    DamageInfo* damage = nullptr;
    Unit* GetActor() { return actor; }
    Unit* GetActionTarget() { return victim; }
    DamageInfo* GetDamageInfo() { return damage; }
};
struct AuraEffect { };
struct Hook { template<class T> void operator+=(T) { } };
struct AuraScript
{
    Unit* target = nullptr;
    bool prevented = false;
    Hook DoCheckProc, OnEffectProc;
    virtual bool Validate(SpellInfo const*) { return true; }
    virtual void Register() { }
    Unit* GetTarget() { return target; }
    bool ValidateSpellInfo(std::initializer_list<uint32>) { return true; }
    void PreventDefaultAction() { prevented = true; }
};
struct SpellScript
{
    Unit* caster = nullptr;
    Hook BeforeCast, AfterCast;
    virtual bool Load() { return true; }
    virtual void Register() { }
    Unit* GetCaster() { return caster; }
};
#define PrepareAuraScript(name)
#define PrepareSpellScript(name)
#define AuraCheckProcFn(...) 0
#define AuraEffectProcFn(...) 0
#define SpellCastFn(...) 0
#define RegisterSpellScript(name)
// ACTUAL_SOURCE
int main()
{
    Map map, otherMap;
    Player owner;
    Pet pet, other;
    Unit enemy;
    owner.guid = {1};
    pet.guid = {2};
    owner.pet = &pet;
    pet.owner = other.owner = &owner;
    owner.map = pet.map = &map;
    stormbringer_pet_lifecycle lifecycle;
    PetType type = MAX_PET_TYPE;
    lifecycle.OnPlayerBeforeGuardianInitStatsForLevel(&owner, &pet, nullptr, type);
    assert(type == SUMMON_PET);
    other.entry = 1;
    type = HUNTER_PET;
    lifecycle.OnPlayerBeforeGuardianInitStatsForLevel(&owner, &other, nullptr, type);
    assert(type == HUNTER_PET);
    pet.loading = true;
    lifecycle.OnPlayerUpdate(&owner, 1);
    assert(owner.casts.empty());
    pet.loading = false;
    lifecycle.OnPlayerUpdate(&owner, 1);
    lifecycle.OnPlayerUpdate(&owner, 1);
    assert(owner.casts == std::vector<uint32>{806010});
    assert(pet.HasAura(806010, owner.guid) && pet.HasAura(806020, pet.guid));
    pet.auras.erase(806020);
    lifecycle.OnPlayerUpdate(&owner, 1);
    assert(owner.casts.size() == 2);
    aura_ascension_air_invigoration proc;
    proc.target = &pet;
    DamageInfo damage;
    ProcEventInfo event{&pet, &enemy, &damage};
    assert(proc.CheckProc(event));
    proc.Invigorate(nullptr, event);
    assert(proc.prevented && pet.casts == std::vector<uint32>{500348});
    assert(fixtureRolls == 0 && !owner.HasAura(500019, owner.guid));
    owner.spells.insert(712431);
    fixtureRoll = 14;
    proc.Invigorate(nullptr, event);
    assert(fixtureRolls == 1 && owner.casts.back() == 500019);
    assert(owner.GetAura(500019, owner.guid)->charges == 1);
    owner.GetAura(500019, owner.guid)->charges = 0;
    proc.Invigorate(nullptr, event);
    assert(owner.GetAura(500019, owner.guid)->charges == 1);
    owner.auras.erase(500019);
    fixtureRoll = 15;
    proc.Invigorate(nullptr, event);
    assert(!owner.HasAura(500019, owner.guid));
    owner.spells.erase(712431);
    fixtureRoll = 0;
    proc.Invigorate(nullptr, event);
    assert(fixtureRolls == 3 && !owner.HasAura(500019, owner.guid));
    enemy.alive = false;
    assert(proc.CheckProc(event));
    enemy.alive = true;
    damage.damage = 0;
    assert(!proc.CheckProc(event));
    damage.damage = 30;
    event.actor = &owner;
    assert(!proc.CheckProc(event));
    event.actor = &pet;
    enemy.friendly = true;
    assert(!proc.CheckProc(event));
    enemy.friendly = false;
    proc.target = &other;
    assert(!proc.CheckProc(event));
    proc.target = &pet;
    for (bool Unit::* required : {&Unit::alive, &Unit::inWorld, &Unit::samePhase})
    {
        owner.*required = false;
        assert(!proc.CheckProc(event));
        owner.*required = true;
    }
    pet.map = &otherMap;
    assert(!proc.CheckProc(event));
    pet.map = &map;
    for (int stack = 1; stack <= 10; ++stack)
    {
        pet.auras[680918].caster = pet.guid;
        Aura* aura = pet.GetAura(680918, pet.guid);
        aura->m_stackAmount = stack;
        aura->duration = 2300;
        spell_ascension_air_invigoration_duration script;
        script.caster = &pet;
        assert(script.Load());
        script.SnapshotDuration();
        aura->ModStackAmount(1);
        assert(aura->duration == 15000);
        script.RestoreDuration();
        assert(aura->duration == 2300 && aura->m_stackAmount == (stack == 10 ? 10 : stack + 1));
    }
    pet.auras.erase(680918);
    spell_ascension_air_invigoration_duration first;
    first.caster = &pet;
    first.SnapshotDuration();
    pet.auras[680918].caster = pet.guid;
    first.RestoreDuration();
    assert(pet.GetAura(680918, pet.guid)->duration == 15000);
    pet.auras[807465].caster=pet.guid;
    damage.damage=0;assert(!proc.CheckProc(event) && pet.flurries.empty());
    damage.damage=30;
    assert(proc.CheckProc(event));proc.Invigorate(nullptr,event);
    assert(pet.flurries.size()==1 && pet.flurries[0].first==&enemy && pet.flurries[0].second==159);
    assert(!pet.HasAura(807465,pet.guid));
    proc.Invigorate(nullptr,event);assert(pet.flurries.size()==1);
    pet.auras[807465].caster=owner.guid;
    proc.Invigorate(nullptr,event);assert(pet.flurries.size()==1);
    SpellInfo flurryInfo;
    stormbringer_pet_contracts contracts;
    contracts.OnLoadSpellCustomAttr(&flurryInfo);
    assert(flurryInfo.DmgClass==1 && !flurryInfo.Effects[0].BonusMultiplier);
    flurryInfo=SpellInfo{};flurryInfo.SpellFamilyName=3;
    contracts.OnLoadSpellCustomAttr(&flurryInfo);assert(flurryInfo.Effects[0].BonusMultiplier==1.0f);
    flurryInfo = SpellInfo{};
    flurryInfo.Id = 807464;
    flurryInfo.Effects[1].ApplyAuraName = SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN;
    flurryInfo.Effects[0].BasePoints = -21;
    flurryInfo.Effects[1].BasePoints = -3;
    contracts.OnLoadSpellCustomAttr(&flurryInfo);
    assert(flurryInfo.Effects[1].BasePoints + flurryInfo.Effects[1].DieSides == 2);
    assert(flurryInfo.Effects[0].BasePoints == -21);
    flurryInfo.SpellFamilyName = 3;
    flurryInfo.Effects[1].BasePoints = -3;
    contracts.OnLoadSpellCustomAttr(&flurryInfo);
    assert(flurryInfo.Effects[1].BasePoints == -3);
    owner.spells.clear();
    assert(!first.Load() && !proc.CheckProc(event));
    lifecycle.OnPlayerUpdate(&owner, 1);
    assert(owner.removed && !owner.pet);
    owner.pet = &pet;
    owner.spells.insert(804019);
    owner.cls = CLASS_MAGE;
    assert(!first.Load() && !proc.CheckProc(event));
    type = MAX_PET_TYPE;
    lifecycle.OnPlayerBeforeGuardianInitStatsForLevel(&owner, &pet, nullptr, type);
    assert(type == MAX_PET_TYPE);
}
