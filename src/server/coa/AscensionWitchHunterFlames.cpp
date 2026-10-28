/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchHunterFlames.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <limits>

namespace
{
constexpr uint32 FLAME_FAMILY = uint32(CLASS_WITCH_HUNTER) + 6;
constexpr uint32 SPELL_FLAMES_BUFF = 803422;
constexpr uint32 SPELL_FLAMES_DAMAGE = 802850;

bool IsFlameCaster(Unit* caster)
{
    return caster && caster->IsPlayer() && caster->getClass() == CLASS_WITCH_HUNTER;
}

bool IsFlameGrantHelper(uint32 id)
{
    return id == 803710 || id == 802845 || id == 803503 || id == 504779 || id == 805365;
}

uint32 GetFlameGrantForAbility(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != FLAME_FAMILY)
        return 0;

    switch (spellInfo->GetFirstRankSpell()->Id)
    {
        case 680537:
            return 803710;
        case 802019:
            return 802845;
        case 802140:
            return 803503;
        default:
            return 0;
    }
}

class spell_ascension_witch_hunter_flame_grant : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_flame_grant);

    bool Validate(SpellInfo const* spellInfo) override
    {
        uint32 helper = GetFlameGrantForAbility(spellInfo);
        return helper && ValidateSpellInfo({helper});
    }

    bool Load() override
    {
        return IsFlameCaster(GetCaster()) && !GetSpell()->IsTriggered();
    }

    void GrantFlames()
    {
        uint32 helper = GetFlameGrantForAbility(GetSpellInfo());
        if (helper)
            GetCaster()->CastSpell(GetCaster(), helper, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_witch_hunter_flame_grant::GrantFlames);
    }
};

class spell_ascension_witch_hunter_flame_duration : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_flame_duration);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo && IsFlameGrantHelper(spellInfo->Id) && spellInfo->SpellFamilyName == FLAME_FAMILY &&
            spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_TRIGGER_SPELL &&
            spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_FLAMES_BUFF &&
            spellInfo->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_CASTER &&
            spellInfo->Effects[EFFECT_1].Effect == SPELL_EFFECT_ASCENSION_MODIFY_AURA_DURATION &&
            spellInfo->Effects[EFFECT_1].MiscValue == int32(SPELL_FLAMES_BUFF) &&
            spellInfo->Effects[EFFECT_1].TargetA.GetTarget() == TARGET_UNIT_CASTER &&
            ValidateSpellInfo({SPELL_FLAMES_BUFF});
    }

    bool Load() override
    {
        return IsFlameCaster(GetCaster());
    }

    void PreventReapplication(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
    }

    void GrantOrExtend(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Unit* caster = GetCaster();
        int32 extension = GetEffectValue();
        if (!caster || GetHitUnit() != caster || !caster->IsAlive() || extension <= 0)
            return;

        if (Aura* aura = caster->GetAura(SPELL_FLAMES_BUFF, caster->GetGUID()))
        {
            int32 duration = int32(std::min(int64(std::max(0, aura->GetDuration())) + extension,
                int64(std::numeric_limits<int32>::max())));
            if (duration > aura->GetMaxDuration())
                aura->SetMaxDuration(duration);
            aura->SetDuration(duration);
        }
        else
            caster->CastCustomSpell(SPELL_FLAMES_BUFF, SPELLVALUE_AURA_DURATION, extension, caster, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_ascension_witch_hunter_flame_duration::PreventReapplication, EFFECT_0, SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_witch_hunter_flame_duration::PreventReapplication, EFFECT_0, SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_witch_hunter_flame_duration::GrantOrExtend, EFFECT_1, SPELL_EFFECT_ASCENSION_MODIFY_AURA_DURATION);
    }
};

