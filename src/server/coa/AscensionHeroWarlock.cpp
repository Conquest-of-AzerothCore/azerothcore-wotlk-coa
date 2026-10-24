/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionHeroWarlock.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "Unit.h"

// Grim Reach 818219 capstone: "Dealing periodic Shadow damage to an enemy within melee range has a 33% chance to
// trigger a Grim Strike"
class aura_hero_warlock_grim_reach : public AuraScript
{
    PrepareAuraScript(aura_hero_warlock_grim_reach);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetProcTarget();
        return target && target != GetTarget() && GetTarget()->IsWithinMeleeRange(target);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_warlock_grim_reach::CheckProc);
    }
};

// Seed of Corruption 27243-47836: "When the target takes $s2 total damage or dies, the seed will inflict ...". This
// server's Spell.dbc zeroes $s2 on every rank, so any damage detonated the seed. Ascension's extract (2026-09-02) carries
// 515 / - / - / - / 1296 / 1518: ranks 5 and 6 equal the seed's own damage over time (6 ticks), so ranks 2-4 take the
// same rule from their ticks (109 / 141 / 174). The stock script still adds the spell power bonus on top.
void ApplyAscensionHeroWarlockContracts(SpellInfo* spellInfo)
{
    int32 threshold = 0;
    switch (spellInfo->Id)
    {
        case 27243: threshold = 515; break;
        case 27251: threshold = 654; break;
        case 27252: threshold = 846; break;
        case 27253: threshold = 1044; break;
        case 47835: threshold = 1296; break;
        case 47836: threshold = 1518; break;
        default: return;
    }
    if (spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_DUMMY)
        spellInfo->Effects[EFFECT_1].BasePoints = threshold - 1;
}

void AddSC_AscensionHeroWarlock()
{
    RegisterSpellScript(aura_hero_warlock_grim_reach);
}
