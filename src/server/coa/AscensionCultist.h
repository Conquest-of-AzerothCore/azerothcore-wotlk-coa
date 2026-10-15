/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_CULTIST_H
#define ASCENSION_CULTIST_H
#include "EventMap.h"
#include "ObjectGuid.h"
#include "SpellInfo.h"
#include "TaskScheduler.h"
#include <list>
#include <set>
class Player;
class Spell;
class Unit;
class Aura;
namespace AscensionCultist
{
constexpr uint32 Insanity = 500706;
constexpr uint32 VoidRune = 800431;
constexpr uint32 Madness = 803061;
constexpr uint32 Herald = 520326;
constexpr uint32 BlackBlood = 804153;
constexpr uint32 CthunTentacle = 50272;
constexpr uint32 MentalAssault = 801151;
constexpr uint32 CthunDamage = 804999;
struct CultistState
{
    EventMap timers;
    TaskScheduler scheduler;
    ObjectGuid covenant, tentacle;
    std::set<ObjectGuid> summons, dashHits;
    Position dashPrevious;
    uint32 dashMs = 0, shockInsanity = 0;
    uint64 sequence = 0;
    bool event = false, refreshing = false;
};
Player* Owner(Unit const* unit);
CultistState& State(Player* player);
bool Named(SpellInfo const* info, uint32 root);
bool Any(SpellInfo const* info, std::initializer_list<uint32> roots);
bool Derived(SpellInfo const* info);
uint32 Count(Unit const* unit, uint32 id);
int32 Amount(uint32 id, uint8 slot = 0, Unit* caster = nullptr);
float Radius(uint32 id, uint8 slot = 0);
void Cast(Unit* caster, Unit* target, uint32 id);
void Copy(Unit* caster, Unit* target, uint32 id, uint32 amount);
void Mana(Player* player, uint32 amount);
bool Resource(Player* player, uint32 id, int32 delta, bool force = false);
void Refresh(Player* player);
bool Chance(Player* player, uint32 id, uint32 cooldown = 0);
std::list<Unit*> Nearby(Unit* center, float radius);
std::list<Unit*> Allies(Player* player, Unit* center, float radius, uint32 count = 0);
uint32 Highest(Player* player, uint32 root);
void Reduce(Player* player, uint32 root, int32 milliseconds);
void RestoreBlade(Player* player);
void SetHelper(Player* player, uint32 id, bool enabled);
void SetAmount(Player* player, uint32 id, uint8 slot, int32 amount);
void Accumulate(Player* player, Unit* target, uint32 id, uint32 total);
void Summon(Player* player, uint32 entry, Position const& position, uint32 duration, Unit* target = nullptr);
void Command(Player* player, Unit* target, bool blast = false);
void StartDash(Player* player);
void UpdateDash(Player* player, uint32 diff);
void ApplyContracts(SpellInfo* info);
}
#endif
