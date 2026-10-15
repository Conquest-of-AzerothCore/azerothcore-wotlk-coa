/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionVenomancer.h"
#include "AscensionVenomancerData.h"
#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include <algorithm>
#include <cmath>
namespace AscensionVenomancer
{
void ApplyContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != 35)
        return;
    uint32 id = info->Id;
    auto dummy = [info](uint8 slot)
    {
        info->Effects[slot].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[slot].TriggerSpell = 0;
    };
    auto aura = [info](uint8 slot, AuraType type, int32 amount, int32 misc)
    {
        auto& effect = info->Effects[slot];
        effect.Effect = SPELL_EFFECT_APPLY_AURA;
        effect.ApplyAuraName = type;
        effect.BasePoints = amount;
        effect.DieSides = 0;
        effect.MiscValue = misc;
        effect.TriggerSpell = 0;
        effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        effect.TargetB = SpellImplicitTargetInfo();
    };
    for (auto list : {std::pair(VenomancerEvents,std::size(VenomancerEvents)),
                     std::pair(VenomancerDrivers,std::size(VenomancerDrivers)),
                     std::pair(VenomancerFinite,std::size(VenomancerFinite))})
        for (size_t n = 0; n < list.second; ++n)
            if (list.first[n] == id)
            {
                for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
                    if (info->Effects[slot].ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL ||
                        info->Effects[slot].ApplyAuraName == 354)
                        dummy(slot);
                info->ProcFlags = info->ProcCharges = 0;
            }
    for (uint32 copy : VenomancerCopies)
        if (id == copy)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            if (id != 504869)
            {
                info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
                info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
                info->AscensionInheritsResolvedAmount = true;
            }
            bool heal = id == 707594 || id == 504803 || id == 808084;
            info->Effects[0].TargetA = SpellImplicitTargetInfo(heal ? TARGET_UNIT_TARGET_ALLY : TARGET_UNIT_TARGET_ENEMY);
            info->Effects[0].TargetB = SpellImplicitTargetInfo();
        }
    if (id == 504796 || id == 504803)
        info->Effects[1].Effect = 0;
    if (id == Brood)
        for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
            dummy(slot);
    if (id == Exposed)
        info->Effects[2].Effect = 0;
    if (id == 805102)
        info->Effects[0].Effect = SPELL_EFFECT_DUMMY;
    if (id == 504705)
    {
        info->Effects[2].Effect = 0;
        info->Effects[2].TriggerSpell = 0;
    }
    if (id == 704264)
        dummy(0);
    if (id == 803196 || id == 803192 || id == 800910 || id == 681056 || id == 681417 || id == 706453 ||
        id == 707191 || id == 707658 || id == 803207)
        for (auto& effect : info->Effects)
            if (effect.Effect)
                effect.Effect = SPELL_EFFECT_DUMMY;
    if (id == 800892)
    {
        info->Effects[1].Effect = SPELL_EFFECT_DUMMY;
        dummy(2);
        info->Effects[2].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
    }
    if (id == 803206)
    {
        info->Effects[1].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[1].TriggerSpell = 0;
    }
    if (Named(info,804983))
    {
        info->Effects[2].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[2].Amplitude = 10000;
        info->Effects[2].TriggerSpell = 0;
    }
    if (id == 705970)
    {
        aura(0,SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE,15,-1);
        aura(1,SPELL_AURA_MOD_RATING,3,224);
        dummy(2);
    }
    constexpr uint32 EmpoweredExoskeleton = 804993;
    constexpr uint32 StingingChitin = 705977;
    constexpr uint32 RapidInjection = 705989;
    if (id == EmpoweredExoskeleton)
        info->Effects[1].MiscValue = SPELLMOD_RADIUS;
    if (id == StingingChitin || id == RapidInjection)
        info->Attributes |= SPELL_ATTR0_PASSIVE;
    if (id == 803216)
        info->Effects[1].ApplyAuraName = SPELL_AURA_230;
    if (id == 805139)
    {
        info->CasterAuraSpell = Beetle;
        dummy(1);
    }
    if (id == 804968)
        info->Stances = 0;
    if (id == 680800)
        dummy(0);
    if (id == 706035)
        dummy(1);
    if (id == 631226)
        dummy(1);
    if (id == 504737)
    {
        info->Effects[0].Effect = 0;
        info->ProcCharges = 2;
    }
    if (id == 505203)
        info->ProcCharges = 5;
    if (id == 808083)
        info->ProcCharges = 12;
    if (id == 806602)
    {
        dummy(0);
        dummy(1);
    }
    if (id == 706032)
        info->Effects[1].Effect = 0;
    if (id == 681321)
        info->Effects[0].Effect = 0;
    if (id == 706038 || id == 804984 || id == 503852 || id == 504704 || id == 574353 || id == 706015)
        dummy(0);
    if (id == 805104)
    {
        dummy(0);
        dummy(2);
    }
    if (id == 800293)
        info->Effects[2].SpellClassMask = flag96(0,8388608,0);
    if (id == 805933)
        dummy(1);
    if (id == 707563)
        info->Effects[1].ApplyAuraName = SPELL_AURA_MOD_HEALING_DONE_PERCENT;
    if (id == 300974)
        info->Effects[0].MiscValue = SPELL_SCHOOL_MASK_ALL;
    if (id == 560194 || id == 561349)
    {
        info->Effects[0].SpellClassMask = flag96(0,16777216,0);
        dummy(1);
    }
    if (id == 300685 || id == 300684)
        for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
            if (info->Effects[slot].MiscValue == 40 || info->Effects[slot].MiscValue == 41)
                dummy(slot);
    if (id == 706009 || id == 706010)
        for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
            if (info->Effects[slot].Effect)
                dummy(slot);
    if (id == 803210)
        dummy(1);
    if (id == 706015)
        dummy(1);
    if (id == 803211)
        dummy(0);
    if (id == 804971 || id == 804687 || id == 806454 || id == 706017)
        dummy(id == 804687 ? 1 : 0);
    if (id == 805931)
    {
        info->Effects[0].MiscValue = SPELL_SCHOOL_MASK_NORMAL;
        info->Effects[1].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[1].TriggerSpell = 0;
        dummy(2);
    }
    if (id == 800878)
    {
        dummy(1);
        info->Effects[1].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
    }
    if (id == 707234)
    {
        dummy(2);
        info->Effects[2].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
    }
    if (id == 681291)
    {
        dummy(1);
        info->Effects[1].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
    }
    if (id == 804978)
    {
        dummy(1);
        dummy(2);
    }
    if (Any(info,{800871,804977,706962}))
    {
        auto& snapshot = info->Effects[2];
        snapshot.Effect = SPELL_EFFECT_APPLY_AURA;
        snapshot.ApplyAuraName = SPELL_AURA_DUMMY;
        snapshot.BasePoints = snapshot.DieSides = 0;
        snapshot.TargetA = info->Effects[0].TargetA;
        snapshot.TargetB = info->Effects[0].TargetB;
    }
    if (id == 706456)
        for (uint8 slot : {uint8(1),uint8(2)})
        {
            aura(slot,SPELL_AURA_DUMMY,0,0);
            info->Effects[slot].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        }
    if (id == 572058)
        info->Effects[0].ApplyAuraName = SPELL_AURA_MOD_MELEE_HASTE;
    if (id == 805431)
    {
        info->Effects[1].BasePoints = 30;
        info->Effects[1].DieSides = 0;
        info->Effects[2].Effect = 0;
    }
    if (id == 805932)
        info->Effects[1].Effect = 0;
    if (id == 680764)
        info->Effects[1].Effect = 0;
    if (id == 805774)
    {
        info->Effects[0].Effect = SPELL_EFFECT_DUMMY;
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
    }
    if (id == 560281)
        info->Effects[1].ApplyAuraName = SPELL_AURA_ABILITY_PERIODIC_CRIT;
    if (id == 503990)
    {
        aura(0,SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN,-10,SPELL_SCHOOL_MASK_HOLY);
        info->DurationEntry = sSpellDurationStore.LookupEntry(1);
    }
    if (id == 707358)
        info->DurationEntry = sSpellDurationStore.LookupEntry(35);
    if (id == 800921)
    {
        info->CasterAuraSpell = Skulk;
        aura(0,SPELL_AURA_SCHOOL_IMMUNITY,0,SPELL_SCHOOL_MASK_ALL);
        info->Effects[1].Effect = SPELL_EFFECT_DUMMY;
    }
    if (id == 804003)
        for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
            dummy(slot);
    if (id == 806154)
    {
        dummy(2);
        info->Effects[2].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[2].Amplitude = 500;
    }
    if (id == 806217)
    {
        info->Effects[0].Effect = SPELL_EFFECT_DUMMY;
        info->AttributesEx5 |= SPELL_ATTR5_ALLOW_WHILE_STUNNED;
    }
    if (id == 803537)
        info->AttributesEx5 |= SPELL_ATTR5_ALLOW_WHILE_STUNNED;
    if (id == 704235)
        info->Effects[2].Effect = SPELL_EFFECT_DUMMY;
    if (Named(info,800870))
    {
        info->Effects[2].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[2].TriggerSpell = 0;
    }
    if (Named(info,800901))
        for (uint8 slot : {uint8(1),uint8(2)})
        {
            aura(slot,SPELL_AURA_MOD_DEBUFF_RESISTANCE,20,slot == 1 ? DISPEL_POISON : DISPEL_CURSE);
            info->Effects[slot].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
        }
    if (Named(info,706962))
    {
        info->Effects[1].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[1].TriggerSpell = 0;
    }
    if (id == 807153)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
    }
    if (Named(info,504342))
        info->Effects[1].Effect = SPELL_EFFECT_DUMMY;
    if (id == 680767)
        for (auto& effect : info->Effects)
            if (effect.Effect == 177)
                effect.Effect = SPELL_EFFECT_DUMMY;
    if (id == 800848)
        info->StackAmount = 3;
    if (id == 706014)
        for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
            dummy(slot);
    if (id == 803724)
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
        info->Effects[1].Effect = info->Effects[2].Effect = 0;
    }
    if (id == 807611)
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
        info->Effects[1].Effect = 0;
    }
    if (id == 808082)
        dummy(1);
    if (id == 504867)
    {
        info->Effects[0].TriggerSpell = 0;
        aura(1,SPELL_AURA_DUMMY,0,0);
        info->Effects[1].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
    }
    if (id == 503989 || (id >= 503990 && id <= 503994))
        info->StackAmount = 0;
    if (id == 706037)
        aura(2, SPELL_AURA_MOD_SPELL_CRIT_CHANCE_SCHOOL, 1, SPELL_SCHOOL_MASK_SHADOW | SPELL_SCHOOL_MASK_NATURE);
    info->_InitializeExplicitTargetMask();
}
}
namespace
{
using namespace AscensionVenomancer;
class venomancer_scaling : public UnitScript
{
public:
    venomancer_scaling() : UnitScript("venomancer_scaling",true,
        {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE,UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
         UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK,UNITHOOK_ON_DAMAGE,
         UNITHOOK_ON_BEFORE_ROLL_MELEE_OUTCOME_AGAINST,UNITHOOK_CAN_UNIT_ATTACK}) { }
    bool CanUnitAttack(Unit const* attacker, Unit const* target, SpellInfo const* info) override
    {
        if (attacker && attacker->HasAura(800921))
            return false;
        return (info && info->IsAffectingArea()) || !CrossesLair(attacker,target);
    }
    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player* player = Owner(caster);
        if (!player || !info || info->SpellFamilyName != 35 || Derived(info) || !std::isfinite(value))
            return;
        for (uint32 curved : {503929,504543,503925,503857,705985,570208,707234,807342,807611})
            if (info->Id == curved && (index == 0 || (info->Id == 707234 && index == 1)))
            {
                double level = player->GetLevel();
                value *= float(.0267291844060354 + .0048541098014737 * level + .0001859597762293 * level * level);
            }
        for (auto const& row : VenomancerCoefficients)
            if (row.spell == info->Id && row.effect == index)
            {
                auto school = row.school ? SpellSchoolMask(row.school) : info->GetSchoolMask();
                float sp = row.sp, healing = row.healing;
                if (Named(info,706962) && player->HasAura(706038))
                    sp *= 1 + Amount(706038) / 100.0f;
                if (Named(info,800946))
                    if (AuraEffect const* talent = player->GetAuraEffectOfRankedSpell(560194,EFFECT_1))
                        sp *= 1 + talent->GetAmount() / 100.0f;
                if (info->Id == 504543)
                    sp = State(player).mushroomCoefficient;
                if (info->Id == 560202 || Named(info,800899) || Named(info,800901))
                    if (AuraEffect const* talent = player->GetAuraEffectOfRankedSpell(300685,EFFECT_0))
                        healing *= 1 + talent->GetAmount() / 100.0f;
                value += sp * std::max(0,player->SpellBaseDamageBonusDone(school)) +
                    row.ap * player->GetTotalAttackPowerValue(BASE_ATTACK) +
                    healing * std::max(0,player->SpellBaseHealingBonusDone(info->GetSchoolMask()));
            }
        if (caster != player && State(player).summons.count(caster->GetGUID()) &&
            player->HasAura(704264) && player->HasAura(Beetle) && player->HasAura(560247))
            AddPct(value,Amount(704264));
        value = std::clamp(value,float(INT32_MIN / 2),float(INT32_MAX / 2));
    }
    float DamageFactor(Player* player, Unit* target, SpellInfo const* info, bool periodic)
    {
        if (!target || !info || info->SpellFamilyName != 35 || Derived(info))
            return 1;
        float factor = 1;
        if (player->HasAura(805104) && player->HasAura(Spider) && player->GetDistance(target) > 10)
            factor *= 1 + Amount(805104) / 100.0f;
        if (Named(info,706962) && player->HasAura(805104) && player->HasAura(Spider))
            factor *= 1 + Amount(805104,2) / 100.0f;
        if (periodic)
        {
            if (auto* effect = target->GetAuraEffect(804971,EFFECT_0,player->GetGUID()))
                factor *= 1 + effect->GetAmount() / 100.0f;
            if (player->HasAura(574353) && Any(info,{800871,804977}) && target->GetHealthPct() > 75)
                factor *= 1 + Amount(574353) / 100.0f;
        }
        if (player->HasAura(804984) && Poison(info) && target->GetHealthPct() > 50)
            factor *= 1 + Amount(804984) / 100.0f;
        if (player->HasAura(805933) && Named(info,804961) && target->GetHealthPct() < 35)
            factor *= 1 + Amount(805933,1) / 100.0f;
        return factor;
    }
    void ModifySpellDamageTaken(Unit* target, Unit* caster, int32& damage, SpellInfo const* info) override
    {
        if (Player* player = Owner(caster); player && player == caster)
            damage = int32(damage * DamageFactor(player,target,info,false));
    }
    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* caster, uint32& value, SpellInfo const* info) override
    {
        if (!target || !info || Derived(info))
            return;
        bool healing = info->HasAura(SPELL_AURA_PERIODIC_HEAL);
        if (!healing && (info->SchoolMask & SPELL_SCHOOL_MASK_MAGIC))
            if (Player* defender = Owner(target); defender == target && defender && defender->HasAura(804687))
                value -= CalculatePct(value,std::abs(Amount(804687,1)));
        Player* player = Owner(caster);
        if (!player)
            return;
        if (healing)
        {
            value = uint32(value * HealingFactor(player,target,info));
            for (uint32 id : {806454,706017})
                if (auto* effect = target->GetAuraEffect(id,EFFECT_0,player->GetGUID()))
                    AddPct(value,effect->GetAmount());
            if (Aura* vigil = target->GetAura(505203,player->GetGUID()); vigil && value)
            {
                AddPct(value,Amount(505203));
                if (vigil->GetCharges() > 1)
                    vigil->SetCharges(vigil->GetCharges()-1);
                else
                    vigil->Remove();
            }
        }
        else
            value = uint32(value * DamageFactor(player,target,info,true));
    }
    void OnDamage(Unit*, Unit* target, uint32& damage) override
    {
        Player* player = Owner(target);
        if (player && player == target && player->HasAura(803210) && !player->HasAura(803211))
            damage -= CalculatePct(damage,std::abs(Amount(803210,1)));
    }
    void OnBeforeRollMeleeOutcomeAgainst(Unit const* attacker, Unit const*, WeaponAttackType, int32&, int32&,
        int32&, int32&, int32&, int32&, int32& dodge, int32& parry, int32&) override
    {
        Player* player = Owner(attacker);
        if (player == attacker && player && player->HasAura(705966) && (player->HasAura(Spider) || player->HasAura(Beetle)))
            dodge = parry = 0;
    }
};
}
void AddSC_AscensionVenomancerContracts()
{
    new venomancer_scaling();
}
