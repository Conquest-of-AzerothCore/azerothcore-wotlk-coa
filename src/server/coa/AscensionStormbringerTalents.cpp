/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCustomResourceData.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <limits>
#include <list>
#include <vector>

namespace
{
enum StormbringerTalentSpells : uint32
{
    SPELL_CLOUDBURST = 801838,
    SPELL_CLOUDBURST_KNOCKBACK = 802385,
    SPELL_SHOCK = 804020,
    SPELL_SHOCK_DOT = 560336,
    SPELL_SHOCK_HIDDEN_PASSIVE = 707058,
    SPELL_PERPETUAL_SHOCK = 570054,
    SPELL_INVOKING_STORMS_RANK_1 = 705667,
    SPELL_INVOKING_STORMS_RANK_2 = 707793,
    SPELL_CALL_LIGHTNING = 500040,
    SPELL_THUNDER_WARD = 800098,
    SPELL_STATIC = 803102,
    SPELL_GENERATE_STATIC_20 = 804086,
    SPELL_BAROMETRIC_SLOW = 803566,
    SPELL_ELECTRICAL_CHARGE = 800299,
    SPELL_CHARGED_CONDUIT = 803790,
    SPELL_ELECTROCUTIONER_PASSIVE = 500068,
    SPELL_ELECTROCUTIONER_TALENT = 92096,
    SPELL_ELECTROCUTIONER = 804592,
    SPELL_DARK_SKIES_BUFF = 680855,
    SPELL_CRITICAL_CIRCUIT = 807314,
    SPELL_REFUND_STATIC_10 = 804084,
    SPELL_CONJURATION_MASTERY = 300595,
    SPELL_PREDICTABLE_WEATHER_WINDOW = 807481,
    SPELL_LIGHTNING_ROD = 300609,
    SPELL_LIGHTNING_ROD_SPREAD = 300928,
    SPELL_VOLT = 500928,
    SPELL_FORKED_LIGHTNING = 801851,
    SPELL_NEVER_STRIKES_TWICE = 804828,
    SPELL_ELECTROCUTE = 801844,
    SPELL_STORMBREAKER = 705669,
    SPELL_PULSE_CONVERSION = 707619,
    SPELL_PULSE_CONVERSION_HEAL = 504830,
    SPELL_STORM_BARRIER = 707204,
    SPELL_LIGHTNING_CAGE_BARRIER = 560032,
    SPELL_THORIMS_GIFT = 570173,
    SPELL_THORIMS_GIFT_PATCH = 570174,
    SPELL_HURRICANES_BUFF = 570129,
    SPELL_UNBOUND_ELEMENTALIST = 705702
};

constexpr int32 ASCENSION_SPELLMOD_BONUS_MULTIPLIER = 41;
constexpr uint32 CONJURE_STORM_FAMILY_FLAG_TWO = 16;

bool IsConjureStorm(SpellInfo const* info)
{
    return info && info->SpellFamilyName == 22 && (info->SpellFamilyFlags[2] & CONJURE_STORM_FAMILY_FLAG_TWO);
}

bool SpendsStatic(uint32 spellId)
{
    for (AscensionCompatData::ResourceCostRule const& rule : AscensionCompatData::ResourceCostRules)
        if (rule.ClassId == CLASS_STORMBRINGER && rule.ResourceSpellId == SPELL_STATIC &&
            spellId >= rule.FirstSpellId && spellId <= rule.LastSpellId)
            return rule.Consumption != AscensionCompatData::ResourceConsumption::None;
    return false;
}

uint32 TalentProcChance(uint32 talent)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(talent);
    return info ? info->ProcChance : 0;
}

void ReduceRankCooldowns(Player* player, uint32 firstRank, int32 delta)
{
    if (!player || delta >= 0)
        return;
    std::vector<uint32> cooldowns;
    for (auto const& entry : player->GetSpellCooldownMap())
        if (sSpellMgr->GetFirstSpellInChain(entry.first) == firstRank)
            cooldowns.push_back(entry.first);
    for (uint32 spell : cooldowns)
    {
        uint32 remaining = player->GetSpellCooldownDelay(spell);
        if (uint64(-int64(delta)) >= remaining)
            player->RemoveSpellCooldown(spell, true);
        else
            player->ModifySpellCooldown(spell, delta);
    }
}

