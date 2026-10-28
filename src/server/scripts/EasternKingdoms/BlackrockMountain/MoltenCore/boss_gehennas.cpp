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

#include "CreatureScript.h"
#include "ScriptedCreature.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "TemporarySummon.h"
#include "molten_core.h"

#include <algorithm>

enum Spells
{
    SPELL_GEHENNAS_CURSE        = 19716,
    SPELL_RAIN_OF_FIRE          = 19717,
    SPELL_SHADOW_BOLT_RANDOM    = 19728,
    SPELL_SHADOW_BOLT_VICTIM    = 19729,
};

// CoA addition: Conjure Flame Orb (2105417, coa_boss_schedule idx 5) has a dummy effect
// (EFFECT_0) and a trigger-spell effect (EFFECT_1) that only fires 2180023 "Cosmetic - Camera
// Shake Big" -- a client-side visual with no summon, so the cast otherwise does nothing. The
// orb itself (2105418, periodic trigger every 275ms per Spell.dbc amplitude, infinite
// SpellDuration.dbc index 21) is a creature that has to be summoned by script. Lifetime 11000ms
// is measured from coa-log-history (12 orb instances across fights 307/1617/1741: first-to-last
// tick spans 10.1-11.0s, i.e. 37-40 ticks of 275ms -- 40 ticks = 11000ms).
constexpr uint32 SPELL_CONJURE_FLAME_ORB   = 2105417;
constexpr uint32 SPELL_FLAME_ORB_PULSE     = 2105418;
constexpr uint32 NPC_COA_GEHENNAS_FLAME_ORB = 80644;
constexpr uint32 FLAME_ORB_LIFETIME_MS     = 11000;

// CoA addition: the orb spawns on Gehennas and walks a straight line to the spot its target
// occupied when the cast completed (MovePoint, not MoveFollow/chase, so it never retargets a
// moving player), arriving as its lifetime ends -- no position evidence exists in the combat
// logs, so speed = distance / lifetime is the best-supported value, floored so a short hop
// still visibly moves.
constexpr float FLAME_ORB_MIN_SPEED = 1.0f;

enum Events
{
    EVENT_GEHENNAS_CURSE    = 1,
    EVENT_RAIN_OF_FIRE,
    EVENT_SHADOW_BOLT,
};

struct boss_gehennas : public BossAI
{
    boss_gehennas(Creature* creature) : BossAI(creature, DATA_GEHENNAS) {}

    void JustEngagedWith(Unit* /*attacker*/) override
    {
        _JustEngagedWith();
        events.ScheduleEvent(EVENT_GEHENNAS_CURSE, 6s, 9s);
        events.ScheduleEvent(EVENT_RAIN_OF_FIRE, 10s);
        events.ScheduleEvent(EVENT_SHADOW_BOLT, 3s, 5s);
    }

    void ExecuteEvent(uint32 eventId) override
    {
        switch (eventId)
        {
            case EVENT_GEHENNAS_CURSE:
            {
                DoCastVictim(SPELL_GEHENNAS_CURSE);
                events.Repeat(25s, 30s);
                break;
            }
            case EVENT_RAIN_OF_FIRE:
            {
                if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 0.0f, true))
                    DoCast(target, SPELL_RAIN_OF_FIRE, true);
                events.Repeat(6s);
                break;
            }
            case EVENT_SHADOW_BOLT:
            {
                if (urand(0, 1))
                {
                    if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 0.0f, true, false))
                        DoCast(target, SPELL_SHADOW_BOLT_RANDOM);
                    else
                        DoCastVictim(SPELL_SHADOW_BOLT_VICTIM);
                }
                else
                {
                    DoCastVictim(SPELL_SHADOW_BOLT_VICTIM);
                }

                events.Repeat(5s);
                break;
            }
        }
    }
};

// CoA addition: the summoned orb. It pulses area fire damage on its own (SPELL_FLAME_ORB_PULSE)
// for FLAME_ORB_LIFETIME_MS and is never meant to be attacked (creature_template unit_flags/
// flags_extra copied from the stock WotLK "Flame Orb" entry 30702, the same visual effect).
struct npc_coa_gehennas_flame_orb : public ScriptedAI
{
    npc_coa_gehennas_flame_orb(Creature* creature) : ScriptedAI(creature) {}

    void Reset() override
    {
        DoCastSelf(SPELL_FLAME_ORB_PULSE, true);
    }

    void UpdateAI(uint32 /*diff*/) override {}
};

// 2105417 Conjure Flame Orb: EFFECT_0 is a plain dummy, so the summon has to happen here.
class spell_gehennas_conjure_flame_orb : public SpellScript
{
    PrepareSpellScript(spell_gehennas_conjure_flame_orb);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_FLAME_ORB_PULSE });
    }

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;

        Position const destination = target->GetPosition();
        TempSummon* orb = caster->SummonCreature(NPC_COA_GEHENNAS_FLAME_ORB, caster->GetPosition(),
                                                  TEMPSUMMON_TIMED_DESPAWN, FLAME_ORB_LIFETIME_MS);
        if (!orb)
            return;

        float const distance = orb->GetDistance(destination);
        float const speed = std::max(FLAME_ORB_MIN_SPEED, distance / (FLAME_ORB_LIFETIME_MS / 1000.0f));
        orb->SetSpeed(MOVE_WALK, speed / baseMoveSpeed[MOVE_WALK], true);
        orb->GetMotionMaster()->MovePoint(0, destination, FORCED_MOVEMENT_NONE, speed);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_gehennas_conjure_flame_orb::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

void AddSC_boss_gehennas()
{
    RegisterMoltenCoreCreatureAI(boss_gehennas);
    RegisterCreatureAI(npc_coa_gehennas_flame_orb);

    // Spells
    RegisterSpellScript(spell_gehennas_conjure_flame_orb);
}
