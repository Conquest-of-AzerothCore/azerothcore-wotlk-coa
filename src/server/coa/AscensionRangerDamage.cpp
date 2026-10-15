/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRangerDamage.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>
#include <limits>

namespace
{
constexpr uint32 SPELL_RANGER_RUSTY_SHIV = 561315;
constexpr uint32 SPELL_RANGER_RUSTY_SHIV_DAMAGE = 681459;
constexpr uint32 RANGER_SPELL_FAMILY = 27;
constexpr uint32 SPELL_RANGER_WILD_STRIKE_OFF_HAND = 560962;
constexpr int32 WILD_STRIKE_OFF_HAND_COPIED_BASE_POINTS = 318;
constexpr uint32 RUSTY_SHIV_DAMAGE_DIVISOR = 5;
constexpr int32 FALCONSTRIKE_WEAPON_BASE_POINTS = 120;

struct FalconstrikeRank
{
    uint32 SpellId;
    int32 MalformedBasePoints;
};

constexpr std::array<FalconstrikeRank, 7> FALCONSTRIKE_RANKS = {{
    {806437, 928},
    {806438, 1143},
    {806439, 1404},
    {806440, 1725},
    {806441, 2119},
    {806442, 2603},
    {806443, 3196}
}};

void ApplyFalconstrikeWeaponContract(SpellInfo* spellInfo)
{
    auto const rank = std::find_if(FALCONSTRIKE_RANKS.begin(), FALCONSTRIKE_RANKS.end(),
        [spellInfo](FalconstrikeRank const& value) { return value.SpellId == spellInfo->Id; });
    if (rank == FALCONSTRIKE_RANKS.end())
        return;

    SpellEffectInfo& percent = spellInfo->Effects[EFFECT_2];
    bool const shape = spellInfo->SpellFamilyName == RANGER_SPELL_FAMILY &&
        spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG &&
        percent.Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE && percent.DieSides == 1 &&
        !percent.RealPointsPerLevel && !percent.PointsPerComboPoint;
    if (shape && percent.BasePoints == FALCONSTRIKE_WEAPON_BASE_POINTS)
        return;

    if (shape && percent.BasePoints == rank->MalformedBasePoints)
        percent.BasePoints = FALCONSTRIKE_WEAPON_BASE_POINTS;
    else
        LOG_ERROR("coa", "Skipped unexpected Falconstrike weapon record {}", spellInfo->Id);
}

bool IsRustyShivContract(SpellInfo const* spellInfo)
{
    return spellInfo && spellInfo->Id == SPELL_RANGER_RUSTY_SHIV &&
        spellInfo->SpellFamilyName == RANGER_SPELL_FAMILY &&
        spellInfo->HasAttribute(SPELL_ATTR3_DOT_STACKING_RULE) &&
        spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
        spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_RANGER_RUSTY_SHIV_DAMAGE &&
        spellInfo->Effects[EFFECT_1].IsAura(SPELL_AURA_DUMMY) &&
        spellInfo->Effects[EFFECT_1].MiscValueB == 20;
}

class spell_ascension_ranger_rusty_shiv : public AuraScript
{
    PrepareAuraScript(spell_ascension_ranger_rusty_shiv);

    bool _paid = false;

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsRustyShivContract(spellInfo) && ValidateSpellInfo({ SPELL_RANGER_RUSTY_SHIV_DAMAGE });
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->ToPlayer()->getClass() == CLASS_RANGER;
    }

    void CalculateAmount(AuraEffect const*, int32& amount, bool& canBeRecalculated)
    {
        amount = 0;
        canBeRecalculated = false;
    }

    void ResetWindow(AuraEffect const*, AuraEffectHandleModes)
    {
        GetEffect(EFFECT_0)->SetAmount(0);
        GetEffect(EFFECT_1)->SetAmount(0);
        _paid = false;
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        Unit* caster = GetCaster();
        return caster && damage && damage->GetDamage() &&
            eventInfo.GetActor() == caster && damage->GetAttacker() == caster &&
            damage->GetVictim() == GetTarget() &&
            (!damage->GetSpellInfo() || damage->GetSpellInfo()->Id != SPELL_RANGER_RUSTY_SHIV_DAMAGE);
    }

    void Accumulate(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (!CheckProc(eventInfo))
            return;

        AuraEffect* remainder = GetEffect(EFFECT_1);
        uint64 total = uint64(std::max(0, effect->GetAmount())) * RUSTY_SHIV_DAMAGE_DIVISOR;
        total += std::clamp(remainder->GetAmount(), 0, int32(RUSTY_SHIV_DAMAGE_DIVISOR - 1));
        total += eventInfo.GetDamageInfo()->GetDamage();
        uint64 maximum = uint64(std::numeric_limits<int32>::max()) * RUSTY_SHIV_DAMAGE_DIVISOR;
        total = std::min(total, maximum);
        GetEffect(EFFECT_0)->SetAmount(int32(total / RUSTY_SHIV_DAMAGE_DIVISOR));
        remainder->SetAmount(int32(total % RUSTY_SHIV_DAMAGE_DIVISOR));
    }

