/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionPvpPowerPolicy.h"
#include "Config.h"
#include "Item.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include <atomic>

namespace PvpPower
{
constexpr uint32 HighRiskAura = 1004019;
constexpr uint32 NoRiskAura = 1004119;
constexpr uint32 PveModeAura = 9931032;
constexpr uint32 RealmLevelCap = 60;
std::atomic<bool> enabled{false};

unsigned EquippedPower(Player const* player)
{
    if (!enabled.load() || !player || player->GetLevel() < RealmLevelCap)
        return 0;

    unsigned total = 0;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item const* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            if (!item->IsBroken())
                for (auto const& spell : item->GetTemplate()->Spells)
                    if (spell.SpellTrigger == ITEM_SPELLTRIGGER_ON_EQUIP)
                        total += SpellPower(spell.SpellId);
    return std::min(total, Cap);
}

bool HighRiskWorld(Player const* player)
{
    return player && player->GetMap() && !player->GetMap()->Instanceable() && player->HasAura(HighRiskAura);
}

unsigned HealingPower(Unit const* caster)
{
    Player const* player = caster ? caster->ToPlayer() : nullptr;
    if (!player || !player->GetMap())
        return 0;
    Map const* map = player->GetMap();
    bool warMode = player->HasAura(NoRiskAura) && !player->HasAura(PveModeAura);
    if (!HealingContext(map->Instanceable(), map->IsBattlegroundOrArena(),
        player->HasAura(HighRiskAura), warMode))
        return 0;
    return EquippedPower(player);
}

uint32 Damage(Unit* target, Unit* attacker, uint32 amount)
{
    if (!enabled.load() || !target || !attacker || target == attacker || !amount)
        return amount;
    Player const* source = attacker->ToPlayer();
    Player const* recipient = target->ToPlayer();
    if (source && (recipient || (!target->GetCharmerOrOwnerPlayerOrPlayerItself() && HighRiskWorld(source))))
        amount = Scale(amount, EquippedPower(source), 5);
    if (recipient && !attacker->GetCharmerOrOwnerPlayerOrPlayerItself() && HighRiskWorld(recipient))
        amount = Scale(amount, EquippedPower(recipient), 5, true);
    return amount;
}

class Configuration : public WorldScript
{
public:
    Configuration() : WorldScript("PvpPowerConfiguration") { }
    void OnAfterConfigLoad(bool) override
    {
        enabled.store(sConfigMgr->GetOption<bool>("PvpPower.Enable", false));
    }
};

class Bonuses : public UnitScript
{
public:
    Bonuses() : UnitScript("PvpPowerBonuses", true, {
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
            healInfo.SetHeal(Scale(healInfo.GetHeal(), HealingPower(healInfo.GetHealer()), 2));
    }

    void OnAfterAuraEffectCalculateAmount(AuraEffect const* effect, Unit* caster, int32& amount) override
    {
        if (amount > 0 && (effect->GetAuraType() == SPELL_AURA_SCHOOL_ABSORB
            || effect->GetAuraType() == SPELL_AURA_MANA_SHIELD))
            amount = int32(Scale(uint32(amount), HealingPower(caster), 2));
    }
};
}

void AddSC_AscensionPvpPower()
{
    new PvpPower::Configuration();
    new PvpPower::Bonuses();
}
