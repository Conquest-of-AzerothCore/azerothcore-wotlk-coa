#ifndef AZEROTHCORE_ASCENSION_EQUIPPED_GEAR_LOOT_H
#define AZEROTHCORE_ASCENSION_EQUIPPED_GEAR_LOOT_H

#include "Define.h"

class Creature;
struct Loot;

namespace AscensionEquippedGearLoot
{
bool AddLoot(Creature const* creature, Loot& loot, uint16 lootMode);
}

#endif
