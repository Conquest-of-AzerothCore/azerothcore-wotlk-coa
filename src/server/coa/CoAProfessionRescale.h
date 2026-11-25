/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_PROFESSION_RESCALE_H
#define COA_PROFESSION_RESCALE_H

#include <cstdint>
#include <optional>

class Item;

namespace ProfessionRescale
{
void Load();
bool OwnsItem(std::uint32_t entry);
std::optional<std::uint32_t> ItemPower(std::uint32_t entry, bool pvp);
void NormalizeProperty(Item* item);
}

#endif
