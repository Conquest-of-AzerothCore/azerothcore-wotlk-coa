/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchHunterTonics.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <cmath>
#include <limits>

namespace
{
constexpr uint32 WITCH_HUNTER_SPELL_FAMILY = 21;
constexpr uint32 SPELL_VAMPIRIC_TONIC = 802276;
constexpr uint32 SPELL_VAMPIRIC_TONIC_HEAL = 802271;
constexpr uint32 SPELL_HOLY_WATER_TONIC = 802826;
constexpr uint32 SPELL_HOLY_WATER_TONIC_BUFF = 803535;
constexpr uint32 TONIC_CREATURE_TYPES = (1 << (CREATURE_TYPE_DEMON - 1)) | (1 << (CREATURE_TYPE_UNDEAD - 1));

bool IsWitchHunter(Unit* unit)
{
    return unit && unit->IsPlayer() && unit->ToPlayer()->getClass() == CLASS_WITCH_HUNTER;
}

bool IsDarkTonicContract(SpellInfo const* spellInfo)
{
    if (!spellInfo || !(spellInfo->Id == 680491 || (spellInfo->Id >= 572295 && spellInfo->Id <= 572298)))
        return false;

    SpellEffectInfo const& heal = spellInfo->Effects[EFFECT_0];
    return spellInfo->SpellFamilyName == WITCH_HUNTER_SPELL_FAMILY &&
        spellInfo->SpellFamilyFlags == flag96(0, 67108864, 512) &&
        heal.Effect == SPELL_EFFECT_HEAL && heal.TargetA.GetTarget() == TARGET_UNIT_CASTER &&
        heal.DieSides > 0 && !heal.PointsPerComboPoint &&
        !heal.BonusMultiplier && !sSpellMgr->GetSpellBonusData(spellInfo->Id) &&
        spellInfo->Effects[EFFECT_1].IsAura(SPELL_AURA_MOD_INCREASE_HEALTH_PERCENT);
}

class spell_ascension_witch_hunter_dark_tonic : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_dark_tonic);

    bool _scaled = false;

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsDarkTonicContract(spellInfo);
    }

    bool Load() override
    {
        return IsWitchHunter(GetCaster());
    }

    void ScaleHealing(SpellEffIndex)
    {
        if (_scaled)
            return;
        _scaled = true;

        double bonus = 6.0 * GetCaster()->GetStat(STAT_STAMINA);
        if (!std::isfinite(bonus) || bonus < 0 || bonus > std::numeric_limits<int32>::max())
            return;

        int64 base = int64(GetSpellValue()->EffectBasePoints[EFFECT_0]) + int32(bonus);
        int64 maximum = int64(std::numeric_limits<int32>::max()) - GetSpellInfo()->Effects[EFFECT_0].DieSides;
        base = std::clamp<int64>(base, 0, maximum);
        GetSpell()->SetSpellValue(SPELLVALUE_BASE_POINT0, int32(base + 1));
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_ascension_witch_hunter_dark_tonic::ScaleHealing, EFFECT_0, SPELL_EFFECT_HEAL);
    }
};

