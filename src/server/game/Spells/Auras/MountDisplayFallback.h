/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef MOUNT_DISPLAY_FALLBACK_H
#define MOUNT_DISPLAY_FALLBACK_H

#include "Define.h"
#include <atomic>

/// The display a mount aura uses when its creature entry has no creature_template row. The module that owns the
/// client's collection models installs the resolver.
namespace MountDisplayFallback
{
using Resolver = uint32 (*)(uint32 creatureEntry);
inline std::atomic<Resolver> Owner{nullptr};

inline uint32 For(uint32 creatureEntry)
{
    Resolver const resolver = Owner.load(std::memory_order_relaxed);
    return resolver ? resolver(creatureEntry) : 0;
}
}

#endif
