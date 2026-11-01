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
constexpr uint32 EARTHEN_GUARDIAN_MASTERY = 1134980;
constexpr uint32 SHAMAN_LIGHTNING_BOLT = 0x1;
constexpr uint32 SHAMAN_CHAIN_LIGHTNING = 0x2;
constexpr uint32 LIGHTNING_OVERLOAD_BOLT = 1145284;
constexpr uint32 LIGHTNING_OVERLOAD_CHAIN = 1145297;
constexpr int32 LIGHTNING_OVERLOAD_PCT = 50;
constexpr uint32 SHAMAN_STONECLAW_TOTEM = 0x8;
constexpr uint32 SHAMAN_SEARING_TOTEM = 0x10;
constexpr uint32 SHAMAN_MAGMA_TOTEM = 0x1000;
constexpr uint32 EARTHEN_GUARDIAN = 1182001;
constexpr uint32 TOTEMIC_BOND_DAMAGE_REDUCTION = 1182042;
constexpr std::array<uint32, 3> TOTEMIC_BOND = { 1182036, 1182037, 1182038 };
constexpr std::array<uint32, 3> TOTEMIC_BOND_THREAT = { 1182039, 1182040, 1182041 };

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

    void Absorb(AuraEffect*, DamageInfo& dmgInfo, uint32& absorbAmount)
    {
        absorbAmount = dmgInfo.GetBlock() ?
            CalculatePct(dmgInfo.GetDamage(), GetSpellInfo()->Effects[EFFECT_0].CalcValue()) : 0;
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

class spell_ascension_reborn_lightning_overload : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_lightning_overload);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ LIGHTNING_OVERLOAD_BOLT, LIGHTNING_OVERLOAD_CHAIN });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        return spellInfo && eventInfo.GetActionTarget() && eventInfo.GetDamageInfo() && GetTarget()->IsPlayer() &&
            (spellInfo->SpellFamilyFlags[0] & (SHAMAN_LIGHTNING_BOLT | SHAMAN_CHAIN_LIGHTNING)) &&
            roll_chance_i(LIGHTNING_OVERLOAD_PCT);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        int32 damage = eventInfo.GetDamageInfo()->GetDamage();
        if (eventInfo.GetHitMask() & PROC_EX_CRITICAL_HIT)
            damage /= 2;
        damage /= 2;
        uint32 const overload = (eventInfo.GetSpellInfo()->SpellFamilyFlags[0] & SHAMAN_CHAIN_LIGHTNING) ?
            LIGHTNING_OVERLOAD_CHAIN : LIGHTNING_OVERLOAD_BOLT;
        GetTarget()->CastCustomSpell(overload, SPELLVALUE_BASE_POINT0, damage, eventInfo.GetActionTarget(), true, nullptr,
            aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_reborn_lightning_overload::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_lightning_overload::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_reborn_totemic_bond : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_totemic_bond);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ EARTHEN_GUARDIAN, TOTEMIC_BOND_DAMAGE_REDUCTION, TOTEMIC_BOND_THREAT[0],
            TOTEMIC_BOND_THREAT[1], TOTEMIC_BOND_THREAT[2] });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        if (!spellInfo || spellInfo->SpellFamilyName != SPELLFAMILY_SHAMAN || !spellInfo->HasEffect(SPELL_EFFECT_SUMMON))
            return false;
        if (spellInfo->SpellFamilyFlags[0] & SHAMAN_STONECLAW_TOTEM)
            return GetTarget()->HasAura(EARTHEN_GUARDIAN) && roll_chance_i(GetSpellInfo()->ProcChance);
        return spellInfo->SpellFamilyFlags[0] & (SHAMAN_SEARING_TOTEM | SHAMAN_MAGMA_TOTEM);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* target = GetTarget();
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        if (spellInfo->SpellFamilyFlags[0] & SHAMAN_STONECLAW_TOTEM)
        {
            target->CastSpell(target, TOTEMIC_BOND_DAMAGE_REDUCTION, true, nullptr, aurEff);
            return;
        }
        auto const rank = std::find(TOTEMIC_BOND.begin(), TOTEMIC_BOND.end(), GetId());
        Creature* totem = target->GetMap()->GetCreature(target->m_SummonSlot[SUMMON_SLOT_TOTEM_FIRE]);
        if (rank != TOTEMIC_BOND.end() && totem && totem->GetUInt32Value(UNIT_CREATED_BY_SPELL) == spellInfo->Id)
            totem->CastSpell(target, TOTEMIC_BOND_THREAT[rank - TOTEMIC_BOND.begin()], true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_reborn_totemic_bond::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_totemic_bond::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};
}
}

void ApplyAscensionWarcraftRebornShamanContracts(SpellInfo* spellInfo)
{
    using namespace AscensionWarcraftReborn;
    if (!spellInfo)
        return;
    if (spellInfo->Id == EARTHEN_GUARDIAN_MASTERY && spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_MOD_THREAT &&
        !spellInfo->Effects[EFFECT_1].MiscValue)
        spellInfo->Effects[EFFECT_1].MiscValue = SPELL_SCHOOL_MASK_ALL;
    if (std::find(DUAL_WIELD_SPECIALIZATION.begin(), DUAL_WIELD_SPECIALIZATION.end(), spellInfo->Id) ==
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
    RegisterSpellScript(spell_ascension_reborn_lightning_overload);
    RegisterSpellScript(spell_ascension_reborn_totemic_bond);
}
