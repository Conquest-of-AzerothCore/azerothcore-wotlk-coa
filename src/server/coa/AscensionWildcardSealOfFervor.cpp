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

class aura_wildcard_seal_of_fervor : public AuraScript
{
    PrepareAuraScript(aura_wildcard_seal_of_fervor);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SEAL_OF_FERVOR_DAMAGE});
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
        return spell->SpellFamilyName == SPELLFAMILY_PALADIN && spell->Id != SEAL_OF_FERVOR_DAMAGE;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        float const attackPower = caster->GetTotalAttackPowerValue(BASE_ATTACK);
        int32 const spellPower = caster->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE);
        float const weaponSpeed = caster->GetAttackTime(BASE_ATTACK) / 1000.0f;
        int32 const amount = std::max<int32>(1, int32(1 + weaponSpeed * (0.0085f * attackPower + 0.072f * spellPower)));
        caster->CastCustomSpell(SEAL_OF_FERVOR_DAMAGE, SPELLVALUE_BASE_POINT0, amount, eventInfo.GetProcTarget(), true,
            nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_seal_of_fervor::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_seal_of_fervor::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};
}

void AddSC_AscensionWildcardSealOfFervor()
{
    RegisterSpellScript(aura_wildcard_seal_of_fervor);
}
