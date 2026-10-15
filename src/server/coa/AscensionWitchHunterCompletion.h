/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_WITCH_HUNTER_COMPLETION_H
#define ASCENSION_WITCH_HUNTER_COMPLETION_H

#include "SpellInfo.h"
#include <list>

class Player;
class Unit;

namespace AscensionWitchHunter
{
enum WitchHunterSharedSpells : uint32
{
    SPELL_BRAND_OF_THE_DAMNED_DAMAGE = 807683
};

inline bool Family(SpellInfo const* info, uint8 word, uint32 mask)
{
    return info && info->SpellFamilyName == 21 && (info->SpellFamilyFlags[word] & mask);
}
inline bool Dawn(SpellInfo const* info)
{
    return info && (info->Id == 802024 || (info->Id >= 802248 && info->Id <= 802252) || info->Id == 574342 ||
                    info->Id == 574343);
}
inline bool Dusk(SpellInfo const* info)
{
    return info && (info->Id == 802020 || (info->Id >= 802253 && info->Id <= 802258));
}
inline bool Noctis(SpellInfo const* info)
{
    return Family(info, 1, 64);
}
inline bool Bolt(SpellInfo const* info)
{
    return Family(info, 2, 32 | 16);
}
inline bool Heartseeking(SpellInfo const* info)
{
    return Family(info, 1, 2048);
}
inline bool Quickdraw(SpellInfo const* info)
{
    return Family(info, 0, 64) && info->Id != 807527;
}
inline bool Desecrate(SpellInfo const* info)
{
    return info && info->SpellFamilyName == 21 &&
           (info->Id == 680518 || (info->Id >= 681207 && info->Id <= 681211));
}
inline bool MainBrand(SpellInfo const* info)
{
    return info && (info->Id == 501380 || info->Id == 562390 || info->Id == 562573 || info->Id == 807682 ||
                    (info->Id >= 807705 && info->Id <= 807710));
}
Player* Owner(Unit* unit);
Unit* Hound(Player* player);
uint32 GetShadowhoundDisplay(Player* player);
std::list<Unit*> Nearby(Unit* center, float range);
void Cast(Unit* caster, Unit* target, uint32 id);
void Reset(Player* player, uint32 id);
void Replacement(Player* player, uint32 word, uint32 mask, uint32 child);
void ClearReplacement(Player* player, uint32 word, uint32 mask);
void ApplyContracts(SpellInfo* info);
bool InSmoke(Unit const* attacker, Unit const* target);
void CallHounds(Player* player, Unit* target);
void SummonHounds(Player* player, uint32 count, uint32 duration, uint32 spellId, Unit* target = nullptr);
}

#endif
