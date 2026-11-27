/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include <unordered_map>

namespace
{
std::unordered_map<uint32, uint32> const TalonRipperOwnerBuffs =
{
    { 985807, 985809 },
    { 313465, 313807 },
    { 317465, 317807 },
    { 321465, 321807 },
};

bool IsPlayerPet(Unit const* unit)
{
    if (!unit || !unit->IsPet())
        return false;

    Unit const* owner = unit->GetOwner();
    return owner && owner->IsPlayer();
}

class aura_ascension_item_talon_ripper : public AuraScript
{
    PrepareAuraScript(aura_ascension_item_talon_ripper);

    bool Validate(SpellInfo const* spellInfo) override
    {
        auto const itr = TalonRipperOwnerBuffs.find(spellInfo->Id);
        return itr != TalonRipperOwnerBuffs.end() && ValidateSpellInfo({ itr->second });
    }

    bool CheckProc(ProcEventInfo&)
    {
        return IsPlayerPet(GetTarget());
    }

    void GrantOwnerBuff(AuraEffect const* aurEff, ProcEventInfo&)
    {
        auto const itr = TalonRipperOwnerBuffs.find(GetId());
        if (itr != TalonRipperOwnerBuffs.end())
            GetTarget()->CastSpell(GetTarget(), itr->second, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_item_talon_ripper::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_item_talon_ripper::GrantOwnerBuff, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class aura_ascension_item_leggings_of_beast_mastery : public AuraScript
{
    PrepareAuraScript(aura_ascension_item_leggings_of_beast_mastery);

    void ModifyPet(AuraEffect const* aurEff, bool apply)
    {
        Unit* pet = GetTarget();
        if (!IsPlayerPet(pet))
            return;

        float const amount = float(aurEff->GetAmount());
        switch (aurEff->GetEffIndex())
        {
            case EFFECT_0:
                pet->HandleStatFlatModifier(UNIT_MOD_ATTACK_POWER, TOTAL_VALUE, amount, apply);
                break;
            case EFFECT_1:
                pet->HandleStatFlatModifier(UNIT_MOD_ARMOR, TOTAL_VALUE, amount, apply);
                pet->UpdateResistanceBuffModsMod(SPELL_SCHOOL_NORMAL);
                break;
            case EFFECT_2:
                pet->HandleStatFlatModifier(UNIT_MOD_STAT_STAMINA, TOTAL_VALUE, amount, apply);
                pet->UpdateStatBuffMod(STAT_STAMINA);
                break;
            default:
                break;
        }
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes)
    {
        ModifyPet(aurEff, true);
    }

    void HandleRemove(AuraEffect const* aurEff, AuraEffectHandleModes)
    {
        ModifyPet(aurEff, false);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_item_leggings_of_beast_mastery::HandleApply, EFFECT_ALL,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_item_leggings_of_beast_mastery::HandleRemove, EFFECT_ALL,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionPetItemAuras()
{
    RegisterSpellScript(aura_ascension_item_talon_ripper);
    RegisterSpellScript(aura_ascension_item_leggings_of_beast_mastery);
}
