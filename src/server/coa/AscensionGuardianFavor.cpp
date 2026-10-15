/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
class aura_ascension_guardian_favor_gain : public AuraScript
{
    PrepareAuraScript(aura_ascension_guardian_favor_gain);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == 704322 && info->SpellFamilyName == 24 &&
            info->Effects[EFFECT_0].TriggerSpell == 707821 && ValidateSpellInfo({ 707821, 707822, 712476 });
    }

    bool Check(ProcEventInfo& event)
    {
        Player* owner = GetTarget()->ToPlayer();
        return owner && owner->getClass() == CLASS_GUARDIAN && event.GetActor() == owner &&
            ((event.GetTypeMask() & PROC_FLAG_KILL) ||
                (event.GetDamageInfo() && (event.GetHitMask() & PROC_HIT_CRITICAL)) ||
                ((event.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK) &&
                    owner->GetAura(707821) && owner->GetAura(707821)->GetStackAmount() >= 20));
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Aura const* before = owner->GetAura(707821);
        uint8 oldStacks = before ? before->GetStackAmount() : 0;
        if (oldStacks >= 20 && (event.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK) &&
            event.GetDamageInfo() && event.GetActionTarget() && event.GetActionTarget()->IsAlive())
        {
            owner->RemoveAurasDueToSpell(707821);
            CustomSpellValues values;
            values.AddSpellMod(SPELLVALUE_MELEE_ATTACK_TYPE, event.GetDamageInfo()->GetAttackType());
            SpellCastTargets targets;
            targets.SetUnitTarget(event.GetActionTarget());
            owner->CastSpell(targets, sSpellMgr->GetSpellInfo(712476), &values, TRIGGERED_FULL_MASK);
            oldStacks = 0;
        }
        if (!(event.GetTypeMask() & PROC_FLAG_KILL) && !(event.GetHitMask() & PROC_HIT_CRITICAL))
            return;
        owner->CastSpell(owner, 707821, true, nullptr, effect);
        Aura const* after = owner->GetAura(707821);
        if (oldStacks < 20 && after && after->GetStackAmount() >= 20 && owner->HasAura(705323))
            owner->CastSpell(owner, 707822, true, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_guardian_favor_gain::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_guardian_favor_gain::Proc,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
}

void AddAscensionGuardianFavorScripts()
{
    RegisterSpellScript(aura_ascension_guardian_favor_gain);
}
