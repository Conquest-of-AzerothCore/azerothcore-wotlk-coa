/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWarcraftRebornShaman.h"
#include "Creature.h"
#include "Item.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 TIDAL_FORCE_CRIT = 1155166;
constexpr uint32 MAELSTROM_WEAPON_OVERLAY = 1153816;
constexpr uint32 MAELSTROM_WEAPON_CONSUMPTION = 1153822;
constexpr uint32 SHAMAN_FLAMETONGUE_WEAPON = 0x200000;
constexpr int32 LAVA_SWEEP_FLAMETONGUE_PCT = 50;
constexpr std::array<uint32, 3> DUAL_WIELD_SPECIALIZATION = { 1130816, 1130818, 1130819 };

bool HasFlametongue(Player const* player, Item const* weapon)
{
    for (AuraEffect const* effect : player->GetAuraEffectsByType(SPELL_AURA_DUMMY))
    {
        SpellInfo const* spellInfo = effect->GetSpellInfo();
        if (spellInfo->SpellFamilyName == SPELLFAMILY_SHAMAN && (spellInfo->SpellFamilyFlags[0] & SHAMAN_FLAMETONGUE_WEAPON) &&
            effect->GetBase()->GetCastItemGUID() == weapon->GetGUID())
            return true;
    }
    return false;
}

class spell_ascension_reborn_lava_sweep : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_lava_sweep);

    bool Load() override
    {
        return GetCaster()->IsPlayer();
    }

    void HandleHit()
    {
        Player* caster = GetCaster()->ToPlayer();
        Item* weapon = caster->GetWeaponForAttack(BASE_ATTACK, true);
        int32 damage = GetHitDamage();
        if (!weapon || damage <= 0)
            return;
        if (GetHitUnit() == GetExplTargetUnit())
            if (int32 const otherTargets = GetSpellInfo()->Effects[EFFECT_0].CalcValue(caster))
                damage = damage * 100 / otherTargets;
        if (HasFlametongue(caster, weapon))
            AddPct(damage, LAVA_SWEEP_FLAMETONGUE_PCT);
        if (weapon->GetTemplate()->InventoryType != INVTYPE_2HWEAPON)
            AddPct(damage, GetSpellInfo()->Effects[EFFECT_1].CalcValue(caster));
        SetHitDamage(damage);
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_ascension_reborn_lava_sweep::HandleHit);
    }
};

class spell_ascension_reborn_tidal_force : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_tidal_force);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ TIDAL_FORCE_CRIT });
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes)
    {
        Unit* target = GetTarget();
        target->CastSpell(target, TIDAL_FORCE_CRIT, true, nullptr, aurEff);
        if (Aura* crit = target->GetAura(TIDAL_FORCE_CRIT))
            crit->SetStackAmount(crit->GetSpellInfo()->StackAmount);
    }

    void HandleProc(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        Unit* target = GetTarget();
        target->RemoveAuraFromStack(TIDAL_FORCE_CRIT);
        if (!target->HasAura(TIDAL_FORCE_CRIT))
            Remove();
    }

    void HandleRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(TIDAL_FORCE_CRIT);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_ascension_reborn_tidal_force::HandleApply, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_tidal_force::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_reborn_tidal_force::HandleRemove, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_reborn_maelstrom_weapon : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_maelstrom_weapon);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ MAELSTROM_WEAPON_OVERLAY, MAELSTROM_WEAPON_CONSUMPTION });
    }

    void HandleProc(ProcEventInfo&)
    {
        Unit* target = GetTarget();
        int32 const consumed = sSpellMgr->AssertSpellInfo(MAELSTROM_WEAPON_CONSUMPTION)->Effects[EFFECT_0].CalcValue(target);
        if (Aura* overlay = target->GetAura(MAELSTROM_WEAPON_OVERLAY))
            overlay->ModStackAmount(-consumed);
        ModStackAmount(-consumed);
    }

    void Register() override
    {
        AfterProc += AuraProcFn(spell_ascension_reborn_maelstrom_weapon::HandleProc);
    }
};

class spell_ascension_reborn_totemic_projection : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_totemic_projection);

    void HandleDummy(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        WorldLocation const* destination = GetHitDest();
        if (!destination)
            return;
        for (uint8 slot = SUMMON_SLOT_TOTEM_FIRE; slot < MAX_TOTEM_SLOT; ++slot)
            if (Creature* totem = caster->GetMap()->GetCreature(caster->m_SummonSlot[slot]))
                totem->NearTeleportTo(destination->GetPositionX(), destination->GetPositionY(), destination->GetPositionZ(),
                    totem->GetOrientation());
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_reborn_totemic_projection::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_ascension_reborn_spirit_guard : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_spirit_guard);

    void CalculateAmount(AuraEffect const*, int32& amount, bool&)
    {
        amount = -1;
    }

    void Absorb(AuraEffect* aurEff, DamageInfo& dmgInfo, uint32& absorbAmount)
    {
        absorbAmount = dmgInfo.GetBlock() ? CalculatePct(dmgInfo.GetDamage(), aurEff->GetBaseAmount()) : 0;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ascension_reborn_spirit_guard::CalculateAmount, EFFECT_0,
            SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(spell_ascension_reborn_spirit_guard::Absorb, EFFECT_0);
    }
};

class spell_ascension_reborn_dual_wield_specialization : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_dual_wield_specialization);

    void CalculateAmount(AuraEffect const*, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;
        if (!GetUnitOwner()->HasOffhandWeapon())
            amount = 0;
    }

    void CalcPeriodic(AuraEffect const*, bool& isPeriodic, int32& amplitude)
    {
        isPeriodic = true;
        amplitude = 1 * IN_MILLISECONDS;
    }

    void Update(AuraEffect const* aurEff)
    {
        PreventDefaultAction();
        if ((aurEff->GetAmount() != 0) != GetUnitOwner()->HasOffhandWeapon())
            GetEffect(aurEff->GetEffIndex())->RecalculateAmount();
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ascension_reborn_dual_wield_specialization::CalculateAmount,
            EFFECT_0, SPELL_AURA_MOD_HIT_CHANCE);
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(spell_ascension_reborn_dual_wield_specialization::CalcPeriodic,
            EFFECT_0, SPELL_AURA_MOD_HIT_CHANCE);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_ascension_reborn_dual_wield_specialization::Update, EFFECT_0,
            SPELL_AURA_MOD_HIT_CHANCE);
    }
};
}
}

void ApplyAscensionWarcraftRebornShamanContracts(SpellInfo* spellInfo)
{
    using namespace AscensionWarcraftReborn;
    if (!spellInfo || std::find(DUAL_WIELD_SPECIALIZATION.begin(), DUAL_WIELD_SPECIALIZATION.end(), spellInfo->Id) ==
        DUAL_WIELD_SPECIALIZATION.end())
        return;
    SpellEffectInfo& hit = spellInfo->Effects[EFFECT_0];
    if (hit.Effect == SPELL_EFFECT_APPLY_AURA && hit.ApplyAuraName == SPELL_AURA_DUMMY)
        hit.ApplyAuraName = SPELL_AURA_MOD_HIT_CHANCE;
}

void AddAscensionWarcraftRebornShamanScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_lava_sweep);
    RegisterSpellScript(spell_ascension_reborn_maelstrom_weapon);
    RegisterSpellScript(spell_ascension_reborn_tidal_force);
    RegisterSpellScript(spell_ascension_reborn_totemic_projection);
    RegisterSpellScript(spell_ascension_reborn_spirit_guard);
    RegisterSpellScript(spell_ascension_reborn_dual_wield_specialization);
}
