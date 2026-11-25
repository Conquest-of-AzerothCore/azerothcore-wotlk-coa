/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCultist.h"
#include "AscensionCultistData.h"
#include "DBCStores.h"
#include "Opcodes.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "WorldPacket.h"
#include <algorithm>
#include <tuple>
#include <vector>
namespace AscensionCultist
{
void ApplyContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != 31)
        return;
    uint32 id = info->Id;
    if (id == 807815)
    {
        info->AttributesEx &= ~SPELL_ATTR1_NO_THREAT;
        info->Effects[0].ChainTarget = 0;
    }
    auto dummy = [info](uint8 slot)
    {
        info->Effects[slot].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[slot].TriggerSpell = 0;
    };
    auto aura = [info](uint8 slot, AuraType type, int32 amount, int32 misc, uint32 target)
    {
        auto& effect = info->Effects[slot];
        effect.Effect = SPELL_EFFECT_APPLY_AURA;
        effect.ApplyAuraName = type;
        effect.BasePoints = amount;
        effect.DieSides = 0;
        effect.MiscValue = misc;
        effect.TriggerSpell = 0;
        effect.TargetA = SpellImplicitTargetInfo(target);
        effect.TargetB = SpellImplicitTargetInfo();
    };
    for (auto list : {std::pair(CultistEvents, std::size(CultistEvents)),
                        std::pair(CultistDrivers, std::size(CultistDrivers))})
        for (size_t n = 0; n < list.second; ++n)
            if (list.first[n] == id)
            {
                for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
                    if (info->Effects[i].ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL ||
                        info->Effects[i].ApplyAuraName == 354 || info->Effects[i].ApplyAuraName == 353)
                        dummy(i);
                info->ProcFlags = info->ProcCharges = 0;
            }
    for (uint32 copy : CultistCopies)
        if (id == copy)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
            info->AscensionInheritsResolvedAmount = true;
            bool damage = id == 707750 || id == 807083 || id == 525062 || id == 706910 || id == 520450;
            info->Effects[0].TargetA = SpellImplicitTargetInfo(damage ? TARGET_UNIT_TARGET_ENEMY : TARGET_UNIT_TARGET_ALLY);
            info->Effects[0].TargetB = SpellImplicitTargetInfo();
        }
    if (id == 570263 || id == 500748 || id == 301983 || id == 520450 || id == 520497)
    {
        info->AttributesEx2 &= ~SPELL_ATTR2_CANT_CRIT;
        info->AscensionInheritsResolvedAmount = id == 520450 || id == 520497;
    }
    if (id == 500748)
        info->Effects[0].RealPointsPerLevel = 0.0f;
    if (id == 807083)
        info->Effects[1].Effect = 0;
    if (id == 301983 || id == 806175)
        info->Effects[1].Effect = 0;
    if (id == 502133)
    {
        dummy(0);
        info->Effects[1].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
    }
    if (id == 705106 || id == 705107)
        dummy(0);
    if (id == 802046)
        info->SchoolMask = SPELL_SCHOOL_MASK_NORMAL;
    if (id == 680556)
        info->Effects[0].MiscValue = 250043;
    if (id == 806769)
        info->Effects[2].MiscValue = 250044;
    if (Any(info, {805116, 804152}))
        info->AscensionIgnoreAbsorb = Named(info, 805116);
    if (Any(info, {806222, 804152}))
        info->AscensionFlatAfterWeaponPercent = true;
    if (Named(info, 567524))
        aura(0, SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN, 0, SPELL_SCHOOL_MASK_ALL, TARGET_UNIT_CASTER);
    if (id == 500727)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
        dummy(1);
    }
    if (id == Madness)
        info->Effects[1].Effect = 0;
    if (id == 801157)
        info->Effects[1].Effect = SPELL_EFFECT_DUMMY;
    if (id == 807877)
        dummy(1);
    if (id == 807878)
        info->Effects[1].MiscValue = BlackBlood;
    if (id == 806384 || id == 300284 || id == 805117 || id == 681326 || id == 301258)
        dummy(0);
    if (id == 300287 || id == 300290 || id == 560977)
    {
        dummy(0);
        dummy(1);
        if (id == 560977)
            dummy(2);
    }
    if (id == 300287)
        aura(0, SPELL_AURA_MOD_DISPEL_RESIST, 25, 0, TARGET_UNIT_CASTER);
    if (id == 300290)
        aura(1, SPELL_AURA_MOD_MINIMUM_SPEED, 100, 0, TARGET_UNIT_CASTER);
    if (id == 681106 || id == 707753)
        dummy(0);
    if (id == 300277)
        aura(2, SPELL_AURA_MOD_CRIT_DAMAGE_BONUS, 0, SPELL_SCHOOL_MASK_ALL, TARGET_UNIT_CASTER);
    if (id == 520326)
    {
        dummy(2);
        info->Effects[0].MiscValue = 250042;
    }
    if (id == 681088)
    {
        dummy(0);
        dummy(2);
    }
    for (uint32 infusion : CultistInfusions)
        if (id == infusion)
        {
            info->AuraInterruptFlags = 0;
            info->SpellLevel = 0;
        }
    if (Named(info, 500714))
        info->Effects[1].Effect = SPELL_EFFECT_DUMMY;
    if (id == BlackBlood)
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
    }
    if (id == 802048 || id == 560322)
        dummy(0);
    if (id == 574147)
    {
        aura(0, SPELL_AURA_MOD_HEALING_DONE, 0, SPELL_SCHOOL_MASK_ALL, TARGET_UNIT_CASTER);
        dummy(1);
    }
    if (id == 680609)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
    }
    if (id == 680579)
        dummy(1);
    if (id == 680574)
    {
        info->Effects[0].Effect = 0;
        info->Effects[1].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
    }
    if (id == 807883 || id == 681476 || id == 567529)
        info->DurationEntry = sSpellDurationStore.LookupEntry(21);
    if (id == 520345)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
        dummy(1);
        dummy(2);
        info->Effects[2].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
    }
    if (id == 520346)
    {
        info->Effects[1].BasePoints = info->Effects[0].BasePoints;
        info->Effects[1].DieSides = info->Effects[0].DieSides;
        info->Effects[1].RealPointsPerLevel = info->Effects[0].RealPointsPerLevel;
    }
    if (id == 520348)
    {
        info->Effects[0].Effect = SPELL_EFFECT_DUMMY;
        info->Effects[1].Effect = 0;
    }
    if (id == 520333)
    {
        info->Effects[EFFECT_1].Effect = 0;
        info->Effects[EFFECT_2].Effect = 0;
    }
    if (id == 560943)
        info->Effects[0].MiscValue = SPELL_SCHOOL_MASK_ALL;
    if (id == 573315)
        info->Effects[1].SpellClassMask = flag96(131072, 0, 0);
    if (id == 706181)
        dummy(1);
    if (id == 680576)
    {
        info->Effects[1].ApplyAuraName = SPELL_AURA_MOD_DECREASE_SPEED;
        info->Effects[1].MiscValue = 0;
    }
    if (id == 561392)
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER_AREA_RAID);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
        info->Effects[0].RadiusEntry = sSpellRadiusStore.LookupEntry(10);
    }
    if (id == 255281)
    {
        info->Effects[1].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[1].TriggerSpell = 0;
    }
    if (id == 255276)
        info->Effects[2].BasePoints = -26;
    if (id == 704476)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
    }
    if (id == 804277)
        info->Effects[2].Effect = 0;
    if (id == 804275)
        info->Effects[2].BasePoints = 19;
    if (id == 807124)
        info->Effects[1].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
    if (id == 806769)
        info->Effects[0].Effect = 0;
    if (id == 502133 || id == 301186 || id == 561288 || id == 806250 || id == 301259)
        info->ProcFlags = info->ProcCharges = 0;
    if (id == 301259)
        dummy(0);
    if (id == 520388)
        info->ProcCharges = 5;
    if (id == 600327)
        info->ProcCharges = 10;
    if (id == 520450 || id == 520497)
    {
        info->AuraInterruptFlags = 0;
    }
    if (id == 520498)
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
    }
    if (id == 807216)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
    }
    if (id == 706910)
    {
        for (uint8 slot = 1; slot < MAX_SPELL_EFFECTS; ++slot)
        {
            aura(slot, SPELL_AURA_DUMMY, 0, 0, info->Effects[0].TargetA.GetTarget());
            info->Effects[slot].TargetB = SpellImplicitTargetInfo();
        }
    }
    if (id == 582591)
    {
        aura(1, SPELL_AURA_DUMMY, 0, 0, TARGET_UNIT_CASTER);
        aura(2, SPELL_AURA_DUMMY, 0, 0, TARGET_UNIT_CASTER);
    }
    if (id == 800430)
        info->Effects[1].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
    if (id == 806039)
        info->Effects[1].Effect = SPELL_EFFECT_DUMMY;
    if (id == 704473)
        info->Effects[0].RealPointsPerLevel = 0.0f;
    if (id == 567525)
        info->DurationEntry = sSpellDurationStore.LookupEntry(18);
    if (id == 680600)
        info->Effects[1].BasePoints = 99;
    info->_InitializeExplicitTargetMask();
}
}
namespace
{
using namespace AscensionCultist;
class cultist_scaling : public UnitScript
{
public:
    cultist_scaling() : UnitScript("cultist_scaling", true,
        {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
         UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_MODIFY_HEAL_RECEIVED,
         UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_ON_DAMAGE, UNITHOOK_ON_AURA_APPLY,
         UNITHOOK_ON_AURA_REMOVE}) { }
    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player* player = Owner(caster);
        if (!player || !info || info->SpellFamilyName != 31)
            return;
        if (info->Id == CthunDamage && index == EFFECT_0 && caster->GetEntry() == CthunTentacle)
        {
            double const level = player->GetLevel();
            value *= float(0.0267291844060354 + 0.0048541098014737 * level +
                0.0001859597762293 * level * level);
        }
        for (auto const& row : CultistCoefficients)
            if (row.spell == info->Id && row.effect == index)
            {
                float healing = row.healing;
                if (player->HasAura(300284) && (Named(info, 500711) || Any(info, {808050, 808051, 808052})))
                    healing *= 1 + Amount(300284) / 100.0f;
                float sp = row.sp;
                if (Any(info, {800416, 800413, 808043, 808044, 808045}))
                {
                    float percent = sp * 100.0f;
                    player->ApplySpellMod(info->Id, SPELLMOD_BONUS_MULTIPLIER, percent);
                    sp = percent / 100.0f;
                }
                if (Named(info, 500715) && index == 0 && player->HasAura(681088))
                    value *= 1 + Amount(681088) / 100.0f;
                if (Named(info, 500720) && player->HasAura(803339))
                    sp = .3f;
                value += sp * std::max(0, player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)) +
                         row.ap * player->GetTotalAttackPowerValue(BASE_ATTACK) +
                         healing * std::max(0, player->SpellBaseHealingBonusDone(info->GetSchoolMask())) +
                         row.stamina * player->GetStat(STAT_STAMINA) + row.intellect * player->GetStat(STAT_INTELLECT);
            }
        bool tentacle = caster->GetEntry() == CthunTentacle || caster->GetEntry() == 501464 || caster->GetEntry() == 500465 ||
                        caster->GetEntry() == 50096 || caster->GetEntry() == 500464;
        if (caster != player && tentacle && State(player).summons.count(caster->GetGUID()) && player->HasAura(802048))
            value *= 1 + Amount(802048) / 100.0f;
        value = std::clamp(value, float(INT32_MIN / 2), float(INT32_MAX / 2));
    }
    float Factor(Unit* target, Unit* caster, SpellInfo const* info, bool healing)
    {
        Player* player = Owner(caster);
        if (!player || !info || info->SpellFamilyName != 31 || Derived(info))
            return 1;
        float factor = player->HasAura(Herald) ? 1 + Amount(Herald, 2) / 100.0f : 1;
        if (healing && Any(info, {808050, 808051, 808052}) && player->HasAura(705106))
            factor *= 1 + Amount(705106) / 100.0f;
        if (!healing && Any(info, {808043, 808044, 808045}) && player->HasAura(705107))
            factor *= 1 + Amount(705107) / 100.0f;
        if (!healing && caster != player && State(player).summons.count(caster->GetGUID()) && player->HasAura(802048))
            (void)target;
        bool tentacle = caster != player && State(player).summons.count(caster->GetGUID()) &&
            (caster->GetEntry() == CthunTentacle || caster->GetEntry() == 501464 ||
             caster->GetEntry() == 500465 || caster->GetEntry() == 50096 || caster->GetEntry() == 500464);
        if (!healing && (tentacle || info->Id == Thoughtseize))
            if (Aura* obelisk = player->GetOwnedAura(560322, player->GetGUID()))
                if (AuraEffect* bonus = obelisk->GetEffect(EFFECT_0);
                    bonus && (info->Id == Thoughtseize || player->IsWithinDistInMap(caster, Radius(560322, 0))))
                    factor *= 1 + bonus->GetAmount() / 100.0f;
        return factor;
    }
    void ModifySpellDamageTaken(Unit* target, Unit* caster, int32& damage, SpellInfo const* info) override
    {
        damage = int32(damage * Factor(target, caster, info, false));
    }
    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* caster, uint32& damage, SpellInfo const* info) override
    {
        if (info && info->HasAura(SPELL_AURA_PERIODIC_HEAL))
            return;
        damage = uint32(damage * Factor(target, caster, info, false));
    }
    void ModifyHealReceived(Unit* target, Unit* caster, uint32& amount, SpellInfo const* info) override
    {
        if (target && target->HasAura(520498))
        {
            amount = 0;
            return;
        }
        amount = uint32(amount * Factor(target, caster, info, true));
    }
    void ModifyMeleeDamage(Unit*, Unit* attacker, uint32& damage) override
    {
        Player* player = Owner(attacker);
        if (player == attacker && player && player->HasAura(Herald))
            AddPct(damage, Amount(Herald, 2));
    }
    void OnDamage(Unit*, Unit* victim, uint32& damage) override
    {
        Player* player = Owner(victim);
        if (!player || player != victim)
            return;
        if (player->HasAura(300277) && player->HasAura(681326))
            AddPct(damage, Amount(681326));
        if (player->HasAura(Herald) && player->HasAura(300287))
            AddPct(damage, Amount(300287, 1));
    }
    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (!aura || aura->GetId() != 255275)
            return;
        Player* player = Owner(unit);
        if (!player || player != unit)
            return;
        for (Unit* enemy : Nearby(player, Radius(255276)))
        {
            if (!player->IsValidAttackTarget(enemy))
                continue;
            DispelChargesList dispelList;
            enemy->GetDispellableAuraList(player, (1u << DISPEL_MAGIC), dispelList, aura->GetSpellInfo());
            std::vector<std::tuple<uint32, ObjectGuid, uint8>> toDispel;
            for (auto const& pair : dispelList)
                if (Aura* candidate = pair.first)
                    if (int32 chance = candidate->CalcDispelChance(enemy, true); chance > 0 && roll_chance_i(chance))
                        toDispel.emplace_back(candidate->GetId(), candidate->GetCasterGUID(), pair.second);
            std::vector<uint32> dispelled;
            for (auto const& [spellId, casterGuid, charges] : toDispel)
                if (enemy->GetAura(spellId, casterGuid))
                {
                    enemy->RemoveAurasDueToSpellByDispel(spellId, 255275, casterGuid, player, charges);
                    dispelled.push_back(spellId);
                }
            if (!dispelled.empty())
            {
                WorldPacket data(SMSG_SPELLDISPELLOG, 8 + 8 + 4 + 1 + 4 + dispelled.size() * 5);
                data << enemy->GetPackGUID();
                data << player->GetPackGUID();
                data << uint32(255275);
                data << uint8(0);
                data << uint32(dispelled.size());
                for (uint32 spellId : dispelled)
                    data << uint32(spellId) << uint8(0);
                player->SendMessageToSet(&data, true);
            }
        }
    }
    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode mode) override
    {
        if (mode == AURA_REMOVE_BY_ENEMY_SPELL && application && application->GetBase()->GetId() == 560943)
            if (Player* player = Owner(application->GetBase()->GetCaster()))
                Cast(player, player, 560947);
        if (mode == AURA_REMOVE_BY_EXPIRE && application && application->GetBase()->GetId() == 255275)
            if (Player* player = Owner(unit); player && player == unit && player->IsAlive())
            {
                bool previous = State(player).hourOfTwilightCorruptMind;
                State(player).hourOfTwilightCorruptMind = true;
                for (Unit* enemy : Nearby(player, Radius(255276)))
                    if (player->IsValidAttackTarget(enemy))
                        Cast(player, enemy, 560109);
                State(player).hourOfTwilightCorruptMind = previous;
            }
    }
};
}
void AddSC_AscensionCultistContracts()
{
    new cultist_scaling();
}
