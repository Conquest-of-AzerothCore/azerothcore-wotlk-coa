/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "Unit.h"
#include <list>

namespace
{
enum HeroDruidSpells : uint32
{
    VengefulSoulRestore = 816914
};

constexpr uint32 INSECT_SWARM_FLAG0 = 0x00200000;
constexpr float NATURES_REACH_YARDS = 5.0f;
constexpr uint32 NATURES_REACH_TARGETS = 10;

AuraEffect const* CastersInsectSwarm(Unit* target, Unit* caster)
{
    return target->GetAuraEffect(SPELL_AURA_PERIODIC_DAMAGE, SPELLFAMILY_DRUID, INSECT_SWARM_FLAG0, 0, 0,
        caster->GetGUID());
}
}

class aura_hero_druid_natures_reach : public AuraScript
{
    PrepareAuraScript(aura_hero_druid_natures_reach);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetProcTarget();
        return target && target != GetTarget() && CastersInsectSwarm(target, GetTarget());
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* druid = GetTarget();
        Unit* target = eventInfo.GetProcTarget();
        AuraEffect const* swarm = CastersInsectSwarm(target, druid);
        if (!swarm)
            return;
        std::list<Unit*> nearby;
        Acore::AnyUnfriendlyUnitInObjectRangeCheck check(target, druid, NATURES_REACH_YARDS);
        Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(target, nearby, check);
        Cell::VisitObjects(target, searcher, NATURES_REACH_YARDS);
        uint32 spread = 0;
        for (Unit* enemy : nearby)
        {
            if (enemy == target || CastersInsectSwarm(enemy, druid) || !druid->IsValidAttackTarget(enemy))
                continue;
            druid->CastSpell(enemy, swarm->GetId(), true, nullptr, aurEff);
            if (++spread >= NATURES_REACH_TARGETS)
                break;
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_druid_natures_reach::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_hero_druid_natures_reach::HandleProc, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectProc += AuraEffectProcFn(aura_hero_druid_natures_reach::PreventSecond, EFFECT_2,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }

    void PreventSecond(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
    }
};

class aura_hero_druid_vengeful_soul : public AuraScript
{
    PrepareAuraScript(aura_hero_druid_vengeful_soul);

    void AfterRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        Unit* druid = GetTarget();
        int32 const missing = int32(druid->GetMaxPower(POWER_MANA)) - int32(druid->GetPower(POWER_MANA));
        if (missing <= 0)
            return;
        druid->EnergizeBySpell(druid, VengefulSoulRestore, CalculatePct(missing, 5), POWER_MANA);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_hero_druid_vengeful_soul::AfterRemove, EFFECT_0,
            SPELL_AURA_MOD_DAMAGE_PERCENT_DONE, AURA_EFFECT_HANDLE_REAL);
    }
};

void AddSC_AscensionHeroDruid()
{
    RegisterSpellScript(aura_hero_druid_natures_reach);
    RegisterSpellScript(aura_hero_druid_vengeful_soul);
}
