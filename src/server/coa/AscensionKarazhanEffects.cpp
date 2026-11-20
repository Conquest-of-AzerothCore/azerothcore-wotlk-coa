#include "AscensionRaidReleasePolicy.h"
#include "GlobalScript.h"
#include "Map.h"
#include "Random.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "Unit.h"
#include "UnitScript.h"
#include <algorithm>
#include <array>
#include <limits>

namespace
{
struct KarazhanEffect
{
    uint32 spellId;
    int32 amount;
    uint32 affectedAbility;
};

constexpr std::array<KarazhanEffect, 19> KarazhanEffects = {{
    { 34519, 238, 0 },
    { 37208, 446, 0 },
    { 38321, 111, 801990 },
    { 38322, 69, 575039 },
    { 60800, 73, 800357 },
    { 234519, 257, 0 },
    { 237208, 463, 0 },
    { 238321, 125, 801990 },
    { 238322, 81, 575039 },
    { 260800, 85, 800357 },
    { 334519, 249, 0 },
    { 337208, 453, 0 },
    { 338321, 122, 801990 },
    { 338322, 76, 575039 },
    { 360800, 81, 800357 },
    { 434519, 261, 0 },
    { 438322, 85, 575039 },
    { 460800, 91, 800357 },
    { 1337208, 457, 0 }
}};

struct KarazhanProc
{
    uint32 spellId;
    int32 amount;
    int32 dieSides;
    bool matchSecondaryAmount;
};

struct TierFourRoleBonus
{
    uint32 spellId;
    AuraType aura;
    int32 amount;
    int32 miscValue;
};

constexpr TierFourRoleBonus TierFourRoleBonuses[] = {
    { 37168, SPELL_AURA_MOD_RATING, 20, 1 << CR_HASTE_MELEE },
    { 37183, SPELL_AURA_MOD_RATING, 20, 1 << CR_HASTE_SPELL },
    { 37184, SPELL_AURA_MOD_RATING, 20, 1 << CR_DEFENSE_SKILL },
    { 37185, SPELL_AURA_MOD_RATING, 20, 1 << CR_BLOCK },
    { 37187, SPELL_AURA_MOD_RATING, 20, (1 << CR_HASTE_MELEE) | (1 << CR_HASTE_SPELL) },
    { 37211, SPELL_AURA_MOD_RATING, 20, 1 << CR_HASTE_SPELL },
    { 37292, SPELL_AURA_MOD_RATING, 20, 1 << CR_HASTE_SPELL },
    { 37298, SPELL_AURA_MOD_RESISTANCE_PCT, 2, SPELL_SCHOOL_MASK_NORMAL },
    { 37306, SPELL_AURA_MOD_RATING, 20, 1 << CR_DODGE },
    { 37311, SPELL_AURA_MOD_RATING, 20, 1 << CR_HASTE_MELEE },
    { 37377, SPELL_AURA_MOD_DAMAGE_DONE, 30, SPELL_SCHOOL_MASK_SHADOW },
    { 37380, SPELL_AURA_MOD_RATING, 20, 1 << CR_HASTE_SPELL },
    { 37484, SPELL_AURA_MOD_RATING, 20, 1 << CR_HASTE_RANGED },
    { 37485, SPELL_AURA_MOD_RANGED_ATTACK_POWER, 50, 0 },
    { 37516, SPELL_AURA_MOD_RATING, 20, 1 << CR_BLOCK },
    { 37518, SPELL_AURA_MOD_RATING, 20, 1 << CR_ARMOR_PENETRATION },
    { 37519, SPELL_AURA_DUMMY, 15, 0 },
    { 39437, SPELL_AURA_MOD_DAMAGE_DONE, 30, SPELL_SCHOOL_MASK_FIRE }
};

void RemoveEffect(SpellEffectInfo& effect)
{
    effect.Effect = 0;
    effect.ApplyAuraName = SPELL_AURA_NONE;
    effect.TriggerSpell = 0;
}

void ConfigureTierFourBonus(SpellInfo* spell)
{
    auto const role = std::find_if(std::begin(TierFourRoleBonuses), std::end(TierFourRoleBonuses),
        [spell](TierFourRoleBonus const& bonus) { return bonus.spellId == spell->Id; });
    if (role != std::end(TierFourRoleBonuses))
    {
        SpellEffectInfo& effect = spell->Effects[EFFECT_0];
        effect.Effect = SPELL_EFFECT_APPLY_AURA;
        effect.ApplyAuraName = role->aura;
        effect.BasePoints = role->amount - 1;
        effect.DieSides = 1;
        effect.MiscValue = role->miscValue;
        effect.TriggerSpell = 0;
        effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        effect.TargetB = SpellImplicitTargetInfo();
        spell->Stances = 0;
        spell->StancesNot = 0;
        spell->ProcFlags = 0;
        RemoveEffect(spell->Effects[EFFECT_1]);
        RemoveEffect(spell->Effects[EFFECT_2]);
    }

    if (spell->Id == 37439)
    {
        RemoveEffect(spell->Effects[EFFECT_1]);
        RemoveEffect(spell->Effects[EFFECT_2]);
    }
    if (spell->Id == 37570)
    {
        RemoveEffect(spell->Effects[EFFECT_0]);
        spell->ProcFlags = 0;
    }
}

class ascension_warbringer_bleed_bonus : public UnitScript
{
public:
    ascension_warbringer_bleed_bonus() : UnitScript("ascension_warbringer_bleed_bonus", true,
        {UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK}) { }

