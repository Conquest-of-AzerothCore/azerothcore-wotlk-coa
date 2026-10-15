/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"

namespace
{
enum RylaksBiteSpells : uint32
{
    RylaksBiteCharge = 707293
};

class spell_ascension_rylaks_bite : public SpellScript
{
    PrepareSpellScript(spell_ascension_rylaks_bite);

    void Rush()
    {
        Unit* caster = GetCaster();
        Unit* target = GetExplTargetUnit();
        if (!target)
            return;

        caster->CastSpell(target, RylaksBiteCharge, true);
        if (Player* player = caster->ToPlayer())
            if (Pet* pet = player->GetPet())
                if (pet->IsAlive())
                    pet->CastSpell(target, RylaksBiteCharge, true);
    }

    void Register() override
    {
        OnCast += SpellCastFn(spell_ascension_rylaks_bite::Rush);
    }
};
}

void AddSC_AscensionPrimalistRylaksBite()
{
    RegisterSpellScript(spell_ascension_rylaks_bite);
}
