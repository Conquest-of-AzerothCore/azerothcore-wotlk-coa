/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_TINKER_H
#define ASCENSION_TINKER_H
#include "EventMap.h"
#include "ObjectGuid.h"
#include "Position.h"
#include "SpellInfo.h"
#include "TaskScheduler.h"
#include <list>
#include <map>
#include <set>
class Player;
class Spell;
class Unit;
class Creature;
namespace AscensionTinker
{
constexpr uint32 Scrap = 801816;
constexpr uint32 Mechsuit = 801384;
constexpr uint32 GatlingGun = 500213;
constexpr uint32 Napalm = 805315;
struct TinkerState
{
    EventMap timers;
    TaskScheduler scheduler;
    std::set<ObjectGuid> summons;
    std::set<ObjectGuid> moduleTargets;
    ObjectGuid focus, observedVictim, observedAutoRepeatTarget, reconstruction;
    uint32 module = 0;
    uint64 sequence = 0;
    bool event = false, refreshing = false;
};
Player* Owner(Unit const* unit);
TinkerState& State(Player* player);
bool NotifyAttack(Player* player, Unit* target);
bool NotifySpellAttack(Player* player, SpellInfo const* spellInfo, Unit* target);
void ObserveAttack(Player* player);
bool Named(SpellInfo const* info, uint32 root);
bool Any(SpellInfo const* info, std::initializer_list<uint32> roots);
bool Derived(SpellInfo const* info);
bool Build(SpellInfo const* info);
bool MechAbility(SpellInfo const* info);
bool Shot(SpellInfo const* info);
bool Beacon(uint32 entry);
bool Permanent(uint32 entry);
bool Turret(uint32 entry);
bool Owned(Player* player, Unit* unit);
bool Nanobots(Player* player, Unit* target);
uint32 Count(Unit const* unit, uint32 id);
int32 Amount(uint32 id, uint8 slot = 0, Unit* caster = nullptr);
float Radius(uint32 id, uint8 slot = 0);
void Cast(Unit* caster, Unit* target, uint32 id);
void Copy(Unit* caster, Unit* target, uint32 id, uint32 amount);
void Mana(Unit* target, uint32 amount, Player* source);
bool Resource(Player* player, uint32 id, int32 delta);
bool Chance(Player* player, uint32 id, uint32 cooldown = 0);
void Refresh(Player* player);
void ActivateModule(Player* player, uint32 id);
void ReconcileModules(Player* player);
void ExitMechsuit(Player* player);
std::list<Unit*> Nearby(Unit* center, float range);
std::list<Unit*> Allies(Player* player, Unit* center, float range, uint32 count = 0);
std::list<Creature*> Devices(Player* player);
uint32 Highest(Player* player, uint32 root);
void Reduce(Player* player, uint32 root, int32 milliseconds);
void SetHelper(Player* player, uint32 id, bool enabled);
void SetAmount(Player* player, uint32 id, uint8 slot, int32 amount);
void Grant(Player* player, uint32 id, uint32 charges = 1);
void Spend(Player* player, uint32 id, uint64 generation);
void PetCast(Player* player, Unit* target, uint32 spell, bool turret = false);
void Summon(Player* player, Unit* target, uint32 spell, Position const* position = nullptr);
void DeviceEvent(Player* player, Creature* device, Unit* target, SpellInfo const* info,
                 uint32 damage, uint32 healing, bool critical, bool periodic);
void Overcharge(Player* player, Creature* device);
void Detonate(Player* player);
void Scale(Player* player, Creature* creature, bool initial);
uint32 SummonVulnerability(Player* player, Unit* attacker, Unit* target);
void ApplyContracts(SpellInfo* info);
void ApplyBeaconChargePool(SpellInfo* info);
}
#endif
