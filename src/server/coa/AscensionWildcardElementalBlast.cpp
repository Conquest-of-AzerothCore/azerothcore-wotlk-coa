/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Random.h"
#include "ScriptMgr.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum ElementalBlastSpells : uint32
{
    ElementalBlastCriticalStrike = 954842,
    ElementalBlastHaste = 954843
};

class spell_ascension_wildcard_elemental_blast : public SpellScript
{
    PrepareSpellScript(spell_ascension_wildcard_elemental_blast);

    bool _granted = false;

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ElementalBlastCriticalStrike, ElementalBlastHaste});
    }

    void GrantBuff()
    {
        if (_granted || !GetHitUnit() || GetHitDamage() <= 0)
            return;
        _granted = true;
        GetCaster()->CastSpell(GetCaster(), urand(0, 1) ? ElementalBlastCriticalStrike : ElementalBlastHaste,
            TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_ascension_wildcard_elemental_blast::GrantBuff);
    }
};
}

void AddSC_AscensionWildcardElementalBlast()
{
    RegisterSpellScript(spell_ascension_wildcard_elemental_blast);
}
