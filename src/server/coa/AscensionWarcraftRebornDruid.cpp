/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "GameTime.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 ECLIPSE_SOLAR = 1148517;
constexpr uint32 ECLIPSE_LUNAR = 1148518;
constexpr Milliseconds ECLIPSE_COOLDOWN = 30s;
constexpr uint32 STARFIRE_FLAG = 0x4;
constexpr uint32 WRATH_FLAG = 0x1;

class spell_ascension_reborn_eclipse : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_eclipse);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ ECLIPSE_SOLAR, ECLIPSE_LUNAR });
    }

    bool InEclipse() const
    {
        return GetTarget()->HasAura(ECLIPSE_SOLAR) || GetTarget()->HasAura(ECLIPSE_LUNAR);
    }

    bool Ready(ProcEventInfo& eventInfo, uint32 spellFlag, Milliseconds readyAt) const
    {
        SpellInfo const* procSpell = eventInfo.GetSpellInfo();
        return procSpell && procSpell->SpellFamilyName == SPELLFAMILY_DRUID && (procSpell->SpellFamilyFlags[0] & spellFlag) &&
            GameTime::GetGameTimeMS() >= readyAt && !InEclipse();
    }

    bool CheckSolar(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        return Ready(eventInfo, STARFIRE_FLAG, _solarReady);
    }

    bool CheckLunar(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        return Ready(eventInfo, WRATH_FLAG, _lunarReady);
    }

    void Enter(AuraEffect const* aurEff, uint32 spellId, Milliseconds& readyAt)
    {
        PreventDefaultAction();
        readyAt = GameTime::GetGameTimeMS() + ECLIPSE_COOLDOWN;
        GetTarget()->CastSpell(GetTarget(), spellId, true, nullptr, aurEff);
    }

    void Solar(AuraEffect const* aurEff, ProcEventInfo&)
    {
        Enter(aurEff, ECLIPSE_SOLAR, _solarReady);
    }

    void Lunar(AuraEffect const* aurEff, ProcEventInfo&)
    {
        Enter(aurEff, ECLIPSE_LUNAR, _lunarReady);
    }

    void Register() override
    {
        DoCheckEffectProc += AuraCheckEffectProcFn(spell_ascension_reborn_eclipse::CheckSolar, EFFECT_0, SPELL_AURA_DUMMY);
        DoCheckEffectProc += AuraCheckEffectProcFn(spell_ascension_reborn_eclipse::CheckLunar, EFFECT_1, SPELL_AURA_DUMMY);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_eclipse::Solar, EFFECT_0, SPELL_AURA_DUMMY);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_eclipse::Lunar, EFFECT_1, SPELL_AURA_DUMMY);
    }

    Milliseconds _solarReady = 0ms;
    Milliseconds _lunarReady = 0ms;
};
}
}

void AddAscensionWarcraftRebornDruidScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_eclipse);
}
