constexpr uint32 SPELL_AURA_DUMMY = 4, AURA_EFFECT_HANDLE_REAL = 1, SPELL_AURA_MOD_DAMAGE_FROM_CASTER = 271;
constexpr uint32 PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK = 8, PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS = 32;
constexpr uint32 ALLSPELLHOOK_CAN_PREPARE = 1, ALLSPELLHOOK_ON_SPELL_CHECK_CAST = 2,
    GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 1;
std::map<ObjectGuid, Unit*> world;
namespace ObjectAccessor
{
Unit* GetUnit(Unit&, ObjectGuid id) { auto it = world.find(id); return it == world.end() ? nullptr : it->second; }
}
struct AuraEffect { };
struct DamageInfo { uint32 damage = 100; uint32 GetDamage() const { return damage; } };
struct ProcEventInfo
{
    Unit* actor = nullptr;
    Unit* victim = nullptr;
    DamageInfo damage;
    uint32 mask = 8;
    SpellInfo const* info = nullptr;
    Unit* GetActor() const { return actor; }
    Unit* GetActionTarget() const { return victim; }
    DamageInfo const* GetDamageInfo() const { return &damage; }
    uint32 GetTypeMask() const { return mask; }
    SpellInfo const* GetSpellInfo() const { return info; }
};
struct AuraScript
{
    Unit* caster = nullptr;
    Unit* fixtureTarget = nullptr;
    Aura* aura = nullptr;
    Hook AfterEffectRemove, DoCheckProc, OnEffectProc;
    virtual void Register() { }
    Unit* GetCaster() { return caster; }
    Unit* GetTarget() { return fixtureTarget; }
    Aura* GetAura() { return aura; }
    void PreventDefaultAction() { }
};
struct AllSpellScript
{
    AllSpellScript(char const*, std::initializer_list<uint32>) { }
    virtual bool CanPrepare(Spell*, SpellCastTargets const*, AuraEffect const*) { return true; }
    virtual void OnSpellCheckCast(Spell*, bool, SpellCastResult&) { }
};
struct GlobalScript
{
    GlobalScript(char const*, std::initializer_list<uint32>) { }
    virtual void OnLoadSpellCustomAttr(SpellInfo*) { }
};
#define PrepareAuraScript(name)
#define AuraEffectRemoveFn(...) 0
#define AuraCheckProcFn(...) 0
#define AuraEffectProcFn(...) 0
#define SpellCastFn(...) 0
#define SpellHitFn(...) 0
