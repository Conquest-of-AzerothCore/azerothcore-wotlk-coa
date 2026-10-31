/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef SCRIPT_OBJECT_UNIT_SCRIPT_H_
#define SCRIPT_OBJECT_UNIT_SCRIPT_H_

#include "ScriptObject.h"
#include <optional>
#include <vector>

enum UnitHook
{
    UNITHOOK_ON_HEAL,
    UNITHOOK_ON_DAMAGE,
    UNITHOOK_ON_BLOCK,
    UNITHOOK_ON_PERIODIC_DAMAGE_RESULT,
    UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK,
    UNITHOOK_MODIFY_MELEE_DAMAGE,
    UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
    UNITHOOK_MODIFY_HEAL_RECEIVED,
    UNITHOOK_ON_BEFORE_ROLL_MELEE_OUTCOME_AGAINST,
    UNITHOOK_ON_AURA_APPLY,
    UNITHOOK_ON_AURA_REMOVE,
    UNITHOOK_IF_NORMAL_REACTION,
    UNITHOOK_CAN_SET_PHASE_MASK,
    UNITHOOK_IS_CUSTOM_BUILD_VALUES_UPDATE,
    UNITHOOK_SHOULD_TRACK_VALUES_UPDATE_POS_BY_INDEX,
    UNITHOOK_ON_PATCH_VALUES_UPDATE,
    UNITHOOK_ON_UNIT_UPDATE,
    UNITHOOK_ON_DISPLAYID_CHANGE,
    UNITHOOK_ON_UNIT_ENTER_EVADE_MODE,
    UNITHOOK_ON_UNIT_ENTER_COMBAT,
    UNITHOOK_ON_UNIT_EXIT_COMBAT,
    UNITHOOK_ON_UNIT_DEATH,
    UNITHOOK_ON_UNIT_SET_SHAPESHIFT_FORM,
    UNITHOOK_ON_BEFORE_HEAL_ABSORB,
    UNITHOOK_ON_AFTER_AURA_EFFECT_CALCULATE_AMOUNT,
    UNITHOOK_ON_SEND_AURA_UPDATE,
    UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE,
    UNITHOOK_CAN_UNIT_ATTACK,
    UNITHOOK_SPELL_MAGNET_TARGET,
    UNITHOOK_RESOLVE_SPELL_CAST,
    UNITHOOK_ON_HEALTH_CHANGED,
    UNITHOOK_MODIFY_MELEE_DAMAGE_RANGE,
    UNITHOOK_END
};

enum ReputationRank : uint8;
class ByteBuffer;
class HealInfo;
class AuraEffect;
struct BuildValuesCachePosPointers;

class UnitScript : public ScriptObject
{
protected:
    UnitScript(char const* name, bool addToScripts = true, std::vector<uint16> enabledHooks = std::vector<uint16>());

public:
    // Resolve metadata before Spell construction, preserving targets, flags and forwarded values.
    virtual void ResolveSpellCast(Unit* /*caster*/, SpellInfo const*& /*spellInfo*/) { }

    // Called when a unit deals healing to another unit
    virtual void OnHeal(Unit* /*healer*/, Unit* /*reciever*/, uint32& /*gain*/) { }

    // Runs once for direct and periodic healing, before absorbs and overhealing.
    virtual void OnBeforeHealAbsorb(HealInfo& /*healInfo*/) { }

    // Runs after spell-specific calculations and before applying aura stacks.
    virtual void OnAfterAuraEffectCalculateAmount(AuraEffect const* /*effect*/, Unit* /*caster*/,
        int32& /*amount*/) { }

    // Called when a unit deals damage to another unit
    virtual void OnDamage(Unit* /*attacker*/, Unit* /*victim*/, uint32& /*damage*/) { }

    // Called after a unit blocks a melee or ranged attack
    virtual void OnBlock(Unit* /*victim*/, Unit* /*attacker*/) { }

    // Called after a harmful periodic tick resolves mitigation and damage.
    // Unlike ModifyPeriodicDamageAurasTick, this never observes healing.
    virtual void OnPeriodicDamageResult(Unit* /*target*/, Unit* /*attacker*/, uint32 /*damage*/, SpellInfo const* /*spellInfo*/) { }

    // Called when DoT's Tick Damage is being Dealt
    // Attacker can be nullptr if he is despawned while the aura still exists on target
    virtual void ModifyPeriodicDamageAurasTick(Unit* /*target*/, Unit* /*attacker*/, uint32& /*damage*/, SpellInfo const* /*spellInfo*/) { }

    // Called when Melee Damage is being Dealt
    virtual void ModifyMeleeDamage(Unit* /*target*/, Unit* /*attacker*/, uint32& /*damage*/) { }

