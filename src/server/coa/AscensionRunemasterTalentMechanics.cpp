/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <vector>

namespace
{
enum RunemasterTalentMechanicSpells : uint32
{
    SPELL_RUNIC_BRAND = 712299,
    SPELL_CINDERSTORM_RUNES = 706458,
    SPELL_TURBULENT_SPIRAL = 707153,
    SPELL_GLYPHIC_DESTRUCTION = 800758,
    SPELL_RUNIC_OMEN = 520285,
    SPELL_RUNIC_OMEN_EMPOWER = 705596
};

constexpr uint32 RUNEMASTER_SPELL_FAMILY = uint32(CLASS_SPIRIT_MAGE) + 6;

bool IsRunemaster(Unit const* unit)
{
    return unit && unit->IsPlayer() && unit->getClass() == CLASS_SPIRIT_MAGE;
}

void ReduceRankCooldowns(Player* player, uint32 firstRank, int32 delta)
{
    if (!player || delta >= 0)
        return;
    std::vector<uint32> cooling;
    for (auto const& [spellId, cooldown] : player->GetSpellCooldownMap())
        if (sSpellMgr->GetFirstSpellInChain(spellId) == firstRank)
            cooling.push_back(spellId);
    for (uint32 spellId : cooling)
    {
        uint32 const remaining = player->GetSpellCooldownDelay(spellId);
        if (uint64(-int64(delta)) >= remaining)
            player->RemoveSpellCooldown(spellId, true);
        else
            player->ModifySpellCooldown(spellId, delta);
    }
}

class spell_ascension_runemaster_power_overwhelming_reset : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_power_overwhelming_reset);

    bool Validate(SpellInfo const* info) override
    {
        SpellEffectInfo const& effect = info->Effects[EFFECT_0];
        return effect.Effect == SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN &&
            effect.MiscValue == int32(SPELL_RUNIC_BRAND) && !effect.MiscValueB &&
            ValidateSpellInfo({SPELL_RUNIC_BRAND});
    }

    bool Load() override
    {
        return IsRunemaster(GetCaster());
    }

    void ResetEveryRank(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        ReduceRankCooldowns(GetHitPlayer(), uint32(GetSpellInfo()->Effects[effIndex].MiscValue), GetEffectValue());
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_runemaster_power_overwhelming_reset::ResetEveryRank,
            EFFECT_0, SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN);
    }
};

class spell_ascension_runemaster_runic_omen_empower : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_runic_omen_empower);

    bool Validate(SpellInfo const* info) override
    {
        SpellEffectInfo const& effect = info->Effects[EFFECT_1];
        return effect.Effect == SPELL_EFFECT_DUMMY && effect.TriggerSpell == SPELL_RUNIC_OMEN_EMPOWER &&
            ValidateSpellInfo({SPELL_RUNIC_OMEN_EMPOWER});
    }

    bool Load() override
    {
        return IsRunemaster(GetCaster());
    }

    void Empower(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Player* player = GetHitPlayer();
        if (!player)
            return;
        Aura* counter = player->GetAura(SPELL_RUNIC_OMEN, player->GetGUID());
        if (counter && counter->GetStackAmount() >= 3)
        {
            player->RemoveAurasDueToSpell(SPELL_RUNIC_OMEN, player->GetGUID());
            player->CastSpell(player, SPELL_RUNIC_OMEN_EMPOWER, true);
        }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_runemaster_runic_omen_empower::Empower,
            EFFECT_1, SPELL_EFFECT_DUMMY);
    }
};

