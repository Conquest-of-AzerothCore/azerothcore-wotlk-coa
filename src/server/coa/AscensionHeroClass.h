/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_HERO_CLASS_H
#define ASCENSION_HERO_CLASS_H

#include <algorithm>
#include <array>
#include <cstdint>
#include <optional>

namespace AscensionHeroClass
{
enum StockClass : std::uint8_t
{
    WARRIOR = 1,
    PALADIN = 2,
    HUNTER = 3,
    ROGUE = 4,
    PRIEST = 5,
    DEATH_KNIGHT = 6,
    SHAMAN = 7,
    MAGE = 8,
    WARLOCK = 9,
    DRUID = 11
};

enum Context : std::uint8_t
{
    CONTEXT_ABILITY = 8,
    CONTEXT_ABILITY_REACTIVE = 9,
    CONTEXT_PET = 10,
    CONTEXT_PET_CHARM = 11,
    CONTEXT_EQUIP_RELIC = 12,
    CONTEXT_EQUIP_SHIELDS = 13
};

constexpr std::array<std::uint32_t, 4> OVERPOWER_RANKS = { 7384, 7887, 11584, 11585 };
constexpr std::array<std::uint32_t, 7> COUNTERATTACK_RANKS = { 19306, 19308, 20909, 20910, 27067, 48998, 48999 };

template <std::size_t Count, class HasSpell>
bool OwnsAny(std::array<std::uint32_t, Count> const& ranks, HasSpell const& hasSpell)
{
    return std::any_of(ranks.begin(), ranks.end(), [&hasSpell](std::uint32_t spellId) { return hasSpell(spellId); });
}

template <class HasSpell>
std::optional<bool> Answer(std::uint8_t stockClass, std::uint8_t context, HasSpell const& hasSpell)
{
    switch (context)
    {
        case CONTEXT_EQUIP_RELIC:
        case CONTEXT_EQUIP_SHIELDS:
            return true;
        case CONTEXT_ABILITY_REACTIVE:
            if (stockClass == WARRIOR)
                return OwnsAny(OVERPOWER_RANKS, hasSpell);
            if (stockClass == HUNTER)
                return OwnsAny(COUNTERATTACK_RANKS, hasSpell);
            return std::nullopt;
        case CONTEXT_ABILITY:
            if (stockClass == DEATH_KNIGHT || stockClass == SHAMAN || stockClass == DRUID || stockClass == PRIEST)
                return true;
            return std::nullopt;
        case CONTEXT_PET:
            if (stockClass == HUNTER)
                return true;
            return std::nullopt;
        case CONTEXT_PET_CHARM:
            if (stockClass == WARLOCK)
                return true;
            return std::nullopt;
        default:
            return std::nullopt;
    }
}
}

#endif
