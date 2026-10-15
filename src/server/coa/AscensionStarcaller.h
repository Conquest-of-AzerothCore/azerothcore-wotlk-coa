/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_STARCALLER_H
#define ASCENSION_STARCALLER_H
#include "EventMap.h"
#include "ObjectGuid.h"
#include "SpellInfo.h"
#include "TaskScheduler.h"
#include <list>
#include <map>
class Player;
class Unit;
class Spell;
namespace AscensionStarcaller
{
struct StarcallerState
{
    EventMap timers;
    TaskScheduler scheduler;
    std::map<ObjectGuid, uint64> counters;
    uint64 clock = 0, sequence = 0;
    double spentPercent = 0;
    uint32 secondMoon = 0, cascade = 0, barrage = 0;
    bool event = false, refreshing = false;
    float chargeDistance = 0, chargeX = 0, chargeY = 0;
    uint32 chargeAura = 0;
    bool chargeReady = false;
    uint64 stagger = 0;
};
Player* Owner(Unit const* unit);
StarcallerState& State(Player* player);
bool Named(SpellInfo const* info, uint32 root);
bool Any(SpellInfo const* info, std::initializer_list<uint32> roots);
bool Lunar(SpellInfo const* info, Player* player);
bool Derived(SpellInfo const* info);
bool Burning(Unit const* unit);
uint32 Count(Unit const* unit, uint32 id);
uint32 MaxPhase(Player* player);
constexpr uint32 LunarPhaseThreshold = 4;
int32 Amount(uint32 id, uint8 slot = 0, Unit* caster = nullptr);
void Cast(Unit* caster, Unit* target, uint32 id);
void Copy(Unit* caster, Unit* target, uint32 id, uint32 amount);
void Mana(Player* player, uint32 amount, uint32 spell = 804994);
bool DelayDamage(Player* player, uint32 amount);
void PayDelayedDamage(Player* player, uint32 ticks = 1);
void FinishCharge(Player* player);
void GainPhase(Player* player, uint32 count = 1);
void Stars(Player* player, Unit* target, uint32 count = 1);
bool Consume(Player* player, Unit* target);
void StartConsume(Player* player, Unit* target);
void Refresh(Player* player);
bool Chance(Player* player, uint32 id, uint32 cooldown = 0, float bonus = 0);
std::list<Unit*> Nearby(Unit* center, float range);
void Reduce(Player* player, uint32 root, int32 milliseconds);
void ReduceHealing(Player* player, uint32 percent);
uint32 Highest(Player* player, uint32 root);
void Replace(Player* player, uint32 root, uint32 replacement);
void MarkedHeal(Player* player);
void Aspect(Player* player, Unit* target, uint32 damage, bool forced = false);
void ApplyContracts(SpellInfo* info);
}
#endif
