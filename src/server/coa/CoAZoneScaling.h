/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_ZONE_SCALING_H
#define COA_ZONE_SCALING_H

#include <cstdint>
#include <optional>

class Creature;
class Unit;
class Item;

namespace ZoneScaling
{
void Load();
void SelectLevel(Creature* creature, std::uint8_t& level);
[[nodiscard]] std::optional<std::uint32_t> Health(Creature const* creature);
[[nodiscard]] float MeleeMultiplier(Unit const* attacker);
[[nodiscard]] float SpellMultiplier(Unit const* attacker);
[[nodiscard]] bool OwnsItem(std::uint32_t entry);
[[nodiscard]] std::optional<std::uint32_t> ItemPower(std::uint32_t entry, bool pvp);
void NormalizeProperty(Item* item);
}

#endif
