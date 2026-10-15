#include <algorithm>
#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <map>
#include <set>
#include <vector>
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using SpellEffIndex = uint32;
using AuraEffectHandleModes = uint32;
using SpellCastResult = uint32;
constexpr uint32 CLASS_SON_OF_ARUGAL = 20, SPEC_MASK_ALL = 3, EFFECT_0 = 0, EFFECT_2 = 2,
    SPELL_AURA_MOD_STUN = 12, SPELL_AURA_DUMMY = 4, AURA_EFFECT_HANDLE_REAL = 1,
    ALLSPELLHOOK_CAN_PREPARE = 1, ALLSPELLHOOK_ON_SPELL_CHECK_CAST = 2,
    SPELL_FAILED_BAD_TARGETS = 12, SPELL_EFFECT_REMOVE_AURA = 164,
    GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 1, SMSG_SUPERCEDED_SPELL = 1;
// ENUMS
struct ObjectGuid
{
    uint64 value = 0;
    explicit ObjectGuid(uint64 raw = 0) : value(raw) { }
    auto operator<=>(ObjectGuid const&) const = default;
    uint64 GetRawValue() const { return value; }
};
struct SpellInfo { uint32 Id = 803326, SpellFamilyName = 26, AttributesCu = SPELL_ATTR0_CU_FORCE_AURA_SAVING; };
struct AuraEffect { };
struct Aura
{
    std::map<uint32, uint64> values;
    uint64 GetScriptValue(uint32 id) const { auto it = values.find(id); return it == values.end() ? 0 : it->second; }
    void SetScriptValue(uint32 id, uint64 value) { values[id] = value; }
};
struct Player;
struct Unit
{
    virtual ~Unit() = default;
    virtual Player* ToPlayer() { return nullptr; }
    ObjectGuid guid;
    bool alive = true, inWorld = true, phase = true, friendly = false;
    std::map<std::pair<uint32, ObjectGuid>, Aura> auras;
    ObjectGuid GetGUID() const { return guid; }
    bool IsAlive() const { return alive; }
    bool IsInWorld() const { return inWorld; }
    bool InSamePhase(Unit* other) const { return phase && other->phase; }
    bool IsValidAttackTarget(Unit* other) const { return other != this && !other->friendly; }
    Aura* GetAura(uint32 id, ObjectGuid owner)
    { auto it = auras.find({id, owner}); return it == auras.end() ? nullptr : &it->second; }
    bool HasAura(uint32 id, ObjectGuid owner) { return GetAura(id, owner) != nullptr; }
    Aura* AddAura(uint32 id, Unit* other) { return &other->auras[{id, guid}]; }
    void RemoveAurasDueToSpell(uint32 id, ObjectGuid owner);
};
struct WorldPacket
{
    std::vector<uint32> values;
    WorldPacket(uint32, uint32) { }
    WorldPacket& operator<<(uint32 value) { values.push_back(value); return *this; }
};
struct Session
{
    std::vector<std::vector<uint32>> packets;
    void SendPacket(WorldPacket* packet) { packets.push_back(packet->values); }
};
struct Player : Unit
{
    uint32 cls = 20;
    Session session;
    std::map<uint32, bool> spells;
    std::set<uint32> inactive;
    std::map<uint32, uint32> m_temporarySpellReplacements;
    std::map<uint32, uint32> m_temporarySpellReplacementOrigins;
    Player* ToPlayer() override { return this; }
    uint32 getClass() const { return cls; }
    bool HasActiveSpell(uint32 id) const { return spells.contains(id) && !inactive.contains(id); }
    auto const& GetSpellMap() const { return spells; }
    void learnSpell(uint32 id, bool temporary) { spells[id] = temporary; }
    void removeSpell(uint32 id, uint32 mask, bool onlyTemporary)
    { assert(mask == SPEC_MASK_ALL && onlyTemporary); if (spells.contains(id) && spells[id]) spells.erase(id); }
    Session* GetSession() { return &session; }
    void SendLearnPacket(uint32, bool, bool = false) { }
    void SetTemporarySpellReplacement(uint32 original, uint32 replacement);
    uint32 GetTemporarySpellReplacement(uint32 original) const;
};
struct ScriptMgr
{
    void OnPlayerTemporarySpellRemoveNotice(Player*, uint32, bool) { }
    void OnPlayerTemporarySpellReplacementNotice(Player*, uint32, uint32, bool) { }
} scripts;
auto sScriptMgr = &scripts;
// NATIVE
std::map<ObjectGuid, Unit*> world;
namespace ObjectAccessor
{
Unit* GetUnit(Unit&, ObjectGuid guid)
{ auto it = world.find(guid); return it == world.end() ? nullptr : it->second; }
}
struct SpellCastTargets
{
    Unit* unit = nullptr;
    void SetUnitTarget(Unit* target) { unit = target; }
    Unit* GetUnitTarget() const { return unit; }
};
struct Spell
{
    Unit* caster = nullptr;
    SpellInfo info;
    SpellCastTargets m_targets;
    Unit* GetCaster() { return caster; }
    SpellInfo const* GetSpellInfo() { return &info; }
};
struct Hook { template<class T> void operator+=(T) { } };
struct AuraScript
{
    Unit* fixtureCaster = nullptr;
    Unit* fixtureTarget = nullptr;
    Hook AfterEffectApply, AfterEffectRemove;
    virtual bool Validate(SpellInfo const*) { return true; }
    virtual void Register() { }
    bool ValidateSpellInfo(std::initializer_list<uint32>) { return true; }
    Unit* GetCaster() { return fixtureCaster; }
    Unit* GetTarget() { return fixtureTarget; }
};
struct SpellScript
{
    Unit* fixtureCaster = nullptr;
    Unit* fixtureTarget = nullptr;
    Hook OnEffectHitTarget;
    bool prevented = false;
    virtual void Register() { }
    Unit* GetCaster() { return fixtureCaster; }
    Unit* GetHitUnit() { return fixtureTarget; }
    void PreventHitDefaultEffect(SpellEffIndex index) { assert(index == 2); prevented = true; }
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
#define PrepareSpellScript(name)
#define AuraEffectApplyFn(...) 0
#define AuraEffectRemoveFn(...) 0
#define SpellEffectFn(...) 0
#define RegisterSpellScript(name)
// SOURCE
void Unit::RemoveAurasDueToSpell(uint32 id, ObjectGuid owner)
{
    if (!auras.erase({id, owner})) return;
    if (id == 302895)
    {
        aura_ascension_hemostasis_ready ready;
        ready.fixtureTarget = this;
        ready.OnRemove(nullptr, 1);
    }
    if (id == 681304)
    {
        aura_ascension_hemostasis root;
        root.fixtureCaster = world.at(owner);
        root.fixtureTarget = this;
        root.OnRemove(nullptr, 1);
    }
}
int main()
{
    Player player, other;
    Unit enemy, second;
    player.guid = ObjectGuid(1); other.guid = ObjectGuid(2);
    enemy.guid = ObjectGuid(3); second.guid = ObjectGuid(4);
    for (Unit* unit : {static_cast<Unit*>(&player), static_cast<Unit*>(&other), &enemy, &second})
        world[unit->guid] = unit;
    player.spells[681304] = false;
    aura_ascension_hemostasis root;
    root.fixtureCaster = &player; root.fixtureTarget = &enemy;
    player.AddAura(681304, &enemy); root.Apply(nullptr, 1);
    assert(player.spells.at(803326) && player.GetTemporarySpellReplacement(681304) == 803326);
    assert(player.session.packets.back() == std::vector<uint32>({681304, 803326}));
    assert(HemostasisTarget(&player) == &enemy);
    Spell spell; spell.caster = &player;
    hemostasis_burst_target cast;
    for (Unit* selection : {static_cast<Unit*>(nullptr), &second, static_cast<Unit*>(&player)})
    {
        spell.m_targets.unit = selection;
        assert(cast.CanPrepare(&spell, nullptr, nullptr) && spell.m_targets.unit == &enemy);
        SpellCastResult result = 0; cast.OnSpellCheckCast(&spell, true, result); assert(result == 0);
    }
    for (bool* invalid : {&player.alive, &player.inWorld, &enemy.alive, &enemy.phase})
    {
        *invalid = false; assert(!cast.CanPrepare(&spell, nullptr, nullptr)); *invalid = true;
    }
    enemy.friendly = true; assert(!cast.CanPrepare(&spell, nullptr, nullptr)); enemy.friendly = false;
    player.inactive.insert(681304); assert(!cast.CanPrepare(&spell, nullptr, nullptr)); player.inactive.clear();
    player.cls = 19; assert(!cast.CanPrepare(&spell, nullptr, nullptr)); player.cls = 20;
    world.erase(enemy.guid); assert(!cast.CanPrepare(&spell, nullptr, nullptr)); world[enemy.guid] = &enemy;
    other.AddAura(681304, &enemy);
    spell_ascension_blood_burst burst; burst.fixtureCaster = &player; burst.fixtureTarget = &enemy;
    burst.Release(2);
    assert(burst.prevented && !enemy.HasAura(681304, player.guid) && enemy.HasAura(681304, other.guid));
    assert(!player.spells.contains(803326) && player.GetTemporarySpellReplacement(681304) == 681304);
    assert(player.session.packets.back() == std::vector<uint32>({803326, 681304}));
    assert(!cast.CanPrepare(&spell, nullptr, nullptr));
    spell.m_targets.unit = nullptr; SpellCastResult result = 0;
    cast.OnSpellCheckCast(&spell, false, result); assert(result == SPELL_FAILED_BAD_TARGETS);
    player.AddAura(681304, &enemy); root.Apply(nullptr, 1);
    player.AddAura(681304, &second); root.fixtureTarget = &second; root.Apply(nullptr, 1);
    enemy.RemoveAurasDueToSpell(681304, player.guid);
    assert(HemostasisTarget(&player) == &second);
    player.RemoveAurasDueToSpell(302895, player.guid);
    assert(!player.spells.contains(803326) && !HemostasisTarget(&player));
    player.spells[803326] = false; root.Apply(nullptr, 1);
    player.RemoveAurasDueToSpell(302895, player.guid); assert(player.spells.contains(803326));
    player.inactive.insert(803326); root.Apply(nullptr, 1);
    assert(!player.HasAura(302895, player.guid) && player.spells.contains(803326));
    spell.info.Id = 1; assert(cast.CanPrepare(&spell, nullptr, nullptr));
    hemostasis_contracts metadata; SpellInfo info; info.Id = 302895;
    metadata.OnLoadSpellCustomAttr(&info); assert(info.AttributesCu == SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED);
    info.SpellFamilyName = 0; info.AttributesCu = 2;
    metadata.OnLoadSpellCustomAttr(&info); assert(info.AttributesCu == 2);
}
