/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_OTHER_SIDE_DAMAGE_H
#define COA_OTHER_SIDE_DAMAGE_H

#include "Map.h"
#include "Random.h"
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

    inline float Logged(WorldObject const* source, Unit const* target, Damage3 const& damage)
    {
        float const mythic = float(damage.mythic);
        float const heroic = mythic * HeroicShareOfMythic;
        switch (source->GetMap()->GetDifficulty())
        {
            case DUNGEON_DIFFICULTY_EPIC:
                return mythic;
            case DUNGEON_DIFFICULTY_HEROIC:
                return heroic;
            default:
                break;
        }
        float const normal25 = float(damage.normal25);
        float const normal60 = heroic * NormalShareOfHeroic;
        float const level = target ? float(target->GetLevel()) : MaxLevel;
        if (level >= MaxLevel)
            return normal60;
        if (level >= LogNormalLevel)
            return normal25 + (normal60 - normal25) * (level - LogNormalLevel) / (MaxLevel - LogNormalLevel);
        return normal25 * std::max(1.0f, level) / LogNormalLevel;
    }

    inline int32 Rolled(WorldObject const* source, Unit const* target, Damage3 const& damage)
    {
        return std::max(1, int32(Logged(source, target, damage) * frand(0.9f, 1.1f)));
    }
}

#endif
