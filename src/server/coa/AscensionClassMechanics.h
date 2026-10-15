/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_CLASS_MECHANICS_H
#define ASCENSION_CLASS_MECHANICS_H

#include <cstdint>

class Player;
class Spell;
class SpellInfo;
class Unit;
struct TargetInfo;

void ApplyAscensionClassMechanics(SpellInfo* spellInfo);
void SynchronizeAscensionClassMechanics(Player* player);
void PrepareAscensionClassMechanicsCast(Spell* spell);
void HandleAscensionClassMechanicsCalculatedTarget(Spell* spell, Player* player,
    Unit* target, TargetInfo& targetInfo);
void HandleAscensionClassMechanicsHit(Spell* spell, Player* player,
    Unit* target, std::uint8_t missInfo, std::uint32_t damage,
    std::uint32_t healing, bool critical);
void HandleAscensionClassMechanicsCast(Spell* spell);
void HandleAscensionClassMechanicsBlock(Player* player);
void HandleAscensionClassMechanicsAuraApply(Player* player, std::uint32_t spellId);
void HandleAscensionClassMechanicsAuraRemove(Player* player, std::uint32_t spellId, bool removedByDeath);

#endif