    void PayAtExpiry(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (_paid || GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        _paid = true;

        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        int32 amount = effect->GetAmount();
        if (!caster || !caster->IsPlayer() || caster->ToPlayer()->getClass() != CLASS_RANGER ||
            !caster->IsAlive() || !caster->IsInWorld() || !target->IsAlive() || !target->IsInWorld() ||
            caster->GetMap() != target->GetMap() || !caster->ToPlayer()->GetSession() ||
            caster->ToPlayer()->GetSession()->PlayerLogout() || amount <= 0)
            return;

        caster->CastCustomSpell(SPELL_RANGER_RUSTY_SHIV_DAMAGE, SPELLVALUE_BASE_POINT0,
            amount, target, TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ascension_ranger_rusty_shiv::CalculateAmount,
            EFFECT_ALL, SPELL_AURA_DUMMY);
        AfterEffectApply += AuraEffectApplyFn(spell_ascension_ranger_rusty_shiv::ResetWindow,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAPPLY);
        DoCheckProc += AuraCheckProcFn(spell_ascension_ranger_rusty_shiv::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_ranger_rusty_shiv::Accumulate,
            EFFECT_0, SPELL_AURA_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_ranger_rusty_shiv::PayAtExpiry,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_ranger_rusty_shiv_damage : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_rusty_shiv_damage);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellEffectInfo const& effect = spellInfo->Effects[EFFECT_0];
        return spellInfo->Id == SPELL_RANGER_RUSTY_SHIV_DAMAGE &&
            spellInfo->SpellFamilyName == RANGER_SPELL_FAMILY &&
            effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE && effect.DieSides == 1 &&
            !effect.RealPointsPerLevel && !effect.PointsPerComboPoint;
    }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->ToPlayer()->getClass() == CLASS_RANGER &&
            GetSpell()->IsTriggered();
    }

    void SetAccumulatedDamage(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        int64 amount = int64(GetSpellValue()->EffectBasePoints[EFFECT_0]) + 1;
        SetHitDamage(int32(std::clamp<int64>(amount, 0, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_ranger_rusty_shiv_damage::SetAccumulatedDamage,
            EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

void ApplyWildStrikeOffHandContract(SpellInfo* spellInfo)
{
    if (spellInfo->Id != SPELL_RANGER_WILD_STRIKE_OFF_HAND ||
        spellInfo->SpellFamilyName != RANGER_SPELL_FAMILY)
        return;

    SpellEffectInfo& offHand = spellInfo->Effects[EFFECT_0];
    bool const copied = offHand.Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG &&
        offHand.BasePoints == WILD_STRIKE_OFF_HAND_COPIED_BASE_POINTS && offHand.DieSides == 1;
    if (copied && !spellInfo->Effects[EFFECT_1].IsEffect() && !spellInfo->Effects[EFFECT_2].IsEffect())
    {
        offHand.BasePoints = 0;
        offHand.DieSides = 0;
    }
    else
        LOG_ERROR("coa", "Skipped unexpected Wild Strike off-hand record {}", spellInfo->Id);
}
}

void ApplyAscensionRangerDamageContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    ApplyWildStrikeOffHandContract(spellInfo);
    ApplyFalconstrikeWeaponContract(spellInfo);

    if (spellInfo->Id != SPELL_RANGER_RUSTY_SHIV ||
        spellInfo->SpellFamilyName != RANGER_SPELL_FAMILY)
        return;

    SpellEffectInfo& effect = spellInfo->Effects[EFFECT_1];
    if (spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
        spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_RANGER_RUSTY_SHIV_DAMAGE &&
        effect.IsAura(SPELL_AURA_SCHOOL_ABSORB) && effect.BasePoints == 0 &&
        effect.DieSides == 1 && effect.MiscValue == SPELL_SCHOOL_MASK_ALL && effect.MiscValueB == 10)
    {
        effect.ApplyAuraName = SPELL_AURA_DUMMY;
        effect.BasePoints = -1;
        effect.MiscValueB = 20;
    }

    if (IsRustyShivContract(spellInfo))
        spellInfo->AttributesEx &= ~SPELL_ATTR1_ALLOW_WHILE_STEALTHED;
}

void AddAscensionRangerDamageScripts()
{
    RegisterSpellScript(spell_ascension_ranger_rusty_shiv);
    RegisterSpellScript(spell_ascension_ranger_rusty_shiv_damage);
}
