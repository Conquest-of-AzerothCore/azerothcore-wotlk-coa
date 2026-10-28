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
class aura_wildcard_consecrated_weapon : public AuraScript
{
    PrepareAuraScript(aura_wildcard_consecrated_weapon);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetProcTarget();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!target || !target->IsAlive() || !damage || !damage->GetDamage() || eventInfo.GetTriggerAuraSpell())
            return false;

        SpellInfo const* spell = eventInfo.GetSpellInfo();
        if (!spell)
            return damage->GetAttackType() == BASE_ATTACK;
        return spell->SpellFamilyName == SPELLFAMILY_PALADIN;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetProcTarget();
        if (!target)
            return;

        float const weaponSpeed = caster->GetAttackTime(BASE_ATTACK) / 1000.0f;
        int32 const amount = std::max<int32>(1, int32(aurEff->GetAmount() * weaponSpeed / 100.0f));

        SpellInfo const* spellInfo = aurEff->GetSpellInfo();
        SpellNonMeleeDamage damage(caster, target, spellInfo, SPELL_SCHOOL_MASK_HOLY);
        caster->CalculateSpellDamageTaken(&damage, amount, spellInfo);
        Unit::DealDamageMods(target, damage.damage, &damage.absorb);
        caster->SendSpellNonMeleeDamageLog(&damage);
        caster->DealSpellDamage(&damage, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_consecrated_weapon::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_consecrated_weapon::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};
}

void AddSC_AscensionWildcardConsecratedWeapon()
{
    RegisterSpellScript(aura_wildcard_consecrated_weapon);
}
