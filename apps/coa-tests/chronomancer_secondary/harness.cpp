#include <algorithm>
#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <limits>
#include <list>
#include <map>
#include <vector>
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using uint8 = std::uint8_t;
using int32 = std::int32_t;
using ObjectGuid = uint32;
using AuraEffectHandleModes = uint32;
constexpr uint32 CLASS_CHRONOMANCER = 22, EFFECT_0 = 0, EFFECT_1 = 1,
    UNITHOOK_ON_PERIODIC_DAMAGE_RESULT = 1, GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 2,
    ALLSPELLHOOK_ON_CAST = 3, SPELLVALUE_BASE_POINT0 = 0,
    AURA_REMOVE_BY_DEATH = 4, SPELL_AURA_MOD_DISARM = 67, SPELL_AURA_PROC_TRIGGER_SPELL = 42,
    SPELL_AURA_MECHANIC_IMMUNITY_MASK = 147, SPELL_AURA_ADD_FLAT_MODIFIER = 107,
    AURA_EFFECT_HANDLE_REAL = 1, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK = 3,
    TARGET_UNIT_DEST_AREA_ENEMY = 16, SPELL_ATTR2_CANT_CRIT = 1,
    SPELL_ATTR3_IGNORE_CASTER_MODIFIERS = 2, SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS = 4;
// NATIVE_ENUMS
struct Unit;
struct Player;
struct SpellInfo
{
    uint32 Id = 806335, SpellFamilyName = 28, AttributesEx2 = 0, AttributesEx3 = 0, AttributesEx4 = 0;
    uint32 AttributesCu = SPELL_ATTR0_CU_FORCE_AURA_SAVING;
    bool AscensionInheritsResolvedAmount = false;
    struct Effect
    {
        int32 value = 20;
        float BonusMultiplier = 1.0f;
        int32 CalcValue(Unit*) const { return value; }
    } Effects[3];
};
struct SpellMgr
{
    std::map<uint32, uint32> roots;
    SpellInfo value;
    bool missing = false;
    uint32 GetFirstSpellInChain(uint32 id) const { auto it = roots.find(id); return it == roots.end() ? id : it->second; }
    SpellInfo const* GetSpellInfo(uint32 id) { assert(id == 504727); return missing ? nullptr : &value; }
} manager;
SpellMgr* sSpellMgr = &manager;
struct AuraEffect { uint32 ticks = 0; uint32 GetTickNumber() const { return ticks; } };
struct Aura
{
    uint32 id = 0;
    ObjectGuid caster = 0;
    uint8 stacks = 1;
    uint32 GetId() const { return id; }
    ObjectGuid GetCasterGUID() const { return caster; }
    uint8 GetStackAmount() const { return stacks; }
    void SetStackAmount(uint8 amount) { stacks = amount; }
};
struct AuraApplication
{
    Aura aura;
    uint32 mode = 1;
    Aura* GetBase() { return &aura; }
    uint32 GetRemoveMode() const { return mode; }
};
struct Unit
{
    virtual ~Unit() = default;
    virtual Player* ToPlayer() { return nullptr; }
    virtual uint32 getClass() const { return 0; }
    virtual bool IsPlayer() const { return false; }
    Unit* ToUnit() { return this; }
    uint32 guid = 1, map = 1;
    bool alive = true, inWorld = true, phase = true, friendly = false;
    std::map<uint32, AuraApplication*> applied;
    std::map<std::pair<uint32, uint32>, Aura> auras;
    struct Cast { uint32 id; Unit* target; int32 amount; uint8 charges; };
    std::vector<Cast> casts;
    bool IsAlive() const { return alive; }
    bool IsInWorld() const { return inWorld; }
    bool InSamePhase(Unit* unit) const { return phase && unit->phase; }
    bool IsValidAttackTarget(Unit* unit) const { return unit != this && !unit->friendly && unit->alive; }
    uint32 GetMap() const { return map; }
    uint32 GetGUID() const { return guid; }
    auto const& GetAppliedAuras() const { return applied; }
    Aura* GetAura(uint32 id, uint32 owner)
    { auto it = auras.find({id, owner}); return it == auras.end() ? nullptr : &it->second; }
    Aura* AddAura(uint32 id, Unit* target)
    { Aura& aura = target->auras[{id, guid}]; aura.id = id; aura.caster = guid; return &aura; }
    void RemoveAurasDueToSpell(uint32 id, uint32 owner) { auras.erase({id, owner}); }
    void CastSpell(Unit* target, uint32 id, bool triggered)
    {
        assert(target && triggered);
        Aura* charge = GetAura(806297, guid);
        casts.push_back({id, target, 0, charge ? charge->stacks : uint8(0)});
        if (id == 592009)
        {
            Aura* counter = GetAura(id, guid);
            if (counter) counter->stacks = std::min(uint8(10), uint8(counter->stacks + 1));
            else AddAura(id, this);
        }
        else if (id == 592010) AddAura(id, this);
    }
    void CastCustomSpell(uint32 id, uint32 key, int32 amount, Unit* target, bool triggered)
    { assert(key == 0 && triggered); casts.push_back({id, target, amount, 0}); }
};
using WorldObject = Unit;
constexpr int32 POWER_HEALTH = -2, POWER_MANA = 0;
constexpr uint32 SPELL_AURA_PREVENT_REGENERATE_POWER = 294, SPELL_AURA_MOD_HEALTH_REGEN_PERCENT = 88,
    SPELL_AURA_MOD_REGEN = 84, SPELL_AURA_MOD_REGEN_DURING_COMBAT = 116,
    SPELL_AURA_MOD_HEALTH_REGEN_IN_COMBAT = 161, RATE_HEALTH = 1, CONFIG_LOW_LEVEL_REGEN_BOOST = 2,
    STAT_SPIRIT = 4, IN_MILLISECONDS = 1000, CREATURE_REGEN_INTERVAL = 2000;
