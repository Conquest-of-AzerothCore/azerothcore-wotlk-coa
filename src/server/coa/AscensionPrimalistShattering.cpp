/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"

namespace
{
enum ShatteringSpells : uint32
{
    Shattering = 520469,
    ShatteringBuff = 520729,
    JudgementDamage = 520468
};

class primalist_shattering : public AllSpellScript
{
public:
    primalist_shattering() : AllSpellScript("primalist_shattering", {ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellHitResult(Spell* spell, Unit*, uint8 miss, uint32 damage, uint32, bool) override
    {
        Unit* caster = spell->GetCaster();
        if (damage && miss == SPELL_MISS_NONE && caster->IsPlayer() && caster->IsAlive() &&
            caster->getClass() == CLASS_WILDWALKER && spell->GetSpellInfo()->Id == JudgementDamage &&
            spell->GetSpellInfo()->SpellFamilyName == 37 && caster->HasAura(Shattering, caster->GetGUID()))
            caster->CastSpell(caster, ShatteringBuff, TRIGGERED_FULL_MASK);
    }
};
}

void AddSC_AscensionPrimalistShattering()
{
    new primalist_shattering();
}
