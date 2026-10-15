/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionPrimalistWeapons.h"
#include "Item.h"
#include "Pet.h"
#include "Player.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"

namespace
{
enum PrimalWeaponsSpells : uint32
{
    SPELL_PRIMAL_WEAPONS = 537218,
    SPELL_BESTIAL_MIGHT = 801242,
    SPELL_PRIMAL_MIGHT = 704098,
    SPELL_WILDCLAW_BONUS = 563262,
    SPELL_TALONFURY = 806070,
    SPELL_PET_TALONFURY = 806071
};

uint32 SelectPrimalWeapon(Player* player, bool allowUnconfirmed = false)
{
    if (!IsAscensionPrimalistWeaponsEligible(player, allowUnconfirmed))
        return 0;
    Item* weapon = player->GetWeaponForAttack(BASE_ATTACK, true);
    if (!weapon)
        return 0;
    ItemTemplate const* item = weapon->GetTemplate();
    for (uint32 id : {SPELL_BESTIAL_MIGHT, SPELL_PRIMAL_MIGHT})
        if (SpellInfo const* info = sSpellMgr->GetSpellInfo(id))
            if (item->Class == uint32(info->EquippedItemClass) && item->SubClass < 32 &&
                (info->EquippedItemSubClassMask & (uint32(1) << item->SubClass)))
                return id;
    return 0;
}

class spell_ascension_primal_weapons : public SpellScript
{
    PrepareSpellScript(spell_ascension_primal_weapons);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_BESTIAL_MIGHT, SPELL_PRIMAL_MIGHT});
    }

    SpellCastResult CheckCast()
    {
        return SelectPrimalWeapon(GetCaster()->ToPlayer()) ? SPELL_CAST_OK : SPELL_FAILED_EQUIPPED_ITEM_CLASS;
    }

    void Handle(SpellEffIndex)
    {
        Player* player = GetCaster()->ToPlayer();
        if (uint32 selected = SelectPrimalWeapon(player))
            player->CastSpell(player, selected, true);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_primal_weapons::CheckCast);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_primal_weapons::Handle, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class aura_ascension_primal_weapon : public AuraScript
{
    PrepareAuraScript(aura_ascension_primal_weapon);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_WILDCLAW_BONUS, SPELL_TALONFURY, SPELL_PET_TALONFURY});
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || SelectPrimalWeapon(player, true) != GetId())
        {
            GetAura()->Remove();
            return;
        }
        player->RemoveAurasDueToSpell(GetId() == SPELL_BESTIAL_MIGHT ? SPELL_PRIMAL_MIGHT : SPELL_BESTIAL_MIGHT);
        if (GetId() == SPELL_PRIMAL_MIGHT)
            player->CastSpell(player, SPELL_WILDCLAW_BONUS, true);
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* target = GetTarget();
        if (GetId() == SPELL_PRIMAL_MIGHT)
            target->RemoveAurasDueToSpell(SPELL_WILDCLAW_BONUS, target->GetGUID());
        else
        {
            target->RemoveAurasDueToSpell(SPELL_TALONFURY, target->GetGUID());
            if (Player* player = target->ToPlayer())
                if (Pet* pet = player->GetPet())
                    pet->RemoveAurasDueToSpell(SPELL_PET_TALONFURY, player->GetGUID());
        }
    }

    bool CheckProc(ProcEventInfo& event)
    {
        return GetId() == SPELL_BESTIAL_MIGHT && event.GetActor() == GetTarget() &&
            event.GetDamageInfo() && (event.GetDamageInfo()->GetDamage() || event.GetDamageInfo()->GetAbsorb()) &&
            (event.GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL) && (event.GetHitMask() & PROC_HIT_CRITICAL) &&
            SelectPrimalWeapon(GetTarget()->ToPlayer()) == SPELL_BESTIAL_MIGHT;
    }

    void Proc(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;
        player->CastSpell(player, SPELL_TALONFURY, true, nullptr, effect);
        if (Pet* pet = player->GetPet(); pet && pet->IsAlive())
            player->CastSpell(pet, SPELL_PET_TALONFURY, true, nullptr, effect);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_primal_weapon::Apply,
            EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_primal_weapon::Remove,
            EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
        DoCheckProc += AuraCheckProcFn(aura_ascension_primal_weapon::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_primal_weapon::Proc, EFFECT_ALL, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
}

void RemoveAscensionPrimalistWeapons(Player* player)
{
    if (!player || player->getClass() != CLASS_WILDWALKER || IsAscensionPrimalistWeaponsEligible(player, true))
        return;
    for (uint32 id : {SPELL_BESTIAL_MIGHT, SPELL_PRIMAL_MIGHT, SPELL_WILDCLAW_BONUS, SPELL_TALONFURY})
        player->RemoveAurasDueToSpell(id, player->GetGUID());
    if (Pet* pet = player->GetPet())
        pet->RemoveAurasDueToSpell(SPELL_PET_TALONFURY, player->GetGUID());
}

void ApplyAscensionPrimalistWeaponsContract(SpellInfo* info)
{
    if (info->Id != SPELL_PRIMAL_WEAPONS || info->SpellFamilyName != 37)
        return;
    info->Attributes = 0;
    info->AttributesEx2 = 0;
    info->AuraInterruptFlags = 0;
    info->DurationEntry = nullptr;
    info->PowerType = POWER_MANA;
    info->ManaCostPercentage = 15;
    info->Effects[EFFECT_0].Effect = SPELL_EFFECT_DUMMY;
    info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_NONE;
    info->Effects[EFFECT_0].BasePoints = 0;
    info->Effects[EFFECT_0].DieSides = 0;
    info->Effects[EFFECT_0].MiscValue = 0;
    info->Effects[EFFECT_0].SpellClassMask = flag96();
}

void AddSC_AscensionPrimalistWeapons()
{
    RegisterSpellScript(spell_ascension_primal_weapons);
    RegisterSpellScript(aura_ascension_primal_weapon);
}
