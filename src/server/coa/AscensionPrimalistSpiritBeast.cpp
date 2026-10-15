/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionPrimalistSpiritBeast.h"
#include "Creature.h"
#include "PetDefines.h"
#include "Player.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include <algorithm>

namespace
{
constexpr uint32 SPELL_HARNESS_ANIMAL_SPIRIT = 574301;
constexpr uint32 SPELL_HARNESS_TAME_HELPER = 574304;
constexpr uint32 PRIMALIST_SPELL_FAMILY = 37;
constexpr uint32 HARNESS_DURATION = 20000;
constexpr uint32 HARNESS_OLD_PERIOD = 19000;

bool IsHarnessLayout(SpellInfo const* info)
{
    return info && info->Id == SPELL_HARNESS_ANIMAL_SPIRIT &&
        info->SpellFamilyName == PRIMALIST_SPELL_FAMILY && !info->SpellFamilyFlags &&
        info->IsChanneled() && info->GetDuration() == HARNESS_DURATION && info->TargetCreatureType == 1 &&
        info->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
        info->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY &&
        !info->Effects[EFFECT_0].TargetB.GetTarget() &&
        info->Effects[EFFECT_1].IsAura(SPELL_AURA_PERIODIC_TRIGGER_SPELL) &&
        info->Effects[EFFECT_1].TriggerSpell == SPELL_HARNESS_TAME_HELPER &&
        info->Effects[EFFECT_1].TargetA.GetTarget() == TARGET_UNIT_CASTER &&
        !info->Effects[EFFECT_1].TargetB.GetTarget() && !info->Effects[EFFECT_2].Effect &&
        !info->HasAttribute(SPELL_ATTR5_EXTRA_INITIAL_PERIOD) &&
        (info->Effects[EFFECT_1].Amplitude == HARNESS_OLD_PERIOD ||
            info->Effects[EFFECT_1].Amplitude == HARNESS_DURATION);
}

bool IsTameHelperLayout(SpellInfo const* info)
{
    return info && info->Id == SPELL_HARNESS_TAME_HELPER && !info->SpellFamilyName &&
        !info->SpellFamilyFlags && info->TargetCreatureType == 1 &&
        info->Effects[EFFECT_0].Effect == SPELL_EFFECT_TAMECREATURE &&
        info->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_CHANNEL_TARGET &&
        !info->Effects[EFFECT_0].TargetB.GetTarget() &&
        !info->Effects[EFFECT_1].Effect && !info->Effects[EFFECT_2].Effect;
}

bool HasHarnessContract()
{
    SpellInfo const* parent = sSpellMgr->GetSpellInfo(SPELL_HARNESS_ANIMAL_SPIRIT);
    return IsHarnessLayout(parent) && parent->Effects[EFFECT_1].Amplitude == HARNESS_DURATION &&
        IsTameHelperLayout(sSpellMgr->GetSpellInfo(SPELL_HARNESS_TAME_HELPER));
}

SpellCastResult CheckHarnessTarget(Player* player, Unit* unitTarget)
{
    if (!player || !IsAscensionPrimalistTameEligible(player) || !HasHarnessContract())
    {
        if (player)
            player->SendTameFailure(PET_TAME_UNITS_CANT_TAME);
        return SPELL_FAILED_DONT_REPORT;
    }

    Creature* target = unitTarget ? unitTarget->ToCreature() : nullptr;
    if (!player->IsAlive() || !target || !target->IsAlive() || !target->GetCreatureTemplate())
    {
        player->SendTameFailure(PET_TAME_INVALID_CREATURE);
        return SPELL_FAILED_DONT_REPORT;
    }

    if (target->GetLevel() > player->GetLevel())
    {
        player->SendTameFailure(PET_TAME_TOO_HIGHLEVEL);
        return SPELL_FAILED_DONT_REPORT;
    }
    if (target->GetCreatureTemplate()->IsExotic() && !player->CanTameExoticPets())
    {
        player->SendTameFailure(PET_TAME_CANT_CONTROL_EXOTIC);
        return SPELL_FAILED_DONT_REPORT;
    }
    if (!target->GetCreatureTemplate()->IsTameable(player->CanTameExoticPets()))
    {
        player->SendTameFailure(PET_TAME_NOT_TAMEABLE);
        return SPELL_FAILED_DONT_REPORT;
    }
    if (player->GetPetGUID())
        return SPELL_FAILED_ALREADY_HAVE_SUMMON;
    if (PetStable const* stable = player->GetPetStable())
    {
        if (stable->CurrentPet)
            return SPELL_FAILED_ALREADY_HAVE_SUMMON;
        if (stable->GetUnslottedHunterPet())
        {
            player->SendTameFailure(PET_TAME_TOO_MANY);
            return SPELL_FAILED_DONT_REPORT;
        }
    }
    if (player->GetCharmGUID())
    {
        player->SendTameFailure(PET_TAME_ANOTHER_SUMMON_ACTIVE);
        return SPELL_FAILED_DONT_REPORT;
    }
    if (target->GetOwnerGUID() || target->IsPet())
    {
        player->SendTameFailure(PET_TAME_CREATURE_ALREADY_OWNED);
        return SPELL_FAILED_DONT_REPORT;
    }
    return SPELL_CAST_OK;
}

class spell_ascension_primalist_harness : public SpellScript
{
    PrepareSpellScript(spell_ascension_primalist_harness);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_HARNESS_ANIMAL_SPIRIT &&
            ValidateSpellInfo({ SPELL_HARNESS_ANIMAL_SPIRIT, SPELL_HARNESS_TAME_HELPER });
    }

