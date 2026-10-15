/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"

namespace
{
class aura_ascension_vitality_surge : public AuraScript
{
    PrepareAuraScript(aura_ascension_vitality_surge);

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        HealInfo const* heal = event.GetHealInfo();
        return owner->IsPlayer() && owner->getClass() == CLASS_WILDWALKER &&
            GetCasterGUID() == owner->GetGUID() && event.GetActor() == owner && heal &&
            heal->GetHealer() == owner && heal->GetEffectiveHeal() > 0;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_vitality_surge::Check);
    }
};
}

void AddSC_AscensionPrimalistVitality()
{
    RegisterSpellScript(aura_ascension_vitality_surge);
}
