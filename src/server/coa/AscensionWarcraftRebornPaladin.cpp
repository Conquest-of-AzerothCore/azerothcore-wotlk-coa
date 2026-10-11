/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include <algorithm>
#include <vector>

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 BLESSING_OF_SANCTUARY_BUFF = 1167480;
constexpr uint32 BLESSING_OF_SANCTUARY_ENERGIZE = 57319;
constexpr uint32 RIGHTEOUS_DEFENSE_TAUNT = 1131790;
constexpr std::size_t RIGHTEOUS_DEFENSE_TARGETS = 3;

class spell_ascension_reborn_blessing_of_sanctuary : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_blessing_of_sanctuary);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ BLESSING_OF_SANCTUARY_BUFF, BLESSING_OF_SANCTUARY_ENERGIZE });
    }

    void HandleApply(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Unit* caster = GetCaster())
            caster->CastSpell(GetTarget(), BLESSING_OF_SANCTUARY_BUFF, true);
    }

    void HandleRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAura(BLESSING_OF_SANCTUARY_BUFF, GetCasterGUID());
    }

    bool CheckProc(ProcEventInfo&)
    {
        return GetTarget()->HasActivePowerType(POWER_MANA);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), BLESSING_OF_SANCTUARY_ENERGIZE, true, nullptr, aurEff);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_ascension_reborn_blessing_of_sanctuary::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_reborn_blessing_of_sanctuary::HandleRemove, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        DoCheckProc += AuraCheckProcFn(spell_ascension_reborn_blessing_of_sanctuary::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_blessing_of_sanctuary::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_reborn_righteous_defense : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_righteous_defense);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ RIGHTEOUS_DEFENSE_TAUNT });
    }

    SpellCastResult CheckCast()
    {
        Unit* target = GetExplTargetUnit();
        if (!GetCaster()->IsPlayer())
            return SPELL_FAILED_DONT_REPORT;
        if (!target || !target->IsFriendlyTo(GetCaster()) || target->getAttackers().empty())
            return SPELL_FAILED_BAD_TARGETS;
        return SPELL_CAST_OK;
    }

    void HandleDummy(SpellEffIndex)
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        std::vector<Unit*> attackers(target->getAttackers().begin(), target->getAttackers().end());
        Unit* caster = GetCaster();
        std::sort(attackers.begin(), attackers.end(),
            [target](Unit const* a, Unit const* b) { return target->GetDistance(a) < target->GetDistance(b); });
        std::size_t taunted = 0;
        for (Unit* attacker : attackers)
        {
            if (taunted == RIGHTEOUS_DEFENSE_TARGETS)
                break;
            if (!caster->IsValidAttackTarget(attacker))
                continue;
            caster->CastSpell(attacker, RIGHTEOUS_DEFENSE_TAUNT, true);
            ++taunted;
        }
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_reborn_righteous_defense::CheckCast);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_reborn_righteous_defense::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};
}
}

void AddAscensionWarcraftRebornPaladinScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_blessing_of_sanctuary);
    RegisterSpellScript(spell_ascension_reborn_righteous_defense);
}
