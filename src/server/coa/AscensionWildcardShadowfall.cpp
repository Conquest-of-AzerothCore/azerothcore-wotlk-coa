/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Containers.h"
#include "ScriptMgr.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum ShadowfallSpells : uint32
{
    ShadowfallImpact = 982679
};

class spell_ascension_wildcard_shadowfall_tick : public SpellScript
{
    PrepareSpellScript(spell_ascension_wildcard_shadowfall_tick);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ShadowfallImpact});
    }

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        targets.remove_if([caster](WorldObject const* target)
        {
            return !caster->IsWithinLOS(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ());
        });
        Acore::Containers::RandomResize(targets, 2);
    }

    void HandleDummy(SpellEffIndex)
    {
        GetCaster()->CastSpell(GetHitUnit(), uint32(GetEffectValue()), true);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(
            spell_ascension_wildcard_shadowfall_tick::FilterTargets, EFFECT_0, TARGET_UNIT_SRC_AREA_ENEMY);
        OnEffectHitTarget += SpellEffectFn(
            spell_ascension_wildcard_shadowfall_tick::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};
}

void AddSC_AscensionWildcardShadowfall()
{
    RegisterSpellScript(spell_ascension_wildcard_shadowfall_tick);
}
