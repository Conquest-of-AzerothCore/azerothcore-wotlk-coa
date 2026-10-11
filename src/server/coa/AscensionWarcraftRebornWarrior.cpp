/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 SINGLE_MINDED_FURY_DAMAGE = 1988257;

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
}
}

void AddAscensionWarcraftRebornWarriorScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_shockwave);
    RegisterSpellScript(spell_ascension_reborn_single_minded_fury);
    RegisterSpellScript(spell_ascension_reborn_single_minded_fury_slam);
}
