/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_FELSWORN_H
#define ASCENSION_FELSWORN_H
#include "EventMap.h"
#include "ObjectGuid.h"
#include "SpellInfo.h"
#include "TaskScheduler.h"
#include <list>
#include <vector>
class Player;
class Unit;
class Spell;
namespace AscensionFelsworn
{
enum FelswornSpells : uint32
{
    BurningCommander = 92089,
    MannorothFelfury = 801043,
    Unphased = 803645
};

struct Debt
{
    uint64 remaining;
    uint8 ticks;
};
struct FelswornState
{
    EventMap timers;
    TaskScheduler scheduler;
    std::vector<ObjectGuid> infernals;
    std::vector<Debt> debt;
    uint64 sequence = 0;
    uint32 fury = 0;
    uint32 ruin = 0;
    uint32 carveSteps = 0;
    uint32 spenderCrit = 0;
    bool event = false;
    bool refreshing = false;
};
Player* Owner(Unit const* unit);
FelswornState& State(Player* player);
bool Named(SpellInfo const* info, uint32 root);
bool CanLearnRift(Player const* player, uint32 spellId);
bool Spender(SpellInfo const* info);
bool SpenderImpact(SpellInfo const* info);
bool ResistDebuff(Player* player, SpellInfo const* info);
void SettleDebt(Player* player);
bool Direct(SpellInfo const* info);
bool Derived(SpellInfo const* info);
bool Bane(SpellInfo const* info);
bool Pact(SpellInfo const* info);
bool Rush(SpellInfo const* info);
bool Twin(SpellInfo const* info);
bool Inner(Unit const* player);
bool Triggered(Spell const* spell);
int32 Amount(uint32 spell, uint8 effect = 0, Unit* caster = nullptr);
uint32 Fury(Unit const* player);
void Gain(Player* player, uint32 amount);
void Generated(Player* player, uint32 amount);
void Extend(Player* player, int32 milliseconds);
void Refresh(Player* player);
void Cast(Unit* caster, Unit* target, uint32 spell);
void Copy(Unit* caster, Unit* target, uint32 spell, uint32 amount);
void CopyDot(Player* caster, Unit* target, uint32 spell, uint32 amount);
std::list<Unit*> Nearby(Unit* center, float range);
bool Chance(Player* player, uint32 talent, uint32 cooldown = 0);
void Reduce(Player* player, uint32 root, int32 milliseconds);
void Replace(Player* player, uint32 root, uint32 replacement);
void SpreadCripple(Player* player, Unit* target);
void RefreshUnphased(Player* player);
void Summon(Player* player, Position const& position, bool extended);
void ApplyContracts(SpellInfo* info);
}
#endif
