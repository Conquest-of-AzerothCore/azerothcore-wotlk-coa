/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_DUNGEON_RESCALE_H
#define COA_DUNGEON_RESCALE_H

#include <cstdint>
#include <optional>

class Creature;
class Map;
class Item;
class Unit;
class SpellInfo;
struct Loot;

namespace DungeonRescale
{
void Load();
[[nodiscard]] bool OwnsItem(std::uint32_t entry);
[[nodiscard]] std::optional<std::uint32_t> ItemPower(std::uint32_t entry, bool pvp);
bool ApplyLoot(Loot& loot, Map const* map);
void NormalizeProperty(Item* item);
[[nodiscard]] bool Contains(std::uint32_t map);
[[nodiscard]] bool Owns(Unit const* unit);
[[nodiscard]] bool FixedMap(Map const* map);
[[nodiscard]] std::optional<std::uint32_t> Health(Creature const* creature);
void SelectLevel(Creature* creature, std::uint8_t& level);
[[nodiscard]] float MeleeMultiplier(Unit const* attacker);
[[nodiscard]] float SpellMultiplier(Unit const* attacker, SpellInfo const* spell, bool periodic);
}

#endif
