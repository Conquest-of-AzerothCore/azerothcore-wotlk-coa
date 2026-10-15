#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <map>
#include <vector>
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using uint8 = std::uint8_t;
using int32 = std::int32_t;
using AuraEffectHandleModes = uint32;
constexpr uint32 CLASS_RANGER = 21, EFFECT_0 = 0, SPELL_AURA_ADD_PCT_MODIFIER = 108,
    AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK = 3, AURA_EFFECT_HANDLE_REAL = 1,
    ALLSPELLHOOK_ON_HIT_RESULT = 1, ALLSPELLHOOK_ON_BEFORE_EFFECTS = 2,
    SPELL_MISS_NONE = 0, AURA_STATE_BLEEDING = 1, SPELLVALUE_AURA_DURATION = 1,
    GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 1, TRIGGERED_FULL_MASK = 1;
// ENUMS
struct SpellInfo
{
    uint32 Id = 803105, SpellFamilyName = 27, AttributesCu = SPELL_ATTR0_CU_FORCE_AURA_SAVING, ExcludeTargetAuraSpell = 0;
    bool UseRangedAttackPowerForDamage = false;
};
struct SpellMgr
{
    std::map<uint32, uint32> roots;
    SpellInfo flare;
    uint32 GetFirstSpellInChain(uint32 id) { auto it = roots.find(id); return it == roots.end() ? id : it->second; }
    SpellInfo const* GetSpellInfo(uint32 id) { assert(id == 801935); return &flare; }
} manager;
SpellMgr* sSpellMgr = &manager;
struct Unit;
struct SpellCastTargets
{
    uint32 position = 0;
    Unit* unit = nullptr;
    void SetDst(uint32 value) { position = value; }
    void SetUnitTarget(Unit* value) { unit = value; }
};
struct CustomSpellValues
{
    int32 duration = 0;
    void AddSpellMod(uint32 key, int32 value) { assert(key == SPELLVALUE_AURA_DURATION); duration = value; }
};
struct AuraEffect { };
struct Aura
{
    uint8 stacks = 1;
    uint8 GetStackAmount() const { return stacks; }
    void SetStackAmount(uint8 amount) { stacks = amount; }
};
struct Player;
struct Unit
{
    virtual ~Unit() = default;
    virtual Player* ToPlayer() { return nullptr; }
    virtual bool IsPlayer() const { return false; }
    virtual uint32 getClass() const { return 0; }
    uint32 guid = 1;
    bool alive = true, bleeding = false, friendly = false;
    std::map<std::pair<uint32, uint32>, Aura> auras;
    uint32 GetGUID() const { return guid; }
    uint32 GetPosition() const { return guid; }
    bool IsAlive() const { return alive; }
    bool HasAuraState(uint32 state) const { assert(state == AURA_STATE_BLEEDING); return bleeding; }
    Aura* GetAura(uint32 id, uint32 owner)
    { auto it = auras.find({id, owner}); return it == auras.end() ? nullptr : &it->second; }
    Aura* AddAura(uint32 id, Unit* other) { return &other->auras[{id, guid}]; }
    void RemoveAurasDueToSpell(uint32 id, uint32 owner) { auras.erase({id, owner}); }
};
struct Player : Unit
{
    uint32 cls = 21;
    std::vector<uint32> casts;
    std::vector<std::pair<uint32, int32>> flares;
    Player* ToPlayer() override { return this; }
    bool IsPlayer() const override { return true; }
    uint32 getClass() const override { return cls; }
    bool IsValidAttackTarget(Unit* unit) const { return unit != this && !unit->friendly; }
    bool IsFriendlyTo(Unit* unit) const { return unit->friendly; }
    void CastSpell(Unit* target, uint32 id, bool triggered)
    { assert(target != this && triggered); casts.push_back(id); }
    void CastSpell(SpellCastTargets const& targets, SpellInfo const* info, CustomSpellValues* values, uint32 flags)
    {
        assert(info == &manager.flare && flags == TRIGGERED_FULL_MASK);
        assert(targets.unit && targets.unit->GetPosition() == targets.position);
        flares.emplace_back(targets.position, values->duration);
    }
};
struct Spell
{
    Unit* caster = nullptr;
    SpellInfo info;
    bool triggered = false;
    bool IsTriggered() const { return triggered; }
    std::map<uint32, uint64> markers;
    Unit* GetCaster() { return caster; }
    SpellInfo const* GetSpellInfo() { return &info; }
    uint64 GetScriptValue(uint32 id) const { auto it = markers.find(id); return it == markers.end() ? 0 : it->second; }
    void SetScriptValue(uint32 id, uint64 value) { markers[id] = value; }
};
struct Hook { template<class T> void operator+=(T) { } };
struct AuraScript
{
    Unit* fixtureCaster = nullptr;
    Unit* fixtureOwner = nullptr;
    uint8 fixtureStacks = 1;
    Hook AfterEffectApply, AfterEffectRemove;
    virtual bool Validate(SpellInfo const*) { return true; }
    virtual bool Load() { return true; }
    virtual void Register() { }
    bool ValidateSpellInfo(std::initializer_list<uint32>) { return true; }
    Unit* GetCaster() { return fixtureCaster; }
    Unit* GetTarget() { return fixtureOwner; }
    Unit* GetUnitOwner() { return fixtureOwner; }
    uint8 GetStackAmount() { return fixtureStacks; }
};
struct AllSpellScript
{
    AllSpellScript(char const*, std::initializer_list<uint32>) { }
    virtual void OnSpellHitResult(Spell*, Unit*, uint8, uint32, uint32, bool) { }
    virtual void OnSpellBeforeEffects(Spell*, Unit*, SpellInfo const*) { }
};
struct GlobalScript
{
    GlobalScript(char const*, std::initializer_list<uint32>) { }
    virtual void OnLoadSpellCustomAttr(SpellInfo*) { }
};
#define PrepareAuraScript(name)
#define AuraEffectApplyFn(...) 0
#define AuraEffectRemoveFn(...) 0
#define RegisterSpellScript(name)
// SOURCE
int main()
{
    Player player, other;
    other.guid = 2;
    Unit enemy; enemy.guid = 3;
    aura_ascension_ranger_advantage resource;
    resource.fixtureCaster = resource.fixtureOwner = &player;
    assert(resource.Load());
    for (uint8 stacks : std::initializer_list<uint8>{1, 2, 3, 4, 5, 2, 1})
    {
        resource.fixtureStacks = stacks;
        resource.Sync(nullptr, 3);
        for (uint32 id : AdvantageCompanions) assert(player.GetAura(id, player.guid)->GetStackAmount() == stacks);
    }
    other.AddAura(801429, &player)->SetStackAmount(4);
    resource.Clear(nullptr, 1);
    for (uint32 id : AdvantageCompanions) assert(!player.GetAura(id, player.guid));
    assert(player.GetAura(801429, other.guid)->GetStackAmount() == 4);
    resource.fixtureStacks = 5;
    resource.Sync(nullptr, 1);
    for (uint32 id : AdvantageCompanions) assert(player.GetAura(id, player.guid)->GetStackAmount() == 5);
    resource.fixtureCaster = &other; assert(!resource.Load());
    resource.fixtureCaster = &player; player.cls = 1; assert(!resource.Load()); player.cls = 21;
    Spell spell; spell.caster = &player;
    ranger_secondary_hits hits;
    hits.OnSpellHitResult(&spell, &enemy, 0, 100, 0, false); assert(player.casts.empty());
    enemy.bleeding = true;
    for (int tick = 0; tick < 4; ++tick)
    {
        spell.markers.clear(); hits.OnSpellHitResult(&spell, &enemy, 0, tick ? 100 : 0, 0, false);
        hits.OnSpellHitResult(&spell, &enemy, 0, 100, 0, false);
        assert(player.casts.size() == std::size_t(tick + 1) && player.casts.back() == 803106);
    }
    spell.markers.clear();
    for (uint8 miss : std::initializer_list<uint8>{1, 2, 3, 4, 5, 6, 7})
        hits.OnSpellHitResult(&spell, &enemy, miss, 100, 0, false);
    enemy.alive = false; hits.OnSpellHitResult(&spell, &enemy, 0, 100, 0, false); enemy.alive = true;
    enemy.friendly = true; hits.OnSpellHitResult(&spell, &enemy, 0, 100, 0, false); enemy.friendly = false;
    spell.info.Id = 803106; hits.OnSpellHitResult(&spell, &enemy, 0, 100, 0, false);
    spell.info.Id = 803105; spell.info.SpellFamilyName = 0; hits.OnSpellHitResult(&spell, &enemy, 0, 100, 0, false);
    spell.info.SpellFamilyName = 27; player.cls = 1; hits.OnSpellHitResult(&spell, &enemy, 0, 100, 0, false);
    assert(player.casts.size() == 4);
    player.cls = 21;
    for (uint32 id : {804712u, 806921u, 806922u, 806923u, 806924u, 806925u})
    {
        manager.roots[id] = 804712; spell.info.Id = id;
        for (uint8 stacks = 0; stacks <= 5; ++stacks)
        {
            spell.markers.clear(); player.flares.clear();
            if (stacks) player.AddAura(804329, &player)->SetStackAmount(stacks);
            hits.OnSpellBeforeEffects(&spell, &player, &spell.info);
            player.RemoveAurasDueToSpell(804329, player.guid);
            hits.OnSpellHitResult(&spell, &enemy, 1, 100, 0, false); assert(player.flares.empty());
            hits.OnSpellHitResult(&spell, &enemy, 0, 100, 0, false);
            hits.OnSpellHitResult(&spell, &enemy, 0, 100, 0, false);
            assert(player.flares.size() == std::size_t(stacks ? 1 : 0));
            if (stacks) assert(player.flares.back() == std::make_pair(enemy.GetPosition(), 2000 * int32(stacks)));
        }
    }
    spell.markers.clear(); player.flares.clear(); player.AddAura(804329, &player)->SetStackAmount(5);
    spell.triggered = true; hits.OnSpellBeforeEffects(&spell, &player, &spell.info);
    hits.OnSpellHitResult(&spell, &enemy, 0, 100, 0, false); assert(player.flares.empty());
    ranger_secondary_contracts metadata;
    for (uint32 id : AdvantageCompanions)
    {
        SpellInfo info; info.Id = id; metadata.OnLoadSpellCustomAttr(&info);
        assert(info.AttributesCu == SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED);
    }
    SpellInfo brand; brand.Id = 560805; metadata.OnLoadSpellCustomAttr(&brand);
    assert(brand.ExcludeTargetAuraSpell == 570167);
    brand.SpellFamilyName = 0; brand.ExcludeTargetAuraSpell = 0; metadata.OnLoadSpellCustomAttr(&brand);
    assert(!brand.ExcludeTargetAuraSpell);
    SpellInfo flare; flare.Id = 801935; metadata.OnLoadSpellCustomAttr(&flare);
    assert(flare.UseRangedAttackPowerForDamage);
}
