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
#include "deadmines.h"

enum Spells
{
    SPELL_SMITE_STOMP       = 2102575,
    SPELL_FIERCE_BLOW       = 975011,
    SPELL_STUNNING_STRIKE   = 2102553,
    SPELL_SMITE_RUSH        = 2102576,
    SPELL_RETALIATION       = 2102577,
    SPELL_RUPTURE           = 2102580,

    EQUIP_SWORD             = 1,
    EQUIP_TWO_SWORDS        = 2,
    EQUIP_MACE              = 3,

    EVENT_CHECK_HEALTH1     = 1,
    EVENT_CHECK_HEALTH2     = 2,
    EVENT_SWAP_WEAPON1      = 4,
    EVENT_SWAP_WEAPON2      = 5,
    EVENT_RESTORE_COMBAT    = 6,
    EVENT_KNEEL             = 7,
    EVENT_FIERCE_BLOW       = 8,
    EVENT_STUNNING_STRIKE   = 9,
    EVENT_RUPTURE           = 10,
    EVENT_RETALIATION       = 11,
    EVENT_SWAP_SAY          = 12,
    EVENT_SWAP_MOVE         = 13,

    SAY_SWAP1               = 2,
    SAY_SWAP2               = 3
};

class boss_mr_smite : public CreatureScript
{
public:
    boss_mr_smite() : CreatureScript("boss_mr_smite") { }

    CreatureAI* GetAI(Creature* creature) const override
    {
        return GetDeadminesAI<boss_mr_smiteAI>(creature);
    }

    struct boss_mr_smiteAI : public ScriptedAI
    {
        boss_mr_smiteAI(Creature* creature) : ScriptedAI(creature)
        {
        }

        EventMap events;
        bool health67;
        bool health34;
        uint32 swapEquip;

        void StartWeaponSwap(uint32 equip)
        {
            swapEquip = equip;
            me->CastSpell(me, SPELL_SMITE_STOMP, false);
            events.DelayEvents(10s);
            me->GetMotionMaster()->Clear();
            me->SetUnitFlag(UNIT_FLAG_PACIFIED);
            me->SetReactState(REACT_PASSIVE);
            events.ScheduleEvent(EVENT_SWAP_SAY, 800ms);
            events.ScheduleEvent(EVENT_SWAP_MOVE, 2s);
        }

        void Reset() override
        {
            health67 = false;
            health34 = false;
            me->LoadEquipment(EQUIP_SWORD);
            me->SetCanDualWield(false);
            me->SetStandState(UNIT_STAND_STATE_STAND);
            me->RemoveUnitFlag(UNIT_FLAG_PACIFIED);
            me->SetReactState(REACT_AGGRESSIVE);
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            events.ScheduleEvent(EVENT_CHECK_HEALTH1, 500ms);
            events.ScheduleEvent(EVENT_CHECK_HEALTH2, 500ms);
            events.ScheduleEvent(EVENT_FIERCE_BLOW, 8400ms);
            events.ScheduleEvent(EVENT_STUNNING_STRIKE, 14s, 18s);
            events.ScheduleEvent(EVENT_RUPTURE, 12s, 15s);
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            events.Update(diff);
            switch (events.ExecuteEvent())
            {
                case EVENT_CHECK_HEALTH1:
                    if (me->HealthBelowPct(67) && !health67)
                    {
                        StartWeaponSwap(EQUIP_TWO_SWORDS);
                        events.ScheduleEvent(EVENT_RETALIATION, 13s, 18s);
                        health67 = true;
                        break;
                    }
                    events.ScheduleEvent(EVENT_CHECK_HEALTH1, 500ms);
                    break;
                case EVENT_CHECK_HEALTH2:
                    if (me->HealthBelowPct(34) && !health34)
                    {
                        StartWeaponSwap(EQUIP_MACE);
                        health34 = true;
                        break;
                    }
                    events.ScheduleEvent(EVENT_CHECK_HEALTH2, 500ms);
                    break;
                case EVENT_FIERCE_BLOW:
                    me->CastSpell(me->GetVictim(), SPELL_FIERCE_BLOW, false);
                    events.ScheduleEvent(EVENT_FIERCE_BLOW, 7800ms);
                    break;
                case EVENT_STUNNING_STRIKE:
                    me->CastSpell(me->GetVictim(), SPELL_STUNNING_STRIKE, false);
                    events.ScheduleEvent(EVENT_STUNNING_STRIKE, 20s, 26s);
                    break;
                case EVENT_RUPTURE:
                    me->CastSpell(me->GetVictim(), SPELL_RUPTURE, false);
                    events.ScheduleEvent(EVENT_RUPTURE, 18s, 24s);
                    break;
                case EVENT_RETALIATION:
                    me->CastSpell(me, SPELL_RETALIATION, false);
                    events.ScheduleEvent(EVENT_RETALIATION, 25s, 30s);
                    break;
                case EVENT_SWAP_SAY:
                    Talk(swapEquip == EQUIP_TWO_SWORDS ? SAY_SWAP1 : SAY_SWAP2);
                    break;
                case EVENT_SWAP_MOVE:
                    me->CastSpell(me, SPELL_SMITE_RUSH, true);
                    me->GetMotionMaster()->MovePoint(swapEquip, 1.859f, -780.72f, 9.831f);
                    break;
                case EVENT_SWAP_WEAPON1:
                    me->LoadEquipment(EQUIP_TWO_SWORDS);
                    me->SetCanDualWield(true);
                    break;
                case EVENT_SWAP_WEAPON2:
                    me->LoadEquipment(EQUIP_MACE);
                    me->SetCanDualWield(false);
                    break;
                case EVENT_RESTORE_COMBAT:
                    me->SetReactState(REACT_AGGRESSIVE);
                    me->RemoveUnitFlag(UNIT_FLAG_PACIFIED);
                    me->SetStandState(UNIT_STAND_STATE_STAND);
                    me->RemoveAurasDueToSpell(SPELL_SMITE_RUSH);
                    if (me->GetVictim())
                    {
                        me->GetMotionMaster()->MoveChase(me->GetVictim());
                        me->SetTarget(me->GetVictim()->GetGUID());
                    }
                    break;
                case EVENT_KNEEL:
                    me->SendMeleeAttackStop(me->GetVictim());
                    me->SetStandState(UNIT_STAND_STATE_KNEEL);
                    break;
            }

            DoMeleeAttackIfReady();
        }

        void MovementInform(uint32 type, uint32 point) override
        {
            if (type != POINT_MOTION_TYPE)
                return;

            me->SetTarget();
            me->SetFacingTo(5.558f);
            me->SetStandState(UNIT_STAND_STATE_KNEEL);
            events.ScheduleEvent(point == EQUIP_TWO_SWORDS ? EVENT_SWAP_WEAPON1 : EVENT_SWAP_WEAPON2, 1500ms);
            events.ScheduleEvent(EVENT_RESTORE_COMBAT, 3s);
            events.ScheduleEvent(EVENT_KNEEL, 0ms);
        }
    };
};

void AddSC_boss_mr_smite()
{
    new boss_mr_smite();
}
