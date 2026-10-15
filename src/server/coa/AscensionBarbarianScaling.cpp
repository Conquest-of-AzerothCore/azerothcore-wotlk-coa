/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBarbarianScaling.h"
#include "Player.h"
#include "Spell.h"
#include "SpellMgr.h"
#include <cmath>
#include <limits>

namespace
{
constexpr uint32 BERSERKER_RUSH_DAMAGE = 560519;
constexpr uint8 BARBARIAN_RUSH_SCALING_EVENT = 17;
constexpr double BERSERKER_RUSH_RAP_COEFFICIENT = 0.35;
}

void PrepareAscensionBarbarianScaling(Spell* spell)
{
    if (!spell || !spell->IsTriggered())
        return;

    SpellInfo const* info = spell->GetSpellInfo();
    if (info->Id != BERSERKER_RUSH_DAMAGE || info->SpellFamilyName != uint32(CLASS_BARBARIAN) + 6)
        return;

    Player* player = spell->GetCaster()->ToPlayer();
    if (!player || player->getClass() != CLASS_BARBARIAN)
        return;

    SpellEffectInfo const& effect = info->Effects[EFFECT_0];
    if (effect.Effect != SPELL_EFFECT_SCHOOL_DAMAGE || effect.DieSides != 1 ||
        effect.RealPointsPerLevel != 0.0f || effect.BonusMultiplier != 0.0f ||
        sSpellMgr->GetSpellBonusData(info->Id))
        return;

    double bonus = player->GetTotalAttackPowerValue(RANGED_ATTACK) * BERSERKER_RUSH_RAP_COEFFICIENT;
    if (!std::isfinite(bonus) || bonus < 0 || bonus > std::numeric_limits<int32>::max())
        return;

    int64 value = int64(spell->GetSpellValue()->EffectBasePoints[EFFECT_0]) + 1 + int32(bonus);
    if (value < std::numeric_limits<int32>::min() || value > std::numeric_limits<int32>::max() ||
        !spell->TryMarkScriptEventHandled(BARBARIAN_RUSH_SCALING_EVENT))
        return;

    spell->SetSpellValue(SPELLVALUE_BASE_POINT0, int32(value));
}
