/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <algorithm>

namespace
{
enum SurgeOfMightSpells : uint32
{
    SurgeOfMight = 520083,
    SurgeOfMightDamage = 573254
};

class stormbringer_surge_of_might_scaling : public UnitScript
{
public:
    stormbringer_surge_of_might_scaling() : UnitScript("stormbringer_surge_of_might_scaling", true,
        {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index,
        float& value) override
    {
        if (caster && caster->IsPlayer() && caster->getClass() == CLASS_STORMBRINGER &&
            info->Id == SurgeOfMight && index == EFFECT_0)
            value += 0.7f * float(std::max(0,
                const_cast<Unit*>(caster)->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE)));
    }
};

class aura_ascension_surge_of_might : public AuraScript
{
    PrepareAuraScript(aura_ascension_surge_of_might);

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        return owner->IsPlayer() && owner->IsAlive() && event.GetActor() == owner &&
            victim && victim != owner && !owner->IsFriendlyTo(victim) && damage && damage->GetDamage() &&
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) &&
            (!event.GetSpellInfo() || event.GetSpellInfo()->Id != SurgeOfMightDamage);
    }

    void Register() override { DoCheckProc += AuraCheckProcFn(aura_ascension_surge_of_might::Check); }
};
}

void AddSC_AscensionStormbringerSurge()
{
    new stormbringer_surge_of_might_scaling();
    RegisterSpellScript(aura_ascension_surge_of_might);
}
