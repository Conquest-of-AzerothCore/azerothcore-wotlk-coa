/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_CLASS_MECHANICS_26_TO_32_H
#define ASCENSION_CLASS_MECHANICS_26_TO_32_H

#include <cstdint>

class Player;
class Spell;
class Unit;

void HandleAscensionClassMechanics26To32Hit(Spell* spell, Player* player,
    Unit* target, std::uint8_t missInfo, std::uint32_t damage, bool critical);

void HandleAscensionClassMechanics26To32SuccessfulInterrupt(Spell* spell,
    Player* player);

#endif