class aura_ascension_runemaster_turbulence : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_turbulence);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_TURBULENT_SPIRAL});
    }

    bool Load() override
    {
        return IsRunemaster(GetCaster()) && GetCaster() == GetUnitOwner();
    }

    void LeaveSpiral(AuraEffect const* aurEff)
    {
        Unit* runemaster = GetTarget();
        if (runemaster->IsAlive() && runemaster->IsInWorld())
            runemaster->CastSpell(runemaster, SPELL_TURBULENT_SPIRAL, TRIGGERED_FULL_MASK, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_runemaster_turbulence::LeaveSpiral,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

class runemaster_cinderstorm_runes_metadata : public GlobalScript
{
public:
    runemaster_cinderstorm_runes_metadata() : GlobalScript("runemaster_cinderstorm_runes_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id != SPELL_CINDERSTORM_RUNES || info->SpellFamilyName != RUNEMASTER_SPELL_FAMILY)
            return;
        SpellEffectInfo& effect = info->Effects[EFFECT_0];
        int32 const state = AURA_STATE_HEALTHLESS_20_PERCENT;
        bool const copied = effect.ApplyAuraName == SPELL_AURA_OVERRIDE_CLASS_SCRIPTS &&
            effect.MiscValue == ASCENSION_CLASSMASK_AURASTATE_DAMAGE && effect.MiscValueB == state;
        bool const converted = effect.ApplyAuraName == SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE &&
            effect.MiscValue == state && effect.MiscValueB == ASCENSION_CLASSMASK_AURASTATE_DAMAGE;
        if (effect.Effect != SPELL_EFFECT_APPLY_AURA || (!copied && !converted) || effect.BasePoints != 49 ||
            effect.DieSides != 1 || effect.SpellClassMask != flag96(512, 0, 4) ||
            effect.TargetA.GetTarget() != TARGET_UNIT_CASTER || effect.TargetB.GetTarget())
        {
            LOG_ERROR("coa", "Skipped unexpected Cinderstorm Runes record {}", info->Id);
            return;
        }
        effect.ApplyAuraName = SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE;
        effect.MiscValue = state;
        effect.MiscValueB = ASCENSION_CLASSMASK_AURASTATE_DAMAGE;
    }
};

class runemaster_glyphic_destruction_metadata : public GlobalScript
{
public:
    runemaster_glyphic_destruction_metadata() : GlobalScript("runemaster_glyphic_destruction_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id != SPELL_GLYPHIC_DESTRUCTION || info->SpellFamilyName != RUNEMASTER_SPELL_FAMILY)
            return;
        SpellEffectInfo& effect = info->Effects[EFFECT_0];
        int32 const state = AURA_STATE_FROZEN;
        bool const copied = effect.ApplyAuraName == SPELL_AURA_OVERRIDE_CLASS_SCRIPTS &&
            effect.MiscValue == ASCENSION_CLASSMASK_AURASTATE_DAMAGE && effect.MiscValueB == state;
        bool const converted = effect.ApplyAuraName == SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE &&
            effect.MiscValue == state && effect.MiscValueB == ASCENSION_CLASSMASK_AURASTATE_DAMAGE;
        if (effect.Effect != SPELL_EFFECT_APPLY_AURA || (!copied && !converted) || effect.BasePoints != 99 ||
            effect.DieSides != 1 || effect.SpellClassMask != flag96(4096, 0, 0) ||
            effect.TargetA.GetTarget() != TARGET_UNIT_CASTER || effect.TargetB.GetTarget())
        {
            LOG_ERROR("coa", "Skipped unexpected Glyphic Destruction record {}", info->Id);
            return;
        }
        effect.ApplyAuraName = SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE;
        effect.MiscValue = state;
        effect.MiscValueB = ASCENSION_CLASSMASK_AURASTATE_DAMAGE;
    }
};
}

void AddSC_AscensionRunemasterTalentMechanics()
{
    RegisterSpellScript(spell_ascension_runemaster_power_overwhelming_reset);
    RegisterSpellScript(spell_ascension_runemaster_runic_omen_empower);
    RegisterSpellScript(aura_ascension_runemaster_turbulence);
    new runemaster_cinderstorm_runes_metadata();
    new runemaster_glyphic_destruction_metadata();
}
