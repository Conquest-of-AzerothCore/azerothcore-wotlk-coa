/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_VENOMANCER_H
#define ASCENSION_VENOMANCER_H
#include "EventMap.h"
#include "ObjectGuid.h"
#include "Position.h"
#include "SpellInfo.h"
#include "TaskScheduler.h"
#include <list>
#include <set>
class Player;
class Spell;
class Unit;
namespace AscensionVenomancer
{
constexpr uint32 Brood = 804972;
constexpr uint32 Exposed = 805095;
constexpr uint32 CharmOfWarding = 705967;
constexpr uint32 Spider = 800841;
constexpr uint32 SpiderlingVenomSource = 807702;
constexpr uint32 Beetle = 803183;
constexpr uint32 Skulk = 800843;
constexpr uint32 SpiderLord = 704264;
constexpr uint32 SpiderLordDisplay = 142811;
struct VenomancerState
{
    EventMap timers;
    TaskScheduler scheduler;
    ObjectGuid host;
    Position exit;
    uint32 hostMap = 0;
    std::set<ObjectGuid> summons;
    std::list<ObjectGuid> traps;
    uint64 sequence = 0;
    bool event = false, refreshing = false, parasiteExit = false;
    float mushroomCoefficient = .25f;
};
Player* Owner(Unit const* unit);
VenomancerState& State(Player* player);
bool Named(SpellInfo const* info, uint32 root);
bool Any(SpellInfo const* info, std::initializer_list<uint32> roots);
bool Derived(SpellInfo const* info);
bool Spender(SpellInfo const* info);
bool Poison(SpellInfo const* info);
bool Venom(SpellInfo const* info);
bool HasDispel(Unit const* target, uint32 dispel);
float HealingFactor(Player* player, Unit* target, SpellInfo const* info);
bool CrossesLair(Unit const* attacker, Unit const* target);
void AddFungic(Player* player, Unit* target, uint32 damage);
uint32 Count(Unit const* unit, uint32 id);
int32 Amount(uint32 id, uint8 slot = 0, Unit* caster = nullptr);
float Radius(uint32 id, uint8 slot = 0);
void Cast(Unit* caster, Unit* target, uint32 id);
void Copy(Unit* caster, Unit* target, uint32 id, uint32 amount);
void Mana(Player* player, uint32 amount);
bool Resource(Player* player, uint32 id, int32 delta);
void Expose(Player* player, uint32 stacks, bool molt = false);
uint32 ClearExposed(Player* player);
float BroodMultiplier(uint32 count, int32 effectiveness);
void Refresh(Player* player);
void UpdateSpiderLordDisplay(Player* player);
bool Chance(Player* player, uint32 id, uint32 cooldown = 0);
std::list<Unit*> Nearby(Unit* center, float radius);
std::list<Unit*> Allies(Player* player, Unit* center, float radius, uint32 count = 0);
uint32 Highest(Player* player, uint32 root);
void Reduce(Player* player, uint32 root, int32 milliseconds);
void ReducePercent(Player* player, uint32 root, int32 percent);
void SetHelper(Player* player, uint32 id, bool enabled);
void SetAmount(Player* player, uint32 id, uint8 slot, int32 amount);
void ExtendOwned(Player* player, Unit* target, uint32 root, int32 milliseconds);
void Spread(Player* player, Unit* source, Unit* target, uint32 root);
void ApplyVenoms(Player* player, Unit* target, bool fromSpiderling = false);
void Mushroom(Player* player, Position const& position, float coefficient = .25f, bool big = false);
void Summon(Player* player, Unit* target, uint32 spell, Position const* position = nullptr);
void ExitParasite(Player* player);
void ApplyContracts(SpellInfo* info);
}
#endif
