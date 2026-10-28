/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_OTHER_SIDE_DAMAGE_H
#define COA_OTHER_SIDE_DAMAGE_H

#include "CoACreatureScaling.h"
#include "DBCStores.h"
#include "Map.h"
#include "Random.h"
#include "SpellMgr.h"
#include "Unit.h"
#include <algorithm>

namespace CoAOtherSide
{
    struct Damage3
    {
        uint32 normal25, mythic;
    };

    constexpr float HeroicShareOfMythic = 1.0f / 1.3f;
    constexpr float NormalShareOfHeroic = 0.85f / 1.66f;
    constexpr float LogNormalLevel = 25.0f;
    constexpr float MaxLevel = 60.0f;

    inline float Unscaled(Unit const* attacker, Unit const* target, float value, SpellInfo const* spell)
    {
        float const multiplier = CreatureScaling::SpellDamageMultiplier(target, attacker, spell);
        return multiplier > 0.0f ? value / multiplier : value;
    }

    inline float Logged(Unit const* attacker, Unit const* target, Damage3 const& damage, SpellInfo const* spell)
    {
        float const mythic = float(damage.mythic);
        float const heroic = mythic * HeroicShareOfMythic;
        switch (attacker->GetMap()->GetDifficulty())
        {
            case DUNGEON_DIFFICULTY_EPIC:
                return mythic;
            case DUNGEON_DIFFICULTY_HEROIC:
                return heroic;
            default:
                break;
        }
        float const normal25 = float(damage.normal25);
        float const normal60 = std::max(normal25, heroic * NormalShareOfHeroic);
        float const level = target ? float(target->GetLevel()) : MaxLevel;
        float normal = normal60;
        if (level < LogNormalLevel)
            normal = normal25 * std::max(1.0f, level) / LogNormalLevel;
        else if (level < MaxLevel)
            normal = normal25 + (normal60 - normal25) * (level - LogNormalLevel) / (MaxLevel - LogNormalLevel);
        return Unscaled(attacker, target, normal, spell);
    }

    inline int32 Rolled(Unit const* attacker, Unit const* target, Damage3 const& damage, SpellInfo const* spell)
    {
        return std::max(1, int32(Logged(attacker, target, damage, spell) * frand(0.9f, 1.1f)));
    }

    inline uint32 BaseSpellId(uint32 spellId)
    {
        if (SpellDifficultyEntry const* entry = sSpellDifficultyStore.LookupEntry(sSpellMgr->GetSpellDifficultyId(spellId)))
            if (entry->SpellID[0] > 0)
                return uint32(entry->SpellID[0]);
        return spellId;
    }
}

#endif
