/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Random.h"
#include "ScriptMgr.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum SolarStrikeSpells : uint32
{
    SolarBurn = 274532
};

class spell_ascension_wildcard_solar_strike : public SpellScript
{
    PrepareSpellScript(spell_ascension_wildcard_solar_strike);

    uint8 _comboPoints = 0;

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SolarBurn}); }

    void SnapshotPoints()
    {
        _comboPoints = GetCaster()->GetComboPoints();
    }

    void Burn()
    {
        if (GetHitUnit() && GetHitDamage() > 0 && roll_chance_i(20 * _comboPoints))
            GetCaster()->CastSpell(GetHitUnit(), SolarBurn, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_wildcard_solar_strike::SnapshotPoints);
        AfterHit += SpellHitFn(spell_ascension_wildcard_solar_strike::Burn);
    }
};
}

void AddSC_AscensionWildcardSolarStrike()
{
    RegisterSpellScript(spell_ascension_wildcard_solar_strike);
}
