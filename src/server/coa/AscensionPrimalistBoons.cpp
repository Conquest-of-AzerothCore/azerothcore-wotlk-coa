/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <array>

namespace
{
constexpr uint32 FuryOfTheWild = 801234;
constexpr uint32 PrimalConvergence = 800181;
constexpr uint32 BoonOfTheHawk = 500943;
constexpr std::array<uint32, 5> Boons = {500935, 500939, BoonOfTheHawk, 800137, 504856};
std::array<PetAura, 5> const BoonPetAuras = {
    PetAura(0, Boons[0], true, 0),
    PetAura(0, Boons[1], true, 0),
    PetAura(0, Boons[2], true, 0),
    PetAura(0, Boons[3], true, 0),
    PetAura(0, Boons[4], true, 0)
};

PetAura const* FindBoonPetAura(uint32 spell)
{
    for (PetAura const& aura : BoonPetAuras)
        if (aura.GetAura(0) == spell)
            return &aura;
    return nullptr;
}

Player* Primalist(Unit* unit)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_WILDWALKER ? player : nullptr;
}

bool IsPetCopy(Unit* target, Unit* caster)
{
    Pet* pet = target ? target->ToPet() : nullptr;
    return pet && caster == pet && Primalist(pet->GetOwner());
}

class aura_ascension_primalist_boon : public AuraScript
{
    PrepareAuraScript(aura_ascension_primalist_boon);

    bool Load() override { return Primalist(GetCaster()) || IsPetCopy(GetUnitOwner(), GetCaster()); }

    void Amount(AuraEffect const* effect, int32& amount, bool&)
    {
        if (!IsPetCopy(GetUnitOwner(), GetCaster()))
        {
            Player* player = Primalist(GetCaster());
            if (player && GetUnitOwner() == player)
                if (AuraEffect const* convergence = player->GetAuraEffect(PrimalConvergence, EFFECT_0))
                    AddPct(amount, convergence->GetAmount());
            return;
        }
        if (effect->GetAuraType() == SPELL_AURA_DUMMY)
            return;
        if (Unit* owner = GetUnitOwner()->GetOwner())
            if (Aura* original = owner->GetAura(GetId(), owner->GetGUID()))
                if (AuraEffect const* originalEffect = original->GetEffect(effect->GetEffIndex()))
                    amount = originalEffect->GetAmount();
        if (GetId() != BoonOfTheHawk || effect->GetEffIndex() != EFFECT_2)
            amount /= 2;
    }

    void Applied(AuraEffect const*, AuraEffectHandleModes)
    {
        if (IsPetCopy(GetTarget(), GetCaster()))
        {
            Unit* owner = GetTarget()->GetOwner();
            if (!owner->HasAura(FuryOfTheWild) || !owner->HasAura(GetId(), owner->GetGUID()))
                Remove();
            return;
        }
        Player* player = Primalist(GetTarget());
        if (!player || GetCasterGUID() != player->GetGUID() || !player->HasAura(FuryOfTheWild))
            return;
        Pet* pet = player->GetPet();
        if (pet && pet->IsAlive() && pet->GetOwnerGUID() == player->GetGUID())
            if (PetAura const* aura = FindBoonPetAura(GetId()))
                player->AddPetAura(aura);
    }

    void Removed(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = Primalist(GetTarget());
        if (player && GetCasterGUID() == player->GetGUID())
            if (PetAura const* aura = FindBoonPetAura(GetId()))
                player->RemovePetAura(aura);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_primalist_boon::Amount,
            EFFECT_ALL, SPELL_AURA_ANY);
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_primalist_boon::Applied,
            EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_primalist_boon::Removed,
            EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_primal_convergence : public AuraScript
{
    PrepareAuraScript(aura_ascension_primal_convergence);

    bool Load() override { return Primalist(GetUnitOwner()) != nullptr; }

    void SpellMod(AuraEffect const*, SpellModifier*& modifier)
    {
        if (modifier)
            modifier->value = 0;
    }

    void Refresh(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        for (uint32 spell : Boons)
        {
            if (Aura* boon = player->GetAura(spell, player->GetGUID()))
                for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
                    if (AuraEffect* effect = boon->GetEffect(index))
                        effect->RecalculateAmount();
            if (Pet* pet = player->GetPet())
                if (Aura* boon = pet->GetAura(spell, pet->GetGUID()))
                    for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
                        if (AuraEffect* effect = boon->GetEffect(index))
                            effect->RecalculateAmount();
        }
    }

    void Register() override
    {
        DoEffectCalcSpellMod += AuraEffectCalcSpellModFn(aura_ascension_primal_convergence::SpellMod,
            EFFECT_0, SPELL_AURA_ADD_PCT_MODIFIER);
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_primal_convergence::Refresh,
            EFFECT_0, SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_primal_convergence::Refresh,
            EFFECT_0, SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_fury_of_the_wild : public AuraScript
{
    PrepareAuraScript(aura_ascension_fury_of_the_wild);

    bool Load() override { return Primalist(GetUnitOwner()) != nullptr; }

    void Removed(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        for (PetAura const& aura : BoonPetAuras)
            player->RemovePetAura(&aura);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_fury_of_the_wild::Removed,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_pet_hawk_heal : public SpellScript
{
    PrepareSpellScript(spell_ascension_pet_hawk_heal);

    void Heal()
    {
        SpellInfo const* trigger = GetSpell()->GetTriggeredByAuraSpellInfo();
        Pet* pet = GetHitUnit() ? GetHitUnit()->ToPet() : nullptr;
        Player* owner = pet ? Primalist(pet->GetOwner()) : nullptr;
        if (trigger && trigger->Id == BoonOfTheHawk && owner &&
            pet->HasAura(BoonOfTheHawk, pet->GetGUID()))
            SetHitHeal(GetHitHeal() / 2);
    }

    void Register() override { OnHit += SpellHitFn(spell_ascension_pet_hawk_heal::Heal); }
};

class aura_ascension_lion_boon_periodic : public AuraScript
{
    PrepareAuraScript(aura_ascension_lion_boon_periodic);

    void Periodic(AuraEffect const*, bool&, int32& amplitude)
    {
        if (IsPetCopy(GetUnitOwner(), GetCaster()))
            amplitude *= 2;
    }

    void Register() override
    {
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_ascension_lion_boon_periodic::Periodic,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};
}

void AddSC_AscensionPrimalistBoons()
{
    RegisterSpellScript(aura_ascension_primalist_boon);
    RegisterSpellScript(aura_ascension_primal_convergence);
    RegisterSpellScript(aura_ascension_fury_of_the_wild);
    RegisterSpellScript(spell_ascension_pet_hawk_heal);
    RegisterSpellScript(aura_ascension_lion_boon_periodic);
}
