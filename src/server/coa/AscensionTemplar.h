/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_TEMPLAR_H
#define ASCENSION_TEMPLAR_H
#include "EventMap.h"
#include "ObjectGuid.h"
#include "SpellInfo.h"
#include <list>
#include <vector>

class Player;
class Unit;
class Spell;
namespace AscensionTemplar
{
struct TemplarState
{
    EventMap cooldowns;
    std::vector<ObjectGuid> copies;
    uint64 sequence = 0;
    uint32 zealotry = 0;
    uint32 argent = 0;
    bool event = false;
    bool oath = false;
    bool retribution = false;
};
Player* Owner(Unit const* unit);
TemplarState& State(Player* player);
bool Named(SpellInfo const* info, uint32 root);
inline bool Family(SpellInfo const* info, uint8 word, uint32 mask)
{
    return info && info->SpellFamilyName == 25 && (info->SpellFamilyFlags[word] & mask);
}
inline bool Breaker(SpellInfo const* info)
{
    return Family(info, 2, 128) || Named(info, 805409);
}
bool Libram(SpellInfo const* info);
bool HasLibram(Player* player);
bool Ability(SpellInfo const* info);
bool Derived(SpellInfo const* info);
int32 Amount(uint32 spell, uint8 effect = 0, Unit* caster = nullptr);
void Cast(Unit* caster, Unit* target, uint32 spell);
void Copy(Unit* caster, Unit* target, uint32 spell, uint32 amount);
std::list<Unit*> Nearby(Unit* center, float range);
bool Chance(Player* player, uint32 talent, uint32 cooldown = 0);
void Reduce(Player* player, uint32 root, int32 milliseconds);
void ReduceLibrams(Player* player, int32 milliseconds);
void Replacement(Player* player, uint32 root, uint32 replacement);
void GrantOath(Player* player, uint32 oath);
void ClearOaths(Player* player);
void Delay(Player* player, uint32 amount);
void ReduceDebt(Player* player, uint32 percent, bool oneTick = false);
void Zealotry(Player* player, Unit* target, bool repeat = false);
void SpreadCondemn(Player* player, Unit* target);
uint32 HopeCount(Player* player);
bool DivineSteed(Unit const* unit);
void ApplyContracts(SpellInfo* info);
}
#endif
