/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionHeroPriest.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum HeroPriestSpells : uint32
{
    LesserFrozenLightProc = 300023,
    VoidEruptionBuff      = 760185,
    VoidTouchedExtend     = 833215,
    VoidTouchedStack      = 833216
};

constexpr uint32 MIND_BLAST_FLAG0 = 0x00002000;
// Mind Flay's channel (flags2 0x40) deals its damage through the triggered tick 58381 (flags0 0x800000)
constexpr uint32 MIND_FLAY_TICK_FLAG0 = 0x00800000;

// "a target further than 20 yards away from you" (Holy Reach and Shadow Reach capstones)
constexpr float REACH_CAPSTONE_YARDS = 20.0f;
}

// Holy Reach 827790 and Shadow Reach 817323 capstones: "Directly healing or directly damaging a target further than 20
// yards away from you"
class aura_hero_priest_reach_capstone : public AuraScript
{
    PrepareAuraScript(aura_hero_priest_reach_capstone);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetProcTarget();
        return target && target != GetTarget() && !GetTarget()->IsWithinDist(target, REACH_CAPSTONE_YARDS);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_priest_reach_capstone::CheckProc);
    }
};

// Halo rank 1's heal 954875 also triggers Lesser Frozen Light 300024, the Cryotherapist's Holy-heal buff (ranks 2-5
// carry no such effect, and the tooltip names none). Only a caster holding the Cryotherapist proc grants it.
class spell_hero_priest_halo_frozen_light : public SpellScript
{
    PrepareSpellScript(spell_hero_priest_halo_frozen_light);

    void HandleFrozenLight(SpellEffIndex effIndex)
    {
        Unit* caster = GetCaster();
        if (!caster || !caster->HasAura(LesserFrozenLightProc))
            PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_hero_priest_halo_frozen_light::HandleFrozenLight, EFFECT_2,
            SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectLaunchTarget += SpellEffectFn(spell_hero_priest_halo_frozen_light::HandleFrozenLight, EFFECT_2,
            SPELL_EFFECT_TRIGGER_SPELL);
    }
};

// Void-touched Mind 33215 capstone: "Your Mind Blast extends the duration of Void Eruption by up to 3 seconds and your
// Mind Flay ticks increase the periodic damage increase of Void Eruption by an additional 3%, stacks up to 10 times."
// The rank's proc aura triggered 833215 (Void Eruption +3 sec) with no proc flags, and nothing granted the stacking
// 833216 (+3% periodic Shadow damage, 10 stacks).
class aura_hero_priest_void_touched_mind : public AuraScript
{
    PrepareAuraScript(aura_hero_priest_void_touched_mind);

    static bool IsMindBlast(SpellInfo const* spellInfo)
    {
        return spellInfo->SpellFamilyName == SPELLFAMILY_PRIEST && (spellInfo->SpellFamilyFlags[0] & MIND_BLAST_FLAG0);
    }

    static bool IsMindFlay(SpellInfo const* spellInfo)
    {
        return spellInfo->SpellFamilyName == SPELLFAMILY_PRIEST && (spellInfo->SpellFamilyFlags[0] & MIND_FLAY_TICK_FLAG0);
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        if (!spellInfo || !GetTarget()->HasAura(VoidEruptionBuff))
            return false;
        return IsMindBlast(spellInfo) || IsMindFlay(spellInfo);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* priest = GetTarget();
        priest->CastSpell(priest, IsMindBlast(eventInfo.GetSpellInfo()) ? VoidTouchedExtend : VoidTouchedStack, true,
            nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_priest_void_touched_mind::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_hero_priest_void_touched_mind::HandleProc, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

// The Void-touched stacks are an increase "of Void Eruption": they end with it
class aura_hero_priest_void_eruption_buff : public AuraScript
{
    PrepareAuraScript(aura_hero_priest_void_eruption_buff);

    void AfterRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        GetTarget()->RemoveAurasDueToSpell(VoidTouchedStack);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_hero_priest_void_eruption_buff::AfterRemove, EFFECT_2,
            SPELL_AURA_OVERRIDE_CLASS_SCRIPTS, AURA_EFFECT_HANDLE_REAL);
    }
};

void ApplyAscensionHeroPriestContracts(SpellInfo* spellInfo)
{
    // Penance ranks 7-9 carry Ascension's Stances bit (form 32) without SPELL_ATTR2_ALLOW_WHILE_NOT_SHAPESHIFTED, which every
    // lower rank has: the core refused them with SPELL_FAILED_ONLY_SHAPESHIFT
    if (spellInfo->Id == 53005 || spellInfo->Id == 53006 || spellInfo->Id == 53007)
        spellInfo->AttributesEx2 |= SPELL_ATTR2_ALLOW_WHILE_NOT_SHAPESHIFTED;
    // Mind Flay r9 48156: "causing 588 Shadow damage over 3 sec". Spell.dbc ticks it every 10 sec (ranks 1-8: 1 sec), so
    // the 3 sec channel never dealt damage
    else if (spellInfo->Id == 48156)
    {
        for (SpellEffectInfo& effect : spellInfo->Effects)
            if (effect.ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE && effect.Amplitude == 10000)
                effect.Amplitude = 1000;
    }
}

void AddSC_AscensionHeroPriest()
{
    RegisterSpellScript(aura_hero_priest_reach_capstone);
    RegisterSpellScript(spell_hero_priest_halo_frozen_light);
    RegisterSpellScript(aura_hero_priest_void_touched_mind);
    RegisterSpellScript(aura_hero_priest_void_eruption_buff);
}
