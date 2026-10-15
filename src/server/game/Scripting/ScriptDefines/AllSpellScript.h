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

#ifndef SCRIPT_OBJECT_ALL_SPELL_SCRIPT_H_
#define SCRIPT_OBJECT_ALL_SPELL_SCRIPT_H_

#include "ScriptObject.h"
#include <vector>

enum AllSpellHook
{
    ALLSPELLHOOK_ON_CALC_MAX_DURATION,
    ALLSPELLHOOK_ON_SPELL_CHECK_CAST,
    ALLSPELLHOOK_ON_SPELL_FOCUS_ANSWERED,
    ALLSPELLHOOK_CAN_PREPARE,
    ALLSPELLHOOK_CAN_SCALING_EVERYTHING,
    ALLSPELLHOOK_CAN_SELECT_SPEC_TALENT,
    ALLSPELLHOOK_ON_SCALE_AURA_UNIT_ADD,
    ALLSPELLHOOK_ON_REMOVE_AURA_SCALE_TARGETS,
    ALLSPELLHOOK_ON_BEFORE_AURA_RANK_FOR_LEVEL,
    ALLSPELLHOOK_ON_DUMMY_EFFECT_GAMEOBJECT,
    ALLSPELLHOOK_ON_DUMMY_EFFECT_CREATURE,
    ALLSPELLHOOK_ON_DUMMY_EFFECT_ITEM,
    ALLSPELLHOOK_ON_CAST_CANCEL,
    ALLSPELLHOOK_ON_CAST,
    ALLSPELLHOOK_ON_PREPARE,
    ALLSPELLHOOK_ON_BEFORE_EFFECTS,
    ALLSPELLHOOK_ON_CALCULATED_TARGET,
    ALLSPELLHOOK_ON_HIT_RESULT,
    ALLSPELLHOOK_ON_SUCCESSFUL_INTERRUPT,
    ALLSPELLHOOK_ON_SUCCESSFUL_STEAL,
    ALLSPELLHOOK_ON_CRIT_CHANCE,
    ALLSPELLHOOK_ON_INTERRUPT_DURATION,
    ALLSPELLHOOK_ON_SUCCESSFUL_DISPEL,
    ALLSPELLHOOK_END
};

enum SpellCastResult : uint8;
enum SpellEffIndex : uint8;

class AllSpellScript : public ScriptObject
{
protected:
    AllSpellScript(char const* name, std::vector<uint16> enabledHooks = std::vector<uint16>());

public:
    [[nodiscard]] bool IsDatabaseBound() const override { return false; }

    // Calculate max duration in applying aura
    virtual void OnCalcMaxDuration(Aura const* /*aura*/, int32& /*maxDuration*/) { }

    virtual void OnSpellCheckCast(Spell* /*spell*/, bool /*strict*/, SpellCastResult& /*res*/) { }

    // Called before the core searches for the focus object that a spell's own
    // RequiresSpellFocus names, and only for spells that carry one. Returning
    // true means a script answers that requirement itself: the search is
    // skipped, no object is needed, and the spell keeps its focus field for the
    // refusal the server sends when the answer is no.
    [[nodiscard]] virtual bool OnSpellFocusAnswered(Spell* /*spell*/) { return false; }

    [[nodiscard]] virtual bool CanPrepare(Spell* /*spell*/, SpellCastTargets const* /*targets*/, AuraEffect const* /*triggeredByAura*/) { return true; }

    [[nodiscard]] virtual bool CanScalingEverything(Spell* /*spell*/) { return false; }

    [[nodiscard]] virtual bool CanSelectSpecTalent(Spell* /*spell*/) { return true; }

    virtual void OnScaleAuraUnitAdd(Spell* /*spell*/, Unit* /*target*/, uint32 /*effectMask*/, bool /*checkIfValid*/, bool /*implicit*/, uint8 /*auraScaleMask*/, TargetInfo& /*targetInfo*/) { }

    virtual void OnRemoveAuraScaleTargets(Spell* /*spell*/, TargetInfo& /*targetInfo*/, uint8 /*auraScaleMask*/, bool& /*needErase*/) { }

