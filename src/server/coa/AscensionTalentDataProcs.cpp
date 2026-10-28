/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "GameTime.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"
#include <algorithm>
#include <iterator>

namespace
{
enum TalentDataProcSpells : uint32
{
    SPELL_ECLIPSE_SOLAR = 48517,
    SPELL_ECLIPSE_LUNAR = 48518,
    SPELL_REVITALIZE_ENERGIZE = 48542,
    SPELL_CUT_TO_THE_CHASE_REFRESH = 9931095
};

constexpr Milliseconds ECLIPSE_COOLDOWN = 30s;
constexpr uint32 REVITALIZE_DIRECT_CHANCE[] = {33, 67, 100};

constexpr uint32 DRUID_HEALING_TOUCH = 0x20;
constexpr uint32 DRUID_REGROWTH = 0x40;
constexpr uint32 DRUID_REJUVENATION = 0x10;
constexpr uint32 DRUID_WILD_GROWTH = 0x4000000;
constexpr uint32 DRUID_EFFLORESCENCE = 0x10000000;
constexpr uint32 DRUID_FEROCIOUS_BITE = 0x800000;
constexpr uint32 ROGUE_EVISCERATE = 0x20000;
constexpr uint32 ROGUE_ENVENOM = 0x8;
constexpr uint32 ROGUE_SLICE_AND_DICE = 0x40000;

int32 PctOfMaxMana(Unit const* unit, uint32 spellId)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    return info ? CalculatePct(int32(unit->GetMaxPower(POWER_MANA)), info->Effects[EFFECT_0].CalcValue()) : 0;
}

class aura_ascension_magic_absorption : public AuraScript
{
    PrepareAuraScript(aura_ascension_magic_absorption);

    bool CheckProc(ProcEventInfo&)
    {
        return GetTarget()->GetMaxPower(POWER_MANA) > 0;
    }

    void Restore(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        uint32 const trigger = GetSpellInfo()->Effects[effect->GetEffIndex()].TriggerSpell;
        GetTarget()->CastCustomSpell(trigger, SPELLVALUE_BASE_POINT0, PctOfMaxMana(GetTarget(), trigger), GetTarget(),
            true, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_magic_absorption::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_magic_absorption::Restore, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_ascension_eclipse : public AuraScript
{
    PrepareAuraScript(aura_ascension_eclipse);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_ECLIPSE_SOLAR, SPELL_ECLIPSE_LUNAR});
    }

    bool InEclipse() const
    {
        return GetTarget()->HasAura(SPELL_ECLIPSE_SOLAR) || GetTarget()->HasAura(SPELL_ECLIPSE_LUNAR);
    }

    bool Ready(ProcEventInfo& event, SpellSchoolMask school, Milliseconds readyAt) const
    {
        return (event.GetSchoolMask() & school) && GameTime::GetGameTimeMS() >= readyAt && !InEclipse();
    }

    bool CheckSolar(AuraEffect const*, ProcEventInfo& event)
    {
        return Ready(event, SPELL_SCHOOL_MASK_ARCANE, _solarReady);
    }

    bool CheckLunar(AuraEffect const*, ProcEventInfo& event)
    {
        return Ready(event, SPELL_SCHOOL_MASK_NATURE, _lunarReady);
    }

    void Enter(AuraEffect const* effect, uint32 spellId, Milliseconds& readyAt)
    {
        PreventDefaultAction();
        if (InEclipse())
            return;
        readyAt = GameTime::GetGameTimeMS() + ECLIPSE_COOLDOWN;
        GetTarget()->CastSpell(GetTarget(), spellId, true, nullptr, effect);
    }

    void Solar(AuraEffect const* effect, ProcEventInfo&)
    {
        Enter(effect, SPELL_ECLIPSE_SOLAR, _solarReady);
    }

    void Lunar(AuraEffect const* effect, ProcEventInfo&)
    {
        Enter(effect, SPELL_ECLIPSE_LUNAR, _lunarReady);
    }

