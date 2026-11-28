/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchHunterCompletion.h"
#include "AscensionWitchHunterCoefficients.h"
#include "SpellInfoTestHelper.h"
#include <gtest/gtest.h>

TEST(WitchHunterExtraContractsTest, SaberSlashFireStripsFlatBonusAndUnlistedTriggers)
{
    auto info = SpellInfoBuilder()
        .WithId(680230)
        .WithSpellFamilyName(21)
        .WithAttributesEx3(SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON)
        .WithEffect(EFFECT_0, SPELL_EFFECT_NORMALIZED_WEAPON_DMG)
        .WithEffectBasePoints(EFFECT_0, 1)
        .WithEffectDieSides(EFFECT_0, 1)
        .WithEffect(EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL)
        .WithEffectTriggerSpell(EFFECT_1, 802842)
        .WithEffect(EFFECT_2, SPELL_EFFECT_TRIGGER_SPELL)
        .WithEffectTriggerSpell(EFFECT_2, 802007)
        .BuildUnique();
    info->Effects[EFFECT_0].RealPointsPerLevel = 0.2f;

    AscensionWitchHunter::ApplyContracts(info.get());

    EXPECT_FALSE(info->HasAttribute(SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON));
    EXPECT_EQ(info->Effects[EFFECT_0].Effect, SPELL_EFFECT_NORMALIZED_WEAPON_DMG);
    EXPECT_EQ(info->Effects[EFFECT_0].BasePoints, 0);
    EXPECT_EQ(info->Effects[EFFECT_0].DieSides, 0);
    EXPECT_FLOAT_EQ(info->Effects[EFFECT_0].RealPointsPerLevel, 0.0f);
    EXPECT_EQ(info->Effects[EFFECT_0].CalcValue(), 0);
    EXPECT_EQ(info->Effects[EFFECT_1].Effect, 0u);
    EXPECT_EQ(info->Effects[EFFECT_2].Effect, 0u);
}

TEST(WitchHunterExtraContractsTest, GreaterKnightsEdictClearsTargetCap)
{
    auto info = SpellInfoBuilder()
        .WithId(523510)
        .WithSpellFamilyName(21)
        .WithEffect(EFFECT_0, SPELL_EFFECT_APPLY_AURA, SPELL_AURA_MOD_RESISTANCE)
        .BuildUnique();
    info->MaxAffectedTargets = 10;

    AscensionWitchHunter::ApplyContracts(info.get());

    EXPECT_EQ(info->MaxAffectedTargets, 0u);
}

TEST(WitchHunterExtraContractsTest, NightsWatchDisablesStaleNonHolyThreatAura)
{
    auto info = SpellInfoBuilder()
        .WithId(807733)
        .WithSpellFamilyName(21)
        .WithEffect(EFFECT_0, SPELL_EFFECT_APPLY_AURA, SPELL_AURA_MOD_THREAT)
        .WithEffectBasePoints(EFFECT_0, 209)
        .WithEffectDieSides(EFFECT_0, 1)
        .WithEffectMiscValue(EFFECT_0, 127)
        .WithEffect(EFFECT_1, SPELL_EFFECT_APPLY_AURA, SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN)
        .WithEffect(EFFECT_2, SPELL_EFFECT_APPLY_AURA, SPELL_AURA_MOD_THREAT)
        .WithEffectBasePoints(EFFECT_2, 74)
        .WithEffectDieSides(EFFECT_2, 1)
        .WithEffectMiscValue(EFFECT_2, 125)
        .BuildUnique();
    info->Effects[EFFECT_2].RealPointsPerLevel = 0.5f;

    AscensionWitchHunter::ApplyContracts(info.get());

    EXPECT_EQ(info->Effects[EFFECT_0].Effect, SPELL_EFFECT_APPLY_AURA);
    EXPECT_EQ(info->Effects[EFFECT_0].ApplyAuraName, SPELL_AURA_MOD_THREAT);
    EXPECT_EQ(info->Effects[EFFECT_1].ApplyAuraName, SPELL_AURA_SCHOOL_ABSORB);
    EXPECT_EQ(info->Effects[EFFECT_1].MiscValue, int32(SPELL_SCHOOL_MASK_ALL));
    EXPECT_EQ(info->Effects[EFFECT_2].Effect, 0u);
}

TEST(WitchHunterExtraContractsTest, NightsWatchLeavesUnexpectedEffectTwoUntouched)
{
    auto info = SpellInfoBuilder()
        .WithId(807733)
        .WithSpellFamilyName(21)
        .WithEffect(EFFECT_1, SPELL_EFFECT_APPLY_AURA, SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN)
        .WithEffect(EFFECT_2, SPELL_EFFECT_APPLY_AURA, SPELL_AURA_MOD_THREAT)
        .WithEffectBasePoints(EFFECT_2, 99)
        .WithEffectMiscValue(EFFECT_2, 125)
        .BuildUnique();
    info->Effects[EFFECT_2].RealPointsPerLevel = 0.5f;

    AscensionWitchHunter::ApplyContracts(info.get());

    EXPECT_EQ(info->Effects[EFFECT_2].Effect, SPELL_EFFECT_APPLY_AURA);
}

TEST(WitchHunterExtraContractsTest, BrandOfTheDamnedDamageUsesTwilightSchoolMask)
{
    WitchCoefficient const* found = nullptr;
    for (WitchCoefficient const& row : WitchCoefficients)
        if (row.id == 807683 && row.effect == EFFECT_0)
            found = &row;
    ASSERT_NE(found, nullptr);
    EXPECT_FLOAT_EQ(found->ap, 1.0f);
    EXPECT_FLOAT_EQ(found->rap, 0.0f);
    EXPECT_FLOAT_EQ(found->sp, 1.0f);
    EXPECT_EQ(found->school, uint32(SPELL_SCHOOL_MASK_HOLY | SPELL_SCHOOL_MASK_SHADOW));
}
