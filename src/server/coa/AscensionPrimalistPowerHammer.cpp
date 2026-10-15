/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace
{
constexpr uint32 PowerHammer = 303014;
constexpr uint32 TwoHandedRage = 303030;

void UpdatePowerHammer(Player* player)
{
    if (!player || player->getClass() != CLASS_WILDWALKER || !player->IsInWorld())
        return;
    Item* weapon = player->GetWeaponForAttack(BASE_ATTACK, true);
    if (player->IsAlive() && player->HasAura(PowerHammer, player->GetGUID()) && weapon &&
        weapon->GetTemplate()->InventoryType == INVTYPE_2HWEAPON)
        player->CastSpell(player, TwoHandedRage, TRIGGERED_FULL_MASK);
    else
        player->RemoveAurasDueToSpell(TwoHandedRage, player->GetGUID());
}

class aura_ascension_power_hammer : public AuraScript
{
    PrepareAuraScript(aura_ascension_power_hammer);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({TwoHandedRage}); }

    bool Load() override
    {
        return GetUnitOwner()->IsPlayer() && GetUnitOwner()->getClass() == CLASS_WILDWALKER &&
            GetCasterGUID() == GetUnitOwner()->GetGUID();
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes) { UpdatePowerHammer(GetTarget()->ToPlayer()); }

    void Tick(AuraEffect const*)
    {
        PreventDefaultAction();
        UpdatePowerHammer(GetTarget()->ToPlayer());
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(TwoHandedRage, GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_power_hammer::Apply,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_power_hammer::Tick,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_power_hammer::Remove,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class primalist_power_hammer_equipment : public PlayerScript
{
public:
    primalist_power_hammer_equipment() : PlayerScript("primalist_power_hammer_equipment",
        {PLAYERHOOK_ON_EQUIP, PLAYERHOOK_ON_UNEQUIP_ITEM, PLAYERHOOK_ON_LOGIN}) { }

    void OnPlayerEquip(Player* player, Item*, uint8, uint8, bool) override { UpdatePowerHammer(player); }
    void OnPlayerUnequip(Player* player, Item*) override { UpdatePowerHammer(player); }
    void OnPlayerLogin(Player* player) override { UpdatePowerHammer(player); }
};

class primalist_power_hammer_metadata : public GlobalScript
{
public:
    primalist_power_hammer_metadata() : GlobalScript("primalist_power_hammer_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == TwoHandedRage && info->SpellFamilyName == 37)
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
    }
};
}

void AddSC_AscensionPrimalistPowerHammer()
{
    new primalist_power_hammer_equipment();
    new primalist_power_hammer_metadata();
    RegisterSpellScript(aura_ascension_power_hammer);
}