struct World { float getRate(uint32) const { return 1.0f; } bool getBoolConfig(uint32) const { return false; } } worldConfig;
World* sWorld = &worldConfig;
template<class T> void ApplyPct(T& value, int32 percent) { value = T(value * percent / 100); }
struct RegenUnit : Unit
{
    int32 lock = 100, health = 10;
    uint32 level = 60;
    bool polymorphed = false, combat = false, combatRegen = false, stand = true;
    bool HasAuraTypeWithMiscvalue(uint32 type, int32 misc) const
    { assert(type == SPELL_AURA_PREVENT_REGENERATE_POWER); return misc == lock; }
    uint32 GetHealth() const { return uint32(health); }
    uint32 GetMaxHealth() const { return 1000; }
    uint32 GetLevel() const { return level; }
    bool IsPolymorphed() const { return polymorphed; }
    bool IsInCombat() const { return combat; }
    bool HasRegenDuringCombatAura() const { return combatRegen; }
    bool IsStandState() const { return stand; }
    float GetTotalAuraMultiplier(uint32) const { return 1.0f; }
    int32 GetTotalAuraModifier(uint32) const { return 5; }
    void ModifyHealth(int32 gain) { health += gain; }
};
struct Player : RegenUnit
{
    uint32 cls = 22;
    float m_baseHealthRegen = 25.0f;
    Player* ToPlayer() override { return this; }
    uint32 getClass() const override { return cls; }
    bool IsPlayer() const override { return true; }
    float OCTRegenHPPerSpirit() const { return 12.0f; }
    void RegenerateHealth();
};
struct Creature : RegenUnit
{
    bool regenerating = true, owned = false;
    uint32 mana = 100;
    bool isRegeneratingHealth() const { return regenerating; }
    uint32 GetCharmerOrOwnerGUID() const { return owned ? 1 : 0; }
    float GetStat(uint32) const { return 40.0f; }
    uint32 GetPower(int32) const { return mana; }
    void RegenerateHealth();
};
// NATIVE_REGEN
std::map<ObjectGuid, Unit*> world;
namespace ObjectAccessor
{
Unit* GetUnit(Unit&, ObjectGuid guid) { auto it = world.find(guid); return it == world.end() ? nullptr : it->second; }
}
struct DamageInfo { uint32 damage = 100; uint32 GetDamage() const { return damage; } };
struct HealInfo { uint32 effective = 100; uint32 GetEffectiveHeal() const { return effective; } };
struct ProcEventInfo
{
    Unit* actor = nullptr;
    DamageInfo* damage = nullptr;
    HealInfo* heal = nullptr;
    Unit* GetActor() const { return actor; }
    DamageInfo* GetDamageInfo() const { return damage; }
    HealInfo* GetHealInfo() const { return heal; }
};
struct Spell { bool triggered = false; bool IsTriggered() const { return triggered; } };
struct Hook { template<class T> void operator+=(T) { } };
struct SpellScript
{
    Unit* fixtureTarget = nullptr;
    Hook OnObjectAreaTargetSelect;
    virtual void Register() { }
    Unit* GetExplTargetUnit() { return fixtureTarget; }
};
struct AuraScript
{
    Unit* fixtureCaster = nullptr;
    Unit* fixtureTarget = nullptr;
    AuraApplication fixtureApplication;
    AuraEffect fixtureTimer;
    uint8 fixtureStacks = 1;
    bool prevented = false;
    Hook AfterEffectApply, AfterEffectRemove, OnEffectProc, DoCheckProc;
    virtual bool Load() { return true; }
    virtual bool Validate(SpellInfo const*) { return true; }
    virtual void Register() { }
    bool ValidateSpellInfo(std::initializer_list<uint32>) { return true; }
    Unit* GetTarget() { return fixtureTarget; }
    Unit* GetCaster() { return fixtureCaster; }
    Unit* GetUnitOwner() { return fixtureTarget; }
    uint8 GetStackAmount() const { return fixtureStacks; }
    AuraApplication* GetTargetApplication() { return &fixtureApplication; }
    AuraEffect* GetEffect(uint32 i) { assert(i == 1); return &fixtureTimer; }
    void PreventDefaultAction() { prevented = true; }
};
struct UnitScript
{
    UnitScript(char const*, bool, std::initializer_list<uint32>) { }
    virtual void OnPeriodicDamageResult(Unit*, Unit*, uint32, SpellInfo const*) { }
};
struct AllSpellScript
{
    AllSpellScript(char const*, std::initializer_list<uint32>) { }
    virtual void OnSpellCast(Spell*, Unit*, SpellInfo const*, bool) { }
};
struct GlobalScript
{
    GlobalScript(char const*, std::initializer_list<uint32>) { }
    virtual void OnLoadSpellCustomAttr(SpellInfo*) { }
};
#define PrepareAuraScript(name)
#define PrepareSpellScript(name)
#define AuraEffectApplyFn(...) 0
#define AuraEffectRemoveFn(...) 0
#define AuraEffectProcFn(...) 0
#define AuraCheckProcFn(...) 0
#define SpellObjectAreaTargetSelectFn(...) 0
#define RegisterSpellScript(name)
// SOURCE
int main()
{
    Player player, ally;
    ally.guid = 2;
    Unit enemy, neighbor, corpse;
    enemy.guid = 3; neighbor.guid = 4; corpse.guid = 5; corpse.alive = false;
    world[1] = &player; world[2] = &ally;
    chronomancer_melt_periodic periodic;
    AuraApplication mark, duplicate, other;
    mark.aura = {806335, 1}; duplicate.aura = {503895, 1}; other.aura = {572835, 2};
    manager.roots[503895] = manager.roots[572835] = 806335;
    enemy.applied = {{1, &mark}, {2, &duplicate}, {3, &other}};
    periodic.OnPeriodicDamageResult(&enemy, &ally, 109, nullptr);
    assert(player.casts.size() == 1 && ally.casts.size() == 1 && player.casts.back().amount == 21);
    assert(player.casts.back().target == &enemy && player.casts.back().id == 807570);
    for (int guard = 0; guard < 6; ++guard)
    {
        player.casts.clear();
        player.cls = guard == 0 ? 1 : 22; player.alive = guard != 1; player.inWorld = guard != 2;
        player.phase = guard != 3; player.map = guard == 4 ? 2 : 1;
        periodic.OnPeriodicDamageResult(&enemy, &ally, guard == 5 ? 0 : 100, nullptr);
        assert(player.casts.empty());
    }
    player.cls = 22; player.alive = player.inWorld = player.phase = true; player.map = 1;
    spell_ascension_melt_copy filter; filter.fixtureTarget = &enemy;
    std::list<WorldObject*> targets = {&enemy, &neighbor, &corpse, nullptr};
    filter.Select(targets); assert(targets.size() == 1 && targets.front() == &neighbor);
    aura_ascension_desynchronization disarm; disarm.fixtureCaster = &player; disarm.fixtureTarget = &enemy;
    for (uint32 mode : {1u, 2u, 3u, 4u})
    {
        player.casts.clear(); disarm.fixtureApplication.mode = mode; disarm.End(nullptr, 1);
        assert(player.casts.size() == (mode == 4 ? 0u : 1u));
        if (mode != 4) assert(player.casts.back().id == 561388 && player.casts.back().target == &enemy);
    }
    DamageInfo damage; HealInfo heal;
    ProcEventInfo event; event.actor = &player; event.damage = &damage;
    aura_ascension_ahead_of_the_game ahead; ahead.fixtureTarget = ahead.fixtureCaster = &player;
    player.casts.clear();
    for (int n = 1; n <= 20; ++n)
    {
        event.damage = n % 2 ? &damage : nullptr; event.heal = n % 2 ? nullptr : &heal;
        assert(ahead.Check(event)); ahead.Count(nullptr, event); assert(ahead.prevented);
        Aura* counter = player.GetAura(592009, 1);
        assert(n % 10 ? counter && counter->stacks == n % 10 : !counter);
    }
    assert(std::count_if(player.casts.begin(), player.casts.end(), [](auto const& cast) { return cast.id == 592010; }) == 2);
    heal.effective = 0; assert(!ahead.Check(event)); heal.effective = 100;
    event.actor = &ally; assert(!ahead.Check(event)); event.actor = &player;
    player.AddAura(592009, &player)->stacks = 9;
    player.RemoveAurasDueToSpell(592009, 1);
    ahead.Count(nullptr, event); assert(player.GetAura(592009, 1)->stacks == 1);
    ahead.Clear(nullptr, 1); assert(!player.GetAura(592009, 1) && !player.GetAura(592010, 1));
    aura_ascension_ripple_release ripple; ripple.fixtureCaster = ripple.fixtureTarget = &player;
    for (uint32 ticks = 0; ticks <= 20; ++ticks)
    {
        player.casts.clear(); player.AddAura(806297, &player)->stacks = 30;
        ripple.Start(nullptr, 1); assert(!player.GetAura(806297, 1));
        if (ticks) player.AddAura(806297, &player)->stacks = uint8(ticks);
        ripple.fixtureTimer.ticks = ticks; ripple.End(nullptr, 1);
        assert(player.casts.size() == (ticks >= 6 ? 1u : 0u));
        if (ticks >= 6) assert(player.casts.back().id == 806298 && player.casts.back().charges == ticks);
        assert(!player.GetAura(806297, 1));
    }
    player.casts.clear(); ripple.fixtureApplication.mode = 4; ripple.End(nullptr, 1); assert(player.casts.empty());
    aura_ascension_echo_duration echo; echo.fixtureCaster = echo.fixtureTarget = &player; assert(echo.Load());
    for (uint8 stacks : std::initializer_list<uint8>{1, 2, 3, 4, 5, 3, 1})
    {
        echo.fixtureStacks = stacks; echo.Sync(nullptr, 1);
        assert(player.GetAura(807711, 1)->stacks == stacks);
    }
    ally.AddAura(807711, &player); echo.Clear(nullptr, 1);
    assert(!player.GetAura(807711, 1) && player.GetAura(807711, 2));
    chronomancer_secondary_casts casts; Spell cast; SpellInfo info; info.Id = 524853;
    player.AddAura(804455, &player)->stacks = 5;
    cast.triggered = true; casts.OnSpellCast(&cast, &player, &info, false); assert(player.GetAura(804455, 1));
    cast.triggered = false; casts.OnSpellCast(&cast, &player, &info, false); assert(!player.GetAura(804455, 1));
    chronomancer_secondary_metadata metadata; info.Id = 807570; metadata.OnLoadSpellCustomAttr(&info);
    assert(info.AscensionInheritsResolvedAmount && info.Effects[0].BonusMultiplier == 0.0f);
    for (uint32 id : {807711u, 592009u, 806297u})
    {
        SpellInfo record; record.Id = id; metadata.OnLoadSpellCustomAttr(&record);
        assert(record.AttributesCu & SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED);
        assert(!(record.AttributesCu & SPELL_ATTR0_CU_FORCE_AURA_SAVING));
    }
    for (int mask = 0; mask < 16; ++mask)
    {
        player.polymorphed = mask & 1; player.combat = mask & 2;
        player.combatRegen = mask & 4; player.stand = mask & 8;
        player.health = 10; player.lock = -2; player.RegenerateHealth(); assert(player.health == 10);
        player.lock = 1; player.RegenerateHealth(); assert(player.health > 10);
        Creature pet; pet.owned = mask & 1; pet.polymorphed = mask & 2;
        pet.mana = mask & 4 ? 100 : 0; pet.regenerating = mask & 8;
        pet.lock = -2; pet.RegenerateHealth(); assert(pet.health == 10);
        pet.lock = 1; pet.RegenerateHealth(); assert(pet.regenerating ? pet.health > 10 : pet.health == 10);
    }
}
