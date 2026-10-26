/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionItemPower.h"
#include "AscensionPvePowerPolicy.h"
#include "Config.h"
#include "Item.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include <atomic>

namespace PvePower
{
std::atomic<bool> enabled{false};

unsigned EquippedPower(Player const* player)
{
    if (!enabled.load() || !player || player->GetLevel() < MinimumLevel)
        return 0;

    unsigned total = 0;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item const* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            if (!item->IsBroken())
                total += AscensionItemPower::OfItem(item->GetTemplate(), false);
    return std::min(total, Cap);
}

MapKind KindOf(Map const* map)
{
    if (map->IsBattlegroundOrArena())
        return Battleground;
    return map->Instanceable() ? Instance : OpenWorld;
}

bool PlayerControlled(Unit const* unit)
{
    return unit->GetCharmerOrOwnerPlayerOrPlayerItself() != nullptr;
}

unsigned HealingPower(Unit const* caster)
{
    Player const* player = caster ? caster->ToPlayer() : nullptr;
    if (!player || !player->GetMap() || !Applies(HealingMaps, KindOf(player->GetMap())))
        return 0;
    return EquippedPower(player);
}

uint32 Damage(Unit* target, Unit* attacker, uint32 amount)
{
    if (!enabled.load() || !target || !attacker || target == attacker || !amount)
        return amount;
    Map const* map = target->GetMap();
    if (!map || !Applies(DamageMaps, KindOf(map)))
        return amount;
    Player const* source = attacker->ToPlayer();
    Player const* recipient = target->ToPlayer();
    if (source && !PlayerControlled(target))
        amount = PvpPower::Scale(amount, EquippedPower(source), DamageBasisPoints);
    if (recipient && !PlayerControlled(attacker))
        amount = PvpPower::Scale(amount, EquippedPower(recipient), DamageBasisPoints, true);
    return amount;
}

class Configuration : public WorldScript
{
public:
    Configuration() : WorldScript("PvePowerConfiguration") { }
    void OnAfterConfigLoad(bool) override
    {
        enabled.store(sConfigMgr->GetOption<bool>("PvePower.Enable", true));
    }
};

class Bonuses : public UnitScript
{
public:
    Bonuses() : UnitScript("PvePowerBonuses", true, {
        UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
        UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_ON_BEFORE_HEAL_ABSORB,
        UNITHOOK_ON_AFTER_AURA_EFFECT_CALCULATE_AMOUNT }) { }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& amount) override
    {
        amount = Damage(target, attacker, amount);
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& amount, SpellInfo const*) override
    {
        if (amount > 0)
            amount = int32(Damage(target, attacker, uint32(amount)));
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& amount,
        SpellInfo const* spell) override
    {
        if (spell && !spell->IsPositive() && !spell->HasAura(SPELL_AURA_PERIODIC_DAMAGE_PERCENT))
            amount = Damage(target, attacker, amount);
    }

    void OnBeforeHealAbsorb(HealInfo& healInfo) override
    {
        auto const* spell = healInfo.GetSpellInfo();
        if (spell && spell->SpellFamilyName != SPELLFAMILY_POTION)
            healInfo.SetHeal(PvpPower::Scale(healInfo.GetHeal(), HealingPower(healInfo.GetHealer()),
                HealingBasisPoints));
    }

    void OnAfterAuraEffectCalculateAmount(AuraEffect const* effect, Unit* caster, int32& amount) override
    {
        if (amount > 0 && (effect->GetAuraType() == SPELL_AURA_SCHOOL_ABSORB
            || effect->GetAuraType() == SPELL_AURA_MANA_SHIELD))
            amount = int32(PvpPower::Scale(uint32(amount), HealingPower(caster), HealingBasisPoints));
    }
};
}

void AddSC_AscensionPvePower()
{
    new PvePower::Configuration();
    new PvePower::Bonuses();
}
