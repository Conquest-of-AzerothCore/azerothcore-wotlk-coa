/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchHunterStake.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
bool IsStakeInfo(SpellInfo const* spellInfo)
{
    if (!spellInfo || (spellInfo->Id != 680537 && (spellInfo->Id < 681347 || spellInfo->Id > 681352)))
        return false;

    SpellEffectInfo const& effect = spellInfo->Effects[EFFECT_0];
    SpellEffectInfo const& legacy = spellInfo->Effects[EFFECT_1];
    bool expectedLegacy = !legacy.Effect || (spellInfo->Id != 680537 &&
        legacy.Effect == SPELL_EFFECT_TRIGGER_SPELL && legacy.TriggerSpell == 680548 &&
        legacy.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY && !legacy.TargetB.GetTarget());
    return spellInfo->SpellFamilyName == uint32(CLASS_WITCH_HUNTER) + 6 &&
        spellInfo->SpellFamilyFlags == flag96(0, 0, 1024) && spellInfo->SchoolMask == SPELL_SCHOOL_MASK_NORMAL &&
        spellInfo->DmgClass == SPELL_DAMAGE_CLASS_MELEE && effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
        effect.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY && !effect.TargetB.GetTarget() &&
        expectedLegacy && !spellInfo->Effects[EFFECT_2].Effect;
}

class spell_ascension_witch_hunter_stake : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_stake);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsStakeInfo(spellInfo) && !spellInfo->TargetAuraState && !spellInfo->Effects[EFFECT_1].Effect;
    }

    SpellCastResult CheckHealth()
    {
        Unit* caster = GetCaster();
        Unit* target = GetExplTargetUnit();
        if (!caster || !target)
            return SPELL_FAILED_BAD_TARGETS;

        if (uint64(target->GetHealth()) * 100 <= uint64(target->GetMaxHealth()) * 35)
            return SPELL_CAST_OK;

        for (AuraEffect const* effect : caster->GetAuraEffectsByType(SPELL_AURA_ABILITY_IGNORE_AURASTATE))
            if (effect->IsAffectedOnSpell(GetSpellInfo()))
                return SPELL_CAST_OK;

        return SPELL_FAILED_TARGET_AURASTATE;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_witch_hunter_stake::CheckHealth);
    }
};
}

void ApplyAscensionWitchHunterStakeContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    if (IsStakeInfo(spellInfo) && spellInfo->TargetAuraState == AURA_STATE_HEALTHLESS_35_PERCENT)
    {
        spellInfo->TargetAuraState = 0;
        spellInfo->Effects[EFFECT_1].Effect = 0;
    }

    if (spellInfo->Id == 680540 && spellInfo->SpellFamilyName == uint32(CLASS_WITCH_HUNTER) + 6 &&
        !spellInfo->SpellFamilyFlags && spellInfo->HasAttribute(SPELL_ATTR0_PASSIVE) &&
        spellInfo->TargetAuraState == AURA_STATE_HEALTHLESS_20_PERCENT &&
        spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_PROC_TRIGGER_SPELL) &&
        spellInfo->Effects[EFFECT_0].TriggerSpell == 681295 &&
        spellInfo->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_CASTER &&
        !spellInfo->Effects[EFFECT_0].TargetB.GetTarget() && !spellInfo->Effects[EFFECT_1].Effect &&
        !spellInfo->Effects[EFFECT_2].Effect)
    {
        spellInfo->TargetAuraState = 0;
    }
}

void AddAscensionWitchHunterStakeScripts()
{
    RegisterSpellScript(spell_ascension_witch_hunter_stake);
}
