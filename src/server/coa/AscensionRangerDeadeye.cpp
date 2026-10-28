/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
enum RangerDeadeyeSpells : uint32
{
    SPELL_DEADEYE = 300700,
    SPELL_AUTO_SHOT = 75
};

class ascension_ranger_deadeye_auto_shot : public GlobalScript
{
public:
    ascension_ranger_deadeye_auto_shot()
        : GlobalScript("ascension_ranger_deadeye_auto_shot", {GLOBALHOOK_ON_IS_AFFECTED_BY_SPELL_MOD_CHECK}) { }

    bool OnIsAffectedBySpellModCheck(SpellInfo const* affectSpell, SpellInfo const* checkSpell,
        SpellModifier const* mod) override
    {
        bool const deadeyeExtendsAutoShot = affectSpell->Id == SPELL_DEADEYE && checkSpell->Id == SPELL_AUTO_SHOT &&
            mod->op == SPELLMOD_RANGE;
        return !deadeyeExtendsAutoShot;
    }
};
}

void AddSC_AscensionRangerDeadeye()
{
    new ascension_ranger_deadeye_auto_shot();
}
