/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRunemasterZenith.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <cmath>
#include <limits>

namespace
{
constexpr uint32 SPELL_ZENITH = 712325;
constexpr uint32 SPELL_ZENITH_CHARGES = 712389;
constexpr uint32 SPELL_RUNELORD_PASSIVE = 806984;
constexpr uint32 SPELL_RUNELORD_DAMAGE = 806997;
constexpr uint32 SPELL_RUNELORD_BUFF = 807379;

bool IsRunemasterPlayer(Unit const* caster)
{
    return caster && caster->IsPlayer() && caster->getClass() == CLASS_SPIRIT_MAGE;
}

bool HasPlainAttributes(SpellInfo const* info)
{
    return !info->Attributes && !info->AttributesEx && !info->AttributesEx2 && !info->AttributesEx3 &&
        !info->AttributesEx4 && !info->AttributesEx5 && !info->AttributesEx6 && !info->AttributesEx7;
}

bool IsRunelordDamage(SpellInfo const* info, int32 dieSides)
{
    if (!info || info->Id != SPELL_RUNELORD_DAMAGE || info->SpellFamilyName != 38 ||
        info->SpellFamilyFlags != flag96(0) || !HasPlainAttributes(info) ||
        info->DmgClass != SPELL_DAMAGE_CLASS_MAGIC || info->SchoolMask != 28 ||
        info->BaseLevel != 58 || info->SpellLevel != 58 || info->MaxLevel || info->Speed ||
        info->GetDuration() || info->ProcFlags || info->Effects[EFFECT_1].Effect || info->Effects[EFFECT_2].Effect)
        return false;

    SpellEffectInfo const& effect = info->Effects[EFFECT_0];
    return effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE && !effect.ApplyAuraName &&
        effect.BasePoints == 899 && effect.DieSides == dieSides && effect.RealPointsPerLevel == 0.0f &&
        effect.BonusMultiplier == 0.0f && !effect.TriggerSpell && effect.SpellClassMask == flag96(0) &&
        effect.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY && effect.TargetB.GetTarget() == 0;
}

bool IsCurrentZenith(SpellInfo const* info)
{
    if (!info || (info->Id != SPELL_ZENITH && info->Id != SPELL_ZENITH_CHARGES) ||
        info->SpellFamilyName != 38 || info->SpellFamilyFlags != flag96(268435456, 0, 0) ||
        !HasPlainAttributes(info) || info->DmgClass != SPELL_DAMAGE_CLASS_MAGIC || info->SchoolMask != 8 ||
        info->BaseLevel != 10 || info->SpellLevel != 10 || info->MaxLevel ||
        info->GetDuration() != 6000 || info->Speed || info->ProcFlags ||
        info->ExcludeCasterAuraSpell != (info->Id == SPELL_ZENITH_CHARGES ? SPELL_ZENITH_CHARGES : 0))
        return false;

    SpellEffectInfo const& chance = info->Effects[EFFECT_0];
    return chance.Effect == SPELL_EFFECT_APPLY_AURA && chance.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
        chance.MiscValue == SPELLMOD_CHANCE_OF_SUCCESS && chance.BasePoints == 99 && chance.DieSides == 1 &&
        chance.SpellClassMask == flag96(1073741824, 0, 0) && !chance.TriggerSpell &&
        chance.TargetA.GetTarget() == TARGET_UNIT_CASTER && chance.TargetB.GetTarget() == 0;
}

bool HasRunelordContract()
{
    SpellInfo const* passive = sSpellMgr->GetSpellInfo(SPELL_RUNELORD_PASSIVE);
    SpellInfo const* buff = sSpellMgr->GetSpellInfo(SPELL_RUNELORD_BUFF);
    if (!passive || passive->SpellFamilyName != 38 || passive->ProcFlags ||
        sSpellMgr->GetSpellProcEntry(SPELL_RUNELORD_PASSIVE) ||
        !buff || buff->SpellFamilyName != 38 || buff->GetDuration() != 8000 || buff->StackAmount || buff->ProcFlags ||
        !IsRunelordDamage(sSpellMgr->GetSpellInfo(SPELL_RUNELORD_DAMAGE), 1))
        return false;

    for (uint8 i = 0; i < 2; ++i)
    {
        SpellEffectInfo const& trigger = passive->Effects[i];
        SpellEffectInfo const& modifier = buff->Effects[i];
        if (trigger.Effect != SPELL_EFFECT_APPLY_AURA || trigger.ApplyAuraName != SPELL_AURA_PROC_TRIGGER_SPELL ||
            trigger.TriggerSpell != (i == 0 ? SPELL_RUNELORD_BUFF : SPELL_RUNELORD_DAMAGE) ||
            trigger.TargetA.GetTarget() != TARGET_UNIT_CASTER || trigger.TargetB.GetTarget() || trigger.SpellClassMask != flag96(0) ||
            trigger.BasePoints != (i == 0 ? -1 : 0) || trigger.DieSides != (i == 0 ? 1 : 0) ||
            modifier.Effect != SPELL_EFFECT_APPLY_AURA || modifier.ApplyAuraName != SPELL_AURA_ADD_PCT_MODIFIER ||
            modifier.MiscValue != (i == 0 ? SPELLMOD_DAMAGE : SPELLMOD_DOT) ||
            modifier.BasePoints != 29 || modifier.DieSides != 1 || modifier.TargetA.GetTarget() != TARGET_UNIT_CASTER ||
            modifier.TargetB.GetTarget() || modifier.TriggerSpell ||
            modifier.SpellClassMask != (i == 0 ? flag96(134348832, 4096, 0) : flag96(134348800, 4096, 262144)))
            return false;
    }
    return true;
}

class spell_ascension_runemaster_zenith : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_zenith);

    bool Validate(SpellInfo const* info) override
    {
        return IsCurrentZenith(info) && ValidateSpellInfo({SPELL_RUNELORD_PASSIVE, SPELL_RUNELORD_BUFF, SPELL_RUNELORD_DAMAGE});
    }

    bool Load() override
    {
        return IsRunemasterPlayer(GetCaster()) && HasRunelordContract();
    }

    void CaptureTarget()
    {
        if (_captured)
            return;
        _captured = true;

        Unit* target = GetSpell()->GetOriginalTarget();
        if (!target || target == GetCaster())
            target = GetCaster()->ToPlayer()->GetSelectedUnit();
        if (target && target != GetCaster())
            _target = target->GetGUID();
    }

    void ObserveSelfEffect(SpellEffIndex)
    {
        _selfEffectHit = GetHitUnit() == GetCaster();
    }

    void ConfirmApplication()
    {
        if (!_selfEffectHit || GetHitUnit() != GetCaster())
            return;

        Aura* aura = GetHitAura();
        if (!aura || aura->GetId() != GetSpellInfo()->Id ||
            aura->GetCasterGUID() != GetSpell()->GetOriginalCasterGUID())
            return;
        AuraApplication const* application = aura->GetApplicationOfTarget(GetCaster()->GetGUID());
        _activated = application && !application->GetRemoveMode() && application->HasEffect(EFFECT_0);
    }

    void ReleaseRunelord()
    {
        if (_released || !_activated || !HasRunelordContract())
            return;

        Unit* caster = GetCaster();
        AuraEffect const* source = caster->GetAuraEffect(SPELL_RUNELORD_PASSIVE, EFFECT_0, caster->GetGUID());
        if (!source)
            return;
        _released = true;

        ObjectGuid const original = GetSpell()->GetOriginalCasterGUID();
        caster->CastSpell(caster, SPELL_RUNELORD_BUFF, TRIGGERED_FULL_MASK, nullptr, source, original);

        Unit* target = ObjectAccessor::GetUnit(*caster, _target);
        if (!target || target == caster)
            return;
        SpellInfo const* damage = sSpellMgr->GetSpellInfo(SPELL_RUNELORD_DAMAGE);
        Unit* originalCaster = GetOriginalCaster();
        if (damage->CheckExplicitTarget(originalCaster ? originalCaster : caster, target) != SPELL_CAST_OK ||
            damage->CheckTarget(caster, target, false) != SPELL_CAST_OK)
            return;

        source = caster->GetAuraEffect(SPELL_RUNELORD_PASSIVE, EFFECT_1, caster->GetGUID());
        if (source)
            caster->CastSpell(target, damage, TRIGGERED_FULL_MASK, nullptr, source, original);
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_runemaster_zenith::CaptureTarget);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_runemaster_zenith::ObserveSelfEffect, EFFECT_0, SPELL_EFFECT_APPLY_AURA);
        AfterHit += SpellHitFn(spell_ascension_runemaster_zenith::ConfirmApplication);
        AfterCast += SpellCastFn(spell_ascension_runemaster_zenith::ReleaseRunelord);
    }

    ObjectGuid _target = ObjectGuid::Empty;
    bool _captured = false;
    bool _selfEffectHit = false;
    bool _activated = false;
    bool _released = false;
};

