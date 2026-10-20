#include <algorithm>
#include <array>
#include <cassert>
#include <cstdint>
#include <map>
#include <vector>
using uint8 = std::uint8_t;
using int8 = std::int8_t;
using int16 = std::int16_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;
constexpr uint8 SPELL_MISS_NONE = 0;
constexpr uint32 SPELL_PRIMALIST_EARTHSHAPING = 680441;
constexpr uint32 SPELL_BLOODMAGE_THIRST_PASSIVE = 92112;
constexpr uint32 SPELL_BLOODMAGE_THIRST = 706613;
constexpr uint8 CLASS_SON_OF_ARUGAL = 20;
constexpr uint32 POWER_HEALTH = uint32(-2);
bool roll_chance_i(uint32) { return true; }
struct Player;
using AuraRemoveMode = int;
constexpr int SPELL_ATTR1_AURA_UNIQUE = 1;
using SpellEffects = uint32;
constexpr SpellEffects SPELL_EFFECT_SCHOOL_DAMAGE = 2;
constexpr SpellEffects SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL = 17;
constexpr SpellEffects SPELL_EFFECT_WEAPON_PERCENT_DAMAGE = 31;
constexpr SpellEffects SPELL_EFFECT_WEAPON_DAMAGE = 58;
constexpr SpellEffects SPELL_EFFECT_NORMALIZED_WEAPON_DMG = 121;
struct SpellInfo
{
    uint32 Id = 0;
    int32 StackAmount = 100;
    std::array<uint32, 3> Effects = {};
    uint32 SpellFamilyName = 0;
    uint32 PowerType = 0;
    int32 CalcMaxAuraStacks(Player*) const { return StackAmount; }
    bool HasAttribute(int) const { return false; }
    bool HasEffect(SpellEffects effect) const
    {
        return std::find(Effects.begin(), Effects.end(), uint32(effect)) != Effects.end();
    }
};
struct Aura
{
    SpellInfo info;
    SpellInfo* m_spellInfo = &info;
    int32 m_stackAmount = 1, duration = 10000;
    uint8 GetStackAmount() const { return uint8(m_stackAmount); }
    int32 GetDuration() const { return duration; }
    void SetDuration(int32 value) { duration = value; }
    void SetStackAmount(int32 value) { m_stackAmount = value; }
    Player* GetCaster() { return nullptr; }
    void Remove(AuraRemoveMode) { m_stackAmount = 0; }
    void RefreshSpellMods() { }
    void RefreshTimers(bool) { duration = 10000; }
    void SetCharges(int) { }
    int CalcMaxCharges() { return 0; }
    void SetNeedClientUpdateForTargets() { }
    bool ModStackAmount(int32 num, AuraRemoveMode removeMode = 0, bool periodicReset = false);
};
// NATIVE_STACK
struct Player
{
    uint8 cls = 16;
    bool friendly = false;
    std::map<uint32, Aura> auras;
    Player* ToPlayer() { return this; }
    uint8 getClass() const { return cls; }
    bool IsFriendlyTo(Player const* target) const { return target->friendly; }
    Aura* GetAura(uint32 id)
    {
        auto it = auras.find(id);
        return it != auras.end() && it->second.m_stackAmount ? &it->second : nullptr;
    }
    bool HasAura(uint32 id) const
    {
        auto it = auras.find(id);
        return it != auras.end() && it->second.m_stackAmount;
    }
    Aura* AddAura(uint32 id, Player* target)
    {
        assert(target == this);
        Aura& aura = auras[id];
        aura.m_stackAmount = 1;
        aura.info.StackAmount = id == 800058 || id == 500906 ? 6 : id == SPELL_BLOODMAGE_THIRST ? 10 : 100;
        return &aura;
    }
    void CastSpell(Player* target, uint32 id, bool triggered)
    {
        assert(target == this && triggered);
        if (Aura* aura = GetAura(id))
            aura->ModStackAmount(1);
        else
            AddAura(id, this);
    }
    int32 Count(uint32 id) { Aura* aura = GetAura(id); return aura ? aura->m_stackAmount : 0; }
};
using Unit = Player;
bool IsAscensionCustomClass(Player const* player) { return player->cls >= 12 && player->cls <= 32; }
bool HandleAscensionPrimalistEarthshapingGain(Player*) { return false; }
bool HandleAscensionReaperResource(Player*, uint32, int32) { return false; }
bool HandleAscensionPrimalistEarthshapingGain(Player*) { return false; }
namespace AscensionPyromancer { bool Resource(Player*, uint32, int32) { return false; } }
namespace AscensionCultist { bool Resource(Player*, uint32, int32) { return false; } }
namespace AscensionVenomancer { bool Resource(Player*, uint32, int32) { return false; } }
namespace AscensionTinker { bool Resource(Player*, uint32, int32) { return false; } }
namespace AscensionSunCleric { bool Resource(Player*, uint32, int32) { return false; } }
namespace AscensionFelsworn { void Generated(Player*, uint32) { } }
struct Spell
{
    Player* owner;
    SpellInfo info;
    bool triggered = false;
    uint32 events = 0;
    int32 powerCost = 0;
    Player* GetCaster() const { return owner; }
    SpellInfo const* GetSpellInfo() const { return &info; }
    bool IsTriggered() const { return triggered; }
    int32 GetPowerCost() const { return powerCost; }
    bool TryMarkScriptEventHandled(uint8 event)
    {
        uint32 mask = 1u << event;
        bool first = !(events & mask);
        events |= mask;
        return first;
    }
};
