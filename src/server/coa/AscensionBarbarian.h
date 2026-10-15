/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_BARBARIAN_H
#define ASCENSION_BARBARIAN_H

#include <cstdint>

class Player;
class Spell;
class SpellInfo;

void ApplyAscensionBarbarianSpellChanges(SpellInfo* info);
void HandleAscensionBarbarianAura(Player* player, std::uint32_t spellId, bool apply);
void HandleAscensionBarbarianCast(Spell* spell);
void HandleAscensionBarbarianAttackPower(Player* player, float& modifier, bool ranged);

#endif
