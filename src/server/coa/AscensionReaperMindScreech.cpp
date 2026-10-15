/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <cmath>

namespace
{
constexpr uint32 MindScreechStrike = 802086;

class aura_ascension_reaper_mind_screech : public AuraScript
{
    PrepareAuraScript(aura_ascension_reaper_mind_screech);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({MindScreechStrike}); }

    void Screech(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        SpellInfo const* strike = sSpellMgr->GetSpellInfo(MindScreechStrike);
        if (!strike || !target || target == caster || !target->IsAlive() ||
            target->IsImmunedToSpell(strike, caster) || target->IsImmunedToSpellEffect(strike, EFFECT_1, caster))
            return;

        float const missingHealth = 1.0f - caster->GetHealthPct() / 100.0f;
        int32 const weaponPercent = int32(std::lround(strike->Effects[EFFECT_0].CalcValue(caster) * missingHealth));
        caster->CastCustomSpell(MindScreechStrike, SPELLVALUE_BASE_POINT0, weaponPercent, target, true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(aura_ascension_reaper_mind_screech::Screech, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
}

void AddSC_AscensionReaperMindScreech()
{
    RegisterSpellScript(aura_ascension_reaper_mind_screech);
}
