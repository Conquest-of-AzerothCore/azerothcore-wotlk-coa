/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"
#include <algorithm>

namespace
{
constexpr uint32 SEAL_OF_FERVOR_DAMAGE = 272085;
constexpr uint32 SEAL_OF_ARCANE_WRATH_DAMAGE = 277856;
constexpr uint32 JUDGEMENT_OF_ARCANE_WRATH = 277857;
constexpr uint32 SEAL_JUDGEMENT_UNCHANGED = 0;

class aura_wildcard_righteousness_seal : public AuraScript
{
    PrepareAuraScript(aura_wildcard_righteousness_seal);

public:
    aura_wildcard_righteousness_seal(uint32 damageSpell, SpellSchoolMask school, uint32 judgementSpell) :
        _damageSpell(damageSpell), _school(school), _judgementSpell(judgementSpell) { }

private:
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({_damageSpell}) &&
            (_judgementSpell == SEAL_JUDGEMENT_UNCHANGED || ValidateSpellInfo({_judgementSpell}));
    }

    void CalcJudgement(AuraEffect const*, int32& amount, bool&)
    {
        if (_judgementSpell != SEAL_JUDGEMENT_UNCHANGED)
            amount = int32(_judgementSpell);
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetProcTarget();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!target || !target->IsAlive() || !damage || !damage->GetDamage() || eventInfo.GetTriggerAuraSpell())
            return false;

        SpellInfo const* spell = eventInfo.GetSpellInfo();
        if (!spell)
            return damage->GetAttackType() == BASE_ATTACK;
        return spell->SpellFamilyName == SPELLFAMILY_PALADIN && spell->Id != _damageSpell;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        float const attackPower = caster->GetTotalAttackPowerValue(BASE_ATTACK);
        int32 const spellPower = caster->SpellBaseDamageBonusDone(_school);
        float const weaponSpeed = caster->GetAttackTime(BASE_ATTACK) / 1000.0f;
        int32 const amount = std::max<int32>(1, int32(1 + weaponSpeed * (0.0085f * attackPower + 0.072f * spellPower)));
        caster->CastCustomSpell(_damageSpell, SPELLVALUE_BASE_POINT0, amount, eventInfo.GetProcTarget(), true,
            nullptr, aurEff);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_wildcard_righteousness_seal::CalcJudgement, EFFECT_2,
            SPELL_AURA_DUMMY);
        DoCheckProc += AuraCheckProcFn(aura_wildcard_righteousness_seal::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_righteousness_seal::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }

    uint32 _damageSpell;
    SpellSchoolMask _school;
    uint32 _judgementSpell;
};
}

void AddSC_AscensionWildcardSealOfFervor()
{
    RegisterSpellScriptWithArgs(aura_wildcard_righteousness_seal, "aura_wildcard_seal_of_fervor",
        SEAL_OF_FERVOR_DAMAGE, SPELL_SCHOOL_MASK_FIRE, SEAL_JUDGEMENT_UNCHANGED);
    RegisterSpellScriptWithArgs(aura_wildcard_righteousness_seal, "aura_wildcard_seal_of_arcane_wrath",
        SEAL_OF_ARCANE_WRATH_DAMAGE, SPELL_SCHOOL_MASK_ARCANE, JUDGEMENT_OF_ARCANE_WRATH);
}
