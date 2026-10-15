/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_PRIMALIST_WEAPONS_H
#define ASCENSION_PRIMALIST_WEAPONS_H

class Player;
class SpellInfo;

bool IsAscensionPrimalistWeaponsEligible(Player const* player, bool allowUnconfirmed = false);
void ApplyAscensionPrimalistWeaponsContract(SpellInfo* info);
void RemoveAscensionPrimalistWeapons(Player* player);
void AddSC_AscensionPrimalistWeapons();

#endif
