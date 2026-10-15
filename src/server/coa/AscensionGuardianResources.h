/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_GUARDIAN_RESOURCES_H
#define ASCENSION_GUARDIAN_RESOURCES_H

#include <cstdint>

class Player;
class Spell;
class SpellInfo;

void ApplyAscensionGuardianResourceContracts(SpellInfo* info);
void HandleAscensionGuardianResourceCast(Spell* spell);
void RemoveAscensionGuardianResourceTalent(Player* player, std::uint32_t id);

#endif
