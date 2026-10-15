#include <algorithm>
#include <array>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <initializer_list>
#include <list>
#include <map>
#include <vector>
using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using int32 = std::int32_t;
using int64 = std::int64_t;
enum
{
    SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED = 1,
    CLASS_CHRONOMANCER = 22,
    EFFECT_0 = 0,
    EFFECT_1 = 1,
    EFFECT_2 = 2,
    SPELLMOD_DURATION = 1,
    SPELL_AURA_DUMMY = 4,
    SPELL_AURA_OBS_MOD_POWER = 21,
    SPELLVALUE_BASE_POINT0 = 0,
    TRIGGERED_FULL_MASK = 1,
    SPELL_MISS_NONE = 0,
    SPELL_MISS_IMMUNE = 7,
    PROC_FLAG_DONE_PERIODIC = 262144,
    ALLSPELLHOOK_ON_CAST = 1,
    ALLSPELLHOOK_ON_HIT_RESULT = 2,
    ALLSPELLHOOK_ON_CALCULATED_TARGET = 3,
    GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 1,
    SPELL_ATTR2_CANT_CRIT = 1,
    SPELL_ATTR3_IGNORE_CASTER_MODIFIERS = 1,
    SPELL_ATTR4_ALLOW_CAST_WHILE_CASTING = 0x80,
    SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS = 0x100,
    SPELL_ATTR6_IGNORE_HEALTH_MODIFIERS = 1,
    SPELL_SCHOOL_MASK_NORMAL = 1,
    SPELL_SCHOOL_MASK_MAGIC = 126,
    TARGET_UNIT_TARGET_ENEMY = 6,
    SPELL_SCHOOL_MASK_FROST = 0x10,
    SPELL_SCHOOL_MASK_ARCANE = 0x40
};
enum SpellCastResult
{
    SPELL_CAST_OK,
    SPELL_FAILED
};
struct Unit;
struct Player;
using SpellImplicitTargetInfo = uint32;
struct SpellEffectInfo
{
    uint32 TargetA = 0, TargetB = 0;
    uint32 Effect = 0, ApplyAuraName = 0, Amplitude = 0, TriggerSpell = 0;
    int32 BasePoints = 0, DieSides = 1, MiscValue = 0;
    float radius = 0, RealPointsPerLevel = 0, BonusMultiplier = 0;
    std::array<uint32, 3> mask{}, SpellClassMask{};
    int32 CalcValue() const
    {
        return BasePoints + DieSides;
    }
    float CalcRadius(Unit *) const
    {
        return radius;
    }
};
struct SpellRangeEntry
{
    uint32 ID;
};
struct SpellRangeStore
{
    SpellRangeEntry unlimited{13};
    SpellRangeEntry const *LookupEntry(uint32 id) const
    {
        assert(id == unlimited.ID);
        return &unlimited;
    }
} sSpellRangeStore;
std::array<uint32, 3>& operator|=(std::array<uint32, 3>& left, std::array<uint32, 3> const& right)
{
    for (int i = 0; i < 3; ++i) left[i] |= right[i];
    return left;
}
struct SpellInfo
{
    uint32 Id = 0, SpellFamilyName = 28, StackAmount = 1, MaxAffectedTargets = 0, rank = 1;
    uint32 AttributesCu = 0, AttributesEx2 = 0, AttributesEx3 = 0, AttributesEx4 = 0, AttributesEx6 = 0;
    int32 duration = 0;
    uint32 SchoolMask = 0;
    SpellRangeEntry const *RangeEntry = nullptr;
    std::array<uint32, 3> flags{}, SpellFamilyFlags{};
    std::array<SpellEffectInfo, 3> Effects;
    int32 GetDuration() const
    {
        return duration;
    }
    uint32 GetRank() const
    {
        return rank;
    }
};
struct Manager
{
    std::map<uint32, SpellInfo> infos;
    std::map<uint32, uint32> roots;
    SpellInfo const *GetSpellInfo(uint32 id) const
    {
        auto i = infos.find(id);
        return i == infos.end() ? nullptr : &i->second;
    }
    uint32 GetFirstSpellInChain(uint32 id) const
    {
        auto i = roots.find(id);
        return i == roots.end() ? id : i->second;
    }
} manager;
auto sSpellMgr = &manager;
struct AuraEffect
{
    int32 amount = 0;
    int32 GetAmount() const { return amount; }
    void SetAmount(int32 value) { amount = value; }
};
struct Aura
{
    AuraEffect effect;
    AuraEffect* GetEffect(uint8) { return &effect; }
    uint32 id = 0, caster = 0;
    int32 duration = 0, maximum = 0;
    uint8 stacks = 1;
    bool removed = false;
    std::map<uint32, uint64> values;
    uint32 GetId() const
    {
        return id;
    }
    int32 GetDuration() const
    {
        return duration;
    }
    int32 GetMaxDuration() const
    {
        return maximum;
    }
    uint8 GetStackAmount() const
    {
        return stacks;
    }
    void SetDuration(int32 value)
    {
        duration = value;
    }
    void SetMaxDuration(int32 value)
    {
        maximum = value;
    }
    void Remove()
    {
        removed = true;
    }
    void SetScriptValue(uint32 key, uint64 value)
    {
        values[key] = value;
    }
    uint64 GetScriptValue(uint32 key) const
    {
        auto i = values.find(key);
        return i == values.end() ? 0 : i->second;
    }
};
struct Cast
{
    uint32 id;
    Unit *target;
    int32 amount;
};
struct Unit
{
    virtual ~Unit() = default;
    virtual Player *ToPlayer()
    {
        return nullptr;
    }
    uint32 guid = 1;
    float x = 0;
    bool alive = true, world = true, phase = true, los = true, friendly = true, accept = true;
    std::map<uint32, Aura> auras;
    std::vector<Cast> casts;
    uint32 GetGUID() const
    {
        return guid;
    }
    bool IsAlive() const
    {
        return alive;
    }
    bool IsInWorld() const
    {
        return world;
    }
    bool InSamePhase(Unit *unit) const
    {
        return phase && unit->phase;
    }
    bool IsWithinLOSInMap(Unit *unit) const
    {
        return los && unit->los;
    }
    float GetDistance(Unit *unit) const
    {
        return std::abs(x - unit->x);
    }
    bool IsValidAssistTarget(Unit *unit) const
    {
        return unit->friendly;
    }
    bool IsValidAttackTarget(Unit *unit) const
    {
        return !unit->friendly;
    }
    Aura *GetAura(uint32 id, uint32 caster = 0)
    {
        auto i = auras.find(id);
        return i != auras.end() && !i->second.removed && (!caster || caster == i->second.caster) ? &i->second : nullptr;
    }
    bool HasAura(uint32 id)
    {
        return GetAura(id) != nullptr;
    }
    Aura *GetAuraOfRankedSpell(uint32 root, uint32 caster = 0)
    {
        for (auto &pair : auras)
            if (manager.GetFirstSpellInChain(pair.first) == root && GetAura(pair.first, caster))
                return &pair.second;
        return nullptr;
    }
    void RemoveAurasDueToSpell(uint32 id)
    {
        if (Aura *aura = GetAura(id))
            aura->Remove();
    }
    Aura *Add(uint32 id, Unit *target)
    {
        auto info = manager.GetSpellInfo(id);
        auto &aura = target->auras[id];
        uint8 stacks =
            (!aura.removed && aura.id && info) ? std::min<uint8>(aura.stacks + 1, uint8(info->StackAmount)) : 1;
        aura = {};
        aura.id = id;
        aura.caster = guid;
        aura.stacks = stacks;
        aura.duration = aura.maximum = info ? info->duration : 0;
        return &aura;
    }
    SpellCastResult CastSpell(Unit *target, uint32 id, bool);
    void CastCustomSpell(uint32, int, int32, Unit *, bool);
};
struct Player : Unit
{
    uint32 cls = 22;
    std::map<uint32, int> known;
    std::map<uint32, int32> cooldowns;
    Player *ToPlayer() override
    {
        return this;
    }
    uint32 getClass() const
    {
        return cls;
    }
    bool HasSpell(uint32 id) const
    {
        return known.count(id) != 0;
    }
    auto const &GetSpellMap() const
    {
        return known;
    }
    int32 CalcSpellDuration(SpellInfo const *info) const
    {
        return info->duration;
    }
    void ApplySpellMod(uint32 id, int op, int32 &value)
    {
        assert(op == SPELLMOD_DURATION);
        auto target = manager.GetSpellInfo(id);
        for (auto const &pair : auras)
        {
            auto info = manager.GetSpellInfo(pair.first);
            if (!info || pair.second.removed)
                continue;
            auto const &effect = info->Effects[0];
            bool matches = false;
            for (int i = 0; i < 3; ++i)
                matches |= (effect.mask[i] & target->flags[i]) != 0;
            if (effect.ApplyAuraName == 107 && effect.MiscValue == op && matches)
                value += effect.CalcValue();
        }
    }
    void ModifySpellCooldown(uint32 id, int32 delta)
    {
        if (cooldowns.count(id))
            cooldowns[id] += delta;
    }
};
SpellCastResult Unit::CastSpell(Unit *target, uint32 id, bool triggered)
{
    assert(triggered);
    if (!target->accept)
        return SPELL_FAILED;
    casts.push_back({id, target, 0});
    Aura *aura = Add(id, target);
    if (Player *player = ToPlayer())
        player->ApplySpellMod(id, SPELLMOD_DURATION, aura->duration);
    aura->maximum = aura->duration;
    return SPELL_CAST_OK;
}
void Unit::CastCustomSpell(uint32 id, int slot, int32 value, Unit *target, bool triggered)
{
    assert(slot == SPELLVALUE_BASE_POINT0);
    CastSpell(target, id, triggered);
    casts.back().amount = value;
    target->GetAura(id)->effect.amount = value;
}
std::vector<Unit *> nearby;
namespace Acore
{
struct AnyUnitInObjectRangeCheck
{
    Unit *center;
    float radius;
};
template <class T> struct UnitListSearcher
{
    Unit *center;
    std::list<Unit *> &targets;
    T &check;
    UnitListSearcher(Unit *c, std::list<Unit *> &t, T &q) : center(c), targets(t), check(q)
    {
    }
};
}
namespace Cell
{
template <class T> void VisitObjects(Unit *, T &search, float radius)
{
    for (Unit *unit : nearby)
        if (search.center->GetDistance(unit) <= radius)
            search.targets.push_back(unit);
}
}
struct SpellCastTargets
{
    Unit *unit = nullptr;
    void SetUnitTarget(Unit *value)
    {
        unit = value;
    }
    Unit *GetUnitTarget()
    {
        return unit;
    }
};
struct Echo
{
    uint32 id;
    Unit *target;
    uint64 percent;
};
std::vector<Echo> echoes;
struct Spell
{
    Unit *fixtureCaster;
    SpellInfo const *fixtureInfo;
    bool triggered;
    uint32 healingIncludingOverheal = 0;
    SpellCastTargets m_targets;
    std::map<uint32, uint64> values;
    Spell(Unit *caster, SpellInfo const *info, int flags)
        : fixtureCaster(caster), fixtureInfo(info),
          triggered(flags != 0 || (info->AttributesEx4 & SPELL_ATTR4_ALLOW_CAST_WHILE_CASTING))
    {
    }
    Unit *GetCaster()
    {
        return fixtureCaster;
    }
    SpellInfo const *GetSpellInfo()
    {
        return fixtureInfo;
    }
    bool IsTriggered() const
    {
        return triggered;
    }
    uint32 GetScriptHealingIncludingOverheal() const
    {
        return healingIncludingOverheal;
    }
    void SetScriptValue(uint32 key, uint64 value)
    {
        values[key] = value;
    }
    uint64 GetScriptValue(uint32 key) const
    {
        auto i = values.find(key);
        return i == values.end() ? 0 : i->second;
    }
    SpellCastResult prepare(SpellCastTargets const *targets)
    {
        bool accepted = targets->unit->accept;
        if (accepted)
            echoes.push_back({fixtureInfo->Id, targets->unit, values[706098]});
        delete this;
        return accepted ? SPELL_CAST_OK : SPELL_FAILED;
    }
};
struct TargetInfo
{
    int32 damage = 0, damageBeforeTakenMods = 0;
};
struct AllSpellScript
{
    AllSpellScript(char const *, std::initializer_list<int>)
    {
    }
    virtual void OnSpellCast(Spell *, Unit *, SpellInfo const *, bool)
    {
    }
    virtual void OnSpellCalculatedTarget(Spell *, Unit *, TargetInfo &)
    {
    }
    virtual void OnSpellHitResult(Spell *, Unit *, uint8, uint32, uint32, bool)
    {
    }
};
struct HealInfo
{
    uint32 amount = 0;
    uint32 GetHeal() const
    {
        return amount;
    }
};
struct DamageInfo
{
    uint32 amount = 0;
    Unit* victim = nullptr;
    uint32 school = SPELL_SCHOOL_MASK_NORMAL;
    Unit* GetVictim() const { return victim; }
    uint32 GetSchoolMask() const { return school; }
    uint32 GetDamage() const
    {
        return amount;
    }
};
struct ProcEventInfo
{
    Unit *actor = nullptr;
    uint32 mask = 0;
    HealInfo *heal = nullptr;
    DamageInfo *damage = nullptr;
    Unit *GetActor()
    {
        return actor;
    }
    uint32 GetTypeMask()
    {
        return mask;
    }
    HealInfo *GetHealInfo()
    {
        return heal;
    }
    DamageInfo *GetDamageInfo()
    {
        return damage;
    }
};
struct Hook
{
    void operator+=(int)
    {
    }
};
struct AuraScript
{
    Unit *fixtureTarget = nullptr;
    bool prevented = false;
    Hook DoCheckProc, OnEffectProc;
    virtual bool Validate(SpellInfo const*) { return true; }
    bool ValidateSpellInfo(std::initializer_list<uint32> ids)
    {
        for (uint32 id : ids) if (!manager.GetSpellInfo(id)) return false;
        return true;
    }
    virtual void Register()
    {
    }
    Unit *GetTarget()
    {
        return fixtureTarget;
    }
    void PreventDefaultAction()
    {
        prevented = true;
    }
};
struct GlobalScript
{
    GlobalScript(char const *, std::initializer_list<int>)
    {
    }
    virtual void OnLoadSpellCustomAttr(SpellInfo *)
    {
    }
};
#define PrepareAuraScript(name) public:
#define AuraCheckProcFn(...) 0
#define AuraEffectProcFn(...) 0
#define RegisterSpellScript(...)
