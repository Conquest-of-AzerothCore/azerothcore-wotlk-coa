/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionHealingStatSelectors.h"
#include "SpellInfo.h"

#include <array>

namespace
{
struct ExpectedEffect
{
    uint32 Effect;
    uint32 Aura;
    int32 BasePoints;
    int32 DieSides;
    int32 MiscValue;
    int32 MiscValueB;
    uint32 TargetA;
    uint32 TargetB;
    float BonusMultiplier;
    uint32 ChainTarget;
};

struct ExpectedSpell
{
    uint32 Id;
    uint32 Family;
    uint32 Category;
    uint32 ProcChance;
    uint32 BaseLevel;
    uint32 SpellLevel;
    uint32 PowerType;
    uint32 DamageClass;
    uint32 SchoolMask;
    uint8 HealingEffect;
    int32 HealingStat;
    std::array<uint32, 8> Attributes;
    std::array<ExpectedEffect, 3> Effects;
};

constexpr std::array<ExpectedSpell, 9> ExpectedSpells = {{
    {560280, 19, 0, 101, 0, 0, 0, 0, 1, 0, 4, {320, 1024, 4, 268435456, 0, 0, 0, 0},
        {{{6, 175, 39, 1, 127, 4, 1, 0, 0.0f, 0},
          {6, 219, 99, 1, 4, 0, 1, 0, 0.0f, 0},
          {0, 0, -1, 1, 0, 0, 0, 0, 0.0f, 0}}}},
    {706598, 26, 0, 101, 0, 0, 0, 0, 1, 0, 4, {448, 0, 0, 0, 0, 0, 0, 0},
        {{{6, 175, 24, 1, 127, 4, 1, 0, 0.0f, 0},
          {6, 174, 24, 1, 127, 4, 1, 0, 0.0f, 0},
          {6, 220, 3, 1, 224, 4, 1, 0, 0.0f, 0}}}},
    {707864, 26, 0, 101, 0, 0, 0, 0, 1, 0, 4, {448, 0, 0, 0, 0, 0, 0, 0},
        {{{6, 175, 49, 1, 127, 4, 1, 0, 0.0f, 0},
          {6, 174, 49, 1, 127, 4, 1, 0, 0.0f, 0},
          {6, 220, 7, 1, 224, 4, 1, 0, 0.0f, 0}}}},
    {560283, 28, 0, 101, 0, 0, 0, 0, 1, 0, 4, {448, 1024, 4, 268435456, 0, 0, 0, 0},
        {{{6, 175, 49, 1, 127, 4, 1, 0, 0.0f, 0},
          {0, 0, 0, 0, 0, 0, 0, 0, 0.0f, 0},
          {0, 0, -1, 1, 0, 0, 0, 0, 0.0f, 0}}}},
    {560383, 28, 0, 101, 0, 0, 0, 0, 1, 0, 4, {192, 0, 0, 0, 0, 0, 0, 0},
        {{{6, 175, 24, 1, 127, 4, 1, 0, 0.0f, 0},
          {0, 0, 0, 0, 0, 0, 0, 0, 0.0f, 0},
          {0, 0, -1, 1, 0, 0, 0, 0, 0.0f, 0}}}},
    {561159, 33, 0, 100, 0, 40, 0, 0, 1, 2, 0, {320, 1024, 4, 268435456, 0, 0, 0, 0},
        {{{6, 55, -1, 1, 0, 0, 1, 0, 0.0f, 1},
          {6, 174, 99, 1, 126, 0, 1, 0, 0.0f, 1},
          {6, 175, 99, 1, 126, 0, 1, 0, 0.0f, 1}}}},
    {704910, 33, 0, 100, 20, 20, 0, 0, 2, 0, 3, {448, 268435456, 0, 0, 0, 0, 128, 0},
        {{{6, 175, 14, 1, 126, 3, 0, 0, 0.0f, 0},
          {6, 220, 24, 1, 524288, 3, 1, 0, 0.0f, 1},
          {0, 0, -1, 1, 0, 0, 0, 0, 0.0f, 1}}}},
    {705802, 34, 100, 0, 0, 0, 3, 1, 1, 0, 3, {320, 0, 524288, 0, 524288, 0, 0, 0},
        {{{6, 175, 19, 1, 127, 3, 1, 0, 0.123000003f, 0},
          {6, 220, 14, 1, 1792, 3, 1, 0, 0.0f, 0},
          {0, 0, -1, 1, 0, 0, 0, 0, 0.0f, 0}}}},
    {706211, 35, 0, 101, 0, 0, 0, 0, 1, 1, 3, {64, 0, 0, 0, 0, 0, 0, 0},
        {{{6, 220, 19, 1, 1024, 3, 1, 0, 0.0f, 0},
          {6, 175, 19, 1, 127, 3, 1, 0, 0.0f, 0},
          {0, 0, 0, 1, 0, 0, 0, 0, 0.0f, 0}}}}
}};
}

void ApplyAscensionHealingStatSelectorContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    ExpectedSpell const* expected = nullptr;
    for (ExpectedSpell const& candidate : ExpectedSpells)
        if (candidate.Id == spellInfo->Id)
        {
            expected = &candidate;
            break;
        }

    if (!expected || spellInfo->SpellFamilyName != expected->Family || spellInfo->SpellFamilyFlags ||
        spellInfo->Dispel || spellInfo->Mechanic || spellInfo->Stances || spellInfo->StancesNot ||
        spellInfo->Targets || spellInfo->TargetCreatureType || spellInfo->RequiresSpellFocus ||
        spellInfo->FacingCasterFlags || spellInfo->CasterAuraState || spellInfo->TargetAuraState ||
        spellInfo->CasterAuraStateNot || spellInfo->TargetAuraStateNot || spellInfo->CasterAuraSpell ||
        spellInfo->TargetAuraSpell || spellInfo->ExcludeCasterAuraSpell || spellInfo->ExcludeTargetAuraSpell ||
        !spellInfo->CastTimeEntry || spellInfo->CastTimeEntry->ID != 1 ||
        !spellInfo->DurationEntry || spellInfo->DurationEntry->ID != 21 ||
        !spellInfo->RangeEntry || spellInfo->RangeEntry->ID != 1 || spellInfo->Speed ||
        spellInfo->GetCategory() != expected->Category || spellInfo->RecoveryTime || spellInfo->CategoryRecoveryTime ||
        spellInfo->StartRecoveryCategory || spellInfo->StartRecoveryTime || spellInfo->InterruptFlags ||
        spellInfo->AuraInterruptFlags || spellInfo->ChannelInterruptFlags || spellInfo->ProcFlags ||
        spellInfo->ProcChance != expected->ProcChance || spellInfo->ProcCharges || spellInfo->StackAmount ||
        spellInfo->MaxLevel || spellInfo->BaseLevel != expected->BaseLevel ||
        spellInfo->SpellLevel != expected->SpellLevel ||
        spellInfo->PowerType != expected->PowerType || spellInfo->ManaCost || spellInfo->ManaCostPerlevel ||
        spellInfo->ManaPerSecond || spellInfo->ManaPerSecondPerLevel || spellInfo->ManaCostPercentage ||
        spellInfo->RuneCostID || spellInfo->EquippedItemClass != -1 || spellInfo->EquippedItemSubClassMask ||
        spellInfo->EquippedItemInventoryTypeMask || spellInfo->MaxTargetLevel || spellInfo->MaxAffectedTargets ||
        spellInfo->PreventionType || spellInfo->AreaGroupId ||
        spellInfo->DmgClass != expected->DamageClass || spellInfo->SchoolMask != expected->SchoolMask)
        return;

    std::array<uint32, 8> const attributes = {{spellInfo->Attributes, spellInfo->AttributesEx, spellInfo->AttributesEx2,
        spellInfo->AttributesEx3, spellInfo->AttributesEx4, spellInfo->AttributesEx5,
        spellInfo->AttributesEx6, spellInfo->AttributesEx7}};
    if (attributes != expected->Attributes)
        return;

    for (uint8 index = EFFECT_0; index <= EFFECT_2; ++index)
    {
        SpellEffectInfo const& effect = spellInfo->Effects[index];
        ExpectedEffect const& before = expected->Effects[index];
        if (effect.Effect != before.Effect || effect.ApplyAuraName != before.Aura ||
            effect.BasePoints != before.BasePoints || effect.DieSides != before.DieSides ||
            effect.MiscValue != before.MiscValue || effect.MiscValueB != before.MiscValueB ||
            effect.TargetA.GetTarget() != before.TargetA || effect.TargetB.GetTarget() != before.TargetB ||
            effect.BonusMultiplier != before.BonusMultiplier || effect.Amplitude || effect.RealPointsPerLevel ||
            effect.PointsPerComboPoint || effect.ValueMultiplier || effect.DamageMultiplier != 1.0f ||
            effect.Mechanic || effect.RadiusEntry || effect.ChainTarget != before.ChainTarget ||
            effect.ItemType || effect.TriggerSpell || effect.SpellClassMask)
            return;
    }

    spellInfo->Effects[expected->HealingEffect].MiscValue = expected->HealingStat;
}