    virtual void OnBeforeAuraRankForLevel(SpellInfo const* /*spellInfo*/, SpellInfo const* /*latestSpellInfo*/, uint8 /*level*/) { }

    /**
     * @brief This hook called after spell dummy effect
     *
     * @param caster Contains information about the WorldObject
     * @param spellID Contains information about the spell id
     * @param effIndex Contains information about the SpellEffIndex
     * @param gameObjTarget Contains information about the GameObject
     */
    virtual void OnDummyEffect(WorldObject* /*caster*/, uint32 /*spellID*/, SpellEffIndex /*effIndex*/, GameObject* /*gameObjTarget*/) { }

    /**
     * @brief This hook called after spell dummy effect
     *
     * @param caster Contains information about the WorldObject
     * @param spellID Contains information about the spell id
     * @param effIndex Contains information about the SpellEffIndex
     * @param creatureTarget Contains information about the Creature
     */
    virtual void OnDummyEffect(WorldObject* /*caster*/, uint32 /*spellID*/, SpellEffIndex /*effIndex*/, Creature* /*creatureTarget*/) { }

    /**
     * @brief This hook called after spell dummy effect
     *
     * @param caster Contains information about the WorldObject
     * @param spellID Contains information about the spell id
     * @param effIndex Contains information about the SpellEffIndex
     * @param itemTarget Contains information about the Item
     */
    virtual void OnDummyEffect(WorldObject* /*caster*/, uint32 /*spellID*/, SpellEffIndex /*effIndex*/, Item* /*itemTarget*/) { }

    virtual void OnSpellCastCancel(Spell* /*spell*/, Unit* /*caster*/, SpellInfo const* /*spellInfo*/, bool /*bySelf*/) { }

    virtual void OnSpellCast(Spell* /*spell*/, Unit* /*caster*/, SpellInfo const* /*spellInfo*/, bool /*skipCheck*/) { }

    virtual void OnSpellPrepare(Spell* /*spell*/, Unit* /*caster*/, SpellInfo const* /*spellInfo*/) { }

    // Called after cast validation and target selection, immediately before
    // launch effects are calculated.
    virtual void OnSpellBeforeEffects(Spell* /*spell*/, Unit* /*caster*/, SpellInfo const* /*spellInfo*/) { }

    // Called after one unit target's launch damage/healing and critical result
    // have been calculated, but before those values are applied.
    virtual void OnSpellCalculatedTarget(Spell* /*spell*/, Unit* /*target*/, TargetInfo& /*targetInfo*/) { }

    // Called after one unit target has finished hit processing. missInfo is a
    // SpellMissInfo value; damage and healing are the final applied amounts.
    virtual void OnSpellHitResult(Spell* /*spell*/, Unit* /*target*/, uint8 /*missInfo*/,
        uint32 /*damage*/, uint32 /*healing*/, bool /*critical*/) { }

    // Called once per target after at least one interruptible cast was
    // actually interrupted. A landed interrupt on an idle target is not enough.
    virtual void OnSpellSuccessfulInterrupt(Spell* /*spell*/, Unit* /*target*/) { }

    virtual void OnSpellInterruptDuration(Spell* /*spell*/, Unit* /*target*/, int32& /*duration*/) { }

    // A completed native beneficial-aura steal, after its success list was applied.
    virtual void OnSpellSuccessfulSteal(Spell* /*spell*/, Unit* /*target*/, uint32 /*count*/) { }

    // One native dispel effect completed, after its successful removals were applied.
    virtual void OnSpellSuccessfulDispel(Spell* /*spell*/, Unit* /*target*/, SpellEffIndex /*effect*/,
        uint32 /*count*/) { }

    // After caster critical chance, before target resistance and the single native roll.
    virtual void OnSpellCritChance(Spell* /*spell*/, Unit* /*target*/, float& /*chance*/) { }
};

// Compatibility for old scripts
using SpellSC = AllSpellScript;

#endif
