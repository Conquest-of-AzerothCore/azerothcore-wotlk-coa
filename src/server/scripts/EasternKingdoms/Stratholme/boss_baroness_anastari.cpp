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
#include "InstanceScript.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "TaskScheduler.h"
#include "stratholme.h"

enum Spells
{
    SPELL_BANSHEEWAIL           = 16565,
    SPELL_BANSHEECURSE          = 16867,
    SPELL_SILENCE               = 18327,
    SPELL_POSSESS               = 17244,    // the charm on player
    SPELL_POSSESSED             = 17246,    // the damage debuff on player
    SPELL_POSSESS_INV           = 17250     // baroness becomes invisible while possessing a target
};

class boss_baroness_anastari : public CreatureScript
{
public:
    boss_baroness_anastari() : CreatureScript("boss_baroness_anastari") { }

    struct boss_baroness_anastariAI : public BossAI
    {
        boss_baroness_anastariAI(Creature* creature) : BossAI(creature, TYPE_ZIGGURAT1)
        {
        }

        void Reset() override
        {
            _possessedTargetGuid.Clear();

            instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_POSSESS);
            instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_POSSESSED);
            me->RemoveAurasDueToSpell(SPELL_POSSESS_INV);
            StopStandingAside();

            _scheduler.CancelAll();

            _scheduler.SetValidator([this]
            {
                return !me->HasUnitState(UNIT_STATE_CASTING);
            });
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            _scheduler.Schedule(1s, [this](TaskContext context){
                DoCastVictim(SPELL_BANSHEEWAIL);
                context.Repeat(4s);
            })
            .Schedule(11s, [this](TaskContext context){
                DoCastVictim(SPELL_BANSHEECURSE);
                context.Repeat(18s);
            })
            .Schedule(13s, [this](TaskContext context){
                DoCastVictim(SPELL_SILENCE);
                context.Repeat(13s);
            });

            SchedulePossession();
        }

        void JustDied(Unit* /*killer*/) override
        {
            instance->SetData(TYPE_ZIGGURAT1, IN_PROGRESS);
        }

        void SchedulePossession()
        {
            _scheduler.Schedule(20s, 30s, [this](TaskContext context){
                if (Unit* possessTarget = SelectTarget(SelectTargetMethod::Random, 1, 0, true, false))
                {
                    DoCast(possessTarget, SPELL_POSSESS, true);
                    DoCast(possessTarget, SPELL_POSSESSED, true);
                    StandAside();
                    _possessedTargetGuid = possessTarget->GetGUID();

                    // We must keep track of the possessed player, the aura falls off when their health drops below 50%.
                    // The encounter resumes when the aura falls off.
                    _scheduler.Schedule(1s, [this](TaskContext possessionContext) {
                        Player* possessedTarget = ObjectAccessor::GetPlayer(*me, _possessedTargetGuid);
                        if (!possessedTarget || !possessedTarget->IsAlive() || !possessedTarget->HasAura(SPELL_POSSESSED) || possessedTarget->HealthBelowPct(50))
                        {
                            if (possessedTarget)
                            {
                                possessedTarget->RemoveAurasDueToSpell(SPELL_POSSESS);
                                possessedTarget->RemoveAurasDueToSpell(SPELL_POSSESSED);
                            }
                            StopStandingAside();
                            _possessedTargetGuid.Clear();
                            SchedulePossession();
                        }
                        else
                        {
                            DrivePossessed(possessedTarget);
                            possessionContext.Repeat(1s);
                        }
                    });
                }
                else
                {
                    // No valid possession targets found, retry.
                    context.Repeat(1s);
                }
            });
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
            {
                return;
            }

            _scheduler.Update(diff,
                std::bind(&ScriptedAI::DoMeleeAttackIfReady, this));
        }

        // While she controls a player the Baroness steps out of the fight: she stays where she is,
        // cannot be attacked and does not attack (Ascension showed her as friendly). She used to turn
        // invisible and stunned (17250), and a charmed player sees through the eyes of the one who
        // charms them, so the possessed player lost sight of the group.
        void StandAside()
        {
            me->InterruptNonMeleeSpells(false);
            me->AttackStop();
            me->SetReactState(REACT_PASSIVE);
            me->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE);
        }

        void StopStandingAside()
        {
            me->RemoveUnitFlag(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE);
            me->SetReactState(REACT_AGGRESSIVE);
        }

        // The charm hands the player to the Baroness, but nothing in the core moves a player a
        // creature charms, so they only stood there. Turn them on the nearest of their own group.
        void DrivePossessed(Player* possessed)
        {
            if (!possessed->IsAlive() || possessed->HasUnitState(UNIT_STATE_CASTING))
                return;

            Unit* victim = possessed->GetVictim();
            if (victim && victim->IsAlive() && possessed->IsValidAttackTarget(victim))
                return;

            Player* nearest = nullptr;
            float nearestDist = 40.0f;
            for (auto const& ref : me->GetMap()->GetPlayers())
            {
                Player* player = ref.GetSource();
                if (!player || player == possessed || !player->IsAlive() || !possessed->IsValidAttackTarget(player))
                    continue;
                float const dist = possessed->GetDistance(player);
                if (dist < nearestDist)
                {
                    nearest = player;
                    nearestDist = dist;
                }
            }

            if (nearest)
            {
                possessed->Attack(nearest, true);
                possessed->GetMotionMaster()->MoveChase(nearest);
            }
        }

    private:
        ObjectGuid _possessedTargetGuid;
        TaskScheduler _scheduler;
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return GetStratholmeAI<boss_baroness_anastariAI>(creature);
    }
};

void AddSC_boss_baroness_anastari()
{
    new boss_baroness_anastari;
}
