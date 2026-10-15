/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"

namespace
{
constexpr uint32 SPELL_HACKING_THE_ENEMY = 705796;
constexpr uint32 SPELL_PIERCING_PASSIVE = 653235;

bool IsHackingEffect(SpellInfo const* spellInfo, uint8 index)
{
    if (!spellInfo || spellInfo->Id != SPELL_HACKING_THE_ENEMY ||
        spellInfo->SpellFamilyName != uint32(CLASS_TINKER) + 6 || index > EFFECT_1)
        return false;

    SpellEffectInfo const& effect = spellInfo->Effects[index];
    return effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
        effect.MiscValue == (index == EFFECT_0 ? SPELLMOD_EFFECT1 : SPELLMOD_EFFECT2) &&
        effect.BasePoints == (index == EFFECT_0 ? 9 : -11) && effect.DieSides == 1 &&
        !effect.RealPointsPerLevel && effect.SpellClassMask == flag96(1, 0, 0);
}

class aura_ascension_tinker_hacking : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_hacking);

    bool Validate(SpellInfo const* spellInfo) override
    {
        if (!IsHackingEffect(spellInfo, EFFECT_0) || !IsHackingEffect(spellInfo, EFFECT_1) ||
            spellInfo->Effects[EFFECT_2].Effect)
            return false;

        SpellInfo const* piercing = sSpellMgr->GetSpellInfo(SPELL_PIERCING_PASSIVE);
        return piercing && piercing->SpellFamilyName == uint32(CLASS_TINKER) + 6 &&
            piercing->SpellFamilyFlags == flag96(1, 0, 0) &&
            piercing->Effects[EFFECT_0].Effect == SPELL_EFFECT_APPLY_AURA &&
            piercing->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_MOD_ARMOR_PENETRATION_PCT &&
            piercing->Effects[EFFECT_1].Effect == SPELL_EFFECT_APPLY_AURA &&
            piercing->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_MOD_TARGET_RESISTANCE &&
            piercing->Effects[EFFECT_1].MiscValue == 126;
    }

    void RestrictTarget(AuraEffect const* effect, SpellModifier*& modifier)
    {
        Player* player = GetUnitOwner() ? GetUnitOwner()->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_TINKER || !effect || !modifier ||
            !IsHackingEffect(effect->GetSpellInfo(), effect->GetEffIndex()) ||
            modifier->ownerAura != GetAura() || modifier->spellId != SPELL_HACKING_THE_ENEMY ||
            modifier->type != SPELLMOD_FLAT || modifier->op != SpellModOp(effect->GetMiscValue()) ||
            modifier->mask != flag96(1, 0, 0) ||
            (modifier->targetSpellId && modifier->targetSpellId != SPELL_PIERCING_PASSIVE))
            return;

        modifier->targetSpellId = SPELL_PIERCING_PASSIVE;
    }

    void Register() override
    {
        DoEffectCalcSpellMod += AuraEffectCalcSpellModFn(aura_ascension_tinker_hacking::RestrictTarget,
            EFFECT_0, SPELL_AURA_ADD_FLAT_MODIFIER);
        DoEffectCalcSpellMod += AuraEffectCalcSpellModFn(aura_ascension_tinker_hacking::RestrictTarget,
            EFFECT_1, SPELL_AURA_ADD_FLAT_MODIFIER);
    }
};
}

void AddAscensionTinkerHackingScripts()
{
    RegisterSpellScript(aura_ascension_tinker_hacking);
}
