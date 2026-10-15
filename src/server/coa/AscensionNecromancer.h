/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_NECROMANCER_H
#define ASCENSION_NECROMANCER_H

#include "EventMap.h"
#include "ObjectGuid.h"
#include "SpellInfo.h"
#include <array>
#include <list>
#include <vector>

class Player;
class Creature;
class Unit;
class Aura;
class Spell;

namespace AscensionNecromancer
{
struct MinionRecord
{
    ObjectGuid guid;
    uint32 spell;
    uint8 cost;
};
struct DiseaseSnapshot
{
    uint32 spell;
    uint8 stacks;
    int32 duration;
    int32 maximum;
    uint64 permafrost;
    std::array<int32, 3> amounts;
    std::array<int32, 3> timers;
};
struct NecromancerState
{
    std::vector<MinionRecord> minions;
    std::vector<DiseaseSnapshot> diseases;
    EventMap events;
    EventMap cooldowns;
    ObjectGuid focus;
    ObjectGuid phylactery;
    uint32 stance = 500985;
    uint32 commands = 0;
    uint64 sequence = 0;
    bool syncing = false;
    bool shade = false;
    bool event = false;
};
inline bool Family(SpellInfo const* info, uint8 word, uint32 mask)
{
    return info && info->SpellFamilyName == 29 && (info->SpellFamilyFlags[word] & mask);
}
inline bool Command(SpellInfo const* info)
{
    return Family(info, 2, 16777216);
}
inline bool Raised(SpellInfo const* info)
{
    return Family(info, 2, 2);
}
inline bool Lichfrost(SpellInfo const* info)
{
    return Family(info, 2, 134217728);
}
struct MinionOccupancy
{
    uint32 creature;
    uint32 aura;
};
constexpr MinionOccupancy MinionOccupancies[] = {
    {50065, 805016},
    {50067, 805028},
    {50068, 805017},
    {50073, 805019},
    {50075, 805020},
    {50078, 805021},
    {50115, 805022},
    {50323, 800034},
    {51065, 807927},
    {500650, 807840},
};
inline uint32 OccupancyAura(uint32 creature)
{
    for (auto const& row : MinionOccupancies)
        if (row.creature == creature)
            return row.aura;
    return 0;
}
inline uint32 OccupancyCreature(uint32 aura)
{
    for (auto const& row : MinionOccupancies)
        if (row.aura == aura)
            return row.creature;
    return 0;
}
bool Named(SpellInfo const* info, uint32 root);
Player* Owner(Unit const* unit);
NecromancerState& State(Player* player);
void Forget(Player* player);
int32 Amount(uint32 spell, uint8 effect = 0, Unit* caster = nullptr);
void Cast(Unit* caster, Unit* target, uint32 spell);
void Copy(Unit* caster, Unit* target, uint32 spell, uint32 amount, uint8 effect = 0);
std::list<Unit*> Nearby(Unit* center, float range, bool alive = true);
std::vector<Creature*> Minions(Player* player, bool raisedOnly = false);
uint8 Cost(Player* player, uint32 spell);
uint8 Capacity(Player* player);
uint8 Used(Player* player);
void Sync(Player* player);
void Prune(Player* player, bool all = false);
bool IsMinion(Player* player, Unit const* unit, bool raisedOnly = false);
uint32 Count(Player* player, std::initializer_list<uint32> entries = {});
void BuffArmy(Player* player, uint32 spell, bool owner = false);
void Scale(Player* player, Creature* minion, uint8 cost, float& inheritedSpeed);
bool Responds(uint32 entry, uint32 command);
bool Summon(Player* player, uint32 spell, Unit* target, Position const& position, int32 duration = 0);
void Order(Player* player, Unit* target, uint32 spell);
void Reduce(Player* player, uint32 root, int32 milliseconds);
uint32 KnownRank(Player* player, uint32 root);
bool Chance(Player* player, uint32 talent, float multiplier = 1.0f, uint32 cooldown = 0);
bool Disease(SpellInfo const* info);
uint32 Diseases(Player* player, Unit* target);
void Plague(Player* player, Unit* target, uint8 stacks = 1);
void ExtendWorms(Player* player, Unit* target, int32 milliseconds);
void Spread(Player* player, Unit* source, bool refresh, bool allDiseases = true, uint32 limit = 0);
void CorpseExplosion(Player* player, Unit* center);
void ApplyContracts(SpellInfo* info);
}
#endif
