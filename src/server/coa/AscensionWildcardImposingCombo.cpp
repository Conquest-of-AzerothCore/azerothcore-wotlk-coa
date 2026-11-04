/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
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
}
