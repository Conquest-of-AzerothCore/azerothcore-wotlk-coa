/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionVenomancerCatalyst.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
constexpr uint32 VENOMANCER_FAMILY = uint32(CLASS_PROPHET) + 6;
constexpr uint32 SPELL_CATALYST = 800895;
constexpr uint32 SPELL_CATALYST_IMMEDIATE_RAGE = 803640;
constexpr uint32 SPELL_BEETLE_FORM = 803183;

bool IsCatalystEnergizePayload(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->Id != SPELL_CATALYST_IMMEDIATE_RAGE ||
        spellInfo->SpellFamilyName != VENOMANCER_FAMILY)
        return false;

    SpellEffectInfo const& effect = spellInfo->Effects[EFFECT_0];
    return effect.BasePoints == 149 && effect.DieSides == 1 && effect.MiscValue == POWER_RAGE &&
        effect.TargetA.GetTarget() == TARGET_UNIT_CASTER && effect.TargetB.GetTarget() == 0 &&
        !spellInfo->Effects[EFFECT_1].Effect && !spellInfo->Effects[EFFECT_2].Effect;
}

class spell_ascension_venomancer_catalyst : public SpellScript
{
    PrepareSpellScript(spell_ascension_venomancer_catalyst);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellInfo const* helper = sSpellMgr->GetSpellInfo(SPELL_CATALYST_IMMEDIATE_RAGE);
        return spellInfo && spellInfo->Id == SPELL_CATALYST &&
            spellInfo->SpellFamilyName == VENOMANCER_FAMILY && spellInfo->CasterAuraSpell == SPELL_BEETLE_FORM &&
            spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_PERIODIC_ENERGIZE) &&
            spellInfo->Effects[EFFECT_0].MiscValue == POWER_RAGE &&
            IsCatalystEnergizePayload(helper) && helper->Effects[EFFECT_0].Effect == SPELL_EFFECT_ENERGIZE;
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->getClass() == CLASS_PROPHET && !GetSpell()->IsTriggered();
    }

    void GrantImmediateRage()
    {
        Unit* caster = GetCaster();
        if (caster->HasAura(SPELL_BEETLE_FORM))
            caster->CastSpell(caster, SPELL_CATALYST_IMMEDIATE_RAGE, true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_venomancer_catalyst::GrantImmediateRage);
    }
};
}

void ApplyAscensionVenomancerCatalystContract(SpellInfo* spellInfo)
{
    if (!IsCatalystEnergizePayload(spellInfo))
        return;

    SpellEffectInfo& effect = spellInfo->Effects[EFFECT_0];
    if (effect.Effect == SPELL_EFFECT_ENERGIZE_PCT || effect.Effect == SPELL_EFFECT_ENERGIZE)
        effect.Effect = SPELL_EFFECT_ENERGIZE;
}

void AddSC_AscensionVenomancerCatalyst()
{
    RegisterSpellScript(spell_ascension_venomancer_catalyst);
}
