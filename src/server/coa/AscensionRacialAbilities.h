/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_RACIAL_ABILITIES_H
#define ASCENSION_RACIAL_ABILITIES_H

#include "DBCStructure.h"
#include "SharedDefines.h"
#include <array>

namespace AscensionRacialAbilities
{
enum AdditionalRacialSkills
{
    SKILL_ORC_RACIAL_LEGACY = 11125,
    SKILL_DRAENEI_RACIAL_COA = 11760
};

enum RacialSpells
{
    SPELL_ARCANE_TORRENT_ALL_RESOURCES = 28730,
    SPELL_ARCANE_TORRENT_ENERGY = 814286,
    SPELL_ARCANE_TORRENT_MANA = 814287,
    SPELL_BLOOD_FURY_ATTACK_POWER = 814283,
    SPELL_BLOOD_FURY_SPELL_POWER = 814284,
    SPELL_BLOOD_FURY_HYBRID = 814285,
    SPELL_GIFT_OF_THE_NAARU_SPELL_POWER = 814280,
    SPELL_GIFT_OF_THE_NAARU_ATTACK_POWER = 814281,
    SPELL_GIFT_OF_THE_NAARU_HYBRID = 814282
};

struct RacialSkill
{
    uint8 RaceId;
    uint32 SkillId;
};

struct ClassVariant
{
    uint8 ClassId;
    uint32 SpellId;
};

inline constexpr std::array<ClassVariant, 20> ClassVariantsOutsideDbcMask =
{{
    {CLASS_WITCH_HUNTER, SPELL_BLOOD_FURY_HYBRID},
    {CLASS_MONK, SPELL_BLOOD_FURY_HYBRID},
    {CLASS_SON_OF_ARUGAL, SPELL_BLOOD_FURY_HYBRID},
    {CLASS_CHRONOMANCER, SPELL_BLOOD_FURY_SPELL_POWER},
    {CLASS_STARCALLER, SPELL_BLOOD_FURY_SPELL_POWER},
    {CLASS_SUN_CLERIC, SPELL_BLOOD_FURY_HYBRID},
    {CLASS_PROPHET, SPELL_BLOOD_FURY_SPELL_POWER},
    {CLASS_REAPER, SPELL_BLOOD_FURY_HYBRID},
    {CLASS_BARBARIAN, SPELL_ARCANE_TORRENT_ENERGY},
    {CLASS_WITCH_DOCTOR, SPELL_ARCANE_TORRENT_MANA},
    {CLASS_WITCH_HUNTER, SPELL_ARCANE_TORRENT_ALL_RESOURCES},
    {CLASS_PROPHET, SPELL_ARCANE_TORRENT_MANA},
    {CLASS_WILDWALKER, SPELL_ARCANE_TORRENT_MANA},
    {CLASS_BARBARIAN, SPELL_GIFT_OF_THE_NAARU_ATTACK_POWER},
    {CLASS_WITCH_DOCTOR, SPELL_GIFT_OF_THE_NAARU_SPELL_POWER},
    {CLASS_WITCH_HUNTER, SPELL_GIFT_OF_THE_NAARU_HYBRID},
    {CLASS_SON_OF_ARUGAL, SPELL_GIFT_OF_THE_NAARU_HYBRID},
    {CLASS_RANGER, SPELL_GIFT_OF_THE_NAARU_ATTACK_POWER},
    {CLASS_SUN_CLERIC, SPELL_GIFT_OF_THE_NAARU_HYBRID},
    {CLASS_PROPHET, SPELL_GIFT_OF_THE_NAARU_SPELL_POWER}
}};

constexpr bool IsClassVariantOutsideDbcMask(uint32 spellId, uint8 classId)
{
    for (ClassVariant const& variant : ClassVariantsOutsideDbcMask)
        if (variant.ClassId == classId && variant.SpellId == spellId)
            return true;
    return false;
}

inline constexpr std::array<RacialSkill, 12> Skills =
{{
    {RACE_HUMAN, SKILL_RACIAL_HUMAN},
    {RACE_ORC, SKILL_ORC_RACIAL},
    {RACE_ORC, SKILL_ORC_RACIAL_LEGACY},
    {RACE_DWARF, SKILL_RACIAL_DWARVEN},
    {RACE_NIGHTELF, SKILL_RACIAL_NIGHT_ELF},
    {RACE_UNDEAD_PLAYER, SKILL_RACIAL_UNDED},
    {RACE_TAUREN, SKILL_RACIAL_TAUREN},
    {RACE_GNOME, SKILL_RACIAL_GNOME},
    {RACE_TROLL, SKILL_RACIAL_TROLL},
    {RACE_BLOODELF, SKILL_RACIAL_BLOODELF},
    {RACE_DRAENEI, SKILL_RACIAL_DRAENEI},
    {RACE_DRAENEI, SKILL_DRAENEI_RACIAL_COA}
}};

constexpr uint8 GetRace(uint32 skillId)
{
    for (RacialSkill const& skill : Skills)
        if (skill.SkillId == skillId)
            return skill.RaceId;
    return RACE_NONE;
}

inline bool CanLearn(SkillLineAbilityEntry const& ability, uint8 raceId, uint8 classId)
{
    if (!raceId || GetRace(ability.SkillLine) != raceId || !IsAscensionClass(classId))
        return false;

    return ability.AcquireMethod == SKILL_LINE_ABILITY_LEARNED_ON_SKILL_LEARN &&
        ability.MinSkillLineRank <= 1 && !ability.SupercededBySpell &&
        (!ability.RaceMask || (ability.RaceMask & (uint32(1) << (raceId - 1)))) &&
        (IsClassVariantOutsideDbcMask(ability.Spell, classId) || !ability.ClassMask ||
            (ability.ClassMask & (uint32(1) << (classId - 1))));
}
}

#endif
