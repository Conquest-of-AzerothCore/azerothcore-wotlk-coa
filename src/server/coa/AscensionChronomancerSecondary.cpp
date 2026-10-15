/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <limits>
#include <vector>

namespace
{
enum ChronomancerSecondarySpells : uint32
{
    SPELL_MELT_REALITY = 806335,
    SPELL_MIND_MELT = 572851,
    SPELL_MELT_COPY_VALUE = 504727,
    SPELL_MELT_COPY = 807570,
    SPELL_DESYNCHRONIZATION = 561310,
    SPELL_RESYNCHRONIZATION = 561388,
    SPELL_AHEAD_OF_THE_GAME = 560948,
    SPELL_AHEAD_COUNTER = 592009,
    SPELL_AHEAD_POWER = 592010,
    SPELL_RIPPLE = 806296,
    SPELL_RIPPLE_CHARGE = 806297,
    SPELL_RIPPLE_HEAL = 806298,
    SPELL_ECHO_FRAGMENT = 804455,
    SPELL_ARC_COLLISION = 524853,
    SPELL_ECHO_DURATION = 807711,
    SPELL_UNMAKE = 804418,
    SPELL_ANOMALY_SPIKE = 503826,
    SPELL_CHROMATIC_SHARD = 801292,
    SPELL_CHROMATIC_SHARD_CAST_TIME = 503829,
    SPELL_INFINITE_KEEPER = 806312,
    SPELL_INFINITE_KEEPER_TRIGGER = 806314,
    SPELL_SHIFTING_CHAOS = 706059,
    SPELL_SHIFTING_CHAOS_BLAST = 801269,
    SPELL_GRAVITY_BOMB_EXPLOSION = 801282,
    SPELL_TEMPORAL_ANOMALY = 806315,
    SPELL_TEMPORAL_ANOMALY_HEAL = 807799
};

constexpr uint32 ChronomancerSpellFamily = 28;
constexpr uint32 TimerendFamilyFlag1 = 0x01000000;
constexpr uint32 ChromaticShardFamilyFlag1 = 0x00001000;
constexpr uint32 ChromaticShardFamilyFlag2 = 0x02000000;
constexpr uint32 AnomalySpikeFamilyFlag0 = 0x08000000;

Player* SecondaryChronomancer(Unit* unit)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_CHRONOMANCER && player->IsAlive() && player->IsInWorld()
        ? player : nullptr;
}

bool HasOwnTimerend(Unit const* target, ObjectGuid caster)
{
    for (AuraEffect const* effect : target->GetAuraEffectsByType(SPELL_AURA_PERIODIC_DAMAGE))
    {
        SpellInfo const* info = effect->GetSpellInfo();
        if (effect->GetCasterGUID() == caster && info->SpellFamilyName == ChronomancerSpellFamily &&
            (info->SpellFamilyFlags[1] & TimerendFamilyFlag1))
            return true;
    }
    return false;
}

bool IsChromaticShardOrAnomalySpike(SpellInfo const* info)
{
    if (info->SpellFamilyName != ChronomancerSpellFamily)
        return false;
    flag96 const& flags = info->SpellFamilyFlags;
    return ((flags[1] & ChromaticShardFamilyFlag1) && (flags[2] & ChromaticShardFamilyFlag2)) ||
        (flags[0] & AnomalySpikeFamilyFlag0);
}

void EruptInfiniteKeeper(Player* player, Unit* target)
{
    AuraEffect const* keeper = player->GetAuraEffect(SPELL_INFINITE_KEEPER, EFFECT_0);
    if (keeper && player->IsValidAttackTarget(target) && HasOwnTimerend(target, player->GetGUID()))
        player->CastSpell(target, SPELL_INFINITE_KEEPER_TRIGGER, true, nullptr, keeper);
}

void ReplicateShiftingChaos(Player* player, Unit* target, uint32 damage)
{
    AuraEffect const* chaos = player->GetAuraEffect(SPELL_SHIFTING_CHAOS, EFFECT_0);
    if (!chaos || chaos->GetAmount() <= 0)
        return;
    uint64 amount = uint64(damage) * uint64(chaos->GetAmount()) / 100;
    if (amount)
        player->CastCustomSpell(SPELL_SHIFTING_CHAOS_BLAST, SPELLVALUE_BASE_POINT0,
            int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), target, true, nullptr, chaos);
}

