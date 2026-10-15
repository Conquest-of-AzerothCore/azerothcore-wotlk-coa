/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionVenomancerVenoms.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"

#include <array>

namespace
{
constexpr uint32 SPELL_REMOVE_VENOMS = 630872;
constexpr uint32 SPELL_VENOM_COUNTER = 805779;
constexpr uint32 SPELL_VENOM_COUNTER_REMOVER = 807260;
constexpr uint8 MAX_UNIQUE_VENOMS = 2;

struct VenomDefinition
{
    uint32 SpellId;
    uint32 TriggerSpellId;
    uint32 FamilyMask1;
    uint8 ProcChance;
    uint8 StackAmount;
};

constexpr std::array<VenomDefinition, 6> VENOMS =
{{
    {630868, 630869, 1024, 20, 1},
    {805731, 805895, 64, 30, 1},
    {805775, 805894, 2, 25, 1},
    {805776, 805896, 0, 30, 1},
    {805777, 805897, 4194304, 30, 2},
    {805778, 706000, 0, 35, 2}
}};

VenomDefinition const* FindVenom(uint32 spellId)
{
    for (VenomDefinition const& venom : VENOMS)
        if (venom.SpellId == spellId)
            return &venom;

    return nullptr;
}

bool IsVenomActivation(SpellInfo const* spellInfo)
{
    VenomDefinition const* venom = spellInfo ? FindVenom(spellInfo->Id) : nullptr;
    if (!venom || spellInfo->SpellFamilyName != uint32(CLASS_PROPHET) + 6 ||
        spellInfo->SpellFamilyFlags != flag96(0, venom->FamilyMask1, 268435456) ||
        spellInfo->IsPassive() || !spellInfo->IsDeathPersistent() || spellInfo->GetDuration() != 7200000 ||
        spellInfo->Stances || spellInfo->StancesNot || spellInfo->StackAmount != venom->StackAmount ||
        spellInfo->ProcChance != venom->ProcChance || spellInfo->ProcCharges)
        return false;

    SpellEffectInfo const& effect = spellInfo->Effects[EFFECT_0];
    return effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL &&
        effect.TriggerSpell == venom->TriggerSpellId && !effect.BasePoints && !effect.DieSides &&
        !effect.RealPointsPerLevel && !effect.Amplitude && !effect.MiscValue && !effect.MiscValueB &&
        !effect.SpellClassMask && effect.TargetA.GetTarget() == TARGET_UNIT_CASTER &&
        !effect.TargetB.GetTarget() && !spellInfo->Effects[EFFECT_2].Effect;
}

bool IsRemoveVenoms(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->Id != SPELL_REMOVE_VENOMS ||
        spellInfo->SpellFamilyName != uint32(CLASS_PROPHET) + 6 || spellInfo->SpellFamilyFlags ||
        spellInfo->Stances || spellInfo->StancesNot || spellInfo->Effects[EFFECT_2].Effect)
        return false;

    for (SpellEffIndex index : {EFFECT_0, EFFECT_1})
    {
        SpellEffectInfo const& effect = spellInfo->Effects[index];
        if (effect.Effect != SPELL_EFFECT_TRIGGER_SPELL || effect.TriggerSpell != SPELL_VENOM_COUNTER_REMOVER ||
            effect.ApplyAuraName != SPELL_AURA_NONE || effect.BasePoints != -1 || effect.DieSides != 1 ||
            effect.RealPointsPerLevel || effect.MiscValue != 524287 || effect.MiscValueB ||
            effect.TargetA.GetTarget() != TARGET_UNIT_CASTER || effect.TargetB.GetTarget())
            return false;
    }

    return true;
}

Player* Venomancer(Unit* unit)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_PROPHET ? player : nullptr;
}

Aura* OwnActiveVenom(Player* player, uint32 spellId)
{
    Aura* aura = player->GetOwnedAura(spellId, player->GetGUID());
    return aura && !aura->IsRemoved() && !aura->IsExpired() ? aura : nullptr;
}

