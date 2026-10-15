/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_XOROTH_H
#define ASCENSION_XOROTH_H
#include "EventMap.h"
#include "ObjectGuid.h"
#include "SpellInfo.h"
#include "TaskScheduler.h"
#include <list>
#include <vector>
class Player;
class Unit;
class Creature;
class Aura;
namespace AscensionXoroth
{
enum SecondarySpells : uint32
{
    SPELL_DEMONIC_VISAGE = 300392,
    SPELL_DEMONIC_VISAGE_SLOW = 520309,
    SPELL_UNLEASH_PESTILENCE = 801002,
    SPELL_WARPATH = 805793,
    SPELL_WARPATH_PROTECTION = 805792
};

struct XorothState
{
    EventMap timers;
    TaskScheduler scheduler;
    std::vector<ObjectGuid> imps;
    uint64 sequence = 0;
    uint32 fire = 0;
    uint32 blood = 0;
    uint8 bellowsResult = 0;
    float unleash = 1;
    bool event = false;
    bool refreshing = false;
    bool curseShield = false;
};
Player* Owner(Unit const* unit);
XorothState& State(Player* player);
bool Named(SpellInfo const* info, uint32 root);
bool Spender(SpellInfo const* info);
bool Sever(SpellInfo const* info);
bool Infernal(SpellInfo const* info);
bool Derived(SpellInfo const* info);
bool Pestilence(uint32 id);
bool Mark(SpellInfo const* info);
uint32 Count(Unit const* unit, uint32 id);
int32 Amount(uint32 id, uint8 slot = 0, Unit* caster = nullptr);
void Cast(Unit* caster, Unit* target, uint32 id);
void Copy(Unit* caster, Unit* target, uint32 id, uint32 damage);
void Gain(Player* player, uint32 count);
void Blood(Player* player);
void SetRemainingUses(Aura* aura, uint8 uses);
void Refresh(Player* player);
bool Chance(Player* player, uint32 id, uint32 cooldown = 0, float bonus = 0);
std::list<Unit*> Nearby(Unit* center, float range);
void Reduce(Player* player, uint32 root, int32 milliseconds);
uint32 Highest(Player* player, uint32 root);
void Replace(Player* player, uint32 root, uint32 replacement);
void Unleash(Player* player, Unit* center, float strength = 1, bool pet = false);
void Summon(Player* player, uint32 entry, Position const& position, uint32 duration);
void ImpFormation(uint32 slot, float& distance, float& angle);
Position ImpPosition(Player* player);
void Spread(Player* player, Unit* target);
void ApplyContracts(SpellInfo* info);
}
#endif
