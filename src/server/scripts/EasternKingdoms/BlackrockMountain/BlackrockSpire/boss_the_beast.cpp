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

#include "AreaTriggerScript.h"
#include "CreatureScript.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "blackrock_spire.h"

enum Spells
{
    // Ascension's kit (db.exil.es/npc/10430), which records no timers
    SPELL_BELLOWING_ROAR            = 2100439,
    SPELL_BLAST_WAVE                = 2100205,
    SPELL_FLAME_BREATH              = 2102192,
    SPELL_IMMOLATE                  = 2100036,
    SPELL_OVERRUN                   = 2102159,
    SPELL_OVERRUN_TRAMPLE           = 2102160,
    SPELL_FIERCE_BLOW               = 975011,
    SPELL_SUICIDE                   = 8329
};

enum Events
{
    EVENT_BELLOWING_ROAR            = 1,
    EVENT_BLAST_WAVE                = 2,
    EVENT_FLAME_BREATH              = 3,
    EVENT_IMMOLATE                  = 4,
    EVENT_OVERRUN                   = 5,
    EVENT_FIERCE_BLOW               = 6,
    EVENT_OVERRUN_TRAMPLE           = 7,
    EVENT_OVERRUN_END               = 8
};

enum BeastMisc
{
    DATA_BEAST_REACHED              = 1,
    DATA_BEAST_ROOM                 = 2,
    BEAST_MOVEMENT_ID               = 1379690,
    POINT_OVERRUN                   = 1,

    NPC_BLACKHAND_ELITE             = 10317,

    SAY_BLACKHAND_DOOMED            = 0
};

Position const OrcsRunawayPosition = { 34.163567f, -536.852356f, 110.935196f, 6.056306f };

class OrcMoveEvent : public BasicEvent
{
public:
    OrcMoveEvent(Creature* me) : _me(me) {}

    bool Execute(uint64 /*time*/, uint32 /*diff*/) override
    {
        _me->SetReactState(REACT_PASSIVE);
        Position movePos = _me->GetRandomPoint(OrcsRunawayPosition, 10.0f);
        _me->GetMotionMaster()->MovePoint(1, movePos);
        return true;
    }

private:
    Creature* _me;
};

class OrcDeathEvent : public BasicEvent
{
public:
    OrcDeathEvent(Creature* me) : _me(me) { }

    bool Execute(uint64 /*time*/, uint32 /*diff*/) override
    {
        _me->CastSpell(_me, SPELL_SUICIDE, true);
        return true;
    }

private:
    Creature* _me;
};

// Used to make Hodir disengage whenever he leaves his room
constexpr static float FirewalPositionY = -505.f;
constexpr static float OverrunSpeed = 18.f;

struct boss_the_beast : public BossAI
{
    boss_the_beast(Creature* creature) : BossAI(creature, DATA_THE_BEAST), _beastReached(false), _orcYelled(false), _overrunning(false) {}

    void Reset() override
    {
        _Reset();
        _overrunning = false;
        _overrunEvents.Reset();

        if (_beastReached)
            me->GetMotionMaster()->MoveWaypoint(BEAST_MOVEMENT_ID, true);
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        _JustEngagedWith();
        events.ScheduleEvent(EVENT_IMMOLATE, 3s);
        events.ScheduleEvent(EVENT_FIERCE_BLOW, 9s, 11s);
        events.ScheduleEvent(EVENT_BLAST_WAVE, 10s);
        events.ScheduleEvent(EVENT_FLAME_BREATH, 1s, 3s);
        events.ScheduleEvent(EVENT_OVERRUN, 29s, 31s);
        events.ScheduleEvent(EVENT_BELLOWING_ROAR, 23s);
    }

    void OnSpellFailed(SpellInfo const* spell) override
    {
        BossAI::OnSpellFailed(spell);
        if (spell->Id == SPELL_FIERCE_BLOW)
            events.RescheduleEvent(EVENT_FIERCE_BLOW, 1s);
    }

