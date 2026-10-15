/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
class aura_ascension_primal_strikes : public AuraScript
{
    PrepareAuraScript(aura_ascension_primal_strikes);

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        return owner->IsPlayer() && owner->getClass() == CLASS_WILDWALKER && owner->IsAlive() &&
            GetCaster() == owner && event.GetActor() == owner && victim && victim != owner &&
            !owner->IsFriendlyTo(victim) && event.GetSpellInfo() && damage && damage->GetDamage() &&
            (damage->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL) && (event.GetHitMask() & PROC_HIT_CRITICAL);
    }

    void Register() override { DoCheckProc += AuraCheckProcFn(aura_ascension_primal_strikes::Check); }
};
}

void AddSC_AscensionPrimalistPrimalStrikes()
{
    RegisterSpellScript(aura_ascension_primal_strikes);
}