    void ModifyPeriodicDamageAurasTick(Unit*, Unit* caster, uint32& damage, SpellInfo const* spell) override
    {
        if (!caster || !spell || !damage || spell->HasAura(SPELL_AURA_PERIODIC_HEAL))
            return;

        AuraEffect const* bonus = caster->GetAuraEffect(37519, EFFECT_0);
        if (!bonus)
            return;

        for (SpellEffectInfo const& effect : spell->GetEffects())
            if ((effect.ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE ||
                    effect.ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE_PERCENT ||
                    effect.ApplyAuraName == SPELL_AURA_PERIODIC_LEECH) &&
                (spell->GetEffectMechanicMask(effect.EffectIndex) & (1ULL << MECHANIC_BLEED)))
            {
                AddPct(damage, bonus->GetAmount());
                return;
            }
    }
};

class ascension_karazhan_encounter_damage : public UnitScript
{
public:
    ascension_karazhan_encounter_damage() : UnitScript("ascension_karazhan_encounter_damage", true,
        {UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK}) { }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
    {
        ScaleDamage(target, attacker, damage);
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* spell) override
    {
        if (spell && !spell->IsPositive() && damage > 0)
            ScaleDamage(target, attacker, damage);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* spell) override
    {
        if (spell && !spell->IsPositive() && !spell->HasAura(SPELL_AURA_PERIODIC_DAMAGE_PERCENT))
            ScaleDamage(target, attacker, damage);
    }

private:
    template <class Damage>
    static void ScaleDamage(Unit* target, Unit* attacker, Damage& amount)
    {
        if (!target || (!target->IsPlayer() && !target->IsPet()) || !attacker ||
            !attacker->IsCreature() || attacker->IsControlledByPlayer() || attacker->IsFriendlyTo(target) ||
            attacker->GetMapId() != RaidRelease::MapKarazhan)
            return;

        Map const* map = attacker->FindMap();
        if (!map || map->IsScriptedPrivateInstance())
            return;

        constexpr std::array<int32, MAX_RAID_DIFFICULTY> damagePercent = {100, 144, 188, 232};
        uint8 const mode = map->GetSpawnMode();
        if (mode > 0 && mode < damagePercent.size())
            amount = Damage(std::min<int64>(int64(amount) * damagePercent[mode] / 100,
                std::numeric_limits<Damage>::max()));
    }
};

constexpr std::array<KarazhanProc, 26> KarazhanProcs = {{
    { 34580, 491, 0, false },
    { 34585, 121, 0, false },
    { 34587, 272, 0, false },
    { 34597, 106, 0, true },
    { 35095, 21, 0, false },
    { 37661, 496, 0, false },
    { 38333, 205, 124, false },
    { 234580, 514, 0, false },
    { 234585, 123, 0, false },
    { 234587, 284, 0, false },
    { 234597, 111, 0, true },
    { 235095, 23, 0, false },
    { 237661, 520, 0, false },
    { 238333, 214, 130, false },
    { 334580, 513, 0, false },
    { 334586, 284, 0, false },
    { 335095, 22, 0, false },
    { 337661, 518, 0, false },
    { 338333, 231, 143, false },
    { 434587, 292, 0, false },
    { 435095, 23, 0, false },
    { 437661, 535, 0, false },
    { 438333, 231, 147, false },
    { 1334580, 529, 0, false },
    { 1334585, 122, 0, false },
    { 1334597, 115, 0, false }
}};

KarazhanEffect const* FindKarazhanEffect(uint32 spellId)
{
    auto const found = std::lower_bound(KarazhanEffects.begin(), KarazhanEffects.end(), spellId,
        [](KarazhanEffect const& effect, uint32 id) { return effect.spellId < id; });
    return found != KarazhanEffects.end() && found->spellId == spellId ? &*found : nullptr;
}

uint32 RibbonHealSpell(uint32 auraId)
{
    switch (auraId)
    {
        case 38332: return 38333;
        case 338332: return 338333;
        case 238332: return 238333;
        case 438332: return 438333;
        default: return 0;
    }
}

class spell_karazhan_ribbon_of_sacrifice : public AuraScript
{
    PrepareAuraScript(spell_karazhan_ribbon_of_sacrifice);

