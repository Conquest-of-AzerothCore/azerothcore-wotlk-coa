#include <algorithm>
#include <array>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <initializer_list>
#include <limits>
#include <list>
#include <map>
#include <tuple>
#include <vector>
using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using int32 = std::int32_t;
using int64 = std::int64_t;
using ObjectGuid = uint32;
// NATIVE_ENUMS
struct Unit;
struct Player;
struct Spell;
struct SpellCastTargets { };
struct AuraEffect { };
struct EffectRecord { uint32 Effect = 0, TriggerSpell = 0; };
struct SpellInfo
{
    uint32 Id = 802310, SpellFamilyName = 26, ManaCost = 200, ManaCostPercentage = 0;
    int32 PowerType = POWER_RAGE;
    std::array<EffectRecord, 3> Effects{};
};
struct Aura
{
    uint32 caster = 1, stacks = 10;
    uint8 GetStackAmount() const { return uint8(stacks); }
    void ModStackAmount(int32 amount) { stacks = uint32(std::max(0, int32(stacks) + amount)); }
    bool IsUsingCharges() const { return false; }
};
struct Unit
{
    virtual ~Unit() = default;
    uint32 guid = 1, cls = CLASS_SON_OF_ARUGAL, health = 500, maxHealth = 1000;
    uint8 level = 1;
    bool alive = true, inWorld = true;
    float spirit = 300;
    std::map<uint32, Aura> auras;
    std::vector<std::tuple<Unit*, uint32, int32>> casts;
    virtual Player* ToPlayer() { return nullptr; }
    bool IsPlayer() const { return cls != 0; }
    uint32 getClass() const { return cls; }
    uint8 GetLevel() const { return level; }
    bool IsAlive() const { return alive; }
    bool IsInWorld() const { return inWorld; }
    uint32 GetGUID() const { return guid; }
    bool HasAura(uint32 id) const { return auras.contains(id) && auras.at(id).stacks != 0; }
    void RemoveAurasDueToSpell(uint32 spellId, uint32) { auras.erase(spellId); }
    Aura* GetAura(uint32 id, uint32 owner) { return HasAura(id) && auras[id].caster == owner ? &auras[id] : nullptr; }
    void CastSpell(Unit* target, uint32 id, bool triggered)
    {
        assert(triggered); casts.emplace_back(target, id, 0);
        if (id == 680687)
        {
            uint32 old = HasAura(id) ? auras[id].stacks : 0;
            auras[id] = {guid, std::min(10u, old + 1)};
        }
    }
    void CastCustomSpell(Unit* target, uint32 id, int32* amount, int32*, int32*, bool triggered)
    {
        assert(triggered); casts.emplace_back(target, id, *amount);
    }
    float GetStat(Stats stat) const { assert(stat == STAT_SPIRIT); return spirit; }
    uint32 CountPctFromMaxHealth(int32 pct) const { return maxHealth * pct / 100; }
    uint32 SpellHealingBonusDone(Unit*, SpellInfo const*, uint32 amount, DamageEffectType, uint8) { return amount * 2; }
    uint32 SpellHealingBonusTaken(Unit*, SpellInfo const*, uint32 amount, DamageEffectType) { return amount / 2; }
    int32 ModifyHealth(int32 change)
    {
        int32 old = int32(health);
        health = uint32(std::clamp(old + change, 0, int32(maxHealth)));
        return int32(health) - old;
    }
    void ModifyPower(Powers, int32) { }
    void SetLastManaUse(uint32) { }
    virtual Player* GetSpellModOwner() { return nullptr; }
};
struct SpellModifier
{
    SpellModOp op = SPELLMOD_COST;
    uint32 type = SPELLMOD_FLAT;
    int32 value = 0;
    Aura* ownerAura = nullptr;
};
struct Player : Unit
{
    bool cheat = false;
    Spell* m_spellModTakingSpell = nullptr;
    std::array<std::vector<SpellModifier*>, MAX_SPELLMOD> m_spellMods;
    Player* ToPlayer() override { return this; }
    Player* GetSpellModOwner() override { return this; }
    bool GetCommandStatus(uint32) const { return cheat; }
    template<class T> void ApplySpellMod(uint32, SpellModOp, T&, Spell* = nullptr, bool = false);
    bool IsAffectedBySpellmod(SpellInfo const*, SpellModifier*, Spell*) { return true; }
    bool HasSpellModApplied(SpellModifier*, Spell*) { return true; }
    void ApplyModToSpell(SpellModifier*, Spell*) { }
};
template<class T, class P> float CalculatePct(T value, P pct) { return float(value) * float(pct) / 100; }
struct Target { ObjectGuid targetGUID = 0; SpellMissInfo missCondition = SPELL_MISS_NONE; };
using TargetInfo = Target;
struct Targets { ObjectGuid GetUnitTargetGUID() { return 0; } };
struct Spell
{
    Player* m_caster;
    SpellInfo* m_spellInfo;
    bool triggered = false, m_CastItem = false, m_triggeredByAuraSpell = false;
    int32 m_powerCost = 0;
    Targets m_targets;
    std::list<TargetInfo> m_UniqueTargetInfo;
    std::map<uint32, uint64> values;
    Unit* GetCaster() const { return m_caster; }
    SpellInfo const* GetSpellInfo() const { return m_spellInfo; }
    bool IsTriggered() const { return triggered; }
    void SetScriptValue(uint32 key, uint64 value) { values[key] = value; }
    uint64 GetScriptValue(uint32 key) const { return values.contains(key) ? values.at(key) : 0; }
    void TakePower();
    void TakeRunePower(bool) { }
};
struct Manager
{
    std::map<uint32, SpellInfo> rows;
    SpellInfo const* GetSpellInfo(uint32 id) { return rows.contains(id) ? &rows.at(id) : nullptr; }
} manager;
auto sSpellMgr = &manager;
constexpr uint32 CHEAT_POWER = 1;
int32 irand(int32 low, int32) { return low; }
namespace GameTime { struct Time { uint32 count() const { return 0; } }; Time GetGameTimeMS() { return {}; } }
#define LOG_ERROR(...)
struct AllSpellScript
{
    AllSpellScript(char const*, std::initializer_list<int>) { }
    virtual bool CanPrepare(Spell*, SpellCastTargets const*, AuraEffect const*) { return true; }
    virtual void OnSpellCheckCast(Spell*, bool, SpellCastResult&) { }
    virtual void OnSpellBeforeEffects(Spell*, Unit*, SpellInfo const*) { }
    virtual void OnSpellCast(Spell*, Unit*, SpellInfo const*, bool) { }
    virtual void OnSpellHitResult(Spell*, Unit*, uint8, uint32, uint32, bool) { }
};
struct UnitScript
{
    UnitScript(char const*, bool, std::initializer_list<int>) { }
    virtual void ModifySpellEffectBaseValue(Unit const*, SpellInfo const*, uint8, float&) { }
};
constexpr int ALLSPELLHOOK_CAN_PREPARE = 1, ALLSPELLHOOK_ON_SPELL_CHECK_CAST = 2,
    ALLSPELLHOOK_ON_BEFORE_EFFECTS = 3, ALLSPELLHOOK_ON_CAST = 4, ALLSPELLHOOK_ON_HIT_RESULT = 5,
    UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE = 6;
struct Hook { void operator+=(int) { } };
struct SpellScript
{
    Spell* spell = nullptr;
    Unit* hit = nullptr;
    Unit* initial = nullptr;
    int32 heal = 0, damage = 0, effectValue = 0;
    uint32 m_scriptSpellId = 0;
    bool prevented = false;
    Hook OnEffectLaunchTarget, OnHit;
    virtual bool Load() { return true; }
    virtual void Register() { }
    Unit* GetCaster() { return spell->GetCaster(); }
    SpellInfo const* GetSpellInfo() { return spell->GetSpellInfo(); }
    Spell* GetSpell() { return spell; }
    Unit* GetHitUnit() { return hit; }
    Unit* GetExplTargetUnit() { return initial; }
    int32 GetHitHeal() { return heal; }
    int32 GetHitDamage() { return damage; }
    int32 GetEffectValue() { return effectValue; }
    void SetHitDamage(int32 value) { damage = value; }
    void SetHitHeal(int32 value) { heal = value; }
    void PreventHitDefaultEffect(SpellEffIndex) { prevented = true; }
};
#define PrepareSpellScript(name)
#define SpellEffectFn(...) 0
#define SpellHitFn(...) 0
#define RegisterSpellScript(name)
