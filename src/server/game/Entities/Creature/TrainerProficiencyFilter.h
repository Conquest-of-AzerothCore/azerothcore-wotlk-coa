/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef TRAINER_PROFICIENCY_FILTER_H
#define TRAINER_PROFICIENCY_FILTER_H

#include "Define.h"
#include <atomic>

class Player;

namespace TrainerProficiencyFilter
{
using Resolver = bool (*)(Player const*, uint32);
inline std::atomic<Resolver> Owner{nullptr};

inline bool Refuses(Player const* player, uint32 spellId)
{
    Resolver const resolver = Owner.load(std::memory_order_relaxed);
    return resolver && resolver(player, spellId);
}
}

#endif
