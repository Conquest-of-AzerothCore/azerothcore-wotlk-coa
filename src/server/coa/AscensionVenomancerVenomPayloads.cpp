/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionVenomancerVenomPayloads.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraDefines.h"
#include "SpellInfo.h"

#include <cmath>
#include <limits>

namespace
{
bool IsFamily(SpellInfo const* info, uint32 id, uint32 flags2)
{
    return info && info->Id == id && info->SpellFamilyName == uint32(CLASS_PROPHET) + 6 &&
        info->SpellFamilyFlags == flag96(0, 32768, flags2);
}

bool IsPeriodicBase(SpellInfo const* info)
{
    if (!info || info->Effects[EFFECT_1].Effect || info->Effects[EFFECT_2].Effect ||
        info->GetDuration() != 6000 || info->MaxLevel || info->StackAmount != 1)
        return false;

    SpellEffectInfo const& effect = info->Effects[EFFECT_0];
    if (effect.Effect != SPELL_EFFECT_APPLY_AURA || effect.RealPointsPerLevel || effect.BonusMultiplier ||
        effect.TriggerSpell || effect.SpellClassMask || effect.MiscValue || effect.MiscValueB ||
        effect.TargetB.GetTarget())
        return false;

    if (IsFamily(info, 630869, 524288))
        return effect.ApplyAuraName == SPELL_AURA_PERIODIC_HEAL && effect.BasePoints == 66 &&
            effect.DieSides == 6 && effect.Amplitude == 2000 &&
            effect.TargetA.GetTarget() == TARGET_UNIT_DEST_AREA_ALLY && info->MaxAffectedTargets == 1;

    return IsFamily(info, 805896, 256) && effect.ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE &&
        effect.BasePoints == 136 && effect.DieSides == 4 && effect.Amplitude == 1000 &&
        effect.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY && !info->MaxAffectedTargets;
}

void NormalizeAdrenal(SpellInfo* info)
{
    if (!IsFamily(info, 805894, 64) || info->GetDuration() != 6000 || info->StackAmount != 3 ||
        info->Effects[EFFECT_2].Effect)
        return;

    SpellEffectInfo const& attack = info->Effects[EFFECT_0];
    SpellEffectInfo& casting = info->Effects[EFFECT_1];
    if (attack.Effect == SPELL_EFFECT_APPLY_AURA && attack.ApplyAuraName == SPELL_AURA_MOD_MELEE_RANGED_HASTE &&
        attack.BasePoints == 5 && attack.DieSides == 1 && !attack.RealPointsPerLevel && !attack.MiscValue &&
        !attack.MiscValueB && !attack.SpellClassMask && !attack.TriggerSpell && !attack.Amplitude &&
        attack.TargetA.GetTarget() == TARGET_UNIT_CASTER && !attack.TargetB.GetTarget() &&
        casting.Effect == SPELL_EFFECT_APPLY_AURA && casting.ApplyAuraName == SPELL_AURA_HASTE_SPELLS &&
        casting.BasePoints == 2 && casting.DieSides == 1 && !casting.RealPointsPerLevel && !casting.MiscValue &&
        !casting.MiscValueB && !casting.SpellClassMask && !casting.TriggerSpell && !casting.Amplitude &&
        casting.TargetA.GetTarget() == TARGET_UNIT_CASTER && !casting.TargetB.GetTarget())
        casting.BasePoints = 5;
}

class AscensionVenomancerVenomPayloadMetadata : public GlobalScript
{
public:
    AscensionVenomancerVenomPayloadMetadata()
        : GlobalScript("AscensionVenomancerVenomPayloadMetadata", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        NormalizeAdrenal(info);
    }
};

class AscensionVenomancerVenomBaseValues : public UnitScript
{
public:
    AscensionVenomancerVenomBaseValues()
        : UnitScript("AscensionVenomancerVenomBaseValues", true, {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player const* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_PROPHET || index != EFFECT_0 || !IsPeriodicBase(info) ||
            !std::isfinite(value))
            return;

        double const level = player->GetLevel();
        double const curve = 0.0267291844060354 + 0.0048541098014737 * level +
            0.0001859597762293 * level * level;
        double const adjusted = double(value) * curve / (info->Id == 630869 ? 3.0 : 1.0);
        if (!std::isfinite(adjusted))
            return;

        float const result = float(adjusted);
        if (std::isfinite(result) && double(result) >= std::numeric_limits<int32>::min() &&
            double(result) <= std::numeric_limits<int32>::max())
            value = result;
    }
};
}

void AddAscensionVenomancerVenomPayloadScripts()
{
    new AscensionVenomancerVenomPayloadMetadata();
    new AscensionVenomancerVenomBaseValues();
}
