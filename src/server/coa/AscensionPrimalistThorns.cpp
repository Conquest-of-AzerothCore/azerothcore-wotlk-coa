/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"

namespace
{
class aura_ascension_primalist_thorns : public AuraScript
{
    PrepareAuraScript(aura_ascension_primalist_thorns);

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* enemy = event.GetActor() == owner ? event.GetActionTarget() : event.GetActor();
        DamageInfo const* damage = event.GetDamageInfo();
        return owner->IsPlayer() && owner->getClass() == CLASS_WILDWALKER && owner->IsAlive() &&
            GetCaster() == owner && enemy && enemy != owner && !owner->IsFriendlyTo(enemy) &&
            damage && damage->GetDamage() && (damage->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_primalist_thorns::Check);
    }
};
}

void AddSC_AscensionPrimalistThorns()
{
    RegisterSpellScript(aura_ascension_primalist_thorns);
}