void ApplyUnboundElementalistContract(SpellInfo* info)
{
    SpellEffectInfo& owner = info->Effects[EFFECT_0];
    SpellEffectInfo const& elemental = info->Effects[EFFECT_1];
    if (owner.Effect != SPELL_EFFECT_APPLY_AURA || owner.ApplyAuraName != SPELL_AURA_ADD_PCT_MODIFIER ||
        owner.MiscValue != SPELLMOD_ALL_EFFECTS || owner.BasePoints != -1 || owner.DieSides != 1 ||
        owner.SpellClassMask != flag96(16, 0, 0) || elemental.ApplyAuraName != owner.ApplyAuraName ||
        elemental.MiscValue != owner.MiscValue || elemental.SpellClassMask != owner.SpellClassMask ||
        elemental.DieSides != owner.DieSides || elemental.BasePoints <= 0)
    {
        LOG_ERROR("coa", "Skipped unexpected Unbound Elementalist record {}", info->Id);
        return;
    }

    owner.BasePoints = elemental.BasePoints;
}

uint32 StaticScaledChance(Player const* player, uint32 talent)
{
    Aura const* staticAura = player->GetAura(SPELL_STATIC);
    return TalentProcChance(talent) + (staticAura ? staticAura->GetStackAmount() / 5 : 0);
}

std::list<Unit*> NearbyUnits(Unit* center, float range)
{
    std::list<Unit*> result;
    if (!center || !center->IsInWorld())
        return result;
    Acore::AnyUnitInObjectRangeCheck check(center, range);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center, result, check);
    Cell::VisitObjects(center, search, range);
    result.remove_if([center](Unit* unit) { return !unit->IsAlive() || !center->InSamePhase(unit); });
    result.sort([](Unit* a, Unit* b) { return a->GetGUID() < b->GetGUID(); });
    return result;
}

void SpreadVolt(Player* player, Unit* source, uint32 count, float radius)
{
    Aura* origin = source ? source->GetAuraOfRankedSpell(SPELL_VOLT, player->GetGUID()) : nullptr;
    if (!origin || !count)
        return;
    for (Unit* target : NearbyUnits(source, radius))
    {
        if (target == source || !player->IsValidAttackTarget(target) || !player->IsWithinLOSInMap(target))
            continue;
        if (Aura* old = target->GetAura(origin->GetId(), player->GetGUID());
            old && old->GetDuration() >= origin->GetDuration())
            continue;
        Aura* copy = player->AddAura(origin->GetId(), target);
        if (!copy)
            continue;
        copy->SetStackAmount(origin->GetStackAmount());
        copy->SetMaxDuration(origin->GetMaxDuration());
        copy->SetDuration(origin->GetDuration());
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            if (AuraEffect* effect = origin->GetEffect(i))
                if (AuraEffect* next = copy->GetEffect(i))
                {
                    next->ChangeAmount(effect->GetAmount());
                    next->SetCritChance(effect->GetCritChance());
                    next->SetPctMods(effect->GetPctMods());
                    next->SetPeriodicTimer(effect->GetPeriodicTimer());
                }
        if (!--count)
            break;
    }
}

