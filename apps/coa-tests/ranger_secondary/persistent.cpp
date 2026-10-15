#include <cassert>
#include <cstdint>
#include <memory>
using uint32 = std::uint32_t;
using int32 = std::int32_t;
using SpellEffIndex = uint32;
constexpr uint32 SPELL_EFFECT_HANDLE_HIT = 1, WORLD_TRIGGER = 12999, DYNAMIC_OBJECT_AREA_SPELL = 1, MAX_EFFECT_MASK = 7;
enum class HighGuid { DynamicObject };
#define ASSERT(value) assert(value)
struct Map { template<HighGuid> uint32 GenerateLowGuid() { return 1; } } map;
struct Unit
{
    bool inWorld = true, hasMap = true;
    uint32 GetEntry() const { return 0; }
    bool IsInWorld() const { return inWorld; }
    Map* FindMap() { return hasMap ? &map : nullptr; }
    Map* GetMap() { return FindMap(); }
    uint32 GetGUID() const { return 1; }
};
namespace ObjectAccessor { Unit* GetUnit(Unit& unit, uint32) { return &unit; } }
struct SpellInfo
{
    uint32 Id = 801935;
    int32 duration = 500;
    struct Effect { float CalcRadius(Unit*) const { return 10; } } Effects[3];
};
struct DynamicObject
{
    bool CreateDynamicObject(uint32, Unit*, uint32, uint32, float, uint32) { return true; }
};
struct Aura
{
    static Aura instance;
    int32 maximum = 500, duration = 500;
    bool registered = false;
    uint32 effects = 0;
    std::unique_ptr<DynamicObject> owner;
    static Aura* TryCreate(SpellInfo const* info, uint32, DynamicObject* object, Unit*, int32*)
    {
        instance.owner.reset(object); instance.maximum = instance.duration = info->duration;
        instance.registered = false; instance.effects = 0; return &instance;
    }
    int32 GetMaxDuration() const { return maximum; }
    void SetMaxDuration(int32 value) { maximum = value; }
    void SetDuration(int32 value) { duration = value; }
    void SetTriggeredByAuraSpellInfo(SpellInfo const*) { }
    void _RegisterForTargets() { registered = true; }
    DynamicObject* GetDynobjOwner() { return owner.get(); }
    void _ApplyEffectForTargets(SpellEffIndex index) { effects |= 1u << index; }
};
Aura Aura::instance;
struct SpellValue { int32 AuraDuration = 0, EffectBasePoints[3] = {}; };
struct Spell
{
    uint32 effectHandleMode = SPELL_EFFECT_HANDLE_HIT;
    Aura* m_spellAura = nullptr;
    Unit* m_caster = nullptr;
    Unit* m_originalCaster = nullptr;
    SpellInfo const* m_spellInfo = nullptr;
    SpellValue* m_spellValue = nullptr;
    uint32 destination = 42;
    uint32* destTarget = &destination;
    struct Trigger { SpellInfo const* spellInfo = nullptr; } m_triggeredByAuraSpell;
    void EffectPersistentAA(SpellEffIndex);
};
// NATIVE
int main()
{
    Unit caster;
    SpellInfo info;
    SpellValue values;
    for (int32 duration : {0, 2000, 4000, 6000, 8000, 10000, -1})
    {
        Spell spell; spell.m_caster = &caster; spell.m_spellInfo = &info; spell.m_spellValue = &values;
        values.AuraDuration = duration; spell.EffectPersistentAA(0);
        assert(spell.m_spellAura->maximum == (duration ? duration : 500));
        assert(spell.m_spellAura->duration == (duration ? duration : 500));
        assert(spell.m_spellAura->registered && spell.m_spellAura->effects == 1);
        spell.EffectPersistentAA(1); assert(spell.m_spellAura->effects == 3);
    }
    Spell spell; spell.m_caster = &caster; spell.m_spellInfo = &info; spell.m_spellValue = &values;
    info.duration = -1; values.AuraDuration = 2000; spell.EffectPersistentAA(0);
    assert(spell.m_spellAura->maximum == -1 && spell.m_spellAura->duration == 2000);
    spell.m_spellAura = nullptr; caster.inWorld = false; spell.EffectPersistentAA(0); assert(!spell.m_spellAura);
}
