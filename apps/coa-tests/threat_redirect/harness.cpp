#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <map>
#include <set>
using uint32 = std::uint32_t;
using uint8 = std::uint8_t;
using ObjectGuid = uint32;
using AuraEffectHandleModes = uint32;
// ENUMS
constexpr uint32 EFFECT_0 = 0, EFFECT_1 = 1, SPELL_AURA_DUMMY = 4, AURA_EFFECT_HANDLE_REAL = 1;
constexpr uint32 GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 1;
struct ThreatManager
{
    std::map<uint32, std::map<ObjectGuid, uint32>> _redirectRegistry;
    void UpdateRedirectInfo() { }
    bool HasRedirects() const { return !_redirectRegistry.empty(); }
    void RegisterRedirectThreat(uint32 spellId, ObjectGuid const& victim, uint32 pct);
    void UnregisterRedirectThreat(uint32 spellId);
};
struct AuraEffect { };
struct Unit
{
    ThreatManager threat;
    std::set<uint32> auras;
    bool canCast = true;
    uint32 lastCast = 0;
    ThreatManager& GetThreatMgr() { return threat; }
    bool HasAura(uint32 id) const { return auras.contains(id); }
    void CastSpell(Unit* target, uint32 id, bool triggered, void*, AuraEffect const*)
    {
        assert(target == this && triggered);
        lastCast = id;
        if (canCast)
            auras.insert(id);
    }
};
struct SpellInfo { uint32 Id = 0, AttributesCu = 0; };
struct DamageInfo { uint32 amount = 1; uint32 GetDamage() const { return amount; } };
struct ProcEventInfo
{
    Unit* actor;
    DamageInfo* damage;
    Unit* GetActor() const { return actor; }
    DamageInfo const* GetDamageInfo() const { return damage; }
};
struct Application
{
    AuraRemoveMode mode = AURA_REMOVE_BY_DEFAULT;
    AuraRemoveMode GetRemoveMode() const { return mode; }
};
struct Hook { template<class T> void operator+=(T) { } };
struct AuraScript
{
    Unit* owner = nullptr;
    uint32 id = 0;
    Application application;
    bool removed = false, prevented = false;
    Hook DoCheckProc, OnEffectProc, AfterEffectRemove;
    virtual bool Validate(SpellInfo const*) { return true; }
    virtual void Register() { }
    Unit* GetTarget() const { return owner; }
    uint32 GetId() const { return id; }
    Application* GetTargetApplication() { return &application; }
    bool ValidateSpellInfo(std::initializer_list<uint32>) { return true; }
    void PreventDefaultAction() { prevented = true; }
    void Remove(AuraRemoveMode mode) { removed = true; application.mode = mode; }
};
struct GlobalScript
{
    GlobalScript(char const*, std::initializer_list<uint32>) { }
    virtual void OnLoadSpellCustomAttr(SpellInfo*) { }
};
#define PrepareAuraScript(name)
#define RegisterSpellScript(name)
#define AuraCheckProcFn(...) 0
#define AuraEffectProcFn(...) 0
#define AuraEffectRemoveFn(...) 0
// NATIVE
// SOURCE
int main()
{
    for (auto const& [parent, child] : std::map<uint32, uint32>{{574356,574357},{534605,535214},{534480,535097}})
    {
        Unit owner, other;
        AuraEffect effect;
        DamageInfo damage;
        ProcEventInfo event{&owner, &damage};
        aura_ascension_threat_redirect pending;
        pending.owner = &owner;
        pending.id = parent;
        assert(!pending.CheckProc(event));
        owner.threat.RegisterRedirectThreat(parent, 42, 100);
        owner.threat.RegisterRedirectThreat(999, 43, 20);
        assert(pending.CheckProc(event));
        event.actor = &other;
        assert(!pending.CheckProc(event));
        event.actor = &owner;
        event.damage = nullptr;
        assert(!pending.CheckProc(event));
        event.damage = &damage;
        damage.amount = 0;
        assert(!pending.CheckProc(event));
        damage.amount = 1;
        pending.Activate(&effect, event);
        assert(pending.removed && pending.prevented && owner.lastCast == child && owner.HasAura(child));
        pending.OnRemove(&effect, 1);
        assert(owner.threat._redirectRegistry.at(parent).at(42) == 100);
        aura_ascension_threat_redirect_active active;
        active.owner = &owner;
        active.id = child;
        for (AuraRemoveMode mode : {AURA_REMOVE_BY_EXPIRE, AURA_REMOVE_BY_CANCEL,
                AURA_REMOVE_BY_ENEMY_SPELL, AURA_REMOVE_BY_DEATH})
        {
            active.application.mode = mode;
            active.OnRemove(&effect, 1);
            assert(!owner.threat._redirectRegistry.contains(parent));
            assert(owner.threat._redirectRegistry.at(999).at(43) == 20);
            owner.threat.RegisterRedirectThreat(parent, 42, 100);
            pending.application.mode = mode;
            pending.OnRemove(&effect, 1);
            assert(!owner.threat._redirectRegistry.contains(parent));
            owner.threat.RegisterRedirectThreat(parent, 42, 100);
        }
        owner.auras.clear();
        owner.canCast = false;
        pending.Activate(&effect, event);
        pending.OnRemove(&effect, 1);
        assert(!owner.threat._redirectRegistry.contains(parent));
        threat_redirect_metadata metadata;
        for (uint32 sid : {parent, child})
        {
            SpellInfo info{sid, SPELL_ATTR0_CU_FORCE_AURA_SAVING};
            metadata.OnLoadSpellCustomAttr(&info);
            assert(!(info.AttributesCu & SPELL_ATTR0_CU_FORCE_AURA_SAVING));
            assert(info.AttributesCu & SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED);
        }
        SpellInfo unrelated{123, 0};
        metadata.OnLoadSpellCustomAttr(&unrelated);
        assert(!unrelated.AttributesCu);
    }
}