    SpellCastResult CheckCast()
    {
        return CheckHarnessTarget(GetCaster()->ToPlayer(), GetExplTargetUnit());
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_primalist_harness::CheckCast);
    }
};

class spell_ascension_primalist_harness_tame : public SpellScript
{
    PrepareSpellScript(spell_ascension_primalist_harness_tame);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_HARNESS_TAME_HELPER &&
            ValidateSpellInfo({ SPELL_HARNESS_ANIMAL_SPIRIT, SPELL_HARNESS_TAME_HELPER });
    }

    void ValidateTame(SpellEffIndex effIndex)
    {
        SpellInfo const* trigger = GetSpell()->GetTriggeredByAuraSpellInfo();
        if (!trigger || trigger->Id != SPELL_HARNESS_ANIMAL_SPIRIT ||
            GetSpell()->GetTriggeredByAuraTickNumber() != 1 ||
            CheckHarnessTarget(GetCaster()->ToPlayer(), GetHitUnit()) != SPELL_CAST_OK)
            PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_primalist_harness_tame::ValidateTame,
            EFFECT_0, SPELL_EFFECT_TAMECREATURE);
    }
};
}

bool HasAscensionPrimalistHunterPetContext(Player const* player)
{
    if (!player || player->getClass() != CLASS_WILDWALKER)
        return false;
    if (IsAscensionPrimalistTameEligible(player))
        return true;
    PetStable const* stable = player->GetPetStable();
    if (!stable)
        return false;

    if (stable->CurrentPet && stable->CurrentPet->Type == HUNTER_PET)
        return true;
    for (auto const& pet : stable->StabledPets)
        if (pet && pet->Type == HUNTER_PET)
            return true;
    return std::any_of(stable->UnslottedPets.begin(), stable->UnslottedPets.end(),
        [](PetStable::PetInfo const& pet) { return pet.Type == HUNTER_PET; });
}

void ApplyAscensionPrimalistSpiritBeastContract(SpellInfo* spellInfo)
{
    if (IsHarnessLayout(spellInfo))
        spellInfo->Effects[EFFECT_1].Amplitude = HARNESS_DURATION;
}

void AddSC_AscensionPrimalistSpiritBeast()
{
    RegisterSpellScript(spell_ascension_primalist_harness);
    RegisterSpellScript(spell_ascension_primalist_harness_tame);
}
