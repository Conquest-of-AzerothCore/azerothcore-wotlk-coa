/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <cmath>
#include <limits>

namespace
{
class spell_ascension_ranger_skullpiercer : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_skullpiercer);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo && (spellInfo->Id == 802036 || (spellInfo->Id >= 501715 && spellInfo->Id <= 501723)) &&
            spellInfo->SpellFamilyName == uint32(CLASS_RANGER) + 6 &&
            spellInfo->SpellFamilyFlags == flag96(0, 134217728, 0) &&
            spellInfo->DmgClass == SPELL_DAMAGE_CLASS_RANGED &&
            spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
            spellInfo->Effects[EFFECT_0].BonusMultiplier == 0.0f &&
            !spellInfo->Effects[EFFECT_1].Effect && !spellInfo->Effects[EFFECT_2].Effect &&
            !sSpellMgr->GetSpellBonusData(spellInfo->Id);
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->ToPlayer()->getClass() == CLASS_RANGER;
    }

    void ScaleDamage(SpellEffIndex)
    {
        Unit* target = GetHitUnit();
        Unit* caster = GetCaster();
        if (!target || !caster)
            return;

        double melee = caster->GetTotalAttackPowerValue(BASE_ATTACK);
        melee += target->GetTotalAuraModifier(SPELL_AURA_MELEE_ATTACK_POWER_ATTACKER_BONUS);
        double ranged = caster->GetTotalAttackPowerValue(RANGED_ATTACK);
        ranged += target->GetTotalAuraModifier(SPELL_AURA_RANGED_ATTACK_POWER_ATTACKER_BONUS);
        double bonus = 0.25 * ranged + 0.10 * melee;
        float const multiplier = caster->GetSpellAttackPowerCoefficientMultiplier(GetSpellInfo(), false);
        if (multiplier != 1.0f)
            bonus = float(bonus) * multiplier;
        if (!std::isfinite(bonus) || bonus < std::numeric_limits<int32>::min() || bonus > std::numeric_limits<int32>::max())
            return;

        int64 amount = int64(GetEffectValue()) + int32(bonus);
        SetEffectValue(int32(std::clamp<int64>(amount, 0, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_ranger_skullpiercer::ScaleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class spell_ascension_ranger_nerve_venom : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_nerve_venom);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo && spellInfo->Id == 570244 &&
            spellInfo->SpellFamilyName == uint32(CLASS_RANGER) + 6 &&
            spellInfo->DmgClass == SPELL_DAMAGE_CLASS_RANGED &&
            spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
            spellInfo->Effects[EFFECT_0].BonusMultiplier == 0.0f &&
            !sSpellMgr->GetSpellBonusData(spellInfo->Id);
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->ToPlayer()->getClass() == CLASS_RANGER;
    }

    void ScaleDamage(SpellEffIndex)
    {
        Unit* target = GetHitUnit();
        Unit* caster = GetCaster();
        if (!target || !caster)
            return;

        double melee = caster->GetTotalAttackPowerValue(BASE_ATTACK);
        melee += target->GetTotalAuraModifier(SPELL_AURA_MELEE_ATTACK_POWER_ATTACKER_BONUS);
        double bonus = 0.05 * melee;
        float const multiplier = caster->GetSpellAttackPowerCoefficientMultiplier(GetSpellInfo(), false);
        if (multiplier != 1.0f)
            bonus = float(bonus) * multiplier;
        if (!std::isfinite(bonus) || bonus < std::numeric_limits<int32>::min() || bonus > std::numeric_limits<int32>::max())
            return;

        int64 amount = int64(GetEffectValue()) + int32(bonus);
        SetEffectValue(int32(std::clamp<int64>(amount, 0, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_ranger_nerve_venom::ScaleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class spell_ascension_ranger_burning_toxin : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_burning_toxin);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo && spellInfo->Id == 570245 &&
            spellInfo->SpellFamilyName == uint32(CLASS_RANGER) + 6 &&
            spellInfo->DmgClass == SPELL_DAMAGE_CLASS_RANGED &&
            spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
            spellInfo->Effects[EFFECT_0].BonusMultiplier == 0.0f &&
            !sSpellMgr->GetSpellBonusData(spellInfo->Id);
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->ToPlayer()->getClass() == CLASS_RANGER;
    }

    void ScaleDamage(SpellEffIndex)
    {
        Unit* target = GetHitUnit();
        Unit* caster = GetCaster();
        if (!target || !caster)
            return;

        double melee = caster->GetTotalAttackPowerValue(BASE_ATTACK);
        melee += target->GetTotalAuraModifier(SPELL_AURA_MELEE_ATTACK_POWER_ATTACKER_BONUS);
        double bonus = 0.10 * melee;
        float const multiplier = caster->GetSpellAttackPowerCoefficientMultiplier(GetSpellInfo(), false);
        if (multiplier != 1.0f)
            bonus = float(bonus) * multiplier;
        if (!std::isfinite(bonus) || bonus < std::numeric_limits<int32>::min() || bonus > std::numeric_limits<int32>::max())
            return;

        int64 amount = int64(GetEffectValue()) + int32(bonus);
        SetEffectValue(int32(std::clamp<int64>(amount, 0, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_ranger_burning_toxin::ScaleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};
}

void AddAscensionRangerScalingScripts()
{
    RegisterSpellScript(spell_ascension_ranger_skullpiercer);
    RegisterSpellScript(spell_ascension_ranger_nerve_venom);
    RegisterSpellScript(spell_ascension_ranger_burning_toxin);
}
