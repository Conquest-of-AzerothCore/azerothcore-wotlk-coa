/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_TAMING_DATA_H
#define ASCENSION_TAMING_DATA_H

#include <array>
#include <cstdint>

namespace AscensionTaming
{
enum CreatureKind : std::uint32_t
{
    KIND_BEAST = 1,
    KIND_DRAGONKIN = 2,
    KIND_DEMON = 3,
    KIND_ELEMENTAL = 4,
    KIND_UNDEAD = 6
};

struct FamilyCall
{
    std::uint32_t SpellId;
    std::uint32_t Kind;
    std::uint32_t Starter;
};

constexpr std::array<FamilyCall, 10> FAMILY_CALLS = { {
    { 883, KIND_BEAST, 2031 },
    { 1100883, KIND_BEAST, 2031 },
    { 1350883, KIND_BEAST, 2031 },
    { 884, KIND_DEMON, 1547 },
    { 1100884, KIND_DEMON, 1547 },
    { 885, KIND_UNDEAD, 2178 },
    { 91602, KIND_ELEMENTAL, 832 },
    { 1441602, KIND_ELEMENTAL, 832 },
    { 91631, KIND_DRAGONKIN, 4016 },
    { 1441631, KIND_DRAGONKIN, 4016 },
} };

struct TamingChannel
{
    std::uint32_t SpellId;
    std::uint32_t Kind;
};

constexpr std::array<TamingChannel, 9> TAMING_CHANNELS = { {
    { 1515, KIND_BEAST },
    { 890, KIND_DEMON },
    { 896, KIND_DEMON },
    { 891, KIND_UNDEAD },
    { 899, KIND_UNDEAD },
    { 91606, KIND_ELEMENTAL },
    { 93569, KIND_ELEMENTAL },
    { 91634, KIND_DRAGONKIN },
    { 93558, KIND_DRAGONKIN },
} };

constexpr FamilyCall const* FindFamilyCall(std::uint32_t spellId)
{
    for (FamilyCall const& call : FAMILY_CALLS)
        if (call.SpellId == spellId)
            return &call;
    return nullptr;
}

constexpr std::uint32_t CreatureTypeMask(std::uint32_t kind)
{
    return 1u << (kind - 1);
}
}

#endif
