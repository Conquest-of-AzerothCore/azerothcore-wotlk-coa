/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionGuardianCompletion.h"
#include "AscensionClientSpellPatches.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "CellImpl.h"
#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <cmath>
#include <limits>

namespace
{
Player* GuardianPlayer(Unit* unit)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_GUARDIAN ? player : nullptr;
}

float ShieldValue(Player const* player)
{
    Item const* shield = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
    return shield && !shield->IsBroken() && shield->GetTemplate()->InventoryType == INVTYPE_SHIELD ?
        float(player->GetShieldBlockValue()) : 0.0f;
}

uint32 Nearby(Unit* unit, bool allies, float range)
{
    std::list<Unit*> units;
    Acore::AnyUnitInObjectRangeCheck check(unit, range);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> searcher(unit, units, check);
    Cell::VisitObjects(unit, searcher, range);
    return uint32(std::count_if(units.begin(), units.end(), [=](Unit* target)
    {
        if (target == unit || !target->IsAlive() || !unit->InSamePhase(target))
            return false;
        return allies ? unit->IsFriendlyTo(target) && target->IsControlledByPlayer() :
            unit->IsValidAttackTarget(target);
    }));
}

bool Dynamic(uint32 id)
{
    return id == 300860 || id == 505199 || id == 705381 || id == 807794 || id == 707662;
}

int32 DynamicAmount(Unit* owner, uint32 id)
{
    Player* player = GuardianPlayer(owner);
    if (!player)
        return 0;
    switch (id)
    {
        case 300860:
            return int32(std::min(20u, Nearby(owner, true,
                sSpellMgr->GetSpellInfo(id)->Effects[EFFECT_0].CalcRadius(owner))));
        case 505199:
            return -int32(std::min(sSpellMgr->GetSpellInfo(id)->MaxAffectedTargets, Nearby(owner, false,
                sSpellMgr->GetSpellInfo(id)->Effects[EFFECT_1].CalcRadius(owner))));
        case 705381: return int32(player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_BLOCK));
        case 807794: return int32(player->GetStat(STAT_STAMINA) * 0.2f);
        case 707662: return 15 + int32(ShieldValue(player) * 0.3f);
        default: return 0;
    }
}

class guardian_scaling : public UnitScript
{
public:
    guardian_scaling() : UnitScript("guardian_scaling", true, { UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE }) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        if (caster && info->Id == 800629 && !index)
        {
            Player const* owner = caster->GetCharmerOrOwnerPlayerOrPlayerItself();
            if (owner && owner->getClass() == CLASS_GUARDIAN && owner->HasAura(802296))
                value -= 15.0f;
            return;
        }
        Player const* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_GUARDIAN || info->SpellFamilyName != 24)
            return;
        uint32 id = info->Id;
        if (!index && AscensionGuardian::Ram(id))
            value += ShieldValue(player);
        else if (!index && (AscensionGuardian::HeavyBlow(id) || id == 802629))
            value += player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_DEFENSE_SKILL) * 0.5f;
        else if (!index && id == 573212)
            value += player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_DEFENSE_SKILL) * 0.2f;
        else if (!index && id == 803131)
            value += player->GetStat(STAT_STAMINA) * 0.0375f;
        else if (!index && id == 707140)
            value += player->GetStat(STAT_STAMINA) * 0.1f + player->GetTotalAttackPowerValue(BASE_ATTACK) * 0.11f;
        else if (!index && id == 520651)
            value += player->GetTotalAttackPowerValue(BASE_ATTACK) * 0.1f;
        value = std::clamp(value, -float(std::numeric_limits<int32>::max() / 2),
            float(std::numeric_limits<int32>::max() / 2));
    }
};