    void OnSpellCast(SpellInfo const* spell) override
    {
        if (spell->Id != SPELL_OVERRUN)
            return;

        Unit* target = ObjectAccessor::GetUnit(*me, _overrunTargetGUID);
        if (!target)
            return;

        _overrunning = true;
        float destinationY = std::min(target->GetPositionY(), FirewalPositionY - 2.f);
        me->GetMotionMaster()->MoveCharge(target->GetPositionX(), destinationY, target->GetPositionZ(), OverrunSpeed,
            POINT_OVERRUN, nullptr, true);
        _overrunEvents.ScheduleEvent(EVENT_OVERRUN_TRAMPLE, 0ms);
        _overrunEvents.ScheduleEvent(EVENT_OVERRUN_END, 3s);
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type == POINT_MOTION_TYPE && id == POINT_OVERRUN)
            EndOverrun();
    }

    void Trample()
    {
        me->CastSpell(me->GetPositionX(), me->GetPositionY(), me->GetPositionZ(), SPELL_OVERRUN_TRAMPLE, true);
    }

    void EndOverrun()
    {
        if (!_overrunning)
            return;

        _overrunning = false;
        _overrunEvents.Reset();
        Trample();
    }

    void UpdateOverrun(uint32 diff)
    {
        _overrunEvents.Update(diff);

        while (uint32 eventId = _overrunEvents.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_OVERRUN_TRAMPLE:
                    Trample();
                    _overrunEvents.ScheduleEvent(EVENT_OVERRUN_TRAMPLE, 300ms);
                    break;
                case EVENT_OVERRUN_END:
                    EndOverrun();
                    return;
            }
        }
    }

    void SetData(uint32 type, uint32 /*data*/) override
    {
        switch (type)
        {
            case DATA_BEAST_ROOM:
            {
                if (!_orcYelled)
                {
                    if (_nearbyOrcsGUIDs.empty())
                        FindNearbyOrcs();

                    //! vector still empty, creatures are missing
                    if (_nearbyOrcsGUIDs.empty())
                        return;

                    _orcYelled = true;

                    bool yelled = false;
                    for (ObjectGuid guid : _nearbyOrcsGUIDs)
                    {
                        if (Creature* orc = ObjectAccessor::GetCreature(*me, guid))
                        {
                            if (!yelled)
                            {
                                yelled = true;
                                orc->AI()->Talk(SAY_BLACKHAND_DOOMED);
                            }

                            orc->m_Events.AddEventAtOffset(new OrcMoveEvent(orc), 3s);
                            orc->m_Events.AddEventAtOffset(new OrcDeathEvent(orc), 9s);
                        }
                    }
                }
                break;
            }
            case DATA_BEAST_REACHED:
            {
                if (!_beastReached)
                {
                    _beastReached = true;
                    me->GetMotionMaster()->MoveWaypoint(BEAST_MOVEMENT_ID, true);

                    // There is a chance player logged in between areatriggers (realm crash or restart)
                    // executing part of script which happens when player enters boss room
                    // otherwise we will see weird behaviour when someone steps on the previous areatrigger (dead mob yelling/moving)
                    SetData(DATA_BEAST_ROOM, DATA_BEAST_ROOM);
                }
                break;
            }
        }
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        if (me->GetPositionY() > FirewalPositionY)
        {
            EnterEvadeMode();
            return;
        }

        if (_overrunning)
        {
            UpdateOverrun(diff);
            return;
        }

        events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_BELLOWING_ROAR:
                    DoCastAOE(SPELL_BELLOWING_ROAR);
                    events.ScheduleEvent(EVENT_BELLOWING_ROAR, 20s);
                    break;
                case EVENT_BLAST_WAVE:
                    me->CastSpell(me, SPELL_BLAST_WAVE, TRIGGERED_IGNORE_POWER_AND_REAGENT_COST);
                    events.ScheduleEvent(EVENT_BLAST_WAVE, 12s, 16s);
                    break;
                case EVENT_FLAME_BREATH:
                    if (Unit* victim = me->GetVictim())
                        me->CastSpell(victim, SPELL_FLAME_BREATH, TRIGGERED_IGNORE_POWER_AND_REAGENT_COST);
                    events.ScheduleEvent(EVENT_FLAME_BREATH, 20s, 22s);
                    break;
                case EVENT_IMMOLATE:
                    if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 40.f, true))
                        me->CastSpell(target, SPELL_IMMOLATE, TRIGGERED_IGNORE_POWER_AND_REAGENT_COST);
                    events.ScheduleEvent(EVENT_IMMOLATE, 8s);
                    break;
                case EVENT_OVERRUN:
                {
                    Unit* target = SelectTarget(SelectTargetMethod::Random, 1, 40.f, true);
                    if (!target)
                        target = me->GetVictim();
                    if (target)
                    {
                        _overrunTargetGUID = target->GetGUID();
                        DoCast(target, SPELL_OVERRUN);
                    }
                    events.ScheduleEvent(EVENT_OVERRUN, 35s, 37s);
                    break;
                }
                case EVENT_FIERCE_BLOW:
                    DoCastVictim(SPELL_FIERCE_BLOW);
                    events.ScheduleEvent(EVENT_FIERCE_BLOW, 9s, 10s);
                    break;
            }

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;
        }

        DoMeleeAttackIfReady();
    }

    void FindNearbyOrcs()
    {
        std::list<Creature*> temp;
        me->GetCreatureListWithEntryInGrid(temp, NPC_BLACKHAND_ELITE, 50.0f);
        for (Creature* creature : temp)
            if (creature->IsAlive())
                _nearbyOrcsGUIDs.push_back(creature->GetGUID());
    }

private:
    bool _beastReached;
    bool _orcYelled;
    bool _overrunning;
    ObjectGuid _overrunTargetGUID;
    EventMap _overrunEvents;
    GuidVector _nearbyOrcsGUIDs;
};

//! The beast room areatrigger, this one triggers boss pathing. (AT Id 2066)
class at_trigger_the_beast_movement : public AreaTriggerScript
{
public:
    at_trigger_the_beast_movement() : AreaTriggerScript("at_trigger_the_beast_movement") { }

    bool OnTrigger(Player* player, AreaTrigger const* /*at*/) override
    {
        if (InstanceScript* instance = player->GetInstanceScript())
        {
            if (Creature* beast = ObjectAccessor::GetCreature(*player, instance->GetGuidData(DATA_THE_BEAST)))
                beast->AI()->SetData(DATA_BEAST_REACHED, DATA_BEAST_REACHED);

            return true;
        }

        return false;
    }
};

class at_the_beast_room : public AreaTriggerScript
{
public:
    at_the_beast_room() : AreaTriggerScript("at_the_beast_room") { }

    bool OnTrigger(Player* player, AreaTrigger const* /*at*/) override
    {
        if (InstanceScript* instance = player->GetInstanceScript())
        {
            if (Creature* beast = ObjectAccessor::GetCreature(*player, instance->GetGuidData(DATA_THE_BEAST)))
                beast->AI()->SetData(DATA_BEAST_ROOM, DATA_BEAST_ROOM);

            return true;
        }

        return false;
    }
};

void AddSC_boss_thebeast()
{
    RegisterBlackrockSpireCreatureAI(boss_the_beast);
    new at_trigger_the_beast_movement();
    new at_the_beast_room();
}
