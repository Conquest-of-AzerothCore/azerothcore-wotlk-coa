#include <array>
#include <cassert>
#include <cstdint>
#include <iostream>
#include <map>
#include <set>
#include <tuple>
#include <vector>
using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;
using SpellEffIndex = uint8;
using AuraEffectHandleModes = uint8;
using TimePoint = uint32;
constexpr uint32 CLASS_WILDWALKER = 31, BASE_ATTACK = 0, POWER_MANA = 0;
[[maybe_unused]] constexpr uint32 SPELL_EFFECT_DUMMY = 3, SPELL_AURA_NONE = 0, SPELL_AURA_ANY = 999;
[[maybe_unused]] constexpr uint32 SPELL_AURA_PROC_TRIGGER_SPELL = 42, SPELL_SCHOOL_MASK_NORMAL = 1,
    PROC_HIT_CRITICAL = 2;
[[maybe_unused]] constexpr uint8 EFFECT_0 = 0, EFFECT_ALL = 255, MAX_SPELL_EFFECTS = 3;
[[maybe_unused]] constexpr uint8 AURA_EFFECT_HANDLE_REAL = 1, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK = 3;
constexpr uint32 SPELLMOD_CHARGES = 1, SPELL_ATTR6_DO_NOT_CONSUME_RESOURCES = 1;
constexpr uint32 PROC_ATTR_USE_STACKS_FOR_CHARGES = 1;
enum SpellCastResult { SPELL_CAST_OK, SPELL_FAILED_EQUIPPED_ITEM_CLASS };
struct flag96 { std::array<uint32, 3> values{}; };
struct SpellEffectInfo
{
    uint32 Effect = 6, ApplyAuraName = 4, DieSides = 1;
    int32 BasePoints = -101, MiscValue = 10;
    flag96 SpellClassMask{{16, 0, 0}};
};
struct SpellInfo
{
    uint32 Id = 0, SpellFamilyName = 37, Attributes = 192, AttributesEx2 = 1074266112;
    uint32 AuraInterruptFlags = 0, PowerType = 1, ManaCostPercentage = 0, ProcCharges = 0;
    void const* DurationEntry = this;
    int32 EquippedItemClass = 2;
    uint32 EquippedItemSubClassMask = 0;
    std::array<SpellEffectInfo, 3> Effects;
    bool HasAttribute(uint32) const { return false; }
};
struct SpellProcEntry { uint32 Charges = 2, Cooldown = 0, AttributesMask = 0; };
struct Manager
{
    std::map<uint32, SpellInfo> rows;
    SpellProcEntry charges;
    SpellInfo const* GetSpellInfo(uint32 id) const
    {
        auto it = rows.find(id);
        return it == rows.end() ? nullptr : &it->second;
    }
    SpellProcEntry const* GetSpellProcEntry(uint32) const { return &charges; }
} manager;
auto sSpellMgr = &manager;
struct Player;
struct AuraEffect { };
struct Unit
{
    virtual Player* ToPlayer() { return nullptr; }
    virtual ~Unit() = default;
    bool alive = true;
    uint32 guid = 1;
    std::set<uint32> auras;
    std::vector<std::tuple<Unit*, uint32>> casts;
    uint32 GetGUID() const { return guid; }
    bool IsAlive() const { return alive; }
    Player* GetSpellModOwner() { return nullptr; }
    void CastSpell(Unit* target, uint32 id, bool, void* = nullptr, AuraEffect const* = nullptr)
    {
        casts.emplace_back(target, id);
        target->auras.insert(id);
    }
    void RemoveAurasDueToSpell(uint32 id, uint32 = 0) { auras.erase(id); }
};
struct Pet : Unit { };
struct ItemTemplate { uint32 Class = 2, SubClass = 0; };
struct Item
{
    ItemTemplate data;
    bool broken = false;
    ItemTemplate const* GetTemplate() { return &data; }
};
struct Player : Unit
{
    uint32 cls = CLASS_WILDWALKER, level = 20;
    bool knows = true;
    Item* weapon = nullptr;
    Pet* pet = nullptr;
    Player* ToPlayer() override { return this; }
    uint32 getClass() const { return cls; }
    uint32 GetLevel() const { return level; }
    bool HasSpell(uint32 id) const { return id == 537218 && knows; }
    Item* GetWeaponForAttack(uint32, bool) { return weapon && !weapon->broken ? weapon : nullptr; }
    Pet* GetPet() { return pet; }
    void ApplySpellMod(uint32, uint32, uint32&) { }
};
namespace AscensionCompatConfig { constexpr uint32 ENABLED = 1; }
struct Config
{
    bool enabled = true;
    template<typename T> T GetConfigValue(uint32) const { return enabled; }
} ascensionCompatConfig;
struct AscensionClassService
{
    uint32 spec = 59;
    static AscensionClassService& Instance() { static AscensionClassService instance; return instance; }
    uint32 GetActiveSpecialization(Player const*) const { return spec; }
};
struct DamageInfo
{
    uint32 amount = 100, absorbed = 0;
    uint32 GetDamage() const { return amount; }
    uint32 GetAbsorb() const { return absorbed; }
};
struct ProcEventInfo
{
    Unit* actor = nullptr;
    DamageInfo* damage = nullptr;
    uint32 school = 1, hit = 2;
    Unit* GetActor() { return actor; }
    DamageInfo* GetDamageInfo() { return damage; }
    uint32 GetSchoolMask() { return school; }
    uint32 GetHitMask() { return hit; }
    SpellInfo const* GetSpellInfo() { return nullptr; }
};
struct AuraApplication { };
struct Aura
{
    SpellInfo const* m_spellInfo = nullptr;
    uint8 m_procCharges = 2;
    bool removed = false;
    uint32 GetId() const { return m_spellInfo->Id; }
    bool IsUsingCharges() const { return true; }
    uint8 GetCharges() const { return m_procCharges; }
    void Remove() { removed = true; }
    void ModStackAmount(int32) { assert(false); }
    bool CallScriptPrepareProcHandlers(AuraApplication*, ProcEventInfo&) { return true; }
    void SetNeedClientUpdateForTargets() { }
    void AddProcCooldown(TimePoint) { }
    uint8 CalcMaxCharges(Unit* = nullptr) const;
    void PrepareProcToTrigger(AuraApplication*, ProcEventInfo&, TimePoint);
    void ConsumeProcCharges(SpellProcEntry const*);
};
#define ASSERT(value) assert(value)
#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable: 4244)
#endif
// ACTUAL_CHARGES
#ifdef _MSC_VER
#pragma warning(pop)
#endif
struct Hook { template<typename T> void operator+=(T) { } };
struct SpellScript
{
    Unit* caster = nullptr;
    Hook OnCheckCast, OnEffectHitTarget;
    virtual ~SpellScript() = default;
    virtual bool Validate(SpellInfo const*) { return true; }
    virtual void Register() { }
    Unit* GetCaster() { return caster; }
    bool ValidateSpellInfo(std::initializer_list<uint32>) { return true; }
};
struct AuraScript
{
    Unit* fixtureTarget = nullptr;
    Aura aura;
    bool prevented = false;
    Hook AfterEffectApply, AfterEffectRemove, DoCheckProc, OnEffectProc;
    virtual ~AuraScript() = default;
    virtual bool Validate(SpellInfo const*) { return true; }
    virtual void Register() { }
    Unit* GetTarget() { return fixtureTarget; }
    uint32 GetId() { return aura.GetId(); }
    Aura* GetAura() { return &aura; }
    bool ValidateSpellInfo(std::initializer_list<uint32>) { return true; }
    void PreventDefaultAction() { prevented = true; }
};
#define PrepareSpellScript(name)
#define PrepareAuraScript(name)
#define SpellCheckCastFn(name) &name
#define SpellEffectFn(name, ...) &name
#define AuraEffectApplyFn(name, ...) &name
#define AuraEffectRemoveFn(name, ...) &name
#define AuraEffectProcFn(name, ...) &name
#define AuraCheckProcFn(name) &name
#define RegisterSpellScript(name) ((void)sizeof(name))
// ACTUAL_ELIGIBILITY
// ACTUAL_SOURCE

