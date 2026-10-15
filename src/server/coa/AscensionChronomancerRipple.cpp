/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <cmath>
#include <limits>

namespace
{
enum RippleSpells : uint32
{
    Clasp = 805847,
    EndOfTime = 807690,
    EndOfTimeRelease = 525050,
    Ripple = 806296,
    EternityWarper = 806301,
    AeonRenewal = 806290,
    AeonResilience = 806291,
    AeonProtection = 806292,
    AeonOblivion = 806293,
    Renewal = 560384,
    Oblivion = 560388,
    Protection = 560394,
    Resilience = 560396,
    StaggerDebt = 806733
};

bool IsRippleHelper(uint32 id)
{
    return id == Renewal || id == Oblivion || id == Protection || id == Resilience;
}

bool IsChannelActive(Unit* caster)
{
    return caster && caster->IsPlayer() && caster->getClass() == CLASS_CHRONOMANCER && caster->IsAlive() &&
        caster->IsInWorld() && caster->HasAura(EternityWarper) && caster->HasAura(Ripple, caster->GetGUID());
}

bool IsProtected(Unit* caster, Unit* target)
{
    return IsChannelActive(caster) && target->IsAlive() && target->IsInWorld() &&
        caster->GetMap() == target->GetMap() && caster->InSamePhase(target);
}

class chronomancer_expiry_events : public UnitScript
{
public:
    chronomancer_expiry_events() : UnitScript("chronomancer_expiry_events", true, {UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraRemove(Unit* target, AuraApplication* application, AuraRemoveMode mode) override
    {
        if (!application || mode != AURA_REMOVE_BY_EXPIRE || !target || !target->IsAlive() || !target->IsInWorld())
            return;
        Aura* aura = application->GetBase();
        Unit* caster = aura->GetCaster();
        if (aura->GetId() == Clasp && caster && caster->IsPlayer() && caster->getClass() == CLASS_CHRONOMANCER &&
            caster->IsAlive() && caster->IsInWorld() && caster->HasAura(EndOfTime) &&
            caster->GetMap() == target->GetMap() && caster->InSamePhase(target) && caster->IsValidAttackTarget(target))
            caster->CastSpell(target, EndOfTimeRelease, true);
    }
};

class aura_ascension_ripple_aeon : public AuraScript
{
    PrepareAuraScript(aura_ascension_ripple_aeon);

    void Start(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* caster = GetTarget();
        if (!IsChannelActive(caster))
            return;
        uint32 helper = 0;
        if (caster->HasAura(AeonRenewal)) helper = Renewal;
        else if (caster->HasAura(AeonResilience)) helper = Resilience;
        else if (caster->HasAura(AeonProtection)) helper = Protection;
        else if (caster->HasAura(AeonOblivion)) helper = Oblivion;
        if (helper)
            caster->CastSpell(caster, helper, true);
    }

    void Stop(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* caster = GetTarget();
        for (uint32 helper : {Renewal, Oblivion, Protection, Resilience})
            caster->RemoveAurasDueToSpell(helper, caster->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_ripple_aeon::Start,
            EFFECT_0, SPELL_AURA_MECHANIC_IMMUNITY_MASK, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_ripple_aeon::Stop,
            EFFECT_0, SPELL_AURA_MECHANIC_IMMUNITY_MASK, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_ripple_pulses : public AuraScript
{
    PrepareAuraScript(aura_ascension_ripple_pulses);

    void Tick(AuraEffect const*)
    {
        if (!IsChannelActive(GetCaster()))
        {
            PreventDefaultAction();
            GetAura()->Remove();
        }
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_ripple_pulses::Tick,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

class aura_ascension_ripple_protection : public AuraScript
{
    PrepareAuraScript(aura_ascension_ripple_protection);

    void Amount(AuraEffect const*, int32& amount, bool& recalculate)
    {
        recalculate = false;
        Unit* caster = GetCaster();
        if (caster)
        {
            double result = double(amount) + caster->SpellBaseHealingBonusDone(GetSpellInfo()->GetSchoolMask()) * 0.75;
            if (std::isfinite(result))
                amount = int32(std::clamp(result, 0.0, double(std::numeric_limits<int32>::max())));
        }
    }

    void Absorb(AuraEffect*, DamageInfo&, uint32& amount)
    {
        if (!IsProtected(GetCaster(), GetTarget()))
            amount = 0;
    }

    void Cleanup(AuraEffect const*)
    {
        if (!IsProtected(GetCaster(), GetTarget()))
            GetAura()->Remove();
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_ripple_protection::Amount,
            EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_ripple_protection::Absorb, EFFECT_0);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_ripple_protection::Cleanup,
            EFFECT_1, SPELL_AURA_PERIODIC_DUMMY);
    }
};

class aura_ascension_ripple_resilience : public AuraScript
{
    PrepareAuraScript(aura_ascension_ripple_resilience);

    void Amount(AuraEffect const*, int32& amount, bool& recalculate)
    {
        amount = -1;
        recalculate = false;
    }

    bool Eligible(DamageInfo& damage)
    {
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        return IsProtected(caster, target) && (damage.GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL) &&
            (damage.GetDamageType() == DIRECT_DAMAGE || damage.GetDamageType() == SPELL_DIRECT_DAMAGE) &&
            caster->IsWithinDistInMap(target, GetSpellInfo()->Effects[EFFECT_0].CalcRadius(caster));
    }

    void Absorb(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        amount = 0;
        if (!Eligible(damage))
            return;
        Unit* target = GetTarget();
        Aura* debt = target->GetAura(StaggerDebt, target->GetGUID());
        if (!debt)
            debt = target->AddAura(StaggerDebt, target);
        if (!debt || !debt->GetEffect(EFFECT_1))
            return;
        uint32 pending = uint32(std::max(0, debt->GetEffect(EFFECT_1)->GetAmount()));
        uint32 room = uint32(std::numeric_limits<int32>::max()) - pending;
        amount = uint32(std::min<uint64>(uint64(damage.GetDamage()) * 30 / 100, room));
    }

    void Store(AuraEffect*, DamageInfo&, uint32& amount)
    {
        Unit* target = GetTarget();
        if (amount)
            if (Aura* debt = target->GetAura(StaggerDebt, target->GetGUID()))
            {
                AuraEffect* bank = debt->GetEffect(EFFECT_1);
                bank->SetAmount(int32(std::min<uint64>(uint64(std::max(0, bank->GetAmount())) + amount,
                    std::numeric_limits<int32>::max())));
                debt->GetEffect(EFFECT_2)->SetAmount(5);
                debt->SetDuration(debt->GetMaxDuration());
            }
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_ripple_resilience::Amount,
            EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_ripple_resilience::Absorb, EFFECT_0);
        AfterEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_ripple_resilience::Store, EFFECT_0);
    }
};

class aura_ascension_ripple_debt : public AuraScript
{
    PrepareAuraScript(aura_ascension_ripple_debt);

    void SavedAmount(AuraEffect const*, int32&, bool& recalculate) { recalculate = false; }

    void Pay(bool final)
    {
        Unit* target = GetTarget();
        if (!target->IsAlive())
            return;
        AuraEffect* bank = GetEffect(EFFECT_1);
        AuraEffect* counter = GetEffect(EFFECT_2);
        uint32 remaining = uint32(std::max(0, bank->GetAmount()));
        uint32 ticks = final ? 1u : uint32(std::max(1, counter->GetAmount()));
        uint32 payment = uint32((uint64(remaining) + ticks - 1) / ticks);
        bank->SetAmount(int32(remaining - payment));
        counter->SetAmount(int32(ticks - 1));
        if (payment)
        {
            uint32 dealt = Unit::DealDamage(target, target, payment, nullptr, DOT, SPELL_SCHOOL_MASK_NORMAL,
                GetSpellInfo(), false);
            target->SendSpellNonMeleeDamageLog(target, GetSpellInfo(), dealt, SPELL_SCHOOL_MASK_NORMAL,
                0, 0, false, 0);
        }
    }

    void Tick(AuraEffect const*) { Pay(false); }

    void End(AuraEffect const*, AuraEffectHandleModes)
    {
        AuraRemoveMode mode = GetTargetApplication()->GetRemoveMode();
        if (mode == AURA_REMOVE_BY_EXPIRE || mode == AURA_REMOVE_BY_CANCEL || mode == AURA_REMOVE_BY_ENEMY_SPELL)
            Pay(true);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_ripple_debt::SavedAmount,
            EFFECT_ALL, SPELL_AURA_ANY);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_ripple_debt::Tick,
            EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_ripple_debt::End,
            EFFECT_0, SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class chronomancer_ripple_duration : public AllSpellScript
{
public:
    chronomancer_ripple_duration() : AllSpellScript("chronomancer_ripple_duration",
        {ALLSPELLHOOK_ON_CALC_MAX_DURATION}) { }

    void OnCalcMaxDuration(Aura const* aura, int32& duration) override
    {
        if (IsRippleHelper(aura->GetId()))
            if (Unit* caster = aura->GetCaster(); IsChannelActive(caster))
                if (Aura* channel = caster->GetAura(Ripple, caster->GetGUID()))
                    duration = channel->GetDuration();
    }
};

class chronomancer_ripple_metadata : public GlobalScript
{
public:
    chronomancer_ripple_metadata() : GlobalScript("chronomancer_ripple_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 28)
            return;
        if (info->Id == Clasp)
            info->Effects[EFFECT_2].Effect = 0;
        if (info->Id == Protection)
        {
            SpellEffectInfo& cleanup = info->Effects[EFFECT_1];
            cleanup.Effect = SPELL_EFFECT_APPLY_AURA;
            cleanup.ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
            cleanup.Amplitude = 250;
            cleanup.TargetA = info->Effects[EFFECT_0].TargetA;
            cleanup.TargetB = info->Effects[EFFECT_0].TargetB;
            cleanup.RadiusEntry = info->Effects[EFFECT_0].RadiusEntry;
        }
        if (info->Id == Resilience)
        {
            SpellEffectInfo& shield = info->Effects[EFFECT_0];
            shield.ApplyAuraName = SPELL_AURA_SCHOOL_ABSORB;
            shield.BasePoints = -1;
            shield.DieSides = 0;
            shield.MiscValue = SPELL_SCHOOL_MASK_NORMAL;
            shield.Amplitude = 0;
            shield.TriggerSpell = 0;
        }
        if (info->Id == StaggerDebt)
        {
            info->ProcFlags = 0;
            info->AttributesCu |= SPELL_ATTR0_CU_NEGATIVE_EFF0;
            for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            {
                SpellEffectInfo& effect = info->Effects[i];
                effect.Effect = SPELL_EFFECT_APPLY_AURA;
                effect.ApplyAuraName = i == EFFECT_0 ? SPELL_AURA_PERIODIC_DUMMY : SPELL_AURA_DUMMY;
                effect.BasePoints = i == EFFECT_2 ? 5 : 0;
                effect.DieSides = 0;
                effect.Amplitude = i == EFFECT_0 ? 1000 : 0;
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
                effect.TargetB = SpellImplicitTargetInfo(0);
                effect.TriggerSpell = 0;
                effect.MiscValue = 0;
            }
        }
    }
};
}

void AddSC_AscensionChronomancerRipple()
{
    new chronomancer_expiry_events();
    new chronomancer_ripple_duration();
    new chronomancer_ripple_metadata();
    RegisterSpellScript(aura_ascension_ripple_aeon);
    RegisterSpellScript(aura_ascension_ripple_pulses);
    RegisterSpellScript(aura_ascension_ripple_protection);
    RegisterSpellScript(aura_ascension_ripple_resilience);
    RegisterSpellScript(aura_ascension_ripple_debt);
}
