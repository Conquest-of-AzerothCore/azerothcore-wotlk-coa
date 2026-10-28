#include "DataMap.h"
#include <algorithm>
#include <cassert>
#include <cstdint>
#include <list>
#include <set>

using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
constexpr float INTERACTION_DISTANCE = 5.5f;
constexpr uint32 PLAYER_FLAGS_GHOST = 1;
enum SpellCastResult { SPELL_CAST_OK, SPELL_FAILED_AFFECTING_COMBAT, SPELL_FAILED_BAD_TARGETS };
enum class DeathState { Alive, Corpse, Dead };
enum CorpseType { CORPSE_BONES, CORPSE_RESURRECTABLE_PVP };
enum CreatureType { CREATURE_TYPE_BEAST = 1, CREATURE_TYPE_DEMON = 3, CREATURE_TYPE_ELEMENTAL = 4,
                    CREATURE_TYPE_HUMANOID = 7 };

struct ObjectGuid
{
    uint64 value;
    explicit ObjectGuid(uint64 raw = 0) : value(raw) { }
    uint64 GetRawValue() const { return value; }
};
struct Creature;
struct Player;
struct Corpse;
struct WorldObject
{
    float x = 0;
    DataMap CustomData;
    virtual ~WorldObject() = default;
    virtual Creature* ToCreature() { return nullptr; }
    virtual Player* ToPlayer() { return nullptr; }
    virtual Corpse* ToCorpse() { return nullptr; }
    ObjectGuid GetGUID() const { return ObjectGuid(reinterpret_cast<std::uintptr_t>(this)); }
    float GetExactDistSq(WorldObject const* other) const { return (x - other->x) * (x - other->x); }
};
using Unit = WorldObject;
struct Creature : WorldObject
{
    DeathState state;
    CreatureType type;
    Creature(float position, CreatureType kind, DeathState death = DeathState::Corpse) : state(death), type(kind)
    {
        x = position;
    }
    Creature* ToCreature() override { return this; }
    DeathState getDeathState() const { return state; }
    CreatureType GetCreatureType() const { return type; }
};
struct Player : WorldObject
{
    bool combat = false;
    bool alive = true;
    bool ghost = false;
    Corpse* corpse = nullptr;
    std::list<WorldObject*> world;
    std::set<WorldObject*> hidden;
    Player* ToPlayer() override { return this; }
    bool IsAlive() const { return alive; }
    bool HasPlayerFlag(uint32 flag) const { assert(flag == PLAYER_FLAGS_GHOST); return ghost; }
    bool IsInCombat() const { return combat; }
    Corpse* GetCorpse() { return corpse; }
    bool IsWithinLOSInMap(WorldObject* object) const { return !hidden.count(object); }
    bool IsWithinDistInMap(WorldObject* object, float range) const { return GetExactDistSq(object) <= range * range; }
    void GetDeadCreatureListInGrid(std::list<Creature*>& found, float range, bool excludeAlive) const
    {
        assert(excludeAlive);
        for (WorldObject* object : world)
            if (Creature* creature = object->ToCreature())
                if (creature->state != DeathState::Alive && GetExactDistSq(creature) <= range * range)
                    found.push_back(creature);
    }
};
struct Corpse : WorldObject
{
    CorpseType type = CORPSE_RESURRECTABLE_PVP;
    ObjectGuid owner;
    Corpse* ToCorpse() override { return this; }
    CorpseType GetType() const { return type; }
    ObjectGuid GetOwnerGUID() const { return owner; }
};
namespace ObjectAccessor
{
WorldObject* GetWorldObject(Player&, ObjectGuid guid) { return reinterpret_cast<WorldObject*>(guid.value); }
Player* FindConnectedPlayer(ObjectGuid guid)
{
    return guid.value ? reinterpret_cast<WorldObject*>(guid.value)->ToPlayer() : nullptr;
}
}
namespace Acore
{
template<class Check> struct WorldObjectListSearcher
{
    std::list<WorldObject*>& found;
    Check& check;
    WorldObjectListSearcher(Player*, std::list<WorldObject*>& objects, Check& predicate) : found(objects), check(predicate)
    {
    }
};
}
namespace Cell
{
template<class Check> void VisitObjects(Player* player, Acore::WorldObjectListSearcher<Check>& search, float)
{
    for (WorldObject* object : player->world)
        if (search.check(object))
            search.found.push_back(object);
}
}
struct Spell;
struct SpellInfo
{
    uint32 Id = 801042;
    float range = 0;
    float GetMaxRange(bool positive, Player*, Spell*) const
    {
        assert(!positive);
        return range;
    }
};
struct SpellCastTargets
{
    Unit* unit = nullptr;
    Unit* GetUnitTarget() const { return unit; }
    Corpse* GetCorpseTarget() const { return unit ? unit->ToCorpse() : nullptr; }
    void SetUnitTarget(Unit* target) { unit = target; }
    void RemoveObjectTarget() { unit = nullptr; }
};
struct Spell
{
    SpellInfo spellInfo;
    SpellCastTargets m_targets;
    uint64 selected = 0;
    SpellInfo const* GetSpellInfo() const { return &spellInfo; }
    uint64 GetScriptValue(uint32) const { return selected; }
    void SetScriptValue(uint32, uint64 guid) { selected = guid; }
};
// ACTUAL_FLAY_HELPERS
SpellCastResult Check(Player* player, Spell* spell)
{
    spell->selected = 0;
    SpellInfo const* info = spell->GetSpellInfo();
    SpellCastResult result = SPELL_CAST_OK;
    // ACTUAL_FLAY_CAST_CHECK
    return result;
}
WorldObject* Choice(Player* player, Spell* spell)
{
    return spell->selected ? ObjectAccessor::GetWorldObject(*player, ObjectGuid(spell->selected))
        : spell->m_targets.GetUnitTarget();
}
int main()
{
    Player player;
    Creature far(40, CREATURE_TYPE_HUMANOID), elemental(2, CREATURE_TYPE_ELEMENTAL), beast(6, CREATURE_TYPE_BEAST),
        demon(-9, CREATURE_TYPE_DEMON), living(1, CREATURE_TYPE_HUMANOID, DeathState::Alive),
        walled(3, CREATURE_TYPE_HUMANOID), bones(4, CREATURE_TYPE_HUMANOID, DeathState::Dead);
    player.world = {&far, &elemental, &beast, &demon, &living, &walled, &bones};
    player.hidden = {&walled};
    Spell spell;
    spell.spellInfo.range = 10;

    assert(Check(&player, &spell) == SPELL_CAST_OK);
    assert(Choice(&player, &spell) == &beast);
    spell.m_targets.SetUnitTarget(&demon);
    assert(Check(&player, &spell) == SPELL_CAST_OK);
    assert(Choice(&player, &spell) == &demon);
    spell.m_targets.SetUnitTarget(&living);
    assert(Check(&player, &spell) == SPELL_CAST_OK);
    assert(Choice(&player, &spell) == &beast);
    spell.m_targets.SetUnitTarget(&elemental);
    assert(Check(&player, &spell) == SPELL_CAST_OK);
    assert(Choice(&player, &spell) == &beast);
    player.hidden.clear();
    spell.m_targets.SetUnitTarget(nullptr);
    assert(Check(&player, &spell) == SPELL_CAST_OK);
    assert(Choice(&player, &spell) == &walled);
    player.hidden = {&walled};
    player.combat = true;
    spell.m_targets.SetUnitTarget(nullptr);
    assert(Check(&player, &spell) == SPELL_FAILED_AFFECTING_COMBAT);
    player.combat = false;
    spell.spellInfo.range = 0;
    spell.m_targets.SetUnitTarget(nullptr);
    assert(Check(&player, &spell) == SPELL_FAILED_BAD_TARGETS);
    assert(Choice(&player, &spell) == nullptr);
    beast.x = 5;
    assert(Check(&player, &spell) == SPELL_CAST_OK);
    assert(Choice(&player, &spell) == &beast);
    player.world = {&far, &elemental, &living, &bones};
    spell.spellInfo.range = 100;
    spell.m_targets.SetUnitTarget(&living);
    assert(Check(&player, &spell) == SPELL_CAST_OK);
    assert(Choice(&player, &spell) == &far);
    player.world = {&elemental, &living, &bones};
    spell.m_targets.SetUnitTarget(&living);
    assert(Check(&player, &spell) == SPELL_FAILED_BAD_TARGETS);

    Player fallen;
    fallen.alive = false;
    fallen.x = 2;
    player.world = {&fallen};
    spell.m_targets.SetUnitTarget(&fallen);
    assert(Check(&player, &spell) == SPELL_CAST_OK);
    assert(Choice(&player, &spell) == &fallen);
    Corpse released;
    released.x = 3;
    released.owner = fallen.GetGUID();
    fallen.ghost = true;
    fallen.corpse = &released;
    player.world = {&released, &fallen};
    spell.m_targets.SetUnitTarget(nullptr);
    assert(Check(&player, &spell) == SPELL_CAST_OK);
    assert(Choice(&player, &spell) == &released);
    released.type = CORPSE_BONES;
    spell.m_targets.SetUnitTarget(nullptr);
    assert(Check(&player, &spell) == SPELL_FAILED_BAD_TARGETS);
}
