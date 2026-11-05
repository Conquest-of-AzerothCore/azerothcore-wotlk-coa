/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "GameTime.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
class aura_wildcard_imposing_combo_ability : public AuraScript
{
    PrepareAuraScript(aura_wildcard_imposing_combo_ability);

    uint32 _spell = 0;
    Milliseconds _at = 0ms;
    bool _fired = false;

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        if (!spell || !target || eventInfo.GetActor() != caster || !(eventInfo.GetHitMask() & (PROC_HIT_NORMAL | PROC_HIT_CRITICAL)))
            return false;
        if (caster->GetComboTarget() != target || !caster->GetComboPoints())
            return false;
        Milliseconds const now = GameTime::GetGameTimeMS();
        if (_spell == spell->Id && _at == now)
            return !_fired;
        _spell = spell->Id;
        _at = now;
        _fired = false;
        return true;
    }

    void MarkFired(ProcEventInfo&)
    {
        _fired = true;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_imposing_combo_ability::CheckProc);
        AfterProc += AuraProcFn(aura_wildcard_imposing_combo_ability::MarkFired);
    }
};

class spell_wildcard_imposing_combo_clear_combo_points : public SpellScript
{
    PrepareSpellScript(spell_wildcard_imposing_combo_clear_combo_points);

    void HandleClear(SpellEffIndex)
    {
        GetCaster()->ClearComboPoints();
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_wildcard_imposing_combo_clear_combo_points::HandleClear, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};
}

void AddSC_AscensionWildcardImposingCombo()
{
    RegisterSpellScript(spell_wildcard_imposing_combo_clear_combo_points);
    RegisterSpellScript(aura_wildcard_imposing_combo_ability);
}
