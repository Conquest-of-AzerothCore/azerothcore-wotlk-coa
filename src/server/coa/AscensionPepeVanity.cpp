/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"

namespace
{
constexpr uint32 SPELL_PEPE_VANITY = 985980;
constexpr uint32 SPELL_PEPE_WINTERVEIL = 498612;
constexpr uint32 AURA_PEPE_WINTERVEIL = 498613;
constexpr uint32 SPELL_PEPE_VANITY_FIRST = 985981;
constexpr uint32 PEPE_VANITY_VARIANTS = 10;

void RemovePepeVanityBirds(Unit* unit)
{
    for (uint32 i = 0; i < PEPE_VANITY_VARIANTS; ++i)
        unit->RemoveAurasDueToSpell(SPELL_PEPE_VANITY_FIRST + i);
}

class spell_ascension_pepe_vanity : public SpellScript
{
    PrepareSpellScript(spell_ascension_pepe_vanity);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_PEPE_VANITY && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_APPLY_AURA;
    }

    void PerchOnHead(SpellEffIndex)
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        PreventHitAura();
        target->RemoveAurasDueToSpell(AURA_PEPE_WINTERVEIL);
        RemovePepeVanityBirds(target);
        target->CastSpell(target, SPELL_PEPE_VANITY_FIRST + urand(0, PEPE_VANITY_VARIANTS - 1), true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_pepe_vanity::PerchOnHead, EFFECT_0, SPELL_EFFECT_APPLY_AURA);
    }
};

class spell_ascension_pepe_winterveil : public SpellScript
{
    PrepareSpellScript(spell_ascension_pepe_winterveil);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_PEPE_WINTERVEIL;
    }

    void ReplaceVanityBird()
    {
        RemovePepeVanityBirds(GetCaster());
    }

    void Register() override
    {
        OnCast += SpellCastFn(spell_ascension_pepe_winterveil::ReplaceVanityBird);
    }
};
}

void AddAscensionPepeVanityScripts()
{
    RegisterSpellScript(spell_ascension_pepe_vanity);
    RegisterSpellScript(spell_ascension_pepe_winterveil);
}