class spell_ascension_witch_hunter_flames_of_sin : public AuraScript
{
    PrepareAuraScript(spell_ascension_witch_hunter_flames_of_sin);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo && spellInfo->Id == SPELL_FLAMES_BUFF && spellInfo->SpellFamilyName == FLAME_FAMILY &&
            spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
            spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_FLAMES_DAMAGE && ValidateSpellInfo({SPELL_FLAMES_DAMAGE});
    }

    bool Load() override
    {
        return IsFlameCaster(GetCaster()) && GetCaster() == GetUnitOwner();
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* caster = GetCaster();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        return caster && caster->IsAlive() && eventInfo.GetActor() == caster && damage && damage->GetDamage() &&
            damage->GetAttacker() == caster && damage->GetVictim() && damage->GetVictim() != caster &&
            (eventInfo.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_RANGED_AUTO_ATTACK));
    }

    void DealFlameDamage(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (!CheckProc(eventInfo))
            return;

        GetAura()->GetEffect(EFFECT_0)->RecalculateAmount();
        uint64 amount = uint64(eventInfo.GetDamageInfo()->GetDamage()) * uint32(std::max(0, effect->GetAmount())) / 100;
        amount = std::min(amount, uint64(std::numeric_limits<int32>::max()));
        if (amount)
            GetCaster()->CastCustomSpell(SPELL_FLAMES_DAMAGE, SPELLVALUE_BASE_POINT0, int32(amount),
                eventInfo.GetDamageInfo()->GetVictim(), TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_witch_hunter_flames_of_sin::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_witch_hunter_flames_of_sin::DealFlameDamage, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_witch_hunter_flame_damage : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_flame_damage);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo && spellInfo->Id == SPELL_FLAMES_DAMAGE && spellInfo->SpellFamilyName == FLAME_FAMILY &&
            spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
            spellInfo->Effects[EFFECT_0].DieSides == 1 && !spellInfo->Effects[EFFECT_0].RealPointsPerLevel &&
            !spellInfo->Effects[EFFECT_0].BonusMultiplier && !sSpellMgr->GetSpellBonusData(SPELL_FLAMES_DAMAGE) &&
            spellInfo->HasAttribute(SPELL_ATTR2_CANT_CRIT);
    }

    bool Load() override
    {
        return IsFlameCaster(GetCaster()) && GetSpell()->IsTriggered();
    }

    void ApplyCopiedDamage(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Unit* target = GetHitUnit();
        if (!target || !target->IsAlive())
            return;

        int64 forwarded = int64(GetSpellValue()->EffectBasePoints[EFFECT_0]) + 1;
        uint32 amount = uint32(std::clamp(forwarded, int64(0), int64(std::numeric_limits<int32>::max())));
        amount = target->SpellDamageBonusTaken(GetCaster(), GetSpellInfo(), amount, SPELL_DIRECT_DAMAGE);
        int64 combined = int64(GetHitDamage()) + amount;
        SetHitDamage(int32(std::clamp(combined, int64(0), int64(std::numeric_limits<int32>::max()))));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_witch_hunter_flame_damage::ApplyCopiedDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class spell_ascension_witch_hunter_flame_modifier_update : public AuraScript
{
    PrepareAuraScript(spell_ascension_witch_hunter_flame_modifier_update);

    bool Validate(SpellInfo const* spellInfo) override
    {
        if (!spellInfo || spellInfo->SpellFamilyName != FLAME_FAMILY ||
            (spellInfo->Id != 802277 && spellInfo->Id != 503655 && spellInfo->Id != 504890))
            return false;

        uint8 index = spellInfo->Id == 802277 ? EFFECT_2 : EFFECT_1;
        return spellInfo->Effects[index].IsAura(SPELL_AURA_ADD_PCT_MODIFIER) &&
            spellInfo->Effects[index].MiscValue == SPELLMOD_EFFECT1 &&
            spellInfo->Effects[index].SpellClassMask == flag96(0, 256, 0);
    }

    bool Load() override
    {
        return IsFlameCaster(GetUnitOwner());
    }

    void UpdateFlameAmount(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* owner = GetTarget();
        if (Aura* aura = owner->GetAura(SPELL_FLAMES_BUFF, owner->GetGUID()))
            if (AuraEffect* effect = aura->GetEffect(EFFECT_0))
                effect->RecalculateAmount();
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_ascension_witch_hunter_flame_modifier_update::UpdateFlameAmount, EFFECT_ALL, SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_CHANGE_AMOUNT_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_witch_hunter_flame_modifier_update::UpdateFlameAmount, EFFECT_ALL, SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_CHANGE_AMOUNT_MASK);
    }
};
}

void ApplyAscensionWitchHunterFlameContracts(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != FLAME_FAMILY)
        return;

    if (spellInfo->Id == SPELL_FLAMES_BUFF && spellInfo->SpellFamilyFlags == flag96(0, 256, 0) &&
        spellInfo->Effects[EFFECT_0].IsAura(AuraType(354)) && spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_FLAMES_DAMAGE &&
        spellInfo->Effects[EFFECT_1].IsAura(SPELL_AURA_PERIODIC_TRIGGER_SPELL) && spellInfo->Effects[EFFECT_1].TriggerSpell == 680227)
    {
        spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        spellInfo->Effects[EFFECT_1].Effect = 0;
        spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_NONE;
        spellInfo->Effects[EFFECT_1].Amplitude = 0;
        spellInfo->Effects[EFFECT_1].TriggerSpell = 0;
    }
    else if (spellInfo->Id == SPELL_FLAMES_DAMAGE && spellInfo->SpellFamilyFlags == flag96(0, 0, 16384) &&
        spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE && spellInfo->Effects[EFFECT_0].DieSides == 1 &&
        !spellInfo->Effects[EFFECT_0].RealPointsPerLevel)
    {
        spellInfo->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        spellInfo->Effects[EFFECT_0].ChainTarget = 1;
        spellInfo->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
    }
    else if (spellInfo->Id == 802277 && spellInfo->SpellFamilyFlags == flag96(268435456, 0, 512) &&
        spellInfo->Effects[EFFECT_2].IsAura(SPELL_AURA_ADD_PCT_MODIFIER) &&
        spellInfo->Effects[EFFECT_2].MiscValue == SPELLMOD_EFFECT1 &&
        spellInfo->Effects[EFFECT_2].SpellClassMask == flag96(0, 256, 0) &&
        spellInfo->Effects[EFFECT_2].BasePoints == 39 && spellInfo->Effects[EFFECT_0].BasePoints == 29)
        spellInfo->Effects[EFFECT_2].BasePoints = spellInfo->Effects[EFFECT_0].BasePoints;
}

void AddAscensionWitchHunterFlameScripts()
{
    RegisterSpellScript(spell_ascension_witch_hunter_flame_grant);
    RegisterSpellScript(spell_ascension_witch_hunter_flame_duration);
    RegisterSpellScript(spell_ascension_witch_hunter_flames_of_sin);
    RegisterSpellScript(spell_ascension_witch_hunter_flame_damage);
    RegisterSpellScript(spell_ascension_witch_hunter_flame_modifier_update);
}
