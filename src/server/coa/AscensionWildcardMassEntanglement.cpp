/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum MassEntanglementSpells : uint32
{
    SpreadingRootsA1 = 954643,
    SpreadingRootsA2 = 954644,
    SpreadingRootsIcdA = 954645,
    SpreadingRootsB1 = 283457,
    SpreadingRootsB2 = 283458,
    SpreadingRootsIcdB = 283460
};

uint32 IcdFor(uint32 spellId)
{
    if (spellId == SpreadingRootsA1 || spellId == SpreadingRootsA2)
        return SpreadingRootsIcdA;
    if (spellId == SpreadingRootsB1 || spellId == SpreadingRootsB2)
        return SpreadingRootsIcdB;
    return 0;
}
}

class spell_ascension_wildcard_mass_entanglement_spread : public SpellScript
{
    PrepareSpellScript(spell_ascension_wildcard_mass_entanglement_spread);

    void FilterAlreadyRooted(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        uint32 icd = IcdFor(GetSpellInfo()->Id);
        if (!caster || !icd)
            return;
        targets.remove_if([&](WorldObject* object)
        {
            Unit* unit = object->ToUnit();
            return unit && unit->HasAura(icd, caster->GetGUID());
        });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(
            spell_ascension_wildcard_mass_entanglement_spread::FilterAlreadyRooted,
            EFFECT_0, TARGET_UNIT_DEST_AREA_ENEMY);
    }
};

void AddSC_AscensionWildcardMassEntanglement()
{
    RegisterSpellScript(spell_ascension_wildcard_mass_entanglement_spread);
}
