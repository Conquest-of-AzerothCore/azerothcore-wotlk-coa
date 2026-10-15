/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionSpecLoot.h"
#include "AscensionCoATalentData.h"
#include "AscensionSpecialization.h"
#include "ItemTemplate.h"
#include "Player.h"
#include <algorithm>
#include <optional>

namespace AscensionSpecLoot
{
namespace
{
enum Role : uint8
{
    ROLE_CASTER,
    ROLE_PHYSICAL,
    ROLE_TANK,
    ROLE_COUNT,
};

bool Lists(PrimaryStats const& stats, uint32 stat)
{
    return stat && std::find(stats.begin(), stats.end(), stat) != stats.end();
}

bool IsAttribute(uint32 stat)
{
    return stat == ITEM_MOD_AGILITY || stat == ITEM_MOD_STRENGTH || stat == ITEM_MOD_INTELLECT ||
        stat == ITEM_MOD_SPIRIT;
}

std::optional<Role> RoleOf(uint32 stat)
{
    switch (stat)
    {
        case ITEM_MOD_HIT_SPELL_RATING:
        case ITEM_MOD_CRIT_SPELL_RATING:
        case ITEM_MOD_SPELL_HEALING_DONE:
        case ITEM_MOD_SPELL_DAMAGE_DONE:
        case ITEM_MOD_MANA_REGENERATION:
        case ITEM_MOD_SPELL_POWER:
        case ITEM_MOD_SPELL_PENETRATION:
            return ROLE_CASTER;
        case ITEM_MOD_HIT_MELEE_RATING:
        case ITEM_MOD_HIT_RANGED_RATING:
        case ITEM_MOD_CRIT_MELEE_RATING:
        case ITEM_MOD_CRIT_RANGED_RATING:
        case ITEM_MOD_EXPERTISE_RATING:
        case ITEM_MOD_ATTACK_POWER:
        case ITEM_MOD_RANGED_ATTACK_POWER:
        case ITEM_MOD_ARMOR_PENETRATION_RATING:
            return ROLE_PHYSICAL;
        case ITEM_MOD_DEFENSE_SKILL_RATING:
        case ITEM_MOD_DODGE_RATING:
        case ITEM_MOD_PARRY_RATING:
        case ITEM_MOD_BLOCK_RATING:
        case ITEM_MOD_BLOCK_VALUE:
            return ROLE_TANK;
        default:
            return std::nullopt;
    }
}

uint32 MainAttribute(PrimaryStats const& stats)
{
    for (uint32 stat : stats)
        if (IsAttribute(stat))
            return stat;
    return 0;
}

bool SpecTakesRole(PrimaryStats const& stats, Role role)
{
    uint32 const mainAttribute = MainAttribute(stats);
    switch (role)
    {
        case ROLE_CASTER:
            return mainAttribute == ITEM_MOD_INTELLECT || mainAttribute == ITEM_MOD_SPIRIT;
        case ROLE_PHYSICAL:
            return mainAttribute == ITEM_MOD_STRENGTH || mainAttribute == ITEM_MOD_AGILITY;
        case ROLE_TANK:
            return Lists(stats, ITEM_MOD_STAMINA);
        default:
            return false;
    }
}
}

PrimaryStats ActivePrimaryStats(Player const* player)
{
    if (!player)
        return {};

    uint32 const active = GetAscensionActiveSpecialization(player);
    for (AscensionCompatData::CoASpecialization const& specialization : AscensionCompatData::CoASpecializations)
        if (specialization.SpecId == active && specialization.ClassId == player->getClass())
            return specialization.PrimaryStats;
    return {};
}

Fit ItemFit(PrimaryStats const& stats, ItemTemplate const* item)
{
    if (!item || stats == PrimaryStats{})
        return Fit::None;

    std::array<int32, ITEM_MOD_SPIRIT + 1> attributes{};
    std::array<int32, ROLE_COUNT> roles{};
    int32 stamina = 0;
    for (uint32 index = 0; index < item->StatsCount && index < MAX_ITEM_PROTO_STATS; ++index)
    {
        uint32 const type = item->ItemStat[index].ItemStatType;
        int32 const value = item->ItemStat[index].ItemStatValue;
        if (value <= 0)
            continue;
        if (IsAttribute(type))
            attributes[type] += value;
        else if (type == ITEM_MOD_STAMINA)
            stamina += value;
        else if (std::optional<Role> role = RoleOf(type))
            roles[*role] += value;
    }

    int32 const strongestAttribute = *std::max_element(attributes.begin(), attributes.end());
    if (strongestAttribute > 0)
    {
        uint32 const mainAttribute = MainAttribute(stats);
        if (mainAttribute && attributes[mainAttribute] == strongestAttribute)
            return Fit::Primary;
        for (uint32 attribute = 0; attribute < attributes.size(); ++attribute)
            if (attributes[attribute] && Lists(stats, attribute))
                return Fit::Shared;
        return Fit::None;
    }

    int32 const strongestRole = *std::max_element(roles.begin(), roles.end());
    if (strongestRole > 0)
    {
        for (uint8 role = 0; role < ROLE_COUNT; ++role)
            if (roles[role] == strongestRole && SpecTakesRole(stats, Role(role)))
                return Fit::Primary;
        return Fit::None;
    }

    return stamina > 0 && SpecTakesRole(stats, ROLE_TANK) ? Fit::Primary : Fit::None;
}
}