class stormbringer_talent_casts : public AllSpellScript
{
public:
    stormbringer_talent_casts() : AllSpellScript("stormbringer_talent_casts",
        {ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (player && player->getClass() == CLASS_STORMBRINGER && info->SpellFamilyName == 22 &&
            info->Id == SPELL_CLOUDBURST && !spell->IsTriggered())
            player->CastSpell(player, SPELL_CLOUDBURST_KNOCKBACK, true);

        if (player && player->getClass() == CLASS_STORMBRINGER && IsConjureStorm(info) &&
            !spell->IsTriggered() && player->HasSpell(SPELL_CONJURATION_MASTERY))
            player->CastSpell(player, SPELL_REFUND_STATIC_10, true);
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool critical) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        SpellInfo const* info = spell->GetSpellInfo();
        if (!player || player->getClass() != CLASS_STORMBRINGER || info->SpellFamilyName != 22 ||
            !target || target == player || player->IsFriendlyTo(target) || miss != SPELL_MISS_NONE)
            return;

        if (damage && !spell->IsTriggered() &&
            (player->HasSpell(SPELL_ELECTROCUTIONER_PASSIVE) || player->HasSpell(SPELL_ELECTROCUTIONER_TALENT)) &&
            roll_chance_i(StaticScaledChance(player, SPELL_ELECTROCUTIONER_TALENT)))
            player->CastSpell(player, SPELL_ELECTROCUTIONER, true);

        if (critical && damage && !spell->IsTriggered() && player->HasAura(SPELL_CRITICAL_CIRCUIT) &&
            SpendsStatic(info->Id) && !spell->GetScriptValue(SPELL_CRITICAL_CIRCUIT))
        {
            spell->SetScriptValue(SPELL_CRITICAL_CIRCUIT, 1);
            player->CastSpell(player, SPELL_REFUND_STATIC_10, true);
        }

        if (damage && !spell->IsTriggered() && player->HasSpell(SPELL_LIGHTNING_ROD) &&
            sSpellMgr->GetFirstSpellInChain(info->Id) == SPELL_FORKED_LIGHTNING &&
            roll_chance_i(StaticScaledChance(player, SPELL_LIGHTNING_ROD)))
        {
            if (SpellInfo const* spread = sSpellMgr->GetSpellInfo(SPELL_LIGHTNING_ROD_SPREAD))
                SpreadVolt(player, target, spread->MaxAffectedTargets,
                    spread->Effects[EFFECT_0].CalcRadius(player));
        }

        if (damage && !spell->IsTriggered() && player->HasSpell(SPELL_NEVER_STRIKES_TWICE) &&
            sSpellMgr->GetFirstSpellInChain(info->Id) == SPELL_ELECTROCUTE &&
            roll_chance_i(TalentProcChance(SPELL_NEVER_STRIKES_TWICE)))
            player->CastSpell(target, info->Id, true);

        bool repeat =info->Id == SPELL_PERPETUAL_SHOCK;
        if (!repeat && (spell->IsTriggered() || sSpellMgr->GetFirstSpellInChain(info->Id) != SPELL_SHOCK))
            return;

        SpellInfo const* periodicShare = sSpellMgr->GetSpellInfo(SPELL_SHOCK_HIDDEN_PASSIVE);
        if (damage && periodicShare && !spell->GetScriptValue(SPELL_SHOCK_DOT))
        {
            spell->SetScriptValue(SPELL_SHOCK_DOT, 1);
            int32 const share = player->CalculateSpellDamage(target, periodicShare, EFFECT_0);
            player->CastCustomSpell(SPELL_SHOCK_DOT, SPELLVALUE_BASE_POINT0, int32(damage) * share / 100,
                target, true);
        }
        if (player->HasSpell(SPELL_CALL_LIGHTNING) && !player->HasAura(SPELL_THUNDER_WARD) &&
            !spell->GetScriptValue(SPELL_STATIC))
        {
            spell->SetScriptValue(SPELL_STATIC, 1);
            player->CastSpell(player, SPELL_GENERATE_STATIC_20, true);
        }
    }
};

class stormbringer_pulse_conversion : public AllSpellScript
{
public:
    stormbringer_pulse_conversion() : AllSpellScript("stormbringer_pulse_conversion",
        {ALLSPELLHOOK_ON_SUCCESSFUL_DISPEL}) { }

    void OnSpellSuccessfulDispel(Spell* spell, Unit* target, SpellEffIndex effect, uint32 count) override
    {
        Unit* caster = spell->GetCaster();
        SpellInfo const* info = spell->GetSpellInfo();
        if (!count || !target || !caster->IsPlayer() || caster->getClass() != CLASS_STORMBRINGER ||
            info->Id != SPELL_STORMBREAKER || info->SpellFamilyName != 22 ||
            info->Effects[effect].MiscValue != DISPEL_MAGIC ||
            !caster->HasAura(SPELL_PULSE_CONVERSION, caster->GetGUID()))
            return;
        SpellInfo const* heal = sSpellMgr->GetSpellInfo(SPELL_PULSE_CONVERSION_HEAL);
        if (!heal)
            return;
        int32 amount = int32(caster->CountPctFromMaxHealth(heal->Effects[EFFECT_0].CalcValue()));
        caster->CastCustomSpell(SPELL_PULSE_CONVERSION_HEAL, SPELLVALUE_BASE_POINT0, amount, caster,
            TRIGGERED_FULL_MASK);
    }
};

