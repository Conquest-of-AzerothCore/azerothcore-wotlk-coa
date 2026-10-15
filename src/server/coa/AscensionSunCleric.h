/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_SUN_CLERIC_H
#define ASCENSION_SUN_CLERIC_H
#include "EventMap.h"
#include "ObjectGuid.h"
#include "SpellInfo.h"
#include "TaskScheduler.h"
#include <list>
#include <set>
class Player;
class Spell;
class Unit;
namespace AscensionSunCleric
{
constexpr uint32 SolarPower = 500149;
constexpr uint32 Dawn = 807440;
constexpr uint32 DawnCast = 804584;
constexpr uint32 Bless = 804247;
constexpr uint32 HolyForm = 805301;
constexpr uint32 Sunrise = 500477;
constexpr uint32 Sunset = 500511;
constexpr uint32 RejuvenatingRays = 807240;
constexpr uint32 Rejuvenating = 807239;
struct SunClericState
{
    EventMap timers;
    TaskScheduler scheduler;
    ObjectGuid blessed, gate;
    std::set<ObjectGuid> firstAttacks;
    uint64 sequence = 0;
    uint32 sunchargeStacks = 0;
    bool event = false, refreshing = false, dawnEvent = false;
    bool landingDawn = false, landingFulfillment = false;
    bool gavelHealing = false;
    bool healthyAbove80 = false;
};
Player* Owner(Unit const* unit);
SunClericState& State(Player* player);
bool Named(SpellInfo const* info, uint32 root);
bool Any(SpellInfo const* info, std::initializer_list<uint32> roots);
bool Derived(SpellInfo const* info);
bool Invocation(SpellInfo const* info);
bool Gavel(SpellInfo const* info);
Spell* Origin(Player* player, Spell* spell);
uint32 Count(Unit const* unit, uint32 id);
int32 Amount(uint32 id, uint8 slot = 0, Unit* caster = nullptr);
float Radius(uint32 id, uint8 slot = 0);
void Cast(Unit* caster, Unit* target, uint32 id);
void Copy(Unit* caster, Unit* target, uint32 id, uint32 amount);
void Mana(Player* player, uint32 amount);
bool Resource(Player* player, uint32 id, int32 delta);
void Refresh(Player* player);
bool Chance(Player* player, uint32 id, uint32 cooldown = 0);
std::list<Unit*> Nearby(Unit* center, float radius);
std::list<Unit*> Allies(Player* player, Unit* center, float radius, uint32 count = 0);
uint32 Highest(Player* player, uint32 root);
void Reduce(Player* player, uint32 root, int32 milliseconds);
void ReducePercent(Player* player, uint32 root, int32 percent);
void ReduceInvocations(Player* player, int32 milliseconds);
void SetHelper(Player* player, uint32 id, bool enabled);
void SetAmount(Player* player, uint32 id, uint8 slot, int32 amount);
void Extend(Player* player, uint32 id, int32 milliseconds);
void StackWithoutRefresh(Player* player, uint32 id);
void ActivateDawn(Player* player);
void Fulfill(Player* player, Spell* spell, Unit* target);
void Eclipse(Player* player, Unit* target, uint32 amount);
void ReleaseSuncharge(Player* player, Unit* target, uint32 stacks);
bool Daytime();
void SunGate(Player* player);
void Valkyr(Player* player, Unit* target, bool dawn = false, bool fulfillment = false);
void ApplyContracts(SpellInfo* info);
}
#endif
