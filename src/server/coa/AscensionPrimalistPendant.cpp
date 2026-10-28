/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <algorithm>
#include <limits>

namespace
{
constexpr uint32 EarthmotherPendantHeal = 524972;

class aura_ascension_earthmother_pendant : public AuraScript
{
    PrepareAuraScript(aura_ascension_earthmother_pendant);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({EarthmotherPendantHeal}); }

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        return owner->IsPlayer() && owner->getClass() == CLASS_WILDWALKER && owner->IsAlive() &&
            GetCaster() == owner && event.GetActor() == owner && victim && victim != owner &&
            !owner->IsFriendlyTo(victim) && damage && damage->GetDamage() &&
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC);
    }

    void Heal(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (amount)
            GetTarget()->CastCustomSpell(EarthmotherPendantHeal, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), GetTarget(), TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_earthmother_pendant::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_earthmother_pendant::Heal, EFFECT_0, AuraType(354));
    }
};
}

void AddSC_AscensionPrimalistPendant()
{
    RegisterSpellScript(aura_ascension_earthmother_pendant);
}