class chronomancer_melt_periodic : public UnitScript
{
public:
    chronomancer_melt_periodic() : UnitScript("chronomancer_melt_periodic", true,
        {UNITHOOK_ON_PERIODIC_DAMAGE_RESULT}) { }

    void OnPeriodicDamageResult(Unit* target, Unit*, uint32 damage, SpellInfo const*) override
    {
        if (!target || !target->IsInWorld() || !damage)
            return;
        std::vector<ObjectGuid> owners;
        for (auto const& pair : target->GetAppliedAuras())
        {
            Aura* aura = pair.second->GetBase();
            if (sSpellMgr->GetFirstSpellInChain(aura->GetId()) == SPELL_MELT_REALITY &&
                std::find(owners.begin(), owners.end(), aura->GetCasterGUID()) == owners.end())
                owners.push_back(aura->GetCasterGUID());
        }
        SpellInfo const* value = sSpellMgr->GetSpellInfo(SPELL_MELT_COPY_VALUE);
        if (!value)
            return;
        for (ObjectGuid const& guid : owners)
            if (Player* player = SecondaryChronomancer(ObjectAccessor::GetUnit(*target, guid));
                player && player->GetMap() == target->GetMap() && player->InSamePhase(target) &&
                player->IsValidAttackTarget(target))
            {
                uint64 amount = uint64(damage) * std::max(0, value->Effects[EFFECT_0].CalcValue(player)) / 100;
                if (amount)
                    player->CastCustomSpell(SPELL_MELT_COPY, SPELLVALUE_BASE_POINT0,
                        int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), target, true);
            }
    }
};

class chronomancer_mind_melt_taken : public UnitScript
{
public:
    chronomancer_mind_melt_taken() : UnitScript("chronomancer_mind_melt_taken", true,
        {UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK}) { }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage,
        SpellInfo const* info) override
    {
        if (!target || !attacker || !damage || !info ||
            info->HasAttribute(SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS))
            return;
        if (!info->HasAura(SPELL_AURA_PERIODIC_DAMAGE) && !info->HasAura(SPELL_AURA_PERIODIC_DAMAGE_PERCENT) &&
            !info->HasAura(SPELL_AURA_PERIODIC_LEECH))
            return;
        AuraEffect const* melt = target->GetAuraEffect(SPELL_MIND_MELT, EFFECT_0, attacker->GetGUID());
        if (!melt || melt->GetAmount() <= 0)
            return;
        if (int32 const schoolMask = melt->GetMiscValue();
            schoolMask && !(uint32(schoolMask) & uint32(info->GetSchoolMask())))
            return;
        uint64 const bonus = uint64(damage) * uint64(melt->GetAmount()) / 100;
        damage = uint32(std::min<uint64>(uint64(damage) + bonus,
            std::numeric_limits<uint32>::max()));
    }
};

class spell_ascension_melt_copy : public SpellScript
{
    PrepareSpellScript(spell_ascension_melt_copy);

    void Select(std::list<WorldObject*>& targets)
    {
        Unit* original = GetExplTargetUnit();
        targets.remove_if([original](WorldObject* object)
        {
            Unit* target = object ? object->ToUnit() : nullptr;
            return !target || target == original || !target->IsAlive();
        });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_melt_copy::Select,
            EFFECT_0, TARGET_UNIT_DEST_AREA_ENEMY);
    }
};

