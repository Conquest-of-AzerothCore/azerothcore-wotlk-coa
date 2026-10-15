/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
enum ReflexesSpells : uint32 { SoulHarvest = 573050 };

class aura_ascension_spiritual_reflexes : public AuraScript
{
    PrepareAuraScript(aura_ascension_spiritual_reflexes);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SoulHarvest}); }

    bool CheckProc(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* attacker = event.GetActor();
        return owner->IsPlayer() && owner->getClass() == CLASS_REAPER && owner->IsAlive() &&
            owner->IsInWorld() && owner->HealthBelowPct(35) && event.GetActionTarget() == owner &&
            (event.GetHitMask() & PROC_HIT_DODGE) && attacker && attacker->IsAlive() &&
            owner->IsValidAttackTarget(attacker);
    }

    void Harvest(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (CheckProc(event))
            GetTarget()->CastSpell(event.GetActor(), SoulHarvest, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_spiritual_reflexes::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_spiritual_reflexes::Harvest, EFFECT_0, SPELL_AURA_DUMMY);
    }
};
}

void AddSC_AscensionReaperReflexes()
{
    RegisterSpellScript(aura_ascension_spiritual_reflexes);
}
