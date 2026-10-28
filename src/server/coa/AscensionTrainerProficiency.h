/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_TRAINER_PROFICIENCY_H
#define ASCENSION_TRAINER_PROFICIENCY_H

#include "AscensionCustomClassData.h"
#include "AscensionLiveBaselineData.h"
#include "AscensionSpecialization.h"
#include "Player.h"
#include <algorithm>

namespace AscensionTrainerProficiency
{
inline bool Refuses(Player const* player, uint32 spellId)
{
    if (!player || !IsAscensionCustomClassId(player->getClass()))
        return false;

    bool const proficiency = std::any_of(AscensionCompatData::ProficiencyDefinitions.begin(),
        AscensionCompatData::ProficiencyDefinitions.end(),
        [spellId](AscensionCompatData::ProficiencyDefinition const& entry) { return entry.SpellId == spellId; });
    if (!proficiency)
        return false;

    uint8 const classId = player->getClass();
    bool const baseline = std::any_of(AscensionLiveBaseline::Proficiencies.begin(),
        AscensionLiveBaseline::Proficiencies.end(),
        [classId, spellId](AscensionLiveBaseline::Proficiency const& entry)
        {
            return entry.ClassId == classId && entry.SpellId == spellId;
        });
    if (baseline)
        return false;

    return std::none_of(AscensionCompatData::TalentProficiencies.begin(),
        AscensionCompatData::TalentProficiencies.end(),
        [player, classId, spellId](AscensionCompatData::TalentProficiency const& entry)
        {
            return entry.ClassId == classId && entry.ProficiencySpellId == spellId &&
                player->HasSpell(entry.TalentSpellId);
        });
}
}

#endif