int main()
{
    manager.rows[801242].Id = 801242;
    manager.rows[801242].EquippedItemSubClassMask = 41105;
    manager.rows[704098].Id = 704098;
    manager.rows[704098].EquippedItemSubClassMask = 1378;
    Player player;
    Item weapon;
    player.weapon = &weapon;
    assert(SelectPrimalWeapon(&player) == 801242);
    weapon.data.SubClass = 1;
    assert(SelectPrimalWeapon(&player) == 704098);
    for (uint32 subclass : {2u, 3u, 9u, 20u, 32u})
    {
        weapon.data.SubClass = subclass;
        assert(!SelectPrimalWeapon(&player));
    }
    weapon.data.SubClass = 0;
    weapon.broken = true;
    assert(!SelectPrimalWeapon(&player));
    weapon.broken = false;
    player.level = 19;
    assert(!SelectPrimalWeapon(&player));
    player.level = 20;
    player.cls = 12;
    assert(!SelectPrimalWeapon(&player));
    player.cls = CLASS_WILDWALKER;
    player.knows = false;
    assert(!SelectPrimalWeapon(&player));
    player.knows = true;
    AscensionClassService::Instance().spec = 0;
    assert(!SelectPrimalWeapon(&player));
    AscensionClassService::Instance().spec = 59;
    ascensionCompatConfig.enabled = false;
    assert(!SelectPrimalWeapon(&player));
    ascensionCompatConfig.enabled = true;
    assert(!SelectPrimalWeapon(nullptr));

    SpellInfo action;
    action.Id = 537218;
    ApplyAscensionPrimalistWeaponsContract(&action);
    assert(action.Attributes == 0 && action.AttributesEx2 == 0 && !action.DurationEntry);
    assert(action.PowerType == 0 && action.ManaCostPercentage == 15);
    assert(action.Effects[0].Effect == 3 && action.Effects[0].ApplyAuraName == 0);
    assert(action.Effects[0].BasePoints == 0 && action.Effects[0].MiscValue == 0);
    SpellInfo other;
    ApplyAscensionPrimalistWeaponsContract(&other);
    assert(other.Attributes == 192 && other.Effects[0].Effect == 6);

    spell_ascension_primal_weapons selector;
    selector.caster = &player;
    assert(selector.CheckCast() == SPELL_CAST_OK);
    selector.Handle(0);
    assert(player.casts.size() == 1 && std::get<1>(player.casts.back()) == 801242);
    player.weapon = nullptr;
    assert(selector.CheckCast() != SPELL_CAST_OK);
    selector.Handle(0);
    assert(player.casts.size() == 1);
    player.weapon = &weapon;

    Pet pet;
    pet.guid = 2;
    player.pet = &pet;
    aura_ascension_primal_weapon bestial;
    bestial.fixtureTarget = &player;
    bestial.aura.m_spellInfo = &manager.rows[801242];
    player.auras.insert(704098);
    bestial.Apply(nullptr, 1);
    assert(!player.auras.contains(704098));
    DamageInfo damage;
    ProcEventInfo event{&player, &damage};
    assert(bestial.CheckProc(event));
    bestial.Proc(nullptr, event);
    assert(bestial.prevented && player.auras.contains(806070) && pet.auras.contains(806071));
    event.school = 4;
    assert(!bestial.CheckProc(event));
    event.school = 1;
    event.hit = 1;
    assert(!bestial.CheckProc(event));
    event.hit = 2;
    event.actor = &pet;
    assert(!bestial.CheckProc(event));
    event.actor = &player;
    damage.amount = 0;
    assert(!bestial.CheckProc(event));
    damage.absorbed = 100;
    assert(bestial.CheckProc(event));
    damage.absorbed = 0;
    damage.amount = 100;
    bestial.Remove(nullptr, 1);
    assert(!player.auras.contains(806070) && !pet.auras.contains(806071));

    weapon.data.SubClass = 1;
    assert(!bestial.CheckProc(event));
    aura_ascension_primal_weapon primal;
    primal.fixtureTarget = &player;
    primal.aura.m_spellInfo = &manager.rows[704098];
    primal.Apply(nullptr, 1);
    assert(player.auras.contains(563262) && !player.auras.contains(801242));
    assert(!primal.CheckProc(event));
    primal.Remove(nullptr, 1);
    assert(!player.auras.contains(563262));
    bestial.Apply(nullptr, 1);
    assert(bestial.aura.removed);
    AscensionClassService::Instance().spec = 0;
    primal.Apply(nullptr, 1);
    RemoveAscensionPrimalistWeapons(&player);
    assert(player.auras.contains(563262));
    AscensionClassService::Instance().spec = 60;
    RemoveAscensionPrimalistWeapons(&player);
    assert(!player.auras.contains(563262));
    AscensionClassService::Instance().spec = 59;
    player.auras = {801242, 704098, 563262, 806070, 42};
    pet.auras.insert(806071);
    player.knows = false;
    RemoveAscensionPrimalistWeapons(&player);
    assert(player.auras == std::set<uint32>{42} && !pet.auras.contains(806071));

    for (uint32 id : {806070u, 806071u})
    {
        manager.rows[id].Id = id;
        Aura haste;
        haste.m_spellInfo = &manager.rows[id];
        assert(haste.CalcMaxCharges() == 2);
        haste.PrepareProcToTrigger(nullptr, event, 0);
        haste.ConsumeProcCharges(&manager.charges);
        assert(haste.GetCharges() == 1 && !haste.removed);
        haste.PrepareProcToTrigger(nullptr, event, 0);
        haste.ConsumeProcCharges(&manager.charges);
        assert(haste.GetCharges() == 0 && haste.removed);
    }
    std::cout << "PASS: selector gates, exclusive buffs, physical crit/pet proc, cleanup and native charges\n";
}
