/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace AscensionWarcraftReborn
{
namespace
{
class spell_ascension_reborn_magic_absorption : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_magic_absorption);

    uint32 StockTrigger() const
    {
        SpellInfo const* stock = sSpellMgr->GetSpellInfo(sSpellMgr->GetSpellTwinSource(GetId()));
        return stock ? stock->Effects[EFFECT_0].TriggerSpell : 0;
    }

    bool CheckProc(ProcEventInfo&)
    {
        return GetTarget()->GetMaxPower(POWER_MANA) > 0 && StockTrigger();
    }

    void Restore(AuraEffect const* aurEff, ProcEventInfo&)
    {
        PreventDefaultAction();
        uint32 const trigger = StockTrigger();
        SpellInfo const* triggerInfo = sSpellMgr->GetSpellInfo(trigger);
        if (!triggerInfo)
            return;
        int32 const mana = CalculatePct(int32(GetTarget()->GetMaxPower(POWER_MANA)), triggerInfo->Effects[EFFECT_0].CalcValue());
        GetTarget()->CastCustomSpell(trigger, SPELLVALUE_BASE_POINT0, mana, GetTarget(), true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_reborn_magic_absorption::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_magic_absorption::Restore, EFFECT_0, SPELL_AURA_DUMMY);
    }
};
}
}

void AddAscensionWarcraftRebornMageScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_magic_absorption);
}
