/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"
#include <algorithm>

namespace
{
enum SealOfEbonVengeanceSpells : uint32
{
    SPELL_EBON_CORRUPTION = 288848,
    SPELL_SEAL_OF_EBON_VENGEANCE_DAMAGE = 288849
};

constexpr uint32 EBON_SEAL_FAMILY_FLAG1 = 0x00000800;

class aura_wildcard_seal_of_ebon_vengeance : public AuraScript
{
    PrepareAuraScript(aura_wildcard_seal_of_ebon_vengeance);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_EBON_CORRUPTION, SPELL_SEAL_OF_EBON_VENGEANCE_DAMAGE});
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetProcTarget();
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!target || !target->IsAlive() || !spell || !damage || !damage->GetDamage())
            return false;
        if (spell->SpellFamilyName != SPELLFAMILY_PALADIN && spell->SpellFamilyName != SPELLFAMILY_DEATHKNIGHT)
            return false;
        return spell->SpellFamilyName != SPELLFAMILY_PALADIN ||
            !(spell->SpellFamilyFlags[1] & EBON_SEAL_FAMILY_FLAG1);
    }

    void HandleSeal(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = eventInfo.GetActor();
        Unit* target = eventInfo.GetProcTarget();
        Aura const* corruption = target->GetAura(SPELL_EBON_CORRUPTION, caster->GetGUID());
        if (!corruption)
            return;
        SpellInfo const* damageSpell = sSpellMgr->GetSpellInfo(SPELL_SEAL_OF_EBON_VENGEANCE_DAMAGE);
        uint8 const maxStacks = std::max<uint8>(1, corruption->GetSpellInfo()->StackAmount);
        int32 const amount = damageSpell->Effects[EFFECT_0].CalcValue() * corruption->GetStackAmount() / maxStacks;
        caster->CastCustomSpell(SPELL_SEAL_OF_EBON_VENGEANCE_DAMAGE, SPELLVALUE_BASE_POINT0, amount, target, true,
            nullptr, aurEff);
    }

    void HandleApplyCorruption(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        eventInfo.GetActor()->CastSpell(eventInfo.GetProcTarget(), SPELL_EBON_CORRUPTION, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_seal_of_ebon_vengeance::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_seal_of_ebon_vengeance::HandleSeal, EFFECT_0, SPELL_AURA_DUMMY);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_seal_of_ebon_vengeance::HandleApplyCorruption, EFFECT_0,
            SPELL_AURA_DUMMY);
    }
};
}

void AddSC_AscensionWildcardSealOfEbonVengeance()
{
    RegisterSpellScript(aura_wildcard_seal_of_ebon_vengeance);
}
