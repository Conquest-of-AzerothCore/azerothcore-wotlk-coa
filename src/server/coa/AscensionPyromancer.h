/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_PYROMANCER_H
#define ASCENSION_PYROMANCER_H
#include "EventMap.h"
#include "ObjectGuid.h"
#include "SpellInfo.h"
#include "TaskScheduler.h"
#include <list>
#include <map>
#include <set>
class Player;
class Spell;
class Unit;
class Creature;
class Aura;
namespace AscensionPyromancer
{
constexpr uint32 HeatAura = 807389;
constexpr uint32 EmberAura = 807533;
constexpr uint32 FlamecastingAura = 804301;
struct PyromancerState
{
    EventMap timers;
    TaskScheduler scheduler;
    ObjectGuid phoenix, pyre;
    uint64 sequence = 0;
    uint32 aspectDamage = 0, earth = 0, ignis = 0;
    uint32 dashMs = 0;
    Position dashPrevious;
    std::set<ObjectGuid> dashHits;
    bool event = false, refreshing = false;
};
Player* Owner(Unit const* unit);
PyromancerState& State(Player* player);
bool Named(SpellInfo const* info, uint32 root);
bool Any(SpellInfo const* info, std::initializer_list<uint32> roots);
bool Spender(SpellInfo const* info);
bool Derived(SpellInfo const* info);
uint32 Count(Unit const* unit, uint32 id);
int32 Amount(uint32 id, uint8 slot = 0, Unit* caster = nullptr);
void Cast(Unit* caster, Unit* target, uint32 id);
void Copy(Unit* caster, Unit* target, uint32 id, uint32 amount);
void Mana(Player* player, uint32 amount, uint32 spell = 807768);
bool Resource(Player* player, uint32 id, int32 delta);
void Generated(Player* player, uint32 count);
void Spent(Player* player, uint32 count);
void Flames(Player* player, uint32 count = 1);
void Refresh(Player* player);
bool Chance(Player* player, uint32 id, uint32 cooldown = 0);
std::list<Unit*> Nearby(Unit* center, float range);
std::list<Unit*> Allies(Player* player, Unit* center, float range, uint32 count);
uint32 Highest(Player* player, uint32 root);
void Reduce(Player* player, uint32 root, int32 milliseconds);
void ReducePercent(Player* player, uint32 root, uint32 percent);
void ExtendOwned(Player* player, Unit* target, uint32 root, uint32 milliseconds, uint32 cap);
uint32 Burning(Player* player, Unit* target);
void Spread(Player* player, Unit* source, std::initializer_list<uint32> roots, uint32 count, float radius = 10);
void Accumulate(Player* player, Unit* target, uint32 id, uint32 total);
uint32 Remaining(Aura const* aura);
void Aspect(Player* player, Unit* target, uint32 damage, bool guaranteed = false);
void Summon(Player* player, uint32 entry, uint32 propertiesId, Position const& position, uint32 duration);
void PhoenixCommand(Player* player, Unit* target, bool dive);
bool CanPhoenixCommand(Player* player, Unit* target, bool dive);
void StartDash(Player* player);
void UpdateDash(Player* player, uint32 diff);
void ApplyContracts(SpellInfo* info);
}
#endif