class spell_ascension_witch_hunter_vampiric_tonic : public AuraScript
{
    PrepareAuraScript(spell_ascension_witch_hunter_vampiric_tonic);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellInfo const* heal = sSpellMgr->GetSpellInfo(SPELL_VAMPIRIC_TONIC_HEAL);
        return spellInfo && spellInfo->Id == SPELL_VAMPIRIC_TONIC &&
            spellInfo->SpellFamilyName == WITCH_HUNTER_SPELL_FAMILY &&
            spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
            spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_VAMPIRIC_TONIC_HEAL &&
            heal && heal->SpellFamilyName == WITCH_HUNTER_SPELL_FAMILY &&
            heal->Effects[EFFECT_0].Effect == SPELL_EFFECT_HEAL &&
            !heal->Effects[EFFECT_0].BonusMultiplier && !sSpellMgr->GetSpellBonusData(heal->Id) &&
            heal->HasAttribute(SPELL_ATTR2_CANT_CRIT) && heal->HasAttribute(SPELL_ATTR3_IGNORE_CASTER_MODIFIERS);
    }

    bool Load() override
    {
        return IsWitchHunter(GetCaster()) && GetCaster() == GetUnitOwner();
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* caster = GetCaster();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        return caster && caster->IsAlive() && damage && damage->GetDamage() &&
            eventInfo.GetActor() == caster && damage->GetAttacker() == caster &&
            damage->GetVictim() != caster && damage->GetSchoolMask() == SPELL_SCHOOL_MASK_NORMAL;
    }

    void HealFromDamage(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (!CheckProc(eventInfo))
            return;

        uint64 amount = uint64(eventInfo.GetDamageInfo()->GetDamage()) * uint32(std::max(0, effect->GetAmount())) / 100;
        amount = std::min(amount, uint64(std::numeric_limits<int32>::max()));
        if (amount)
            GetCaster()->CastCustomSpell(SPELL_VAMPIRIC_TONIC_HEAL, SPELLVALUE_BASE_POINT0,
                int32(amount), GetCaster(), TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_witch_hunter_vampiric_tonic::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_witch_hunter_vampiric_tonic::HealFromDamage, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_witch_hunter_holy_water_tonic : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_holy_water_tonic);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellInfo const* buff = sSpellMgr->GetSpellInfo(SPELL_HOLY_WATER_TONIC_BUFF);
        return spellInfo && spellInfo->Id == SPELL_HOLY_WATER_TONIC &&
            spellInfo->SpellFamilyName == WITCH_HUNTER_SPELL_FAMILY &&
            spellInfo->TargetCreatureType == TONIC_CREATURE_TYPES &&
            spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_STUN) &&
            spellInfo->Effects[EFFECT_0].TargetB.GetTarget() == TARGET_UNIT_SRC_AREA_ENEMY &&
            buff && !buff->TargetCreatureType &&
            buff->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_DAMAGE_DONE_VERSUS) &&
            buff->Effects[EFFECT_0].MiscValue == TONIC_CREATURE_TYPES;
    }

    bool Load() override
    {
        return IsWitchHunter(GetCaster());
    }

    void ApplySelfBuff()
    {
        GetCaster()->CastSpell(GetCaster(), SPELL_HOLY_WATER_TONIC_BUFF, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_witch_hunter_holy_water_tonic::ApplySelfBuff);
    }
};
}

void ApplyAscensionWitchHunterTonicContracts(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != WITCH_HUNTER_SPELL_FAMILY ||
        spellInfo->SpellFamilyFlags != flag96(0, 0, 512))
        return;

    SpellEffectInfo& effect = spellInfo->Effects[EFFECT_0];
    if (spellInfo->Id == SPELL_VAMPIRIC_TONIC && effect.IsAura(AuraType(354)) &&
        effect.TriggerSpell == SPELL_VAMPIRIC_TONIC_HEAL && effect.BasePoints == 39 && effect.DieSides == 1 &&
        effect.TargetA.GetTarget() == TARGET_UNIT_CASTER && !effect.TargetB.GetTarget())
        effect.ApplyAuraName = SPELL_AURA_DUMMY;

    if (spellInfo->Id == SPELL_HOLY_WATER_TONIC_BUFF && spellInfo->TargetCreatureType == TONIC_CREATURE_TYPES &&
        effect.IsAura(SPELL_AURA_MOD_DAMAGE_DONE_VERSUS) && effect.MiscValue == TONIC_CREATURE_TYPES &&
        effect.TargetA.GetTarget() == TARGET_UNIT_CASTER && !effect.TargetB.GetTarget() &&
        !spellInfo->Effects[EFFECT_1].Effect && !spellInfo->Effects[EFFECT_2].Effect)
        spellInfo->TargetCreatureType = 0;
}

void AddAscensionWitchHunterTonicScripts()
{
    RegisterSpellScript(spell_ascension_witch_hunter_dark_tonic);
    RegisterSpellScript(spell_ascension_witch_hunter_vampiric_tonic);
    RegisterSpellScript(spell_ascension_witch_hunter_holy_water_tonic);
}