class stormbringer_resource_contracts : public GlobalScript
{
public:
    stormbringer_resource_contracts() : GlobalScript("stormbringer_resource_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info || info->SpellFamilyName != 22)
            return;
        if (info->Id == SPELL_SHOCK_DOT)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AscensionInheritsResolvedAmount = true;
            info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        }
        if (info->Id == SPELL_THORIMS_GIFT_PATCH)
            info->AscensionInheritsResolvedAmount = true;
        if (info->Id == SPELL_PERPETUAL_SHOCK)
            info->Effects[EFFECT_1].Effect = 0;
        if (info->Id == SPELL_CHARGED_CONDUIT)
            info->Effects[EFFECT_2].Effect = 0;
        if (info->Id == SPELL_INVOKING_STORMS_RANK_1 || info->Id == SPELL_INVOKING_STORMS_RANK_2)
        {
            SpellEffectInfo& scaling = info->Effects[EFFECT_0];
            if (scaling.ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER &&
                scaling.MiscValue == ASCENSION_SPELLMOD_BONUS_MULTIPLIER)
                scaling.MiscValue = SPELLMOD_BONUS_MULTIPLIER;
            flag96 const armOfThorimFamilyFlags(0, 2, 0);
            scaling.SpellClassMask |= armOfThorimFamilyFlags;
        }
        if (info->Id == SPELL_PREDICTABLE_WEATHER_WINDOW &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_ADD_PCT_MODIFIER) &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_CASTING_TIME &&
            info->ProcFlags == PROC_FLAG_DONE_MELEE_AUTO_ATTACK && !info->ProcCharges)
        {
            info->ProcFlags = PROC_FLAG_NONE;
            info->ProcCharges = 1;
        }
        if (info->Id == SPELL_HURRICANES_BUFF &&
            info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_MOD_DAMAGE_PERCENT_DONE &&
            !info->Effects[EFFECT_0].MiscValue)
            info->Effects[EFFECT_0].MiscValue = SPELL_SCHOOL_MASK_ALL;
        if (info->Id == SPELL_UNBOUND_ELEMENTALIST)
            ApplyUnboundElementalistContract(info);
    }
};

class spell_ascension_stormbringer_cooldown_reduction : public SpellScript
{
    PrepareSpellScript(spell_ascension_stormbringer_cooldown_reduction);

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_STORMBRINGER;
    }

    void Reduce(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        ReduceRankCooldowns(GetHitPlayer(), uint32(GetSpellInfo()->Effects[index].MiscValue), GetEffectValue());
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_stormbringer_cooldown_reduction::Reduce,
            EFFECT_ALL, SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN);
    }
};

class aura_ascension_barometric_pressure : public AuraScript
{
    PrepareAuraScript(aura_ascension_barometric_pressure);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_BAROMETRIC_SLOW}); }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetCaster() && GetCaster() == GetTarget())
            GetCaster()->AddAura(SPELL_BAROMETRIC_SLOW, GetTarget());
    }

    void OnRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetCasterGUID() == GetTarget()->GetGUID())
            GetTarget()->RemoveAurasDueToSpell(SPELL_BAROMETRIC_SLOW, GetCasterGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_barometric_pressure::Apply,
            EFFECT_1, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_barometric_pressure::OnRemove,
            EFFECT_1, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_electrical_charge : public AuraScript
{
    PrepareAuraScript(aura_ascension_electrical_charge);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_ELECTRICAL_CHARGE, SPELL_CHARGED_CONDUIT});
    }

    void Tick(AuraEffect const*)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        if (owner->isMoving() || owner->HasAura(SPELL_CHARGED_CONDUIT))
            return;
        owner->CastSpell(owner, SPELL_ELECTRICAL_CHARGE, true);
        if (Aura* charges = owner->GetAura(SPELL_ELECTRICAL_CHARGE))
            if (charges->GetStackAmount() >= sSpellMgr->GetSpellInfo(SPELL_ELECTRICAL_CHARGE)->StackAmount)
                owner->CastSpell(owner, SPELL_CHARGED_CONDUIT, true);
    }

    void OnRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SPELL_CHARGED_CONDUIT);
        GetTarget()->RemoveAurasDueToSpell(SPELL_ELECTRICAL_CHARGE);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_electrical_charge::Tick,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_electrical_charge::OnRemove,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_dark_skies : public AuraScript
{
    PrepareAuraScript(aura_ascension_dark_skies);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_DARK_SKIES_BUFF}); }

    bool Check(ProcEventInfo& event)
    {
        Unit* player = GetTarget();
        Unit* victim = event.GetActionTarget();
        return player->IsPlayer() && player->getClass() == CLASS_STORMBRINGER && player->IsAlive() &&
            GetCaster() == player && event.GetActor() == player && victim && victim != player &&
            !player->IsFriendlyTo(victim) && event.GetDamageInfo() && event.GetDamageInfo()->GetDamage();
    }

    void Proc(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* player = GetTarget();
        if (event.GetHitMask() & PROC_HIT_CRITICAL)
            player->RemoveAurasDueToSpell(SPELL_DARK_SKIES_BUFF);
        else
            player->CastSpell(player, SPELL_DARK_SKIES_BUFF, true);
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SPELL_DARK_SKIES_BUFF);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_dark_skies::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_dark_skies::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_dark_skies::Remove,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_thorims_gift : public AuraScript
{
    PrepareAuraScript(aura_ascension_thorims_gift);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_THORIMS_GIFT &&
            info->Effects[EFFECT_0].TriggerSpell == SPELL_THORIMS_GIFT_PATCH &&
            ValidateSpellInfo({SPELL_THORIMS_GIFT_PATCH});
    }

    bool Load() override
    {
        return GetUnitOwner()->IsPlayer() && GetUnitOwner()->getClass() == CLASS_STORMBRINGER;
    }

    bool Check(ProcEventInfo& event)
    {
        DamageInfo const* damage = event.GetDamageInfo();
        Unit* victim = event.GetActionTarget();
        return event.GetActor() == GetTarget() && victim && victim != GetTarget() &&
            !GetTarget()->IsFriendlyTo(victim) && damage && damage->GetDamage();
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (amount)
            GetTarget()->CastCustomSpell(SPELL_THORIMS_GIFT_PATCH, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())),
                event.GetActionTarget(), TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_thorims_gift::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_thorims_gift::Proc, EFFECT_0, AuraType(354));
    }
};

