/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionTemplarLibrams.h"
#include "SpellInfo.h"

void ApplyAscensionTemplarLibramContracts(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->Id != 805423 || spellInfo->SpellFamilyName != 25 ||
        spellInfo->SpellFamilyFlags != flag96(0, 0, 2048) ||
        spellInfo->DmgClass != SPELL_DAMAGE_CLASS_MAGIC || spellInfo->SchoolMask != SPELL_SCHOOL_MASK_HOLY ||
        spellInfo->Dispel != DISPEL_MAGIC || spellInfo->Mechanic ||
        spellInfo->Attributes != 65536 || spellInfo->AttributesEx || spellInfo->AttributesEx2 != 524288 ||
        spellInfo->AttributesEx3 || spellInfo->AttributesEx4 != 524288 || spellInfo->AttributesEx5 ||
        spellInfo->AttributesEx6 != 2147483648u || spellInfo->AttributesEx7 ||
        spellInfo->Stances != 134217728 || spellInfo->StancesNot || spellInfo->Targets ||
        spellInfo->TargetCreatureType || spellInfo->RequiresSpellFocus || spellInfo->FacingCasterFlags ||
        spellInfo->CasterAuraState || spellInfo->TargetAuraState || spellInfo->CasterAuraStateNot ||
        spellInfo->TargetAuraStateNot || spellInfo->CasterAuraSpell || spellInfo->TargetAuraSpell ||
        spellInfo->ExcludeCasterAuraSpell || spellInfo->ExcludeTargetAuraSpell ||
        !spellInfo->CastTimeEntry || spellInfo->CastTimeEntry->ID != 1 ||
        spellInfo->GetCategory() != 911 || spellInfo->RecoveryTime != 180000 || spellInfo->CategoryRecoveryTime ||
        spellInfo->StartRecoveryCategory || spellInfo->StartRecoveryTime || spellInfo->InterruptFlags != 8 ||
        spellInfo->AuraInterruptFlags || spellInfo->ChannelInterruptFlags || spellInfo->ProcFlags ||
        spellInfo->ProcChance != 100 || spellInfo->ProcCharges || spellInfo->StackAmount ||
        spellInfo->MaxLevel || spellInfo->BaseLevel != 16 || spellInfo->SpellLevel != 16 ||
        !spellInfo->DurationEntry || spellInfo->DurationEntry->ID != 18 ||
        !spellInfo->RangeEntry || spellInfo->RangeEntry->ID != 1 || spellInfo->Speed ||
        spellInfo->PowerType != POWER_MANA || spellInfo->ManaCost || spellInfo->ManaCostPerlevel ||
        spellInfo->ManaPerSecond || spellInfo->ManaPerSecondPerLevel || spellInfo->ManaCostPercentage ||
        spellInfo->RuneCostID || spellInfo->EquippedItemClass != -1 ||
        spellInfo->EquippedItemSubClassMask != 1024 || spellInfo->EquippedItemInventoryTypeMask ||
        spellInfo->MaxTargetLevel || spellInfo->MaxAffectedTargets || spellInfo->PreventionType != 1 ||
        spellInfo->AreaGroupId)
        return;

    for (uint8 index = EFFECT_0; index <= EFFECT_2; ++index)
    {
        SpellEffectInfo const& effect = spellInfo->Effects[index];
        if (effect.Effect != SPELL_EFFECT_APPLY_AURA || effect.DieSides != 1 ||
            effect.TargetA.GetTarget() != TARGET_UNIT_CASTER || effect.TargetB.GetTarget() ||
            effect.Amplitude || effect.RealPointsPerLevel || effect.PointsPerComboPoint ||
            effect.ValueMultiplier || effect.DamageMultiplier != 1.0f || effect.BonusMultiplier ||
            effect.Mechanic || effect.RadiusEntry || effect.ChainTarget || effect.ItemType ||
            effect.TriggerSpell || effect.SpellClassMask)
            return;
    }

    SpellEffectInfo const& attackPower = spellInfo->Effects[EFFECT_0];
    SpellEffectInfo const& spellDamage = spellInfo->Effects[EFFECT_1];
    SpellEffectInfo& healing = spellInfo->Effects[EFFECT_2];
    if (attackPower.ApplyAuraName != SPELL_AURA_MOD_ATTACK_POWER_OF_STAT_PERCENT ||
        attackPower.BasePoints != 29 || attackPower.MiscValue != STAT_INTELLECT || attackPower.MiscValueB ||
        spellDamage.ApplyAuraName != SPELL_AURA_MOD_SPELL_DAMAGE_OF_STAT_PERCENT ||
        spellDamage.BasePoints != 29 || spellDamage.MiscValue != 126 || spellDamage.MiscValueB != STAT_AGILITY ||
        healing.ApplyAuraName != SPELL_AURA_MOD_SPELL_HEALING_OF_STAT_PERCENT ||
        healing.BasePoints != 24 || healing.MiscValue != 127 || healing.MiscValueB != STAT_AGILITY)
        return;

    healing.MiscValue = STAT_AGILITY;
    healing.BasePoints = 29;
}
