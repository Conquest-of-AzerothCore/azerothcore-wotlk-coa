/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWarcraftRebornWarlock.h"
#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 CONFLAGRATE = 1117962;
constexpr uint32 CONFLAGRATE_DURATION = 32;
constexpr int32 CONFLAGRATE_TICK_MS = 2000;
constexpr uint32 BACKDRAFT_RANK_3 = 1154277;
constexpr uint32 SUMMONERS_ARMOR = 1701521;
constexpr uint32 FEL_CONCENTRATION_RANK_2 = 1117784;
constexpr uint32 WARLOCK_SEED_AND_UNSTABLE_AFFLICTION = 0x110;
constexpr uint32 WARLOCK_SOUL_GORGE = 0x10000;
constexpr uint32 WARLOCK_ARMORS = 0x10;
constexpr uint32 WARLOCK_UNSTABLE_AFFLICTION_AND_HAUNT = 0x40100;
constexpr std::array<uint32, 3> WARLOCK_AFFLICTION = { 0x48c41a, 0x40713, 0x800 };
constexpr std::array<uint32, 3> DEMONIC_RESILIENCE = { 1130319, 1130320, 1130321 };
constexpr std::array<uint32, 3> CONTAGION = { 1130060, 1130061, 1130062 };
constexpr std::array<uint32, 2> IMPROVED_DRAIN_SOUL = { 1118213, 1118372 };
constexpr std::array<uint32, 5> EMBERSTORM = { 1117954, 1117955, 1117956, 1117957, 1117958 };
constexpr std::array<uint32, 5> SHADOW_MASTERY = { 1118271, 1118272, 1118273, 1118274, 1118275 };
constexpr std::array<uint32, 3> DEMONIC_AEGIS = { 1130143, 1130144, 1130145 };
constexpr std::array<uint32, 3> NEMESIS = { 1163117, 1163121, 1163123 };
constexpr std::array<uint32, 8> LIFE_TAP = { 1101454, 1101455, 1101456, 1111687, 1111688, 1111689, 1127222, 1157946 };

template <std::size_t N>
bool Contains(std::array<uint32, N> const& ids, uint32 id)
{
    return std::find(ids.begin(), ids.end(), id) != ids.end();
}

class spell_ascension_reborn_summoners_armor_demon : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_summoners_armor_demon);

    void CalculateAmount(AuraEffect const*, int32& amount, bool&)
    {
        if (Unit* owner = GetUnitOwner()->GetOwner())
            if (Player* player = owner->ToPlayer())
                player->ApplySpellMod(SUMMONERS_ARMOR, SPELLMOD_ALL_EFFECTS, amount);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ascension_reborn_summoners_armor_demon::CalculateAmount, EFFECT_0, SPELL_AURA_MOD_DAMAGE_DONE);
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ascension_reborn_summoners_armor_demon::CalculateAmount, EFFECT_1, SPELL_AURA_MOD_ATTACK_POWER);
    }
};

class spell_ascension_reborn_reign_of_dread : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_reign_of_dread);

    bool Load() override
    {
        return GetCaster()->IsPlayer();
    }

    void ShortenCooldown()
    {
        Player* caster = GetCaster()->ToPlayer();
        for (uint32 nemesis : NEMESIS)
        {
            if (AuraEffect const* reduction = caster->GetAuraEffect(nemesis, EFFECT_0))
            {
                caster->ModifySpellCooldown(GetSpellInfo()->Id, CalculatePct(int32(GetSpellInfo()->RecoveryTime), reduction->GetAmount()));
                return;
            }
        }
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_reborn_reign_of_dread::ShortenCooldown);
    }
};
}
}