class aura_ascension_desynchronization : public AuraScript
{
    PrepareAuraScript(aura_ascension_desynchronization);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_RESYNCHRONIZATION}); }

    void End(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = SecondaryChronomancer(GetCaster());
        Unit* target = GetTarget();
        if (player && target->IsAlive() && target->IsInWorld() && player->GetMap() == target->GetMap() &&
            player->InSamePhase(target) && player->IsValidAttackTarget(target) &&
            GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_DEATH)
            player->CastSpell(target, SPELL_RESYNCHRONIZATION, true);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_desynchronization::End,
            EFFECT_0, SPELL_AURA_MOD_DISARM, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_ahead_of_the_game : public AuraScript
{
    PrepareAuraScript(aura_ascension_ahead_of_the_game);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_AHEAD_COUNTER, SPELL_AHEAD_POWER}); }

    bool Check(ProcEventInfo& event)
    {
        return SecondaryChronomancer(GetTarget()) && event.GetActor() == GetTarget() &&
            ((event.GetDamageInfo() && event.GetDamageInfo()->GetDamage()) ||
                (event.GetHealInfo() && event.GetHealInfo()->GetEffectiveHeal()));
    }

    void Count(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        Unit* player = GetTarget();
        player->CastSpell(player, SPELL_AHEAD_COUNTER, true);
        if (Aura const* counter = player->GetAura(SPELL_AHEAD_COUNTER, player->GetGUID());
            counter && counter->GetStackAmount() >= 10)
        {
            player->RemoveAurasDueToSpell(SPELL_AHEAD_COUNTER, player->GetGUID());
            player->CastSpell(player, SPELL_AHEAD_POWER, true);
        }
    }

    void Clear(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SPELL_AHEAD_COUNTER, GetTarget()->GetGUID());
        GetTarget()->RemoveAurasDueToSpell(SPELL_AHEAD_POWER, GetTarget()->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_ahead_of_the_game::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_ahead_of_the_game::Count,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_ahead_of_the_game::Clear,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_ripple_release : public AuraScript
{
    PrepareAuraScript(aura_ascension_ripple_release);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_RIPPLE_CHARGE, SPELL_RIPPLE_HEAL}); }

    void Start(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SPELL_RIPPLE_CHARGE, GetTarget()->GetGUID());
    }

    void End(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* player = GetTarget();
        AuraEffect const* timer = GetEffect(EFFECT_1);
        if (SecondaryChronomancer(player) && player == GetCaster() && timer && timer->GetTickNumber() >= 6 &&
            GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_DEATH)
            player->CastSpell(player, SPELL_RIPPLE_HEAL, true);
        player->RemoveAurasDueToSpell(SPELL_RIPPLE_CHARGE, player->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_ripple_release::Start,
            EFFECT_0, SPELL_AURA_MECHANIC_IMMUNITY_MASK, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_ripple_release::End,
            EFFECT_0, SPELL_AURA_MECHANIC_IMMUNITY_MASK, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_echo_duration : public AuraScript
{
    PrepareAuraScript(aura_ascension_echo_duration);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_ECHO_DURATION}); }

    bool Load() override
    {
        return GetCaster() == GetUnitOwner() && GetCaster() && GetCaster()->IsPlayer() &&
            GetCaster()->getClass() == CLASS_CHRONOMANCER;
    }

    void Sync(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* player = GetTarget();
        Aura* companion = player->GetAura(SPELL_ECHO_DURATION, player->GetGUID());
        if (!companion)
            companion = player->AddAura(SPELL_ECHO_DURATION, player);
        if (companion && companion->GetStackAmount() != GetStackAmount())
            companion->SetStackAmount(GetStackAmount());
    }

    void Clear(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SPELL_ECHO_DURATION, GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_echo_duration::Sync,
            EFFECT_0, SPELL_AURA_ADD_FLAT_MODIFIER, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_echo_duration::Clear,
            EFFECT_0, SPELL_AURA_ADD_FLAT_MODIFIER, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_temporal_anomaly : public AuraScript
{
    PrepareAuraScript(aura_ascension_temporal_anomaly);
    uint64 _absorbed = 0;

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_TEMPORAL_ANOMALY && info->SpellFamilyName == ChronomancerSpellFamily &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_SCHOOL_ABSORB) &&
            ValidateSpellInfo({SPELL_TEMPORAL_ANOMALY_HEAL});
    }

    bool Load() override
    {
        return GetCaster() == GetUnitOwner() && SecondaryChronomancer(GetCaster());
    }

    void Amount(AuraEffect const*, int32& amount, bool& recalculate)
    {
        amount = -1;
        recalculate = false;
    }

    void Absorb(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        uint32 const percent = uint32(std::clamp(GetSpellInfo()->Effects[EFFECT_0].MiscValueB, 0, 100));
        amount = uint32(uint64(damage.GetDamage()) * percent / 100);
    }

    void Store(AuraEffect*, DamageInfo&, uint32& amount)
    {
        _absorbed = std::min<uint64>(_absorbed + amount, std::numeric_limits<int32>::max());
    }

    void Release(AuraEffect const* effect, AuraEffectHandleModes)
    {
        Unit* owner = GetTarget();
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE && owner->IsAlive() && _absorbed)
            owner->CastCustomSpell(SPELL_TEMPORAL_ANOMALY_HEAL, SPELLVALUE_BASE_POINT0,
                int32(_absorbed), owner, TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_temporal_anomaly::Amount,
            EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_temporal_anomaly::Absorb, EFFECT_0);
        AfterEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_temporal_anomaly::Store, EFFECT_0);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_temporal_anomaly::Release,
            EFFECT_0, SPELL_AURA_SCHOOL_ABSORB, AURA_EFFECT_HANDLE_REAL);
    }
};