    bool Validate(SpellInfo const* info) override
    {
        return ValidateSpellInfo({RibbonHealSpell(info->Id)});
    }

    bool EligibleHeal(ProcEventInfo& eventInfo)
    {
        Unit* healer = GetTarget();
        HealInfo const* heal = eventInfo.GetHealInfo();
        Unit* ally = heal ? heal->GetTarget() : nullptr;
        SpellInfo const* triggeringSpell = eventInfo.GetSpellInfo();
        return ally && ally->IsAlive() && ally->HealthBelowPct(50) && healer->IsFriendlyTo(ally) &&
            eventInfo.GetActor() == healer && healer->GetMaxPower(POWER_MANA) &&
            healer->GetPowerPct(POWER_MANA) > 50.0f &&
            triggeringSpell && triggeringSpell->Id != RibbonHealSpell(GetId()) &&
            (eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) == 0;
    }

    void OnHeal(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (roll_chance_i(40))
            GetTarget()->CastSpell(eventInfo.GetHealInfo()->GetTarget(), RibbonHealSpell(GetId()), true, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_karazhan_ribbon_of_sacrifice::EligibleHeal);
        OnEffectProc += AuraEffectProcFn(spell_karazhan_ribbon_of_sacrifice::OnHeal, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class ascension_karazhan_effects : public GlobalScript
{
public:
    ascension_karazhan_effects() : GlobalScript("ascension_karazhan_effects",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR, GLOBALHOOK_ON_SPELL_MOD_FAMILY_MASK}) { }

    void OnLoadSpellCustomAttr(SpellInfo* spell) override
    {
        ConfigureTierFourBonus(spell);

        if (spell->Id == 329601)
            spell->Effects[EFFECT_0].TriggerSpell = 335095;

        if (KarazhanEffect const* effect = FindKarazhanEffect(spell->Id))
            spell->Effects[EFFECT_0].BasePoints = effect->amount - 1;

        auto const proc = std::lower_bound(KarazhanProcs.begin(), KarazhanProcs.end(), spell->Id,
            [](KarazhanProc const& effect, uint32 id) { return effect.spellId < id; });
        if (proc == KarazhanProcs.end() || proc->spellId != spell->Id)
            return;

        spell->Effects[EFFECT_0].BasePoints = proc->amount - 1;
        if (proc->dieSides)
            spell->Effects[EFFECT_0].DieSides = proc->dieSides;
        if (proc->matchSecondaryAmount)
            spell->Effects[EFFECT_1].BasePoints = proc->amount - 1;
    }

    void OnSpellModFamilyMask(SpellInfo const* modifier, SpellInfo const* ability, SpellModifier const*,
        bool& affected) override
    {
        KarazhanEffect const* effect = FindKarazhanEffect(modifier->Id);
        if (effect && effect->affectedAbility)
            affected = ability->Id == effect->affectedAbility ||
                sSpellMgr->GetFirstSpellInChain(ability->Id) == effect->affectedAbility;
    }
};
}

void AddSC_AscensionKarazhanEffects()
{
    new ascension_karazhan_effects();
    new ascension_warbringer_bleed_bonus();
    new ascension_karazhan_encounter_damage();
    RegisterSpellScript(spell_karazhan_ribbon_of_sacrifice);
}
