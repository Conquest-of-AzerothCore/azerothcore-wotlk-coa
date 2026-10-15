/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_CLASS_MECHANICS_19_TO_25_H
#define ASCENSION_CLASS_MECHANICS_19_TO_25_H

#include <cstdint>

class Player;
class Spell;
class SpellInfo;
class Unit;

void ApplyAscensionClassMechanics19To25(SpellInfo* spellInfo);
[[nodiscard]] bool CanPrepareAscensionClassMechanics19To25(Spell* spell);
void HandleAscensionClassMechanics19To25Hit(Spell* spell, Player* player,
    Unit* target, std::uint8_t missInfo, std::uint32_t damage);

#endif
