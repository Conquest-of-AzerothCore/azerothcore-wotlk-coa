/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTinker.h"
#include "AscensionTinkerData.h"
#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include <algorithm>
#include <cmath>
namespace AscensionTinker
{
uint32 SummonVulnerability(Player* player, Unit* attacker, Unit* target)
{
    if (!player || !target || !attacker || !attacker->IsCreature() || !Owned(player,attacker))
        return 0;
    uint32 percent = 0;
    for (auto const& pair : target->GetAppliedAuras())
        if (Aura* aura = pair.second->GetBase(); aura->GetId() == 805657 &&
            aura->GetScriptValue(805657) == player->GetGUID().GetRawValue())
            percent = std::max(percent,uint32(std::max(0,Amount(805657,1))));
    return percent;
}
void ApplyContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != 34)
        return;
    uint32 id = info->Id;
    if (info->ExcludeTargetAuraSpell == 560711)
        info->ExcludeTargetAuraSpell = 0;
    if (id == 707495)
    {
        info->Effects[0].Effect = SPELL_EFFECT_APPLY_AURA;
        info->Effects[0].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
        info->Effects[0].BasePoints = 0;
        info->Effects[0].DieSides = 0;
        info->Effects[1].Effect = info->Effects[2].Effect = 0;
        info->SpellFamilyFlags = flag96();
        info->StackAmount = 1;
        info->DurationEntry = sSpellDurationStore.LookupEntry(21);
        info->Attributes |= SPELL_ATTR0_DO_NOT_DISPLAY;
    }
    auto dummy = [info](uint8 slot)
    {
        info->Effects[slot].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[slot].TriggerSpell = 0;
        if (info->Effects[slot].Effect == 190)
            info->Effects[slot].Effect = SPELL_EFFECT_APPLY_AURA;
    };
    if (id == 807293)
    {
        info->Effects[EFFECT_0].Effect = SPELL_EFFECT_APPLY_AURA;
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
    }
    for (auto list : {std::pair(TinkerEvents,std::size(TinkerEvents)),
                     std::pair(TinkerDrivers,std::size(TinkerDrivers)),
                     std::pair(TinkerFinite,std::size(TinkerFinite))})
        for (size_t n = 0; n < list.second; ++n)
            if (list.first[n] == id)
            {
                for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
                    if (info->Effects[slot].ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL ||
                        info->Effects[slot].ApplyAuraName == 354)
                        dummy(slot);
                info->ProcFlags = info->ProcCharges = 0;
            }
    for (uint32 finite : TinkerFinite)
        if (id == finite)
        {
            info->ProcCharges = id == 707261 ? 2 : 1;
            info->StackAmount = 1;
        }
    if (id == 707261)
        info->Effects[1].SpellClassMask = flag96(16,0,0);
    if (id == 707272)
        info->Effects[0].Effect = SPELL_EFFECT_DUMMY;
    if (id == 504594)
    {
        info->SpellFamilyFlags |= flag96(0,536870912,0);
        info->MaxCharges = 2;
        info->ChargeRecoveryTime = 8000;
        info->ChargeRecoveryKey = 504527;
        info->ChargeCategoryId = 323;
        if (auto* base = sSpellMgr->GetSpellInfo(504527))
        {
            info->ManaCost = base->ManaCost;
            info->ManaCostPercentage = base->ManaCostPercentage;
        }
    }
    if (Named(info,500232) || id == 504667 || id == 500612)
    {
        info->Effects[1].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[1].TriggerSpell = 0;
        if (id == 504667 || id == 500612)
        {
            info->Effects[1].BasePoints = info->Effects[0].BasePoints;
            info->Effects[1].DieSides = info->Effects[0].DieSides;
            info->Effects[1].RealPointsPerLevel = info->Effects[0].RealPointsPerLevel;
            info->Effects[0].Effect = SPELL_EFFECT_DUMMY;
        }
    }
    if (id == 806780)
    {
        dummy(0);
        info->ProcFlags = 0;
    }
    if (Named(info,801709))
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
    if (id == 573054)
    {
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->Effects[EFFECT_0].TargetB = SpellImplicitTargetInfo();
    }
    if (id == 524935)
    {
        info->Effects[0].Effect = SPELL_EFFECT_APPLY_AURA;
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
        info->DurationEntry = sSpellDurationStore.LookupEntry(21);
    }
    if (Named(info,504519))
        info->Effects[1].Effect = 0;
    if (id == 560757)
        for (auto& effect : info->Effects)
            if (effect.Effect)
            {
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
                effect.TargetB = SpellImplicitTargetInfo();
            }
    if (id == 801384)
    {
        info->Effects[2].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[2].TriggerSpell = 0;
    }
    if (id == 807635)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
        dummy(1);
    }
    if (id == 653232)
        info->Effects[0].MiscValue = 21003;
    if (id == 680999)
    {
        info->Effects[0].MiscValue = SPELL_SCHOOL_MASK_NORMAL;
        info->DurationEntry = sSpellDurationStore.LookupEntry(21);
    }
    if (id == 681516 && info->Effects[EFFECT_1].TargetA.GetTarget() == TARGET_UNIT_PET)
    {
        info->Effects[EFFECT_1].TargetA = SpellImplicitTargetInfo();
        info->Effects[EFFECT_1].TargetB = SpellImplicitTargetInfo(TARGET_UNIT_PET);
    }
    if (id == 801744)
        for (auto& effect : info->Effects)
            if (effect.Effect)
                effect.Effect = SPELL_EFFECT_DUMMY;
    if (id == 707244 || id == 707256)
        for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
            if (info->Effects[slot].Effect)
                dummy(slot);
    if (Named(info,500232))
        dummy(2);
    if (Named(info,805351))
        info->Effects[2].Effect = 0;
    if (id == 807966 || id == 704475)
        info->Effects[0].SpellClassMask |= flag96(1073741824,1073741824,2684354560u);
    if (id == 805657)
        dummy(1);
    if (id == 707290)
    {
        dummy(1);
        dummy(2);
    }
    if (id == 805315)
    {
        dummy(0);
        info->Effects[1].ApplyAuraName = SPELL_AURA_MOD_HEALING_PCT;
        info->Effects[1].BasePoints = -3;
        info->Effects[1].DieSides = 0;
        info->Effects[1].TriggerSpell = 0;
        info->Effects[1].MiscValue = SPELL_SCHOOL_MASK_ALL;
        dummy(2);
    }
    if (id == 707278 || id == 578323 || id == 805519 || id == 706698)
        for (auto& effect : info->Effects)
        {
            if (!effect.Effect)
                continue;
            if (effect.Effect == 190)
                effect.Effect = SPELL_EFFECT_APPLY_AURA;
            effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
            effect.TargetB = SpellImplicitTargetInfo();
        }
    if (id == 805519 || id == 706698)
    {
        dummy(0);
        info->Effects[0].Amplitude = 0;
        info->ProcFlags = 0;
    }
    if (id == 706698)
        info->DurationEntry = sSpellDurationStore.LookupEntry(32);
    if (id == 808008)
    {
        info->Effects[0].Effect = SPELL_EFFECT_APPLY_AURA;
        info->Effects[0].ApplyAuraName = SPELL_AURA_MOD_HEALING_DONE_PERCENT;
        info->Effects[1].ApplyAuraName = SPELL_AURA_MOD_DAMAGE_PERCENT_DONE;
        for (auto& effect : info->Effects)
            effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
    }
    if (id == 706692)
        info->Effects[1].Effect = 0;
    if (id == 705792)
    {
        info->Effects[0].Effect = 0;
        info->Effects[1].ApplyAuraName = SPELL_AURA_MOD_CRIT_PCT;
        info->Effects[2].ApplyAuraName = SPELL_AURA_ASCENSION_MOD_HIT_CHANCE_ALL_PCT;
    }
    if (id == 520686 && info->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
        info->Effects[EFFECT_1].MiscValue == SPELLMOD_CRIT_DAMAGE_BONUS)
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
    if (id == 560742)
    {
        info->Effects[1].ApplyAuraName = SPELL_AURA_MOD_HIT_CHANCE;
        info->Effects[2].ApplyAuraName = SPELL_AURA_MOD_SPELL_HIT_CHANCE;
        for (uint8 slot : {uint8(1),uint8(2)})
        {
            info->Effects[slot].BasePoints = 100;
            info->Effects[slot].DieSides = 0;
        }
    }
    if (id == 503535 || id == 504822 || id == 560786 || id == 561267 || id == 560709 || id == 560710 ||
        id == 706829 || id == 560746 || id == 681513 || id == 705847 || id == 706255 ||
        id == 560711 || id == 705787 || id == 573269 || id == 578323 || id == 560774 ||
        id == 707698 || id == 560742 || id == 705792)
        for (auto& effect : info->Effects)
            if (effect.Effect)
            {
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
                effect.TargetB = SpellImplicitTargetInfo();
            }
    if (id == 801256 || (id >= 803804 && id <= 803808))
        for (auto& effect : info->Effects)
            if (effect.Effect == SPELL_EFFECT_PERSISTENT_AREA_AURA)
            {
                effect.Effect = SPELL_EFFECT_APPLY_AURA;
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
                effect.TargetB = SpellImplicitTargetInfo();
            }
    if (id == 560709 || id == 560710)
        info->Effects[1].Effect = 0;
    if (id == 561267)
        info->Effects[1].Effect = 0;
    if (id == 524903)
        info->Effects[1].Effect = 0;
    if (id == 578335)
        info->Attributes |= SPELL_ATTR0_NO_IMMUNITIES;
    if (id == 801982 || id == 802477 || id == 500601 || id == 806074 || id == 706648 || id == 802336)
    {
        info->Speed = 0;
        info->Attributes |= SPELL_ATTR0_ALLOW_CAST_WHILE_DEAD;
    }
    if (id == 801982 || id == 802477 || id == 500601 || id == 806074 || id == 706648 ||
        id == 802336 || id == 712680 || id == 561269)
        for (auto& effect : info->Effects)
            if (effect.Effect)
            {
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
                effect.TargetB = SpellImplicitTargetInfo();
            }
    for (uint32 copy : TinkerCopies)
        if (id == copy)
        {
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AscensionInheritsResolvedAmount = true;
        }
    info->_InitializeExplicitTargetMask();
}
void ApplyBeaconChargePool(SpellInfo* info)
{
    if (!info)
        return;
    for (uint32 beacon : TinkerBeacons)
        if (info->Id == beacon)
            info->ChargeRecoveryKey = TinkerBeaconChargeRoot;
}
}
namespace
{
using namespace AscensionTinker;
class tinker_scaling : public UnitScript
{
public:
    tinker_scaling() : UnitScript("tinker_scaling",true,
        {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE,UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,UNITHOOK_MODIFY_MELEE_DAMAGE}) { }
    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player* player = Owner(caster);
        if (!player || !info || info->SpellFamilyName != 34 || Derived(info) || !std::isfinite(value))
            return;
        for (auto const& row : TinkerCoefficients)
            if (row.spell == info->Id && row.effect == index)
            {
                if (row.curve)
                {
                    double level = player->GetLevel();
                    value *= float(.0267291844060354 + .0048541098014737 * level + .0001859597762293 * level * level);
                }
                auto school = row.school ? SpellSchoolMask(row.school) : info->GetSchoolMask();
                value += row.sp * std::max(0,player->SpellBaseDamageBonusDone(school)) +
                    row.ap * player->GetTotalAttackPowerValue(BASE_ATTACK) +
                    row.rap * player->GetTotalAttackPowerValue(RANGED_ATTACK) +
                    row.healing * std::max(0,player->SpellBaseHealingBonusDone(info->GetSchoolMask()));
            }
        value = std::clamp(value,float(INT32_MIN / 2),float(INT32_MAX / 2));
    }
    void ModifyMeleeDamage(Unit* target, Unit* caster, uint32& damage) override
    {
        AddPct(damage,SummonVulnerability(Owner(caster),caster,target));
    }
    void ModifySpellDamageTaken(Unit* target, Unit* caster, int32& damage, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (!player || !target || !info || Derived(info) || info->AscensionInheritsResolvedAmount)
            return;
        AddPct(damage,SummonVulnerability(player,caster,target));
        if (Aura* oil = target->GetAura(707290,player->GetGUID()); oil &&
            (caster == player || Owned(player,caster)))
        {
            if (info->GetSchoolMask() & SPELL_SCHOOL_MASK_FIRE)
                AddPct(damage,Amount(707290,1));
            if ((info->SpellFamilyFlags & flag96(65536,0,0)) || info->Id == 500601)
                AddPct(damage,Amount(707290,2));
        }
        if (caster == player && (info->GetSchoolMask() & SPELL_SCHOOL_MASK_FIRE))
            if (Aura* aura = target->GetAura(Napalm,player->GetGUID()))
                AddPct(damage,Amount(Napalm) * aura->GetStackAmount());
        if (player->HasAura(707256) && (Shot(info) || info->Id == 500601))
            if (Aura* aura = target->GetAura(Napalm,player->GetGUID()))
                AddPct(damage,Amount(707256) * aura->GetStackAmount());
    }
};
}
void AddSC_AscensionTinkerContracts()
{
    new tinker_scaling();
}
