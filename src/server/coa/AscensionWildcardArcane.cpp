/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum WildcardArcaneSpells : uint32
{
    BarrageOverload = 277540,
    BarrageOverloadStack = 277541,
    BarrageUnleashed = 277542,
    UnstableEvocationBlast = 284295
};

constexpr uint32 GLOBAL_COOLDOWN_CATEGORY = 133;

class aura_wildcard_power_overwhelming : public AuraScript
{
    PrepareAuraScript(aura_wildcard_power_overwhelming);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        return spell && spell->StartRecoveryCategory == GLOBAL_COOLDOWN_CATEGORY;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_power_overwhelming::CheckProc);
    }
};

class aura_wildcard_missile_barrage_overload : public AuraScript
{
    PrepareAuraScript(aura_wildcard_missile_barrage_overload);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({BarrageOverloadStack});
    }

    void Consumed(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* target = GetTarget();
        if (!GetAura()->GetCharges() && GetDuration() > 0 && target->HasAura(BarrageOverload))
            target->CastSpell(target, BarrageOverloadStack, true);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_wildcard_missile_barrage_overload::Consumed,
            EFFECT_0, SPELL_AURA_ADD_FLAT_MODIFIER, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_wildcard_arcane_barrage_overload : public SpellScript
{
    PrepareSpellScript(spell_wildcard_arcane_barrage_overload);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({BarrageOverloadStack, BarrageUnleashed});
    }

    void Unleash()
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        Aura* stacks = caster->GetAura(BarrageOverloadStack);
        if (!target || !stacks)
            return;

        int32 const perStack = stacks->GetSpellInfo()->Effects[EFFECT_0].CalcValue(caster);
        int32 const duration = sSpellMgr->AssertSpellInfo(BarrageUnleashed)->GetMaxDuration() +
            perStack * stacks->GetStackAmount();
        stacks->Remove();
        if (Aura* unleashed = caster->AddAura(BarrageUnleashed, target))
        {
            unleashed->SetMaxDuration(duration);
            unleashed->SetDuration(duration);
        }
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_wildcard_arcane_barrage_overload::Unleash);
    }
};

class aura_wildcard_unstable_evocation : public AuraScript
{
    PrepareAuraScript(aura_wildcard_unstable_evocation);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({UnstableEvocationBlast});
    }

    void Completed(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE)
            GetTarget()->CastSpell(GetTarget(), UnstableEvocationBlast, true);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_wildcard_unstable_evocation::Completed,
            EFFECT_0, SPELL_AURA_OBS_MOD_POWER, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionWildcardArcane()
{
    RegisterSpellScript(aura_wildcard_power_overwhelming);
    RegisterSpellScript(aura_wildcard_missile_barrage_overload);
    RegisterSpellScript(spell_wildcard_arcane_barrage_overload);
    RegisterSpellScript(aura_wildcard_unstable_evocation);
}
