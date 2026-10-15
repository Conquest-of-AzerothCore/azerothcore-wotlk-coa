/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_PRIMALIST_SPIRIT_BEAST_H
#define ASCENSION_PRIMALIST_SPIRIT_BEAST_H

class Player;
class SpellInfo;

bool IsAscensionPrimalistTameEligible(Player const* player);
bool HasAscensionPrimalistHunterPetContext(Player const* player);
void ApplyAscensionPrimalistSpiritBeastContract(SpellInfo* spellInfo);
void AddSC_AscensionPrimalistSpiritBeast();

#endif