class aura_ascension_charged_conduit : public AuraScript
{
    PrepareAuraScript(aura_ascension_charged_conduit);

    void OnRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SPELL_ELECTRICAL_CHARGE);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_charged_conduit::OnRemove,
            EFFECT_1, SPELL_AURA_HASTE_SPELLS, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_stormcloak : public AuraScript
{
    PrepareAuraScript(aura_ascension_stormcloak);

    void Calculate(AuraEffect const*, int32& amount, bool& recalculate)
    {
        amount = -1;
        recalculate = false;
    }

    void Absorb(AuraEffect*, DamageInfo& damage, uint32& absorb)
    {
        absorb = 0;
        AuraEffect const* halved = GetEffect(EFFECT_2);
        if (!halved || halved->GetAmount() <= 0 || damage.GetDamageType() == DOT)
            return;
        if (!roll_chance_i(int32(GetSpellInfo()->ProcChance)))
            return;
        absorb = uint32(uint64(damage.GetDamage()) * uint32(halved->GetAmount()) / 100);
    }

    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_stormcloak::Calculate, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_stormcloak::Absorb, EFFECT_0);
    }
};

class aura_ascension_invigorating_winds : public AuraScript
{
    PrepareAuraScript(aura_ascension_invigorating_winds);

    void SetImmunity(bool apply)
    {
        Unit* ally = GetTarget();
        ally->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_SILENCE, apply);
        ally->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_INTERRUPT, apply);
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        SetImmunity(true);
    }

    void OnRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        SetImmunity(false);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_invigorating_winds::Apply,
            EFFECT_1, SPELL_AURA_REDUCE_PUSHBACK, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_invigorating_winds::OnRemove,
            EFFECT_1, SPELL_AURA_REDUCE_PUSHBACK, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_lightning_cage : public AuraScript
{
    PrepareAuraScript(aura_ascension_lightning_cage);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_LIGHTNING_CAGE_BARRIER}); }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* owner = GetTarget()->ToPlayer();
        if (!owner || !owner->HasSpell(SPELL_STORM_BARRIER))
            return;
        if (Aura* barrier = owner->AddAura(SPELL_LIGHTNING_CAGE_BARRIER, owner))
        {
            barrier->SetMaxDuration(GetAura()->GetMaxDuration());
            barrier->SetDuration(GetAura()->GetDuration());
        }
    }

    void OnRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SPELL_LIGHTNING_CAGE_BARRIER);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_lightning_cage::Apply,
            EFFECT_0, SPELL_AURA_MOD_DECREASE_SPEED, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_lightning_cage::OnRemove,
            EFFECT_0, SPELL_AURA_MOD_DECREASE_SPEED, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionStormbringerTalents()
{
    new stormbringer_talent_casts();
    new stormbringer_pulse_conversion();
    new stormbringer_resource_contracts();
    RegisterSpellScript(spell_ascension_stormbringer_cooldown_reduction);
    RegisterSpellScript(aura_ascension_barometric_pressure);
    RegisterSpellScript(aura_ascension_electrical_charge);
    RegisterSpellScript(aura_ascension_thorims_gift);
    RegisterSpellScript(aura_ascension_charged_conduit);
    RegisterSpellScript(aura_ascension_dark_skies);
    RegisterSpellScript(aura_ascension_stormcloak);
    RegisterSpellScript(aura_ascension_invigorating_winds);
    RegisterSpellScript(aura_ascension_lightning_cage);
}
