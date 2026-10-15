/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
constexpr uint32 SPELL_RUIN_TALENT = 805198;
constexpr uint32 SPELL_RUIN = 805199;

class spell_ascension_reaper_ruin_mark : public SpellScript
{
    PrepareSpellScript(spell_ascension_reaper_ruin_mark);

    void MarkTarget(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target || !caster->HasAura(SPELL_RUIN_TALENT))
            return;

        caster->CastSpell(target, SPELL_RUIN, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_reaper_ruin_mark::MarkTarget,
            EFFECT_0, SPELL_EFFECT_ANY);
    }
};
}

void AddSC_AscensionReaperRuin()
{
    RegisterSpellScript(spell_ascension_reaper_ruin_mark);
}
