/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionHeroRogue.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"
#include <algorithm>
#include <array>

namespace
{
enum HeroRogueSpells : uint32
{
    GrapplingHookFollowUp = 760094,
    MassacreEnchant       = 415001
};

constexpr uint32 SHIV_FLAG0 = 0x20000000;

constexpr std::array<uint32, 12> EVISCERATE_RANKS = { 2098, 6760, 6761, 6762, 8623, 8624, 11299, 11300, 31016, 26865,
    48667, 48668 };
constexpr std::array<uint32, 6> ENVENOM_RANKS = { 32645, 32660, 32661, 32684, 57992, 57993 };
constexpr std::array<uint32, 9> RUPTURE_RANKS = { 1943, 8639, 8640, 11273, 11274, 11275, 26867, 48671, 48672 };
constexpr std::array<uint32, 8> CRIMSON_TEMPEST_RANKS = { 954809, 954883, 954884, 954885, 954886, 954887, 954888,
    954889 };
constexpr std::array<uint32, 7> SHURIKEN_TOSS_RANKS = { 954835, 955223, 955224, 955225, 955226, 955227, 955228 };

template <std::size_t Count>
bool IsAnyOf(std::array<uint32, Count> const& ranks, uint32 spellId)
{
    return std::find(ranks.begin(), ranks.end(), spellId) != ranks.end();
}

void SetPowerBonus(SpellInfo* spellInfo, bool periodic, float square, float flat)
{
    for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
    {
        SpellEffectInfo const& effect = spellInfo->Effects[i];
        if (periodic ? effect.IsAura(SPELL_AURA_PERIODIC_DAMAGE) : effect.IsEffect(SPELL_EFFECT_SCHOOL_DAMAGE))
        {
            spellInfo->ComboPointPowerSquare[i] = square;
            spellInfo->ComboPointPowerFlat[i] = flat;
            return;
        }
    }
}

uint32 ComboPoints(Unit* caster)
{
    Player* player = caster ? caster->ToPlayer() : nullptr;
    return player ? std::min<uint32>(player->GetComboPoints(), 5) : 0;
}
}

class aura_hero_rogue_crimson_tempest_bleed : public AuraScript
{
    PrepareAuraScript(aura_hero_rogue_crimson_tempest_bleed);

    void CalculateAmount(AuraEffect const* aurEff, int32& amount, bool& canBeRecalculated)
    {
        if (Unit* caster = GetCaster())
        {
            canBeRecalculated = false;
            amount += GetSpellInfo()->GetComboPointPowerBonus(caster, aurEff->GetEffIndex(), ComboPoints(caster));
        }
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_hero_rogue_crimson_tempest_bleed::CalculateAmount, EFFECT_ALL,
            SPELL_AURA_PERIODIC_DAMAGE);
    }
};

class aura_hero_rogue_blade_twisting : public AuraScript
{
    PrepareAuraScript(aura_hero_rogue_blade_twisting);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        if (!spellInfo)
            return false;
        return spellInfo->Id == GrapplingHookFollowUp ||
            (spellInfo->SpellFamilyName == SPELLFAMILY_ROGUE && (spellInfo->SpellFamilyFlags[0] & SHIV_FLAG0));
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_rogue_blade_twisting::CheckProc);
    }
};

class spell_hero_rogue_killing_spree_massacre : public SpellScript
{
    PrepareSpellScript(spell_hero_rogue_killing_spree_massacre);

    void HandleMassacre(SpellEffIndex effIndex)
    {
        if (!GetCaster()->HasAura(MassacreEnchant))
            PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_hero_rogue_killing_spree_massacre::HandleMassacre, EFFECT_1,
            SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectLaunch += SpellEffectFn(spell_hero_rogue_killing_spree_massacre::HandleMassacre, EFFECT_2,
            SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectLaunchTarget += SpellEffectFn(spell_hero_rogue_killing_spree_massacre::HandleMassacre, EFFECT_1,
            SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectLaunchTarget += SpellEffectFn(spell_hero_rogue_killing_spree_massacre::HandleMassacre, EFFECT_2,
            SPELL_EFFECT_TRIGGER_SPELL);
    }
};

void ApplyAscensionHeroRogueContracts(SpellInfo* spellInfo)
{
    uint32 const id = spellInfo->Id;
    if (IsAnyOf(EVISCERATE_RANKS, id) || IsAnyOf(ENVENOM_RANKS, id))
        SetPowerBonus(spellInfo, false, 0.02f, 0.0f);
    else if (IsAnyOf(RUPTURE_RANKS, id))
        SetPowerBonus(spellInfo, true, 0.0039f, 0.0f);
    else if (IsAnyOf(CRIMSON_TEMPEST_RANKS, id))
    {
        SetPowerBonus(spellInfo, false, 0.015f, 0.02f);
        SetPowerBonus(spellInfo, true, 0.002f, 0.01f);
    }
    else if (IsAnyOf(SHURIKEN_TOSS_RANKS, id))
        spellInfo->UseRangedAttackPowerForDamage = true;
}

void AddSC_AscensionHeroRogue()
{
    RegisterSpellScript(aura_hero_rogue_crimson_tempest_bleed);
    RegisterSpellScript(aura_hero_rogue_blade_twisting);
    RegisterSpellScript(spell_hero_rogue_killing_spree_massacre);
}
