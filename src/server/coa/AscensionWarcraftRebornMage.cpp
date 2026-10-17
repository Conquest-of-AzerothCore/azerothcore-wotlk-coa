/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWarcraftRebornMage.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 MAGE_LIVING_BOMB = 0x20000;
constexpr std::array<uint32, 3> WORLD_IN_FLAMES = { 1111108, 1112349, 1112350 };
constexpr std::array<uint32, 3> FIRE_POWER = { 1111124, 1112378, 1112398 };

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

void ApplyAscensionWarcraftRebornMageContracts(SpellInfo* spellInfo)
{
    using namespace AscensionWarcraftReborn;
    if (!spellInfo)
        return;

    if (std::find(WORLD_IN_FLAMES.begin(), WORLD_IN_FLAMES.end(), spellInfo->Id) != WORLD_IN_FLAMES.end())
    {
        SpellEffectInfo& critChance = spellInfo->Effects[EFFECT_0];
        if (critChance.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER && critChance.MiscValue == SPELLMOD_CRITICAL_CHANCE)
            critChance.SpellClassMask[1] |= MAGE_LIVING_BOMB;
    }

    if (std::find(FIRE_POWER.begin(), FIRE_POWER.end(), spellInfo->Id) != FIRE_POWER.end())
    {
        SpellEffectInfo const& damage = spellInfo->Effects[EFFECT_0];
        SpellEffectInfo& periodic = spellInfo->Effects[EFFECT_1];
        if (damage.ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER && damage.MiscValue == SPELLMOD_DAMAGE &&
            periodic.ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER && periodic.MiscValue == SPELLMOD_DOT)
            periodic.BasePoints = damage.BasePoints;
    }
}

void AddAscensionWarcraftRebornMageScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_magic_absorption);
}