    void Register() override
    {
        DoCheckEffectProc += AuraCheckEffectProcFn(aura_ascension_eclipse::CheckSolar, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        DoCheckEffectProc += AuraCheckEffectProcFn(aura_ascension_eclipse::CheckLunar, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectProc += AuraEffectProcFn(aura_ascension_eclipse::Solar, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectProc += AuraEffectProcFn(aura_ascension_eclipse::Lunar, EFFECT_1, SPELL_AURA_PROC_TRIGGER_SPELL);
    }

    Milliseconds _solarReady = 0ms;
    Milliseconds _lunarReady = 0ms;
};

class aura_ascension_revitalize : public AuraScript
{
    PrepareAuraScript(aura_ascension_revitalize);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_REVITALIZE_ENERGIZE});
    }

    bool CheckProc(ProcEventInfo& event)
    {
        SpellInfo const* spell = event.GetSpellInfo();
        if (!spell || spell->SpellFamilyName != SPELLFAMILY_DRUID || !event.GetProcTarget())
            return false;
        flag96 const& flags = spell->SpellFamilyFlags;
        bool const periodic = event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC;
        if (!periodic && (flags[0] & (DRUID_HEALING_TOUCH | DRUID_REGROWTH)))
        {
            uint8 const rank = std::clamp<uint8>(GetSpellInfo()->GetRank(), 1,
                uint8(std::size(REVITALIZE_DIRECT_CHANCE)));
            return roll_chance_i(REVITALIZE_DIRECT_CHANCE[rank - 1]);
        }
        if ((flags[0] & DRUID_REJUVENATION) || (flags[1] & DRUID_WILD_GROWTH) || (flags[2] & DRUID_EFFLORESCENCE))
            return roll_chance_i(GetSpellInfo()->ProcChance);
        return false;
    }

    void Restore(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* target = event.GetProcTarget();
        GetTarget()->CastCustomSpell(SPELL_REVITALIZE_ENERGIZE, SPELLVALUE_BASE_POINT0,
            PctOfMaxMana(target, SPELL_REVITALIZE_ENERGIZE), target, true, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_revitalize::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_revitalize::Restore, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_ascension_cut_to_the_chase : public AuraScript
{
    PrepareAuraScript(aura_ascension_cut_to_the_chase);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_CUT_TO_THE_CHASE_REFRESH});
    }

    bool CheckProc(ProcEventInfo& event)
    {
        SpellInfo const* spell = event.GetSpellInfo();
        if (!spell)
            return false;
        flag96 const& flags = spell->SpellFamilyFlags;
        if (spell->SpellFamilyName == SPELLFAMILY_ROGUE)
            return (flags[0] & ROGUE_EVISCERATE) || (flags[1] & ROGUE_ENVENOM);
        return spell->SpellFamilyName == SPELLFAMILY_DRUID && (flags[0] & DRUID_FEROCIOUS_BITE);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_cut_to_the_chase::CheckProc);
    }
};

class spell_ascension_cut_to_the_chase_refresh : public SpellScript
{
    PrepareSpellScript(spell_ascension_cut_to_the_chase_refresh);

    void Refresh(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        AuraEffect const* sliceAndDice = caster->GetAuraEffect(SPELL_AURA_MOD_MELEE_HASTE, SPELLFAMILY_ROGUE,
            ROGUE_SLICE_AND_DICE, 0, 0, caster->GetGUID());
        if (!sliceAndDice)
            return;
        Aura* aura = sliceAndDice->GetBase();
        aura->SetDuration(sliceAndDice->GetSpellInfo()->GetMaxDuration(), true);
        aura->SetMaxDuration(aura->GetDuration());
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_cut_to_the_chase_refresh::Refresh, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};
}

void AddSC_AscensionTalentDataProcs()
{
    RegisterSpellScript(aura_ascension_magic_absorption);
    RegisterSpellScript(aura_ascension_eclipse);
    RegisterSpellScript(aura_ascension_revitalize);
    RegisterSpellScript(aura_ascension_cut_to_the_chase);
    RegisterSpellScript(spell_ascension_cut_to_the_chase_refresh);
}
