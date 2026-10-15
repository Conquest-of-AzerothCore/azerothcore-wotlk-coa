#include <algorithm>
#include <array>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <initializer_list>
#include <limits>
#include <map>
#include <tuple>
#include <vector>
using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using int32 = std::int32_t;
constexpr uint8 MAX_SPELL_EFFECTS = 3;
// NATIVE_ENUMS
struct Unit;
struct SpellImplicitTargetInfo
{
    uint32 value;
    explicit SpellImplicitTargetInfo(uint32 v = 0) : value(v) { }
};
struct SpellEffectInfo
{
    uint32 Effect = 0, ApplyAuraName = 0, Amplitude = 0, TriggerSpell = 0;
    int32 BasePoints = 0, DieSides = 0, MiscValue = 0;
    SpellImplicitTargetInfo TargetA, TargetB;
    void* RadiusEntry = nullptr;
    float CalcRadius(Unit*) const { return 40; }
};
struct SpellInfo
{
    uint32 Id = 0, SpellFamilyName = 28, ProcFlags = 0, AttributesCu = 0;
    SpellSchoolMask GetSchoolMask() const { return SPELL_SCHOOL_MASK_ARCANE; }
    std::array<SpellEffectInfo, 3> Effects;
};
struct AuraEffect
{
    int32 fixtureAmount = 0;
    int32 GetAmount() const { return fixtureAmount; }
    void SetAmount(int32 value) { fixtureAmount = value; }
};
struct Aura
{
    Unit* fixtureCaster = nullptr;
    SpellInfo fixtureInfo;
    std::array<AuraEffect, 3> fixtureEffects;
    int32 fixtureDuration = 5000, fixtureMax = 5000;
    bool fixtureRemoved = false;
    uint32 GetId() const { return fixtureInfo.Id; }
    Unit* GetCaster() const { return fixtureCaster; }
    AuraEffect* GetEffect(uint8 i) { return &fixtureEffects[i]; }
    int32 GetDuration() const { return fixtureDuration; }
    int32 GetMaxDuration() const { return fixtureMax; }
    void SetDuration(int32 value) { fixtureDuration = value; }
    void Remove() { fixtureRemoved = true; }
};
struct AuraApplication
{
    Aura* fixtureAura = nullptr;
    AuraRemoveMode fixtureMode = AURA_REMOVE_BY_EXPIRE;
    Aura* GetBase() { return fixtureAura; }
    AuraRemoveMode GetRemoveMode() { return fixtureMode; }
};
struct Unit
{
    uint32 fixtureGuid = 1, fixtureClass = CLASS_CHRONOMANCER, fixtureHealth = 10000;
    bool fixtureAlive = true, fixtureWorld = true, fixturePhase = true, fixtureRange = true;
    void* fixtureMap = nullptr;
    float fixtureHealingPower = 400;
    std::map<uint32, Aura> fixtureAuras;
    std::vector<std::tuple<Unit*, uint32>> fixtureCasts;
    std::vector<uint32> fixturePayments;
    bool IsPlayer() const { return fixtureClass != 0; }
    uint32 getClass() const { return fixtureClass; }
    bool IsAlive() const { return fixtureAlive; }
    bool IsInWorld() const { return fixtureWorld; }
    uint32 GetGUID() const { return fixtureGuid; }
    void* GetMap() const { return fixtureMap; }
    bool InSamePhase(Unit* target) const { return fixturePhase && target->fixturePhase; }
    bool IsValidAttackTarget(Unit* target) const { return target != this; }
    bool IsWithinDistInMap(Unit*, float radius) const { assert(radius == 40); return fixtureRange; }
    Aura* GetAura(uint32 id, uint32 caster = 0)
    {
        auto it = fixtureAuras.find(id);
        return it != fixtureAuras.end() && !it->second.fixtureRemoved &&
            (!caster || it->second.fixtureCaster->GetGUID() == caster) ? &it->second : nullptr;
    }
    bool HasAura(uint32 id, uint32 caster = 0) { return GetAura(id, caster) != nullptr; }
    Aura* AddAura(uint32 id, Unit* target)
    {
        auto& aura = target->fixtureAuras[id];
        aura.fixtureCaster = this; aura.fixtureInfo.Id = id; aura.fixtureRemoved = false;
        if (id == 806733) aura.fixtureEffects[2].fixtureAmount = 5;
        return &aura;
    }
    void CastSpell(Unit* target, uint32 id, bool triggered)
    {
        assert(triggered); fixtureCasts.emplace_back(target, id); AddAura(id, target);
    }
    void RemoveAurasDueToSpell(uint32 id, uint32 caster)
    {
        if (Aura* aura = GetAura(id, caster)) aura->Remove();
    }
    float SpellBaseHealingBonusDone(SpellSchoolMask) const { return fixtureHealingPower; }
    static uint32 DealDamage(Unit* caster, Unit* target, uint32 damage, void*, DamageEffectType kind,
        SpellSchoolMask school, SpellInfo const*, bool)
    {
        assert(caster == target && kind == DOT && school == SPELL_SCHOOL_MASK_NORMAL);
        target->fixturePayments.push_back(damage);
        uint32 taken = std::min(damage, target->fixtureHealth);
        target->fixtureHealth -= taken;
        target->fixtureAlive = target->fixtureHealth != 0;
        return taken;
    }
    void SendSpellNonMeleeDamageLog(Unit*, SpellInfo const*, uint32, SpellSchoolMask, uint32, uint32, bool, uint32) { }
};
struct DamageInfo
{
    uint32 fixtureDamage = 1000;
    DamageEffectType fixtureType = DIRECT_DAMAGE;
    SpellSchoolMask fixtureSchool = SPELL_SCHOOL_MASK_NORMAL;
    uint32 GetDamage() const { return fixtureDamage; }
    DamageEffectType GetDamageType() const { return fixtureType; }
    SpellSchoolMask GetSchoolMask() const { return fixtureSchool; }
};
struct Hook { void operator+=(int) { } };
struct AuraScript
{
    Unit* fixtureTarget = nullptr;
    Aura* fixtureAura = nullptr;
    AuraApplication fixtureApplication;
    bool fixturePrevented = false;
    Hook AfterEffectApply, AfterEffectRemove, OnEffectPeriodic, DoEffectCalcAmount, OnEffectAbsorb, AfterEffectAbsorb;
    virtual void Register() { }
    Unit* GetTarget() { return fixtureTarget; }
    Unit* GetCaster() { return fixtureAura->GetCaster(); }
    Aura* GetAura() { return fixtureAura; }
    SpellInfo const* GetSpellInfo() { return &fixtureAura->fixtureInfo; }
    AuraEffect* GetEffect(uint8 i) { return fixtureAura->GetEffect(i); }
    AuraApplication* GetTargetApplication() { return &fixtureApplication; }
    void PreventDefaultAction() { fixturePrevented = true; }
};
struct UnitScript
{
    UnitScript(char const*, bool, std::initializer_list<int>) { }
    virtual void OnAuraRemove(Unit*, AuraApplication*, AuraRemoveMode) { }
};
struct AllSpellScript
{
    AllSpellScript(char const*, std::initializer_list<int>) { }
    virtual void OnCalcMaxDuration(Aura const*, int32&) { }
};
struct GlobalScript
{
    GlobalScript(char const*, std::initializer_list<int>) { }
    virtual void OnLoadSpellCustomAttr(SpellInfo*) { }
};
constexpr int UNITHOOK_ON_AURA_REMOVE = 1, ALLSPELLHOOK_ON_CALC_MAX_DURATION = 2,
    GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 3;
#define PrepareAuraScript(name)
#define AuraEffectApplyFn(...) 0
#define AuraEffectRemoveFn(...) 0
#define AuraEffectPeriodicFn(...) 0
#define AuraEffectCalcAmountFn(...) 0
#define AuraEffectAbsorbFn(...) 0
#define RegisterSpellScript(name)