void ApplyAscensionWarcraftRebornWarlockContracts(SpellInfo* spellInfo)
{
    using namespace AscensionWarcraftReborn;
    if (!spellInfo)
        return;

    if (spellInfo->Id == CONFLAGRATE)
    {
        SpellEffectInfo& periodic = spellInfo->Effects[EFFECT_1];
        if (periodic.Effect == SPELL_EFFECT_APPLY_AURA && periodic.ApplyAuraName == SPELL_AURA_DUMMY)
        {
            periodic.ApplyAuraName = SPELL_AURA_PERIODIC_DAMAGE;
            periodic.Amplitude = CONFLAGRATE_TICK_MS;
            spellInfo->DurationEntry = sSpellDurationStore.LookupEntry(CONFLAGRATE_DURATION);
        }
    }

    if (spellInfo->Id == BACKDRAFT_RANK_3)
    {
        SpellEffectInfo& noCrit = spellInfo->Effects[EFFECT_2];
        if (noCrit.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER && noCrit.MiscValue == SPELLMOD_CRITICAL_CHANCE &&
            noCrit.CalcValue() == 0)
        {
            noCrit.Effect = 0;
            noCrit.ApplyAuraName = SPELL_AURA_NONE;
        }
    }

    if (Contains(DEMONIC_RESILIENCE, spellInfo->Id) &&
        spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_MOD_ATTACKER_MELEE_CRIT_CHANCE &&
        spellInfo->Effects[EFFECT_2].ApplyAuraName == SPELL_AURA_MOD_ATTACKER_SPELL_CRIT_CHANCE)
        spellInfo->Effects[EFFECT_2].BasePoints = spellInfo->Effects[EFFECT_0].BasePoints;

    if (Contains(CONTAGION, spellInfo->Id) && spellInfo->Effects[EFFECT_0].MiscValue == SPELLMOD_DOT &&
        spellInfo->Effects[EFFECT_1].MiscValue == SPELLMOD_DAMAGE)
        spellInfo->Effects[EFFECT_1].BasePoints = spellInfo->Effects[EFFECT_0].BasePoints;

    if (Contains(IMPROVED_DRAIN_SOUL, spellInfo->Id) && spellInfo->Effects[EFFECT_1].MiscValue == SPELLMOD_THREAT)
        for (uint8 part = 0; part < 3; ++part)
            spellInfo->Effects[EFFECT_1].SpellClassMask[part] |= WARLOCK_AFFLICTION[part];

    if (spellInfo->Id == FEL_CONCENTRATION_RANK_2 && spellInfo->Effects[EFFECT_0].MiscValue == SPELLMOD_NOT_LOSE_CASTING_TIME)
        spellInfo->Effects[EFFECT_0].SpellClassMask[1] |= WARLOCK_UNSTABLE_AFFLICTION_AND_HAUNT;

    if (Contains(EMBERSTORM, spellInfo->Id) && spellInfo->Effects[EFFECT_0].MiscValue == SPELLMOD_DAMAGE &&
        spellInfo->Effects[EFFECT_1].MiscValue == SPELLMOD_DOT)
    {
        spellInfo->Effects[EFFECT_0].SpellClassMask[2] |= WARLOCK_SOUL_GORGE;
        spellInfo->Effects[EFFECT_1].SpellClassMask[1] |= WARLOCK_SEED_AND_UNSTABLE_AFFLICTION;
    }

    if (Contains(SHADOW_MASTERY, spellInfo->Id) && spellInfo->Effects[EFFECT_0].MiscValue == SPELLMOD_DAMAGE)
        spellInfo->Effects[EFFECT_0].SpellClassMask[2] |= WARLOCK_SOUL_GORGE;

    if (Contains(DEMONIC_AEGIS, spellInfo->Id) && spellInfo->Effects[EFFECT_0].MiscValue == SPELLMOD_ALL_EFFECTS)
        spellInfo->Effects[EFFECT_0].SpellClassMask[2] |= WARLOCK_ARMORS;

    if (Contains(LIFE_TAP, spellInfo->Id))
    {
        if (SpellEntry const* entry = sSpellStore.LookupEntry(spellInfo->Id))
        {
            spellInfo->Effects[EFFECT_0].RealPointsPerLevel = entry->EffectRealPointsPerLevel[EFFECT_0];
            spellInfo->MaxLevel = entry->MaxLevel;
            spellInfo->BaseLevel = entry->BaseLevel;
            spellInfo->SpellLevel = entry->SpellLevel;
        }
    }
}

void AddAscensionWarcraftRebornWarlockScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_summoners_armor_demon);
    RegisterSpellScript(spell_ascension_reborn_reign_of_dread);
}
