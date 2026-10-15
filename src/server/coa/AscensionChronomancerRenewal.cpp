/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionRenewalContributions.h"
#include "GameTime.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellScript.h"

class aura_ascension_epoch_renewal : public AuraScript
{
    PrepareAuraScript(aura_ascension_epoch_renewal);

    Ascension::RenewalContributions _contributions;
    bool _nativeTick = false;

    static uint64 Now() { return uint64(GameTime::GetGameTimeMS().count()); }

    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        uint64 now = Now();
        _contributions.Add(now, effect->GetAmount(), uint32(std::max(0, GetDuration())),
            uint32(std::max(1, effect->GetAmplitude())));
        int32 remaining = _contributions.Remaining(now);
        GetAura()->SetMaxDuration(std::max(GetAura()->GetMaxDuration(), remaining));
        GetAura()->SetDuration(remaining);
        Schedule(now);
    }

    void Schedule(uint64 now)
    {
        AuraEffect* effect = GetEffect(EFFECT_0);
        effect->SetAmount(_contributions.Amount());
        effect->ResetTicks();
        effect->SetPeriodicTimer(_contributions.Delay(now));
    }

    void Tick(AuraEffect const*)
    {
        if (_nativeTick)
            return;
        uint64 now = Now();
        auto ticks = _contributions.Advance(now);
        AuraEffect* effect = GetEffect(EFFECT_0);
        _nativeTick = true;
        for (int32 amount : ticks)
        {
            effect->SetAmount(amount);
            effect->PeriodicTick(const_cast<AuraApplication*>(GetTargetApplication()), GetCaster());
            if (GetAura()->IsRemoved())
                break;
        }
        _nativeTick = false;
        PreventDefaultAction();
        if (GetAura()->IsRemoved())
            return;
        if (!_contributions.Remaining(now))
            GetAura()->Remove();
        else
            Schedule(now);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_epoch_renewal::Apply,
            EFFECT_0, SPELL_AURA_PERIODIC_HEAL, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_epoch_renewal::Tick,
            EFFECT_0, SPELL_AURA_PERIODIC_HEAL);
    }
};

void AddSC_AscensionChronomancerRenewal()
{
    RegisterSpellScript(aura_ascension_epoch_renewal);
}
