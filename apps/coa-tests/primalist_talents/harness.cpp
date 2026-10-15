#include <array>
#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <map>
#include <set>
#include <tuple>
#include <vector>
using uint32 = std::uint32_t;
using uint8 = std::uint8_t;
using SpellEffIndex = uint8;
// NATIVE_ENUMS
constexpr uint32 CLASS_WILDWALKER = 31, SPELL_AURA_PERIODIC_DAMAGE = 3, EFFECT_0 = 0, SPELL_EFFECT_DUMMY = 3;
constexpr int UNITHOOK_ON_DAMAGE = 1, UNITHOOK_ON_AURA_REMOVE = 2, ALLSPELLHOOK_ON_CRIT_CHANCE = 3;
constexpr int ALLSPELLHOOK_ON_HIT_RESULT = 4, SPELL_MISS_NONE = 0;
struct Unit;
struct Player;
struct Pet;
struct SpellInfo
{
    uint32 Id = 0, SpellFamilyName = 37;
    std::array<uint32, 3> SpellFamilyFlags{};
    float range = 15.0f;
    float GetMaxRange(bool, Unit*) const { return range; }
};
struct Aura
{
    uint32 id = 0, caster = 1;
    uint32 GetId() const { return id; }
    uint32 GetCasterGUID() const { return caster; }
};
struct AuraEffect
{
    uint32 caster = 1;
    SpellInfo* info = nullptr;
    uint32 GetCasterGUID() const { return caster; }
    SpellInfo const* GetSpellInfo() const { return info; }
};
struct AuraApplication { Aura aura; Aura* GetBase() { return &aura; } };
struct Unit
{
    virtual ~Unit() = default;
    uint32 guid = 1, owner = 0, health = 100, state = 0;
    bool alive = true, inWorld = true, friendly = false, sameMap = true, samePhase = true, inRange = true, los = true;
    std::set<uint32> auras;
    std::vector<AuraEffect*> periodic;
    std::vector<std::tuple<Unit*, uint32, bool>> casts;
    virtual Player* ToPlayer() { return nullptr; }
    uint32 GetGUID() const { return guid; }
    uint32 GetOwnerGUID() const { return owner; }
    uint32 GetHealth() const { return health; }
    bool IsAlive() const { return alive; }
    bool IsInWorld() const { return inWorld; }
    bool IsInMap(Unit* target) const { return sameMap && target->sameMap; }
    bool InSamePhase(Unit* target) const { return samePhase && target->samePhase; }
    bool HasUnitState(uint32 mask) const { return (state & mask) != 0; }
    bool IsValidAttackTarget(Unit* target) const { return target->alive && !target->friendly && target != this; }
    bool IsWithinDistInMap(Unit*, float radius) const { assert(radius == 15.0f); return inRange; }
    bool IsWithinLOSInMap(Unit*) const { return los; }
    bool HasAura(uint32 id) const { return auras.contains(id); }
    bool IsFriendlyTo(Unit* target) const { return target->friendly; }
    auto const& GetAuraEffectsByType(uint32 type) const { assert(type == 3); return periodic; }
    void CastSpell(Unit* target, uint32 id, bool triggered) { casts.emplace_back(target, id, triggered); }
};
struct Pet : Unit { };
struct Player : Unit
{
    uint32 cls = CLASS_WILDWALKER, now = 0;
    Pet* pet = nullptr;
    std::map<uint32, uint32> cooldowns;
    Player* ToPlayer() override { return this; }
    uint32 getClass() const { return cls; }
    Pet* GetPet() const { return pet; }
    bool HasSpellCooldown(uint32 id) const { return cooldowns.contains(id) && cooldowns.at(id) > now; }
    void AddSpellCooldown(uint32 id, uint32, uint32 duration) { cooldowns[id] = now + duration; }
};
struct Spell
{
    Unit* caster = nullptr;
    SpellInfo* info = nullptr;
    std::map<uint32, uint32> values;
    Unit* GetCaster() const { return caster; }
    SpellInfo const* GetSpellInfo() const { return info; }
    uint32 GetScriptValue(uint32 id) const { return values.contains(id) ? values.at(id) : 0; }
    void SetScriptValue(uint32 id, uint32 value) { values[id] = value; }
};
struct Manager
{
    SpellInfo helper;
    SpellInfo const* GetSpellInfo(uint32 id) { assert(id == 500811); return &helper; }
} manager;
auto sSpellMgr = &manager;
struct UnitScript
{
    UnitScript(char const*, bool, std::initializer_list<int>) { }
    virtual void OnDamage(Unit*, Unit*, uint32&) { }
    virtual void OnAuraRemove(Unit*, AuraApplication*, AuraRemoveMode) { }
};
struct AllSpellScript
{
    AllSpellScript(char const*, std::initializer_list<int>) { }
    virtual void OnSpellCritChance(Spell*, Unit*, float&) { }
    virtual void OnSpellHitResult(Spell*, Unit*, uint8, uint32, uint32, bool) { }
};
struct Hook { template<class T> void operator+=(T) { } };
struct SpellScript
{
    Unit* caster = nullptr;
    Unit* fixtureTarget = nullptr;
    Hook OnCheckCast, OnEffectHitTarget;
    virtual bool Validate(SpellInfo const*) { return true; }
    virtual bool Load() { return true; }
    virtual void Register() { }
    Unit* GetCaster() const { return caster; }
    Unit* GetExplTargetUnit() const { return fixtureTarget; }
    Unit* GetHitUnit() const { return fixtureTarget; }
    bool ValidateSpellInfo(std::initializer_list<uint32>) { return true; }
};
#define PrepareSpellScript(name)
#define SpellCheckCastFn(...) 0
#define SpellEffectFn(...) 0
#define RegisterSpellScript(name)
// ACTUAL_SOURCE
int main()
{
    Player player;
    Unit enemy;
    enemy.guid = 2;
    primalist_talent_casts geode;
    SpellInfo geodeInfo;
    geodeInfo.Id = 803138;
    Spell stone;
    stone.caster = &player;
    stone.info = &geodeInfo;
    for (uint32 tick = 0; tick < 3; ++tick)
    {
        stone.values.clear();
        geode.OnSpellHitResult(&stone, &enemy, 1, 0, 0, false);
        geode.OnSpellHitResult(&stone, &player, 0, 10, 0, false);
        enemy.friendly = true;
        geode.OnSpellHitResult(&stone, &enemy, 0, 10, 0, false);
        enemy.friendly = false;
        assert(player.casts.size() == tick);
        geode.OnSpellHitResult(&stone, &enemy, 0, 10, 0, false);
        geode.OnSpellHitResult(&stone, &enemy, 0, 10, 0, true);
        assert(player.casts.size() == tick + 1);
        assert((player.casts.back() == std::tuple<Unit*, uint32, bool>{&player, 802885, true}));
    }
    player.casts.clear();
    stone.values.clear();
    for (uint32 id : {500402u, 502770u, 802885u, 803244u})
    {
        geodeInfo.Id = id;
        geode.OnSpellHitResult(&stone, &enemy, 0, 10, 0, false);
    }
    geodeInfo.Id = 803138;
    geodeInfo.SpellFamilyName = 0;
    geode.OnSpellHitResult(&stone, &enemy, 0, 10, 0, false);
    geodeInfo.SpellFamilyName = 37;
    player.cls = 1;
    geode.OnSpellHitResult(&stone, &enemy, 0, 10, 0, false);
    player.cls = CLASS_WILDWALKER;
    stone.caster = &enemy;
    geode.OnSpellHitResult(&stone, &enemy, 0, 10, 0, false);
    assert(player.casts.empty());
    primalist_talent_events events;
    uint32 damage = 100;
    events.OnDamage(&enemy, &player, damage);
    assert(damage == 100 && player.casts.empty());
    player.auras.insert(560157);
    damage = 99;
    events.OnDamage(&enemy, &player, damage);
    assert(damage == 99 && player.casts.empty());
    damage = 100;
    events.OnDamage(&enemy, &player, damage);
    assert(damage == 0 && player.casts.size() == 1 && std::get<1>(player.casts.back()) == 560179);
    assert(player.cooldowns.at(560157) == 120000);
    for (uint32 time : {0u, 119999u, 120000u})
    {
        player.now = time;
        damage = 200;
        events.OnDamage(&enemy, &player, damage);
        assert(damage == (time < 120000 ? 200u : 0u));
    }
    player.cooldowns.clear();
    player.alive = false;
    damage = 200;
    events.OnDamage(&enemy, &player, damage);
    assert(damage == 200);
    player.alive = true;
    player.cls = 20;
    events.OnDamage(&enemy, &player, damage);
    assert(damage == 200);
    player.cls = CLASS_WILDWALKER;

    AuraApplication app;
    app.aura.id = 680421;
    player.casts.clear();
    events.OnAuraRemove(&player, &app, AURA_REMOVE_BY_EXPIRE);
    assert(player.casts.empty());
    player.auras.insert(300728);
    for (uint32 id : {680421u, 800094u, 503630u})
        for (auto mode : {AURA_REMOVE_BY_EXPIRE, AURA_REMOVE_BY_CANCEL, AURA_REMOVE_BY_ENEMY_SPELL})
        {
            app.aura.id = id;
            player.casts.clear();
            events.OnAuraRemove(&player, &app, mode);
            assert(player.casts.size() == 1 && std::get<1>(player.casts.back()) == 503716);
        }
    player.casts.clear();
    events.OnAuraRemove(&player, &app, AURA_REMOVE_BY_DEATH);
    app.aura.caster = 42;
    events.OnAuraRemove(&player, &app, AURA_REMOVE_BY_EXPIRE);
    app.aura.caster = player.guid;
    app.aura.id = 680427;
    events.OnAuraRemove(&player, &app, AURA_REMOVE_BY_EXPIRE);
    assert(player.casts.empty());

    SpellInfo surge, tremor;
    surge.SpellFamilyFlags[0] = 8;
    tremor.SpellFamilyFlags[0] = 64;
    Spell spell{&player, &surge};
    AuraEffect dot{player.guid, &tremor};
    enemy.periodic = {&dot};
    primalist_talent_casts casts;
    float chance = 12;
    casts.OnSpellCritChance(&spell, &enemy, chance);
    assert(chance == 12);
    player.auras.insert(805336);
    casts.OnSpellCritChance(&spell, &enemy, chance);
    assert(chance == 100);
    chance = 12;
    dot.caster = 42;
    casts.OnSpellCritChance(&spell, &enemy, chance);
    assert(chance == 12);
    dot.caster = player.guid;
    tremor.SpellFamilyName = 19;
    casts.OnSpellCritChance(&spell, &enemy, chance);
    assert(chance == 12);
    tremor.SpellFamilyName = 37;
    surge.SpellFamilyFlags[0] = 16;
    casts.OnSpellCritChance(&spell, &enemy, chance);
    assert(chance == 12);

    Pet pet;
    pet.owner = player.guid;
    spell_ascension_throat_clamp clamp;
    clamp.caster = &player;
    clamp.fixtureTarget = &enemy;
    assert(clamp.Load() && clamp.Validate(nullptr));
    assert(clamp.CheckCast() == SPELL_FAILED_NO_PET);
    player.pet = &pet;
    assert(clamp.CheckCast() == SPELL_CAST_OK);
    clamp.Handle(0);
    assert(pet.casts.size() == 1 && std::get<0>(pet.casts[0]) == &enemy &&
        std::get<1>(pet.casts[0]) == 500811 && !std::get<2>(pet.casts[0]));
    pet.alive = false;
    clamp.Handle(0);
    assert(pet.casts.size() == 1 && clamp.CheckCast() == SPELL_FAILED_NO_PET);
    pet.alive = true;
    pet.owner = 42;
    assert(clamp.CheckCast() == SPELL_FAILED_NO_PET);
    pet.owner = player.guid;
    pet.state = UNIT_STATE_ROOT;
    assert(clamp.CheckCast() == SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW);
    pet.state = 0;
    pet.inRange = false;
    assert(clamp.CheckCast() == SPELL_FAILED_OUT_OF_RANGE);
    pet.inRange = true;
    pet.los = false;
    assert(clamp.CheckCast() == SPELL_FAILED_LINE_OF_SIGHT);
    pet.los = true;
    for (bool Unit::* gate : {&Unit::sameMap, &Unit::samePhase, &Unit::alive})
    {
        enemy.*gate = false;
        assert(clamp.CheckCast() == SPELL_FAILED_BAD_TARGETS);
        enemy.*gate = true;
    }
    enemy.friendly = true;
    assert(clamp.CheckCast() == SPELL_FAILED_BAD_TARGETS);
    player.cls = 20;
    assert(!clamp.Load());
}