class aura_ascension_guardian_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_guardian_lifecycle);

    void Calculate(AuraEffect const* effect, int32& amount, bool& recalculate)
    {
        if (effect->GetEffIndex() == EFFECT_0 && Dynamic(GetId()))
        {
            amount = DynamicAmount(GetUnitOwner(), GetId());
            recalculate = false;
        }
    }

    void Periodic(AuraEffect const* effect, bool& periodic, int32& amplitude)
    {
        if (effect->GetEffIndex() == EFFECT_0 && Dynamic(GetId()))
        {
            periodic = true;
            amplitude = 1000;
        }
    }

    void Tick(AuraEffect const* effect)
    {
        if (effect->GetEffIndex() != EFFECT_0)
            return;
        if (Dynamic(GetId()))
        {
            PreventDefaultAction();
            int32 amount = DynamicAmount(GetTarget(), GetId());
            if (effect->GetAmount() != amount)
                GetEffect(EFFECT_0)->ChangeAmount(amount);
        }
        else if (GetId() == 504139 && !GetTarget()->IsInCombat())
        {
            PreventDefaultAction();
            GetTarget()->RemoveAurasDueToSpell(504145);
        }
    }

    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        for (uint8 i = 0; i < effect->GetEffIndex(); ++i)
            if (GetEffect(i))
                return;
        Unit* owner = GetTarget();
        if (GetId() == 503634)
            owner->CastSpell(owner, 573255, true, nullptr, effect);
        else if (GetId() == 524610)
        {
            if (GetStackAmount() >= 5)
                if (Unit* caster = GetCaster())
                    caster->CastSpell(owner, 524609, true, nullptr, effect);
        }
        else if (GetId() == 801774 && owner == GetCaster())
            owner->CastSpell(owner, 803524, true, nullptr, effect);
        else if (GetId() == 705376)
            owner->CastSpell(owner, 707662, true, nullptr, effect);
        else if (GetId() == 803738)
            owner->CastSpell(owner, 807794, true, nullptr, effect);
        else if (GetId() == 300542 || GetId() == 803130)
            owner->UpdateSpeed(MOVE_RUN, true);
        else if (GetId() == 804691 && GetCaster() && GetCaster()->HasAura(503631))
        {
            owner->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_ROOT, true);
            owner->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_SNARE, true);
            owner->RemoveAurasWithMechanic((1 << MECHANIC_ROOT) | (1 << MECHANIC_SNARE), AURA_REMOVE_BY_DEFAULT);
        }
    }

    void Removed(AuraEffect const* effect, AuraEffectHandleModes)
    {
        for (uint8 i = 0; i < effect->GetEffIndex(); ++i)
            if (GetEffect(i))
                return;
        Unit* owner = GetTarget();
        AuraRemoveMode mode = GetTargetApplication()->GetRemoveMode();
        switch (GetId())
        {
            case 803956:
                if (mode == AURA_REMOVE_BY_EXPIRE && owner->IsAlive() && owner->IsInWorld())
                    owner->CastSpell(owner, 572329, true, nullptr, effect);
                break;
            case 801774: owner->RemoveAurasDueToSpell(803524, owner->GetGUID()); break;
            case 705376: owner->RemoveAurasDueToSpell(707662); break;
            case 803738: owner->RemoveAurasDueToSpell(807794); break;
            case 807297: owner->RemoveAurasDueToSpell(705381); break;
            case 804891: owner->RemoveAurasDueToSpell(572158); break;
            case 706514:
                owner->RemoveAurasDueToSpell(706516);
                owner->RemoveAurasDueToSpell(707138);
                owner->RemoveAurasDueToSpell(803432);
                break;
            case 504139: owner->RemoveAurasDueToSpell(504145); break;
            case 300542:
            case 803130:
                owner->UpdateSpeed(MOVE_RUN, true);
                break;
            case 804691:
                owner->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_ROOT, false);
                owner->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_SNARE, false);
                break;
            default:
                break;
        }
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_guardian_lifecycle::Calculate,
            EFFECT_ALL, SPELL_AURA_ANY);
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_ascension_guardian_lifecycle::Periodic,
            EFFECT_ALL, SPELL_AURA_ANY);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_guardian_lifecycle::Tick, EFFECT_ALL, SPELL_AURA_ANY);
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_guardian_lifecycle::Apply,
            EFFECT_ALL, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_guardian_lifecycle::Removed,
            EFFECT_ALL, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AscensionGuardian::AddParagon(Player* player, std::uint8_t amount)
{
    if (!GuardianPlayer(player) || !player->HasAura(706514) || player->HasAura(707138))
        return;
    for (uint8 i = 0; i < amount; ++i)
        player->CastSpell(player, 706516, true);
    Aura const* stacks = player->GetAura(706516);
    if (stacks && stacks->GetStackAmount() >= 10)
    {
        player->RemoveAurasDueToSpell(706516);
        player->CastSpell(player, 707138, true);
    }
}

void AscensionGuardian::ApplyContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != 24)
        return;
    uint32 id = info->Id;
    if (id == 802629)
        info->PowerType = POWER_ENERGY;
    if (id == 803738)
        for (auto& effect : info->Effects)
            if (effect.Effect == SPELL_EFFECT_TITAN_GRIP)
                effect.Effect = 0;
    if (id == 706807 || id == 705379 || id == 524694 || id == 804891 || id == 801778)
        if (info->Effects[EFFECT_0].ApplyAuraName == 354)
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
    if (id == 706808 || id == 705380 || id == 524091 || id == 575831)
    {
        info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
        info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
        info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
        info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
    }
    if (id == 705377)
        info->ProcFlags = 0;
    if (id == 500673)
        info->Stances = 0;
    if (id == 524610 && info->Effects[EFFECT_1].TriggerSpell == 524609)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == 524608)
    {
        info->Effects[EFFECT_0].DieSides = 1;
        info->Effects[EFFECT_1].Effect = 0;
        info->Effects[EFFECT_2].Effect = 0;
    }
    if (id == 707662)
        info->Effects[EFFECT_0].SpellClassMask = flag96(4, 0, 0);
    if (id == 807794)
        info->Effects[EFFECT_0].SpellClassMask = flag96(0, 4194320, 0);
    if (id == 525043)
        for (uint8 i = 0; i < 2; ++i)
            info->Effects[i].BasePoints = 19;
    if (id == 525043 || id == 524981)
        for (auto& effect : info->Effects)
            if (effect.Effect == SPELL_EFFECT_PERSISTENT_AREA_AURA)
            {
                effect.Effect = SPELL_EFFECT_APPLY_AREA_AURA_RAID;
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
                effect.TargetB = SpellImplicitTargetInfo();
            }
    if (id == 705352)
        info->ExcludeCasterAuraSpell = 0;
    if (id == 503634)
    {
        info->ExcludeTargetAuraSpell = 573255;
        info->Effects[EFFECT_1].Effect = 0;
    }
    if (id == 803721)
        info->Effects[EFFECT_1].BasePoints = 1;
    if (id == 803524)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == 504145 && !info->ProcFlags)
        info->ProcCharges = 1;
    if (id == 802874)
    {
        info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
        for (auto& effect : info->Effects)
            if (effect.Effect)
            {
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_DEST_AREA_ENEMY);
                effect.TargetB = SpellImplicitTargetInfo();
            }
    }
    if (id == 570759)
        for (auto& effect : info->Effects)
            effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
}

void AddAscensionGuardianCompletionScripts()
{
    Ascension::ClientSpellPatches::Instance().Register(500673);
    new guardian_scaling();
    RegisterSpellScript(aura_ascension_guardian_lifecycle);
}
