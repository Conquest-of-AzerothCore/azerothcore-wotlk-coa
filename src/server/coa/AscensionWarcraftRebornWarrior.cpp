/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWarcraftRebornWarrior.h"
#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <cmath>
#include <list>

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 SINGLE_MINDED_FURY_DAMAGE = 1988257;
constexpr uint32 REBORN_SPELL_OFFSET = 1100000;
constexpr uint32 MORTAL_STRIKE_FLAG = 0x2000000;
constexpr uint32 VICTORY_RUSH_FLAG = 0x100;
constexpr int32 VICTORY_RUSH_STOCK_PERCENT = 45;
constexpr uint32 PIERCING_HOWL_FLAG = 0x20;
constexpr uint32 DAZED_FLAG = 0x200000;
constexpr int32 HEROIC_STRIKE_DAZED_PCT = 35;
constexpr int32 BLADESTORM_SINGLE_TARGET_PCT = 30;
constexpr uint32 IMPROVED_SPELL_REFLECTION = 59088;
constexpr uint32 IMPROVED_SPELL_REFLECTION_PARTY = 59725;
constexpr int32 IMPROVED_SPELL_REFLECTION_RADIUS_MOD = 2000;

class spell_ascension_reborn_shockwave : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_shockwave);

    void HandleDamage(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        int32 const pct = GetSpellInfo()->Effects[EFFECT_2].CalcValue(caster);
        if (pct > 0)
            SetEffectValue(GetEffectValue() + int32(CalculatePct(caster->GetTotalAttackPowerValue(BASE_ATTACK), pct)));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_reborn_shockwave::HandleDamage, EFFECT_1, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

bool WieldsTwoOneHanders(Player const* player)
{
    Item const* mainHand = player->GetWeaponForAttack(BASE_ATTACK, true);
    Item const* offHand = player->GetWeaponForAttack(OFF_ATTACK, true);
    return mainHand && offHand && mainHand->GetTemplate()->InventoryType != INVTYPE_2HWEAPON &&
        offHand->GetTemplate()->InventoryType != INVTYPE_2HWEAPON;
}

class spell_ascension_reborn_single_minded_fury : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_single_minded_fury);

    void HandlePeriodic(AuraEffect const* aurEff)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;
        bool const active = player->HasAura(SINGLE_MINDED_FURY_DAMAGE);
        if (WieldsTwoOneHanders(player) && !active)
            player->CastSpell(player, SINGLE_MINDED_FURY_DAMAGE, true, nullptr, aurEff);
        else if (!WieldsTwoOneHanders(player) && active)
            player->RemoveAurasDueToSpell(SINGLE_MINDED_FURY_DAMAGE);
    }

    void HandleRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SINGLE_MINDED_FURY_DAMAGE);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_ascension_reborn_single_minded_fury::HandlePeriodic, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_reborn_single_minded_fury::HandleRemove, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_reborn_single_minded_fury_slam : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_single_minded_fury_slam);

    void HandleOffHand(SpellEffIndex)
    {
        Player* caster = GetCaster()->ToPlayer();
        Unit* target = GetHitUnit();
        if (!caster || !target || !caster->HasAura(SINGLE_MINDED_FURY_DAMAGE) || !WieldsTwoOneHanders(caster))
            return;
        CalcDamageInfo damageInfo;
        caster->CalculateMeleeDamage(target, &damageInfo, OFF_ATTACK);
        caster->DealMeleeDamage(&damageInfo, true);
        caster->SendAttackStateUpdate(&damageInfo);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_reborn_single_minded_fury_slam::HandleOffHand, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

bool Dazed(Unit const* target)
{
    for (AuraEffect const* effect : target->GetAuraEffectsByType(SPELL_AURA_MOD_DECREASE_SPEED))
    {
        SpellInfo const* info = effect->GetSpellInfo();
        if ((info->SpellFamilyName == SPELLFAMILY_WARRIOR && (info->SpellFamilyFlags[1] & (PIERCING_HOWL_FLAG | DAZED_FLAG))) ||
            info->Mechanic == MECHANIC_DAZE || info->HasEffectMechanic(MECHANIC_DAZE))
            return true;
    }
    return false;
}

class spell_ascension_reborn_heroic_strike : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_heroic_strike);

    void HandleHit()
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target || GetHitDamage() <= 0 || !Dazed(target))
            return;
        uint32 const bonus = CalculatePct(GetSpellInfo()->Effects[EFFECT_0].CalcValue(caster), HEROIC_STRIKE_DAZED_PCT);
        SetHitDamage(GetHitDamage() + int32(Unit::CalcArmorReducedDamage(caster, target, bonus, GetSpellInfo())));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_ascension_reborn_heroic_strike::HandleHit);
    }
};