uint8 CountOwnVenoms(Player* player)
{
    uint8 count = 0;
    for (VenomDefinition const& venom : VENOMS)
        if (OwnActiveVenom(player, venom.SpellId))
            ++count;

    return count;
}

void ClearOwnVenoms(Player* player)
{
    ObjectGuid const owner = player->GetGUID();
    for (VenomDefinition const& venom : VENOMS)
        player->RemoveAurasDueToSpell(venom.SpellId, owner);

    player->RemoveAurasDueToSpell(SPELL_VENOM_COUNTER, owner);
}

class spell_ascension_venomancer_venom_selection : public SpellScript
{
    PrepareSpellScript(spell_ascension_venomancer_venom_selection);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsVenomActivation(spellInfo);
    }

    SpellCastResult CheckSelection()
    {
        Player* player = Venomancer(GetCaster());
        if (!player || GetOriginalCaster() != player || !IsVenomActivation(GetSpellInfo()) ||
            OwnActiveVenom(player, GetSpellInfo()->Id))
            return SPELL_CAST_OK;

        return CountOwnVenoms(player) < MAX_UNIQUE_VENOMS ? SPELL_CAST_OK : SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_venomancer_venom_selection::CheckSelection);
    }
};

class aura_ascension_venomancer_venom_selection : public AuraScript
{
    PrepareAuraScript(aura_ascension_venomancer_venom_selection);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsVenomActivation(spellInfo);
    }

    void CheckApplication(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = Venomancer(GetTarget());
        if (!player || GetCasterGUID() != player->GetGUID() || !player->IsInWorld() ||
            GetAura()->IsRemoved() || !IsVenomActivation(GetSpellInfo()))
            return;

        if (CountOwnVenoms(player) > MAX_UNIQUE_VENOMS)
            GetAura()->Remove();
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_venomancer_venom_selection::CheckApplication,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_venomancer_remove_venoms : public SpellScript
{
    PrepareSpellScript(spell_ascension_venomancer_remove_venoms);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsRemoveVenoms(spellInfo);
    }

    void SkipCounterTrigger(SpellEffIndex index)
    {
        Player* player = Venomancer(GetCaster());
        if (player && GetOriginalCaster() == player && IsRemoveVenoms(GetSpellInfo()))
            PreventHitDefaultEffect(index);
    }

    void Clear(SpellEffIndex)
    {
        Player* player = Venomancer(GetCaster());
        if (player && GetOriginalCaster() == player && GetHitUnit() == player && IsRemoveVenoms(GetSpellInfo()))
            ClearOwnVenoms(player);
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_ascension_venomancer_remove_venoms::SkipCounterTrigger,
            EFFECT_0, SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectLaunch += SpellEffectFn(spell_ascension_venomancer_remove_venoms::SkipCounterTrigger,
            EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_venomancer_remove_venoms::SkipCounterTrigger,
            EFFECT_0, SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_venomancer_remove_venoms::SkipCounterTrigger,
            EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_venomancer_remove_venoms::Clear,
            EFFECT_0, SPELL_EFFECT_TRIGGER_SPELL);
    }
};

class AscensionVenomancerVenomsLogin : public PlayerScript
{
public:
    AscensionVenomancerVenomsLogin() : PlayerScript("AscensionVenomancerVenomsLogin", {PLAYERHOOK_ON_LOGIN}) { }

    void OnPlayerLogin(Player* player) override
    {
        if (Venomancer(player) && CountOwnVenoms(player) > MAX_UNIQUE_VENOMS)
            ClearOwnVenoms(player);
    }
};
}

void AddAscensionVenomancerVenomScripts()
{
    RegisterSpellScript(spell_ascension_venomancer_venom_selection);
    RegisterSpellScript(aura_ascension_venomancer_venom_selection);
    RegisterSpellScript(spell_ascension_venomancer_remove_venoms);
    new AscensionVenomancerVenomsLogin();
}