class spell_ascension_runemaster_runelord_damage : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_runelord_damage);

    bool Validate(SpellInfo const* info) override
    {
        return IsRunelordDamage(info, 1);
    }

    bool Load() override
    {
        return IsRunemasterPlayer(GetCaster());
    }

    void ScaleRawMinimum()
    {
        if (_scaled || !IsRunelordDamage(GetSpellInfo(), 1) ||
            GetSpellValue()->EffectBasePoints[EFFECT_0] != GetSpellInfo()->Effects[EFFECT_0].BasePoints)
            return;
        _scaled = true;

        double const level = GetCaster()->GetLevel();
        double const factor = 0.0267291844060354 + 0.0048541098014737 * level +
            0.0001859597762293 * level * level;
        double const amount = 900.0 * factor;
        if (std::isfinite(amount) && amount >= 0.0 && amount <= std::numeric_limits<int32>::max())
            GetSpell()->SetSpellValue(SPELLVALUE_BASE_POINT0, int32(amount));
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_runemaster_runelord_damage::ScaleRawMinimum);
    }

    bool _scaled = false;
};
}

void ApplyAscensionRunemasterZenithContracts(SpellInfo* info)
{
    if (IsRunelordDamage(info, 17))
        info->Effects[EFFECT_0].DieSides = 1;
}

void AddAscensionRunemasterZenithScripts()
{
    RegisterSpellScript(spell_ascension_runemaster_zenith);
    RegisterSpellScript(spell_ascension_runemaster_runelord_damage);
}