    // Called with a melee swing's damage range before the roll
    virtual void ModifyMeleeDamageRange(Unit* /*target*/, Unit* /*attacker*/, float& /*minDamage*/, float& /*maxDamage*/) { }

    // Called when Spell Damage is being Dealt
    virtual void ModifySpellDamageTaken(Unit* /*target*/, Unit* /*attacker*/, int32& /*damage*/, SpellInfo const* /*spellInfo*/) { }

    // Adjust the rolled, level-adjusted base before combo-point and effect modifiers.
    // Implementations must scope their spells and preserve finite, representable values.
    virtual void ModifySpellEffectBaseValue(Unit const* /*caster*/, SpellInfo const* /*spellInfo*/,
        uint8 /*effectIndex*/, float& /*value*/) { }

    // Called when Heal is Recieved
    virtual void ModifyHealReceived(Unit* /*target*/, Unit* /*healer*/, uint32& /*heal*/, SpellInfo const* /*spellInfo*/) { }

    //Called when Damage is Dealt
    virtual uint32 DealDamage(Unit* /*AttackerUnit*/, Unit* /*pVictim*/, uint32 damage,
                              DamageEffectType /*damagetype*/,
                              std::optional<uint32>* /*scriptHealthLeechDamage*/) { return damage; }

    virtual void OnBeforeRollMeleeOutcomeAgainst(Unit const* /*attacker*/, Unit const* /*victim*/, WeaponAttackType /*attType*/, int32& /*attackerMaxSkillValueForLevel*/, int32& /*victimMaxSkillValueForLevel*/, int32& /*attackerWeaponSkill*/, int32& /*victimDefenseSkill*/, int32& /*crit_chance*/, int32& /*miss_chance*/, int32& /*dodge_chance*/, int32& /*parry_chance*/, int32& /*block_chance*/ ) {   };

    virtual void OnAuraApply(Unit* /*unit*/, Aura* /*aura*/) { }

    virtual void OnAuraRemove(Unit* /*unit*/, AuraApplication* /*aurApp*/, AuraRemoveMode /*mode*/) { }

    // World/map-thread notification before the stock aura packet. A null receiver
    // means the target's visible set; a null application means a full snapshot.
    virtual void OnSendAuraUpdate(Unit* /*target*/, Player* /*receiver*/,
        AuraApplication const* /*application*/, bool /*remove*/) { }

    [[nodiscard]] virtual bool IfNormalReaction(Unit const* /*unit*/, Unit const* /*target*/, ReputationRank& /*repRank*/) { return true; }
    [[nodiscard]] virtual bool CanUnitAttack(Unit const* /*attacker*/, Unit const* /*target*/,
        SpellInfo const* /*spell*/) { return true; }
    virtual Unit* SpellMagnetTarget(Unit* /*attacker*/, Unit* /*victim*/, SpellInfo const* /*spell*/) { return nullptr; }

    [[nodiscard]] virtual bool CanSetPhaseMask(Unit const* /*unit*/, uint32 /*newPhaseMask*/, bool /*update*/) { return true; }

    [[nodiscard]] virtual bool IsCustomBuildValuesUpdate(Unit const* /*unit*/, uint8 /*updateType*/, ByteBuffer& /*fieldBuffer*/, Player const* /*target*/, uint16 /*index*/) { return false; }

    [[nodiscard]] virtual bool ShouldTrackValuesUpdatePosByIndex(Unit const* /*unit*/, uint8 /*updateType*/, uint16 /*index*/) { return false; }

    virtual void OnPatchValuesUpdate(Unit const* /*unit*/, ByteBuffer& /*valuesUpdateBuf*/, BuildValuesCachePosPointers& /*posPointers*/, Player* /*target*/) { }

    /**
     * @brief This hook runs in Unit::Update
     *
     * @param unit Contains information about the Unit
     * @param diff Contains information about the diff time
     */
    virtual void OnUnitUpdate(Unit* /*unit*/, uint32 /*diff*/) { }

    virtual void OnDisplayIdChange(Unit* /*unit*/, uint32 /*displayId*/) { }

    virtual void OnUnitEnterEvadeMode(Unit* /*unit*/, uint8 /*evadeReason*/) { }
    virtual void OnUnitEnterCombat(Unit* /*unit*/, Unit* /*victim*/) { }
    virtual void OnUnitExitCombat(Unit* /*unit*/) { }
    virtual void OnUnitDeath(Unit* /*unit*/, Unit* /*killer*/) { }
    virtual void OnUnitSetShapeshiftForm(Unit* /*unit*/, uint8 /*form*/) { }
    virtual void OnHealthChanged(Unit* /*unit*/) { }
};

#endif
