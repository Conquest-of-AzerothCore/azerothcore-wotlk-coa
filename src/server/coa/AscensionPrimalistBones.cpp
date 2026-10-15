/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellScript.h"

namespace
{
enum BonesSpells : uint32
{
    BonesMark = 806552,
    BonesDamage = 806553,
    BonesStacks = 806554,
    BonesListener = 806378
};

Player* PetPrimalist(Unit* unit)
{
    Pet* pet = unit ? unit->ToPet() : nullptr;
    Player* owner = pet ? pet->GetOwner() : nullptr;
    return owner && owner->getClass() == CLASS_WILDWALKER && owner->GetPet() == pet ? owner : nullptr;
}

class spell_ascension_bring_their_bones : public SpellScript
{
    PrepareSpellScript(spell_ascension_bring_their_bones);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({BonesStacks, BonesListener}); }
    bool Load() override { return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER; }

    SpellCastResult CheckPet()
    {
        Pet* pet = GetCaster()->ToPlayer()->GetPet();
        return pet && pet->IsAlive() ? SPELL_CAST_OK : SPELL_FAILED_NO_PET;
    }

    void SkipInitialStack(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_bring_their_bones::CheckPet);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_bring_their_bones::SkipInitialStack,
            EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL);
    }
};

class aura_ascension_bones_mark : public AuraScript
{
    PrepareAuraScript(aura_ascension_bones_mark);

    void RemoveStacks(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(BonesStacks, GetCasterGUID());
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_bones_mark::RemoveStacks,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_bones_listener : public AuraScript
{
    PrepareAuraScript(aura_ascension_bones_listener);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({BonesMark, BonesStacks, BonesDamage}); }

    bool CheckProc(ProcEventInfo& event)
    {
        Unit* pet = GetTarget();
        Player* owner = PetPrimalist(pet);
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        SpellInfo const* info = damage ? damage->GetSpellInfo() : nullptr;
        return owner && owner->IsAlive() && pet->IsAlive() && event.GetActor() == pet &&
            GetCasterGUID() == owner->GetGUID() && victim && victim->IsAlive() &&
            damage && damage->GetDamage() && info && info->Id != BonesDamage &&
            victim->HasAura(BonesMark, owner->GetGUID()) && !pet->IsFriendlyTo(victim);
    }

    void Stack(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (!CheckProc(event))
            return;
        Unit* pet = GetTarget();
        Player* owner = PetPrimalist(pet);
        Unit* victim = event.GetActionTarget();
        Aura* mark = victim->GetAura(BonesMark, owner->GetGUID());
        Aura* stacks = owner->AddAura(BonesStacks, victim);
        if (!stacks)
            return;
        stacks->SetDuration(mark->GetDuration());
        if (stacks->GetStackAmount() < 5)
            return;
        stacks->Remove();
        pet->CastSpell(victim, BonesDamage, true, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bones_listener::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_bones_listener::Stack,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_bones_damage : public SpellScript
{
    PrepareSpellScript(spell_ascension_bones_damage);

    bool Load() override { return PetPrimalist(GetCaster()) != nullptr; }

    void PreserveOtherMarks(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_bones_damage::PreserveOtherMarks,
            EFFECT_1, SPELL_EFFECT_REMOVE_AURA);
    }
};

class primalist_bones_metadata : public GlobalScript
{
public:
    primalist_bones_metadata() : GlobalScript("primalist_bones_metadata", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == BonesStacks && info->SpellFamilyName == 37 && info->StackAmount == 5 &&
            info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            info->AttributesEx3 |= SPELL_ATTR3_DOT_STACKING_RULE;

        if (info->Id == BonesDamage && info->SpellFamilyName == 37 &&
            info->GetSchoolMask() == SPELL_SCHOOL_MASK_NORMAL && info->DmgClass == SPELL_DAMAGE_CLASS_MELEE &&
            info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
            info->Effects[EFFECT_1].Effect == SPELL_EFFECT_REMOVE_AURA &&
            info->Effects[EFFECT_1].TriggerSpell == BonesStacks)
            info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
    }
};
}

void AddSC_AscensionPrimalistBones()
{
    RegisterSpellScript(spell_ascension_bring_their_bones);
    RegisterSpellScript(aura_ascension_bones_mark);
    RegisterSpellScript(aura_ascension_bones_listener);
    RegisterSpellScript(spell_ascension_bones_damage);
    new primalist_bones_metadata();
}
