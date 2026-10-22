/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU
 * AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef ASCENSION_TAUGHT_ABILITY_DATA_H
#define ASCENSION_TAUGHT_ABILITY_DATA_H

#include <array>
#include <cstdint>

namespace AscensionCompatData
{
struct TaughtAbility
{
    std::uint8_t ClassId;
    std::uint32_t SpecId;
    std::uint8_t RequiredLevel;
    std::uint32_t ParentSpellId;
    std::uint32_t SpellId;
};

inline constexpr std::array<TaughtAbility, 23> TaughtAbilities =
{{
    { 12, 3, 0, 804729, 804834 },
    { 13, 6, 0, 561069, 801662 },
    { 15, 11, 0, 801343, 578118 },
    { 15, 11, 0, 801343, 680263 },
    { 15, 12, 10, 92094, 680230 },
    { 16, 13, 10, 92097, 804019 },
    { 20, 99, 10, 92114, 800157 },
    { 20, 99, 10, 92114, 674 },
    { 22, 31, 10, 92119, 806291 },
    { 25, 40, 10, 92131, 520326 },
    { 25, 96, 10, 680750, 567524 },
    { 31, 59, 10, 92148, 574301 },
    { 31, 59, 10, 92148, 574302 },
    { 31, 59, 10, 92148, 574303 },
    { 31, 59, 10, 92148, 500860 },
    { 31, 59, 10, 92148, 570335 },
    { 31, 59, 10, 92148, 574306 },
    { 31, 59, 40, 573365, 573364 },
    { 31, 59, 40, 573365, 573310 },
    { 28, 51, 30, 524834, 524835 },
    { 28, 51, 10, 92140, 524840 },
    { 28, 50, 10, 92141, 801384 },
    { 32, 61, 50, 707876, 707717 }
}};
}

#endif
