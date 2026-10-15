/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCultist.h"
#include "AscensionCultistData.h"
#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include <algorithm>
namespace AscensionCultist
{
void ApplyContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != 31)
        return;
    uint32 id = info->Id;
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
    if (Named(info, 804152))
        info->CasterAuraSpell = 680602;
    if (Any(info, {805116, 804152}))
        info->AscensionIgnoreAbsorb = Named(info, 805116);
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
            info->AuraInterruptFlags = 0;
    if (Named(info, 500714))
        info->Effects[1].Effect = SPELL_EFFECT_DUMMY;
    if (id == BlackBlood)
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
    }
    if (id == 802048)
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
        for (auto& effect : info->Effects)
            if (effect.ApplyAuraName == SPELL_AURA_MOD_BLOCK_CRIT_CHANCE)
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
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
    if (id == 704476)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
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
         UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_ON_DAMAGE}) { }
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
};
}
void AddSC_AscensionCultistContracts()
{
    new cultist_scaling();
}
