/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"

#include <algorithm>
#include <limits>

namespace
{
enum RaidDamageAuraSpells : uint32
{
    Exhaustion = 573255
};

enum class RaidAuraScaling
{
    AttackPower,
    RangedAttackPower,
    ShadowSpellPower,
    ArcaneSpellPower
};

struct RaidDamageAura
{
    uint32 Aura;
    RaidAuraScaling Scaling;
    float Coefficient;
};

constexpr RaidDamageAura RaidDamageAuras[] =
{
    {560530, RaidAuraScaling::AttackPower, 0.35f},
    {537248, RaidAuraScaling::RangedAttackPower, 0.35f},
    {520839, RaidAuraScaling::ShadowSpellPower, 0.6f},
    {520929, RaidAuraScaling::ArcaneSpellPower, 0.7f}
};

RaidDamageAura const* FindRaidDamageAura(uint32 aura)
{
    auto itr = std::find_if(std::begin(RaidDamageAuras), std::end(RaidDamageAuras),
        [aura](RaidDamageAura const& entry) { return entry.Aura == aura; });
    return itr == std::end(RaidDamageAuras) ? nullptr : &*itr;
}

float ScalingValue(Unit* source, RaidAuraScaling scaling)
{
    switch (scaling)
    {
        case RaidAuraScaling::AttackPower: return source->GetTotalAttackPowerValue(BASE_ATTACK);
        case RaidAuraScaling::RangedAttackPower: return source->GetTotalAttackPowerValue(RANGED_ATTACK);
        case RaidAuraScaling::ShadowSpellPower: return float(source->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW));
        case RaidAuraScaling::ArcaneSpellPower: return float(source->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_ARCANE));
    }
    return 0.0f;
}

class spell_ascension_raid_damage_aura : public SpellScript
{
    PrepareSpellScript(spell_ascension_raid_damage_aura);

    void SkipExhausted(std::list<WorldObject*>& targets)
    {
        targets.remove_if([](WorldObject* target)
        {
            Player* player = target->ToPlayer();
            return !player || player->HasAura(Exhaustion);
        });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_raid_damage_aura::SkipExhausted,
            EFFECT_ALL, TARGET_UNIT_CASTER_AREA_RAID);
    }
};

class aura_ascension_raid_damage_aura : public AuraScript
{
    PrepareAuraScript(aura_ascension_raid_damage_aura);

    void Amount(AuraEffect const*, int32& amount, bool&)
    {
        RaidDamageAura const* entry = FindRaidDamageAura(GetId());
        if (Unit* caster = GetCaster(); entry && caster)
            amount = int32(std::clamp(ScalingValue(caster->GetCharmerOrOwnerOrSelf(), entry->Scaling) * entry->Coefficient,
                0.0f, float(std::numeric_limits<int32>::max() / 2)));
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* ally = GetTarget();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        AuraEffect const* effect = GetEffect(EFFECT_0);
        return ally->IsAlive() && event.GetActor() == ally && victim && victim != ally &&
            !ally->IsFriendlyTo(victim) && damage && damage->GetDamage() &&
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) && effect && effect->GetAmount() > 0;
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* ally = GetTarget();
        ally->CastCustomSpell(effect->GetSpellInfo()->Effects[EFFECT_0].TriggerSpell, SPELLVALUE_BASE_POINT0,
            effect->GetAmount(), event.GetActionTarget(), TRIGGERED_FULL_MASK, nullptr, effect, ally->GetGUID());
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_raid_damage_aura::Amount, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL_WITH_VALUE);
        DoCheckProc += AuraCheckProcFn(aura_ascension_raid_damage_aura::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_raid_damage_aura::Proc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL_WITH_VALUE);
    }
};
}

void AddSC_AscensionRaidDamageAuras()
{
    RegisterSpellScript(spell_ascension_raid_damage_aura);
    RegisterSpellScript(aura_ascension_raid_damage_aura);
}
