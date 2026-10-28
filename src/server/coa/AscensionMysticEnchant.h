/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_MYSTIC_ENCHANT_H
#define ASCENSION_MYSTIC_ENCHANT_H

#include "AscensionMysticEnchantRules.h"
#include <array>
#include <optional>
#include <vector>

class Player;

namespace AscensionMysticEnchant
{
struct Collection
{
    std::array<uint32, QUALITY_MAX> Known{};
    std::array<uint32, QUALITY_MAX> Active{};
    std::array<bool, QUALITY_MAX> Offered{};
    uint32 KnownTotal = 0;
    uint32 KnownWorldforged = 0;
    uint32 OpenSlots = 0;
    uint32 FilledSlots = 0;
};

bool ApplyGuide(Player* player, std::vector<GuideEnchant> const& guide, bool learnMissing = false);

uint32 ClearActivePreset(Player* player);

std::optional<Collection> Summarize(Player const* player);
}

#endif
