/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace
{
enum QuakingThaneSpells : uint32
{
    QuakingThane = 561193,
    ThanesRage = 804124,
    QuakeFirst = 803974,
    MountainHammerFirst = 681130
};

class spell_ascension_quaking_thane : public SpellScript
{
    PrepareSpellScript(spell_ascension_quaking_thane);
    uint32 _victims = 0;

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({QuakingThane, ThanesRage}); }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER;
    }

    void Grant()
    {
        Unit* owner = GetCaster();
        if (owner->IsAlive() && owner->HasAura(QuakingThane, owner->GetGUID()))
            owner->CastSpell(owner, ThanesRage, TRIGGERED_FULL_MASK);
    }

    void Hit()
    {
        Unit* victim = GetHitUnit();
        if (GetSpellInfo()->GetFirstRankSpell()->Id == QuakeFirst && victim && victim != GetCaster() &&
            !GetCaster()->IsFriendlyTo(victim) && GetHitDamage() > 0 && ++_victims == 5)
            Grant();
    }

    void Cast()
    {
        if (GetSpellInfo()->GetFirstRankSpell()->Id == MountainHammerFirst)
            Grant();
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_ascension_quaking_thane::Hit);
        AfterCast += SpellCastFn(spell_ascension_quaking_thane::Cast);
    }
};

class primalist_thanes_rage_metadata : public GlobalScript
{
public:
    primalist_thanes_rage_metadata() : GlobalScript("primalist_thanes_rage_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == ThanesRage && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE) &&
            info->Effects[EFFECT_0].MiscValue == STAT_STAMINA)
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_STAT;
    }
};

class aura_ascension_thanes_rage : public AuraScript
{
    PrepareAuraScript(aura_ascension_thanes_rage);

    bool Load() override
    {
        return GetUnitOwner()->IsPlayer() && GetUnitOwner()->getClass() == CLASS_WILDWALKER &&
            GetCasterGUID() == GetUnitOwner()->GetGUID();
    }

    void Calculate(AuraEffect const*, int32& amount, bool& recalculate)
    {
        recalculate = true;
        amount = int32(GetUnitOwner()->GetStat(STAT_STRENGTH) * 0.1f);
    }

    void Period(AuraEffect const*, bool& periodic, int32& interval)
    {
        periodic = true;
        interval = 1000;
    }

    void Update(AuraEffect const*)
    {
        PreventDefaultAction();
        GetAura()->GetEffect(EFFECT_0)->RecalculateAmount();
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_thanes_rage::Calculate,
            EFFECT_0, SPELL_AURA_MOD_STAT);
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_ascension_thanes_rage::Period,
            EFFECT_0, SPELL_AURA_MOD_STAT);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_thanes_rage::Update,
            EFFECT_0, SPELL_AURA_MOD_STAT);
    }
};
}

void AddSC_AscensionPrimalistQuakingThane()
{
    RegisterSpellScript(spell_ascension_quaking_thane);
    RegisterSpellScript(aura_ascension_thanes_rage);
    new primalist_thanes_rage_metadata();
}
