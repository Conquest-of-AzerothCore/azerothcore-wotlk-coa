/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionHeroPaladin.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "Unit.h"
#include <algorithm>
#include <array>

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

struct ExecutionSentenceRank
{
    uint32 Active;
    uint32 Sentence;
    uint32 SentenceBurst;
    uint32 Stay;
    uint32 StayBurst;
};

constexpr std::array<ExecutionSentenceRank, 7> EXECUTION_SENTENCE_RANKS = { {
    { 954817, 954818, 954827, 954819, 954828 },
    { 954972, 954979, 954992, 954985, 954998 },
    { 954973, 954980, 954993, 954986, 954999 },
    { 954974, 954981, 954994, 954987, 955000 },
    { 954975, 954982, 954995, 954988, 955001 },
    { 954976, 954983, 954996, 954989, 955002 },
    { 954977, 954984, 954997, 954991, 955003 } } };

ExecutionSentenceRank const* FindExecutionSentenceRank(uint32 spellId)
{
    auto const rank = std::find_if(EXECUTION_SENTENCE_RANKS.begin(), EXECUTION_SENTENCE_RANKS.end(),
        [spellId](ExecutionSentenceRank const& candidate)
        {
            return candidate.Active == spellId || candidate.Sentence == spellId || candidate.Stay == spellId;
        });
    return rank == EXECUTION_SENTENCE_RANKS.end() ? nullptr : &*rank;
}

constexpr int32 FANATICISM_PCT = 20;
flag96 const FANATICISM_MASK(0x02800400,
    0x20008800, 0);
}

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

    void HandleSelf(AuraEffect const* aurEff, ProcEventInfo&)
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

class spell_hero_paladin_shield_of_righteousness : public SpellScript
{
    PrepareSpellScript(spell_hero_paladin_shield_of_righteousness);

    void HandleDamage(SpellEffIndex)
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

class spell_hero_paladin_execution_sentence : public SpellScript
{
    PrepareSpellScript(spell_hero_paladin_execution_sentence);

    void HandleDummy(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        ExecutionSentenceRank const* rank = FindExecutionSentenceRank(GetSpellInfo()->Id);
        if (!rank || !target)
            return;
        if (caster->IsFriendlyTo(target))
            caster->CastSpell(target, rank->Stay, true);
        else if (caster->IsValidAttackTarget(target))
            caster->CastSpell(target, rank->Sentence, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_hero_paladin_execution_sentence::HandleDummy, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

class aura_hero_paladin_execution_sentence_burst : public AuraScript
{
    PrepareAuraScript(aura_hero_paladin_execution_sentence_burst);

    void HandleRemove(AuraEffect const* aurEff, AuraEffectHandleModes)
    {
        AuraRemoveMode const mode = GetTargetApplication()->GetRemoveMode();
        if (mode != AURA_REMOVE_BY_EXPIRE && mode != AURA_REMOVE_BY_ENEMY_SPELL)
            return;
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        ExecutionSentenceRank const* rank = FindExecutionSentenceRank(GetId());
        if (!caster || !rank || !target->IsAlive())
            return;
        caster->CastSpell(target, GetId() == rank->Sentence ? rank->SentenceBurst : rank->StayBurst, true, nullptr,
            aurEff);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_hero_paladin_execution_sentence_burst::HandleRemove, EFFECT_0,
            SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

void ApplyAscensionHeroPaladinContracts(SpellInfo* spellInfo)
{
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
    RegisterSpellScript(spell_hero_paladin_execution_sentence);
    RegisterSpellScript(aura_hero_paladin_execution_sentence_burst);
}
