/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionHeroPaladin.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum HeroPaladinSpells : uint32
{
    BlindingLight     = 954500,
    FanaticismDebuff  = 31882,
    ShieldOfRighteous = 53600,
    SharedMightAlly   = 920042,
    SharedMightSelf   = 920043,
    ImprovedJudgementsCapstone = 25958,
    Unsealed          = 825958
};

// Fanaticism's debuff: "Increases the damage of your Crusader Strike, Seals and Judgements on targets affected by your
// Execution Sentence by 20%"
constexpr int32 FANATICISM_PCT = 20;
flag96 const FANATICISM_MASK(0x02800400 /* Judgements, Seal of Command */,
    0x20008800 /* Seal of Righteousness, Crusader Strike, Seal of Vengeance */, 0);
}

// Touched by the Light 53590-53592: "When you receive effective healing from another player"
class aura_hero_paladin_touched_by_the_light : public AuraScript
{
    PrepareAuraScript(aura_hero_paladin_touched_by_the_light);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* healer = eventInfo.GetActor();
        HealInfo* heal = eventInfo.GetHealInfo();
        return healer && healer != GetTarget() && healer->IsPlayer() && heal && heal->GetEffectiveHeal();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_paladin_touched_by_the_light::CheckProc);
    }
};

// Sanctified Light 20361 capstone: "After using Blinding Light your next Holy Light, Flash of Light, Holy Shock or
// Light of Dawn has a 100% increased critical effect chance"
class aura_hero_paladin_sanctified_light : public AuraScript
{
    PrepareAuraScript(aura_hero_paladin_sanctified_light);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        return spellInfo && spellInfo->Id == BlindingLight;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_paladin_sanctified_light::CheckProc);
    }
};

// Benediction 20101-20103: "Restores 30% base mana when you kill a target that gives experience or honor"
class aura_hero_paladin_benediction : public AuraScript
{
    PrepareAuraScript(aura_hero_paladin_benediction);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* victim = eventInfo.GetActionTarget();
        Player* player = GetTarget()->ToPlayer();
        return victim && player && player->isHonorOrXPTarget(victim);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_paladin_benediction::CheckProc);
    }
};

// Improved Blessing of Might 20042/20045: "Casting Blessing of Might on an ally increases their and your attack power
// ... Can only be active on one ally at a time." The rank's two triggers fire at the proc target; 920042 cannot be
// self-cast and 920043 is the paladin's own copy.
class aura_hero_paladin_improved_blessing_of_might : public AuraScript
{
    PrepareAuraScript(aura_hero_paladin_improved_blessing_of_might);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* ally = eventInfo.GetProcTarget();
        return ally && ally != GetTarget();
    }

    void HandleAlly(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* paladin = GetTarget();
        Unit* ally = eventInfo.GetProcTarget();
        if (Unit* previous = ObjectAccessor::GetUnit(*paladin, _ally))
            if (previous != ally)
                previous->RemoveAurasDueToSpell(SharedMightAlly, paladin->GetGUID());
        _ally = ally->GetGUID();
        paladin->CastSpell(ally, SharedMightAlly, true, nullptr, aurEff);
    }

    void HandleSelf(AuraEffect const* aurEff, ProcEventInfo& /*eventInfo*/)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), SharedMightSelf, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_paladin_improved_blessing_of_might::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_hero_paladin_improved_blessing_of_might::HandleAlly, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectProc += AuraEffectProcFn(aura_hero_paladin_improved_blessing_of_might::HandleSelf, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }

    ObjectGuid _ally;
};

// Improved Judgements 25958 capstone: "For 10 seconds after using Judgement, your non-instant damaging Holy spells and
// ranged abilities can trigger your active seal". Judgement 20271/53407/53408 cannot trigger procs
// (SPELL_ATTR3_SUPPRESS_CASTER_PROCS) and its damage is cast with procs disabled: the cast grants Unsealed.
class spell_hero_paladin_judgement_unsealed : public SpellScript
{
    PrepareSpellScript(spell_hero_paladin_judgement_unsealed);

    void HandleAfterCast()
    {
        Unit* caster = GetCaster();
        if (caster->HasAura(ImprovedJudgementsCapstone))
            caster->CastSpell(caster, Unsealed, true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_hero_paladin_judgement_unsealed::HandleAfterCast);
    }
};

// Fanaticism 31881 capstone: Execution Sentence marks the target (31882) for the 20% bonus
class aura_hero_paladin_fanaticism : public AuraScript
{
    PrepareAuraScript(aura_hero_paladin_fanaticism);

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (Unit* target = eventInfo.GetProcTarget())
        {
            int32 pct = FANATICISM_PCT;
            GetTarget()->CastCustomSpell(target, FanaticismDebuff, &pct, nullptr, nullptr, true, nullptr, aurEff);
        }
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(aura_hero_paladin_fanaticism::HandleProc, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

// Shield of Righteousness 53600: "causing Holy damage based on your block value plus an additional $s2". Ascension
// moved the damage to effect 2 (5 + 2 per level); the stock handler reads that effect as the block value percent
// (5%). Stock: 100% of block value.
class spell_hero_paladin_shield_of_righteousness : public SpellScript
{
    PrepareSpellScript(spell_hero_paladin_shield_of_righteousness);

    void HandleDamage(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        uint8 const level = caster->GetLevel();
        uint32 const blockValue = caster->GetShieldBlockValue(uint32(float(level) * 29.5f), uint32(float(level) * 34.5f));
        int32 const stockPct = GetSpellInfo()->Effects[EFFECT_1].CalcValue();
        SetEffectValue(GetEffectValue() + int32(CalculatePct(blockValue, 100 - stockPct)));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_hero_paladin_shield_of_righteousness::HandleDamage, EFFECT_1,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

void ApplyAscensionHeroPaladinContracts(SpellInfo* spellInfo)
{
    // Fanaticism's debuff 31882: limited to the abilities the tooltip names
    if (spellInfo->Id == FanaticismDebuff)
        spellInfo->Effects[EFFECT_0].SpellClassMask = FANATICISM_MASK;
}

void AddSC_AscensionHeroPaladin()
{
    RegisterSpellScript(aura_hero_paladin_touched_by_the_light);
    RegisterSpellScript(aura_hero_paladin_sanctified_light);
    RegisterSpellScript(aura_hero_paladin_benediction);
    RegisterSpellScript(aura_hero_paladin_fanaticism);
    RegisterSpellScript(aura_hero_paladin_improved_blessing_of_might);
    RegisterSpellScript(spell_hero_paladin_judgement_unsealed);
    RegisterSpellScript(spell_hero_paladin_shield_of_righteousness);
}
