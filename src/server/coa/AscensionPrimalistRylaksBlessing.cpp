/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"

namespace
{
constexpr uint32 RylaksBlessingBuff = 802596;

class aura_ascension_rylaks_blessing : public AuraScript
{
    PrepareAuraScript(aura_ascension_rylaks_blessing);

    bool Load() override
    {
        return GetUnitOwner()->IsPlayer() && GetUnitOwner()->getClass() == CLASS_WILDWALKER &&
            GetCasterGUID() == GetUnitOwner()->GetGUID();
    }

    bool Check(ProcEventInfo& event)
    {
        Player* owner = GetTarget()->ToPlayer();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        Pet* pet = owner->GetPet();
        return owner->IsAlive() && pet && pet->IsAlive() && event.GetActor() == owner &&
            victim && victim != owner && !owner->IsFriendlyTo(victim) && damage && damage->GetDamage();
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(RylaksBlessingBuff, GetCasterGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_rylaks_blessing::Check);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_rylaks_blessing::Remove,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_rylaks_blessing_pet : public AuraScript
{
    PrepareAuraScript(aura_ascension_rylaks_blessing_pet);

    bool Check(Unit* target)
    {
        Player* owner = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        return owner && owner->getClass() == CLASS_WILDWALKER && target == owner->GetPet();
    }

    void Register() override
    {
        DoCheckAreaTarget += AuraCheckAreaTargetFn(aura_ascension_rylaks_blessing_pet::Check);
    }
};
}

void AddSC_AscensionPrimalistRylaksBlessing()
{
    RegisterSpellScript(aura_ascension_rylaks_blessing);
    RegisterSpellScript(aura_ascension_rylaks_blessing_pet);
}
