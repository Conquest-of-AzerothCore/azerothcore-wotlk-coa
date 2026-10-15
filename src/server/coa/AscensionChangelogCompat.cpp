/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AscensionChangelogCompat.h"
#include "AscensionChangelogData.h"
#include "DBCStores.h"
#include "Log.h"
#include "SpellInfo.h"
#include <algorithm>

namespace
{
using AscensionChangelog::Change;
using AscensionChangelog::Field;

constexpr uint32 DisabledSpellEffect = 0;

int32 ReadChangeValue(SpellInfo const* spellInfo, Change const& change)
{
    switch (change.Property)
    {
        case Field::BasePoints:
            return spellInfo->Effects[change.EffectIndex].BasePoints;
        case Field::RecoveryTime:
            return int32(spellInfo->RecoveryTime);
        case Field::CategoryRecoveryTime:
            return int32(spellInfo->CategoryRecoveryTime);
        case Field::Duration:
            return spellInfo->GetDuration();
        case Field::InitialPeriodicTick:
            return spellInfo->HasAttribute(SPELL_ATTR5_EXTRA_INITIAL_PERIOD) ? 1 : 0;
        case Field::ForceMoveForward:
            return spellInfo->Effects[change.EffectIndex].ApplyAuraName == SPELL_AURA_FORCE_MOVE_FORWARD ? 1 : 0;
    }

    return 0;
}

bool ValidateChange(SpellInfo const* spellInfo, Change const& change)
{
    if (spellInfo->Id != change.SpellId || spellInfo->SpellFamilyName != change.Family ||
        change.EffectIndex >= MAX_SPELL_EFFECTS)
    {
        return false;
    }

    auto const& effect = spellInfo->Effects[change.EffectIndex];
    bool alreadyRemoved = change.Property == Field::ForceMoveForward &&
        effect.Effect == DisabledSpellEffect && effect.ApplyAuraName == SPELL_AURA_NONE;
    if (!alreadyRemoved && (effect.Effect != change.EffectType || effect.ApplyAuraName != change.AuraType))
    {
        return false;
    }

    if (change.Property == Field::Duration)
    {
        SpellDurationEntry const* duration = sSpellDurationStore.LookupEntry(change.DurationEntry);
        if (!spellInfo->DurationEntry || spellInfo->GetDuration() != spellInfo->GetMaxDuration() ||
            !duration || duration->Duration[0] != change.After || duration->Duration[2] != change.After)
        {
            return false;
        }
    }

    int32 value = ReadChangeValue(spellInfo, change);
    return value == change.Before || value == change.After;
}

void ApplyChange(SpellInfo* spellInfo, Change const& change)
{
    switch (change.Property)
    {
        case Field::BasePoints:
            spellInfo->Effects[change.EffectIndex].BasePoints = change.After;
            break;
        case Field::RecoveryTime:
            spellInfo->RecoveryTime = uint32(change.After);
            spellInfo->_requireCooldownInfo = true;
            break;
        case Field::CategoryRecoveryTime:
            spellInfo->CategoryRecoveryTime = uint32(change.After);
            spellInfo->_requireCooldownInfo = true;
            break;
        case Field::Duration:
            spellInfo->DurationEntry = sSpellDurationStore.LookupEntry(change.DurationEntry);
            break;
        case Field::InitialPeriodicTick:
            spellInfo->AttributesEx5 |= SPELL_ATTR5_EXTRA_INITIAL_PERIOD;
            break;
        case Field::ForceMoveForward:
            spellInfo->Effects[change.EffectIndex].Effect = DisabledSpellEffect;
            spellInfo->Effects[change.EffectIndex].ApplyAuraName = SPELL_AURA_NONE;
            spellInfo->_InitializeExplicitTargetMask();
            break;
    }
}
}

void ApplyAscensionChangelogSpellChanges(SpellInfo* spellInfo)
{
    if (!spellInfo)
    {
        return;
    }

    auto const& changes = AscensionChangelog::Changes;
    auto first = std::lower_bound(changes.begin(), changes.end(), spellInfo->Id,
        [](Change const& change, uint32 id) { return change.SpellId < id; });
    auto last = std::upper_bound(first, changes.end(), spellInfo->Id,
        [](uint32 id, Change const& change) { return id < change.SpellId; });

    for (auto it = first; it != last; ++it)
    {
        if (!ValidateChange(spellInfo, *it))
        {
            LOG_WARN("coa",
                "CoA changelog: skipped spell {} (source {}): unexpected family, effect or old value",
                spellInfo->Id, it->SourceId);
            return;
        }
    }

    for (auto it = first; it != last; ++it)
    {
        if (ReadChangeValue(spellInfo, *it) != it->After)
        {
            ApplyChange(spellInfo, *it);
            LOG_DEBUG("coa", "CoA changelog: updated spell {} from source {}",
                spellInfo->Id, it->SourceId);
        }
    }
}
