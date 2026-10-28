/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_NATIVE_ITEM_SCALING_H
#define COA_ASCENSION_NATIVE_ITEM_SCALING_H

#include <cstdint>

class Item;

namespace NativeItemScaling
{
[[nodiscard]] bool Active();
[[nodiscard]] bool Handles(std::uint32_t itemId);
[[nodiscard]] std::uint8_t InstanceLevel(Item const* item);
}

#endif
