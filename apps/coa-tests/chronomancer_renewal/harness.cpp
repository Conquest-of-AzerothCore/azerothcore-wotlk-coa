#include <cassert>
#include <chrono>
#include <cstdint>
#include <functional>
#include <vector>
using uint64 = std::uint64_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;
using AuraEffectHandleModes = int;
constexpr int EFFECT_0 = 0, SPELL_AURA_PERIODIC_HEAL = 8, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK = 1;
namespace GameTime
{
std::chrono::milliseconds now{0};
std::chrono::milliseconds GetGameTimeMS() { return now; }
}
struct Unit { };
struct AuraApplication { };
struct AuraEffect
{
    int32 amount = 0, period = 1000, timer = 1000;
    uint32 ticks = 0;
    std::function<void()> dispatch;
    int32 GetAmount() const { return amount; }
    int32 GetAmplitude() const { return period; }
    void SetAmount(int32 value) { amount = value; }
    void SetPeriodicTimer(int32 value) { timer = value; }
    void ResetTicks() { ticks = 0; }
    void PeriodicTick(AuraApplication*, Unit*) { dispatch(); }
};
struct Aura
{
    int32 duration = 3000, maximum = 3000;
    bool removed = false;
    int32 GetMaxDuration() const { return maximum; }
    void SetMaxDuration(int32 value) { maximum = value; }
    void SetDuration(int32 value) { duration = value; }
    bool IsRemoved() const { return removed; }
    void Remove() { removed = true; }
};
struct Hook { void operator+=(int) { } };
struct AuraScript
{
    Aura aura;
    AuraEffect fixtureEffect;
    AuraApplication application;
    Unit caster;
    Hook AfterEffectApply, OnEffectPeriodic;
    virtual void Register() { }
    int32 GetDuration() const { return aura.duration; }
    Aura* GetAura() { return &aura; }
    AuraEffect* GetEffect(int) { return &fixtureEffect; }
    AuraApplication const* GetTargetApplication() { return &application; }
    Unit* GetCaster() { return &caster; }
    void PreventDefaultAction() { }
};
#define PrepareAuraScript(name) public:
#define AuraEffectApplyFn(...) 0
#define AuraEffectPeriodicFn(...) 0
#define RegisterSpellScript(...)