class chronomancer_secondary_casts : public AllSpellScript
{
public:
    chronomancer_secondary_casts() : AllSpellScript("chronomancer_secondary_casts", {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        if (SecondaryChronomancer(caster) && !spell->IsTriggered() && info->Id == SPELL_ARC_COLLISION)
            caster->RemoveAurasDueToSpell(SPELL_ECHO_FRAGMENT, caster->GetGUID());
    }
};

class chronomancer_secondary_hits : public AllSpellScript
{
public:
    chronomancer_secondary_hits() : AllSpellScript("chronomancer_secondary_hits", {ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool) override
    {
        Player* player = SecondaryChronomancer(spell->GetCaster());
        if (!player || !target || target == player || miss != SPELL_MISS_NONE || !target->IsInWorld())
            return;
        SpellInfo const* info = spell->GetSpellInfo();
        if (damage && info->Id == SPELL_ANOMALY_SPIKE && player->HasSpell(SPELL_CHROMATIC_SHARD))
            player->CastSpell(player, SPELL_CHROMATIC_SHARD_CAST_TIME, true);
        if (sSpellMgr->GetFirstSpellInChain(info->Id) == SPELL_UNMAKE)
            EruptInfiniteKeeper(player, target);
        else if (damage && IsChromaticShardOrAnomalySpike(info))
            ReplicateShiftingChaos(player, target, damage);
    }
};

class chronomancer_secondary_metadata : public GlobalScript
{
public:
    chronomancer_secondary_metadata() : GlobalScript("chronomancer_secondary_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == SPELL_GRAVITY_BOMB_EXPLOSION && info->SpellFamilyName == ChronomancerSpellFamily &&
            info->DmgClass == SPELL_DAMAGE_CLASS_MAGIC && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
            info->UseRangedAttackPowerForDamage = true;
        if (info->Id == SPELL_TEMPORAL_ANOMALY_HEAL && info->SpellFamilyName == ChronomancerSpellFamily &&
            info->Effects[EFFECT_0].Effect == SPELL_EFFECT_HEAL)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AttributesEx6 |= SPELL_ATTR6_IGNORE_HEALTH_MODIFIERS;
            info->AscensionInheritsResolvedAmount = true;
            info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        }
        if (info->Id == SPELL_MELT_COPY && info->SpellFamilyName == 28)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AscensionInheritsResolvedAmount = true;
            info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        }
        if (info->Id == SPELL_SHIFTING_CHAOS_BLAST && info->SpellFamilyName == ChronomancerSpellFamily)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AscensionInheritsResolvedAmount = true;
            info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        }
        if ((info->Id == SPELL_INFINITE_KEEPER || info->Id == SPELL_SHIFTING_CHAOS) &&
            info->SpellFamilyName == ChronomancerSpellFamily)
        {
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
            info->Effects[EFFECT_0].TriggerSpell = 0;
        }
        if (info->Id == SPELL_ECHO_DURATION || info->Id == SPELL_AHEAD_COUNTER || info->Id == SPELL_RIPPLE_CHARGE)
        {
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }
    }
};
}

void AddSC_AscensionChronomancerSecondary()
{
    new chronomancer_melt_periodic();
    new chronomancer_mind_melt_taken();
    new chronomancer_secondary_casts();
    new chronomancer_secondary_hits();
    new chronomancer_secondary_metadata();
    RegisterSpellScript(spell_ascension_melt_copy);
    RegisterSpellScript(aura_ascension_desynchronization);
    RegisterSpellScript(aura_ascension_ahead_of_the_game);
    RegisterSpellScript(aura_ascension_ripple_release);
    RegisterSpellScript(aura_ascension_echo_duration);
    RegisterSpellScript(aura_ascension_temporal_anomaly);
}
