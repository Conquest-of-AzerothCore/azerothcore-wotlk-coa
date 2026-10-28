/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
class spell_ascension_adventure_mode_random_aggro : public SpellScript
{
    PrepareSpellScript(spell_ascension_adventure_mode_random_aggro);

    SpellCastResult CheckCast()
    {
        return GetCaster()->HasSpellCooldown(GetSpellInfo()->Id) ? SPELL_FAILED_DONT_REPORT : SPELL_CAST_OK;
    }

    void StartRecovery()
    {
        GetCaster()->AddSpellCooldown(GetSpellInfo()->Id, 0, GetSpellInfo()->RecoveryTime);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_adventure_mode_random_aggro::CheckCast);
        AfterCast += SpellCastFn(spell_ascension_adventure_mode_random_aggro::StartRecovery);
    }
};
}

void AddSC_AscensionAdventureModeRandomAggro()
{
    RegisterSpellScript(spell_ascension_adventure_mode_random_aggro);
}
