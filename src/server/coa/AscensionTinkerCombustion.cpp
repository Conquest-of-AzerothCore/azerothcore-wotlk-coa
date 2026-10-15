/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionTinkerCombustion.h"
#include "SpellInfo.h"

void ApplyAscensionTinkerCombustionContracts(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->Id != 801388 || spellInfo->SpellFamilyName != 34 ||
        spellInfo->SpellFamilyFlags != flag96(0, 4096, 16384) ||
        spellInfo->DmgClass != SPELL_DAMAGE_CLASS_RANGED || spellInfo->SchoolMask != SPELL_SCHOOL_MASK_FIRE ||
        spellInfo->EquippedItemClass != -1 || spellInfo->EquippedItemSubClassMask ||
        spellInfo->EquippedItemInventoryTypeMask || spellInfo->Attributes || spellInfo->AttributesEx ||
        spellInfo->AttributesEx2 || spellInfo->AttributesEx3 != SPELL_ATTR3_NOT_A_PROC ||
        spellInfo->AttributesEx4 || spellInfo->AttributesEx5 || spellInfo->AttributesEx6 || spellInfo->AttributesEx7 ||
        spellInfo->MaxLevel || spellInfo->BaseLevel != 13 || spellInfo->SpellLevel != 13 ||
        spellInfo->Speed != 30.0f || spellInfo->StackAmount || spellInfo->DurationEntry ||
        !spellInfo->RangeEntry || spellInfo->RangeEntry->ID != 6 || spellInfo->GetCategory() ||
        spellInfo->RecoveryTime || spellInfo->CategoryRecoveryTime || spellInfo->ProcFlags ||
        spellInfo->ProcChance != 101 || spellInfo->ProcCharges)
        return;

    for (uint8 index = EFFECT_0; index <= EFFECT_2; ++index)
    {
        SpellEffectInfo const& effect = spellInfo->Effects[index];
        if (effect.ApplyAuraName || effect.Amplitude || effect.RealPointsPerLevel ||
            effect.PointsPerComboPoint || effect.BonusMultiplier || effect.ValueMultiplier ||
            effect.DamageMultiplier != 1.0f || effect.MiscValue || effect.MiscValueB ||
            effect.Mechanic || effect.ChainTarget || effect.ItemType || effect.TriggerSpell || effect.SpellClassMask)
            return;

        if (index == EFFECT_0)
        {
            if (effect.Effect != SPELL_EFFECT_SCHOOL_DAMAGE || effect.BasePoints || effect.DieSides != 1 ||
                effect.TargetA.GetTarget() != TARGET_DEST_TARGET_ENEMY ||
                effect.TargetB.GetTarget() != TARGET_UNIT_DEST_AREA_ENEMY ||
                !effect.RadiusEntry || effect.RadiusEntry->ID != 14)
                return;
        }
        else if (effect.Effect || effect.TargetA.GetTarget() || effect.TargetB.GetTarget() || effect.RadiusEntry ||
            effect.BasePoints != (index == EFFECT_1 ? 0 : -1) || effect.DieSides != (index == EFFECT_1 ? 0 : 1))
            return;
    }

    spellInfo->UseRangedAttackPowerForDamage = true;
}
