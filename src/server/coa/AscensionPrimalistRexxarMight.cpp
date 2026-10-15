/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"

#include <algorithm>
#include <limits>

namespace
{
enum RexxarMightSpells : uint32
{
    RexxarMight = 806559,
    RexxarReady = 806561,
    RexxarBleed = 806562
};

class aura_ascension_rexxar_might : public AuraScript
{
    PrepareAuraScript(aura_ascension_rexxar_might);

    bool Load() override
    {
        return GetUnitOwner()->IsPlayer() && GetUnitOwner()->getClass() == CLASS_WILDWALKER;
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Pet* pet = GetTarget()->ToPlayer()->GetPet())
            pet->RemoveAurasDueToSpell(RexxarReady, GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_rexxar_might::Remove,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_rexxar_ready : public AuraScript
{
    PrepareAuraScript(aura_ascension_rexxar_ready);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({RexxarBleed});
    }

    bool Check(ProcEventInfo& event)
    {
        Pet* pet = GetTarget()->ToPet();
        Player* owner = pet ? pet->GetOwner() : nullptr;
        DamageInfo const* damage = event.GetDamageInfo();
        Unit* victim = event.GetActionTarget();
        return owner && owner->getClass() == CLASS_WILDWALKER && owner->HasAura(RexxarMight) &&
            GetCasterGUID() == owner->GetGUID() && event.GetActor() == pet && victim &&
            !pet->IsFriendlyTo(victim) && damage && damage->GetDamage();
    }

    void ApplyBleed(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(event.GetActionTarget(), RexxarBleed, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_rexxar_ready::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_rexxar_ready::ApplyBleed,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class primalist_rexxar_bleed : public UnitScript
{
public:
    primalist_rexxar_bleed() : UnitScript("primalist_rexxar_bleed",
        true, {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index,
        float& value) override
    {
        if (!caster || !caster->IsPet() || info->Id != RexxarBleed || index != EFFECT_0 ||
            info->Effects[EFFECT_0].ApplyAuraName != SPELL_AURA_PERIODIC_DAMAGE)
            return;
        Player const* owner = static_cast<Pet const*>(caster)->GetOwner();
        if (!owner || owner->getClass() != CLASS_WILDWALKER)
            return;

        double amount = double(value) + 0.15 * std::max(0.0f, owner->GetTotalAttackPowerValue(BASE_ATTACK));
        value = float(std::clamp(amount, 0.0, double(std::numeric_limits<int32>::max()) - 128.0));
    }
};

class primalist_rexxar_metadata : public GlobalScript
{
public:
    primalist_rexxar_metadata() : GlobalScript("primalist_rexxar_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == RexxarReady)
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
    }
};
}

void AddSC_AscensionPrimalistRexxarMight()
{
    new primalist_rexxar_bleed();
    new primalist_rexxar_metadata();
    RegisterSpellScript(aura_ascension_rexxar_might);
    RegisterSpellScript(aura_ascension_rexxar_ready);
}
