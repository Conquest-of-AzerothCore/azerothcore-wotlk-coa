/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_BARBARIAN_COMPLETION_H
#define ASCENSION_BARBARIAN_COMPLETION_H

#include "SpellInfo.h"

class Player;
class Unit;

namespace AscensionBarbarian
{
enum TankardMarkers : uint32
{
    SPELL_FULL_TANKARD = 805814,
    SPELL_EMPTY_TANKARD = 806055
};

inline bool Family(SpellInfo const* info, uint32 word, uint32 mask)
{
    return info && info->SpellFamilyName == 18 && (info->SpellFamilyFlags[word] & mask);
}
inline bool Spear(SpellInfo const* info) { return Family(info, 0, 5120) || Family(info, 1, 260); }
inline bool Whirl(uint32 id) { return id == 500002 || (id >= 500450 && id <= 500453); }
inline bool Spirit(uint32 id) { return id == 707763 || id == 707764 || id == 707775 || id == 712467 || id == 712468; }
Player* Owner(Unit* unit);
Unit* Ancestor(Player* player);
bool Enraged(Unit const* unit);
void Extend(Unit* owner, uint32 id, int32 amount, int32 cap = 0);
void ReadyToKill(Player* player);
void ApplyContracts(SpellInfo* info);
}

#endif
