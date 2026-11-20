#ifndef COA_ASCENSION_RAID_DIFFICULTY_LOOT_H
#define COA_ASCENSION_RAID_DIFFICULTY_LOOT_H

#include <cstdint>

class LootStore;
class WorldObject;
struct Loot;

namespace AscensionRaidDifficultyLoot
{
void Apply(Loot& loot, LootStore const& store, std::uint32_t lootId, WorldObject const* source);
}

#endif
