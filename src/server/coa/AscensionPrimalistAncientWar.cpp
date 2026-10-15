/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace
{
enum AncientWarSpells : uint32
{
    AncientOfWar = 504222,
    AncientMovement = 504369
};

class primalist_ancient_war_metadata : public GlobalScript
{
public:
    primalist_ancient_war_metadata() : GlobalScript("primalist_ancient_war_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == AncientOfWar && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_1].IsAura(SPELL_AURA_ADD_FLAT_MODIFIER))
            info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
    }
};

class aura_ascension_ancient_war : public AuraScript
{
    PrepareAuraScript(aura_ascension_ancient_war);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({AncientMovement}); }

    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (GetTarget() == GetCaster())
            GetTarget()->CastSpell(GetTarget(), AncientMovement, TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(AncientMovement, GetCasterGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_ancient_war::Apply,
            EFFECT_2, SPELL_AURA_TRANSFORM, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_ancient_war::Remove,
            EFFECT_2, SPELL_AURA_TRANSFORM, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionPrimalistAncientWar()
{
    new primalist_ancient_war_metadata();
    RegisterSpellScript(aura_ascension_ancient_war);
}
