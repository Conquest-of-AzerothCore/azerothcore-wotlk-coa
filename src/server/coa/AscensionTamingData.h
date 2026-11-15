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

constexpr std::uint32_t CLASS_HERO_ID = 10;
constexpr std::uint32_t COSMETIC_PET_TIER_COUNT = 5;

struct PetSpells
{
    std::uint32_t Summon;
    std::uint32_t Dismiss;
};

enum class PetCaster
{
    Stock,
    ConquestOfAzeroth,
    Hero
};

constexpr PetCaster CasterOf(std::uint32_t classId)
{
    if ((classId >= 1 && classId <= 9) || classId == 11)
        return PetCaster::Stock;
    if (classId >= 12 && classId <= 32)
        return PetCaster::ConquestOfAzeroth;
    return PetCaster::Hero;
}

constexpr PetSpells CosmeticPetSpells(std::uint32_t classId, std::uint32_t tier)
{
    PetCaster const caster = CasterOf(classId);
    bool const stock = caster == PetCaster::Stock;
    switch (tier)
    {
        case 1:
            if (stock)
                return { 1100883, 1102641 };
            return caster == PetCaster::ConquestOfAzeroth ? PetSpells{ 574302, 574303 } : PetSpells{ 883, 2641 };
        case 2: return stock ? PetSpells{ 1100884, 1100892 } : PetSpells{ 884, 892 };
        case 3: return { 885, 893 };
        case 4: return stock ? PetSpells{ 1441602, 1441651 } : PetSpells{ 91602, 91651 };
        case 5: return stock ? PetSpells{ 1441631, 1441652 } : PetSpells{ 91631, 91652 };
        default: return { 0, 0 };
    }
}

constexpr std::uint32_t CosmeticPetKind(std::uint32_t tier)
{
    switch (tier)
    {
        case 1: return KIND_BEAST;
        case 2: return KIND_DEMON;
        case 3: return KIND_UNDEAD;
        case 4: return KIND_ELEMENTAL;
        case 5: return KIND_DRAGONKIN;
        default: return 0;
    }
}

constexpr std::uint64_t ClassBit(std::uint32_t classId)
{
    return classId >= 1 && classId <= 64 ? std::uint64_t(1) << (classId - 1) : 0;
}

constexpr std::uint64_t RealmClassMask(bool conquestOfAzeroth, bool warcraftReborn)
{
    std::uint64_t mask = 0;
    if (conquestOfAzeroth)
        for (std::uint32_t classId = 12; classId <= 32; ++classId)
            mask |= ClassBit(classId);
    else if (warcraftReborn)
        for (std::uint32_t classId : { 1u, 2u, 3u, 4u, 5u, 6u, 7u, 8u, 9u, 11u })
            mask |= ClassBit(classId);
    else
        mask = ClassBit(CLASS_HERO_ID);
    return mask;
}
}

#endif
