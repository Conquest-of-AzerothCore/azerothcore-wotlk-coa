/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionHeroWarlock.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "Unit.h"

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