class spell_ascension_reborn_bladestorm_whirlwind : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_bladestorm_whirlwind);

    void CountTargets(std::list<WorldObject*>& targets)
    {
        _single = targets.size() == 1;
    }

    void HandleHit()
    {
        if (_single && GetHitDamage() > 0)
            SetHitDamage(int32(GetHitDamage() * (100 + BLADESTORM_SINGLE_TARGET_PCT) / 100));
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_reborn_bladestorm_whirlwind::CountTargets, EFFECT_0,
            TARGET_UNIT_SRC_AREA_ENEMY);
        OnHit += SpellHitFn(spell_ascension_reborn_bladestorm_whirlwind::HandleHit);
    }

    bool _single = false;
};

class spell_ascension_reborn_spell_reflection : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_spell_reflection);

    void HandleAfterCast()
    {
        Unit* caster = GetCaster();
        AuraEffect const* improved = caster->GetAuraEffectOfRankedSpellOrTwin(IMPROVED_SPELL_REFLECTION, EFFECT_1);
        if (!improved)
            return;
        CustomSpellValues values;
        values.AddSpellMod(SPELLVALUE_MAX_TARGETS, improved->GetAmount());
        values.AddSpellMod(SPELLVALUE_RADIUS_MOD, IMPROVED_SPELL_REFLECTION_RADIUS_MOD);
        caster->CastCustomSpell(sSpellMgr->GetSpellTwinFor(IMPROVED_SPELL_REFLECTION_PARTY, improved->GetId()), values, caster,
            TRIGGERED_FULL_MASK, nullptr);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_reborn_spell_reflection::HandleAfterCast);
    }
};

class spell_ascension_reborn_sudden_death : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_sudden_death);

    bool CheckProc(ProcEventInfo&)
    {
        AuraEffect const* chance = GetEffect(EFFECT_0);
        if (!chance)
            return false;
        ++_hits;
        if (!roll_chance_i(chance->GetAmount() * int32(_hits)))
            return false;
        _hits = 0;
        return true;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_reborn_sudden_death::CheckProc);
    }

    uint32 _hits = 0;
};

bool FlatBonusBeforeWeaponPercent(SpellInfo const* info)
{
    return info->Effects[EFFECT_1].Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG &&
        info->Effects[EFFECT_2].Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE &&
        info->Effects[EFFECT_2].BasePoints + 1 > 0;
}
}
}

void ApplyAscensionWarcraftRebornWarriorContracts(SpellInfo* spellInfo)
{
    using namespace AscensionWarcraftReborn;
    if (!spellInfo || spellInfo->Id < REBORN_SPELL_OFFSET || spellInfo->SpellFamilyName != SPELLFAMILY_WARRIOR)
        return;

    if ((spellInfo->SpellFamilyFlags[1] & VICTORY_RUSH_FLAG) && !spellInfo->Effects[EFFECT_0].BasePoints &&
        spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
        spellInfo->Effects[EFFECT_0].BasePoints = VICTORY_RUSH_STOCK_PERCENT - 1;

    if ((spellInfo->SpellFamilyFlags[0] & MORTAL_STRIKE_FLAG) && FlatBonusBeforeWeaponPercent(spellInfo))
    {
        int32 const percent = spellInfo->Effects[EFFECT_2].BasePoints + 1;
        int32 const bonus = spellInfo->Effects[EFFECT_1].BasePoints + 1;
        spellInfo->Effects[EFFECT_1].BasePoints = int32(std::lround(bonus * 100.0 / percent)) - 1;
    }
}

void AddAscensionWarcraftRebornWarriorScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_shockwave);
    RegisterSpellScript(spell_ascension_reborn_single_minded_fury);
    RegisterSpellScript(spell_ascension_reborn_single_minded_fury_slam);
    RegisterSpellScript(spell_ascension_reborn_sudden_death);
    RegisterSpellScript(spell_ascension_reborn_heroic_strike);
    RegisterSpellScript(spell_ascension_reborn_bladestorm_whirlwind);
    RegisterSpellScript(spell_ascension_reborn_spell_reflection);
}
