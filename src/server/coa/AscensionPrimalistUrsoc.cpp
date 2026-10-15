/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellScript.h"

namespace
{
enum UrsocSpells : uint32
{
    SavageFrenzy = 806549,
    SonOfUrsoc = 706176,
    UrsocForm = 806048
};

class aura_ascension_son_of_ursoc : public AuraScript
{
    PrepareAuraScript(aura_ascension_son_of_ursoc);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SavageFrenzy && ValidateSpellInfo({SonOfUrsoc, UrsocForm});
    }

    bool Load() override
    {
        Unit* owner = GetUnitOwner();
        return owner->IsPlayer() && owner->getClass() == CLASS_WILDWALKER &&
            GetCasterGUID() == owner->GetGUID();
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* owner = GetTarget();
        if (owner->HasAura(SonOfUrsoc) && owner->IsInWorld())
        {
            owner->RemoveMovementImpairingAuras(true);
            owner->CastSpell(owner, UrsocForm, true);
        }
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(UrsocForm, GetCasterGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_son_of_ursoc::Apply,
            EFFECT_0, SPELL_AURA_MOD_DAMAGE_PERCENT_DONE, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_son_of_ursoc::Remove,
            EFFECT_0, SPELL_AURA_MOD_DAMAGE_PERCENT_DONE, AURA_EFFECT_HANDLE_REAL);
    }
};

class primalist_ursoc_metadata : public GlobalScript
{
public:
    primalist_ursoc_metadata() : GlobalScript("primalist_ursoc_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == UrsocForm)
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
    }
};
}

void AddSC_AscensionPrimalistUrsoc()
{
    new primalist_ursoc_metadata();
    RegisterSpellScript(aura_ascension_son_of_ursoc);
}
