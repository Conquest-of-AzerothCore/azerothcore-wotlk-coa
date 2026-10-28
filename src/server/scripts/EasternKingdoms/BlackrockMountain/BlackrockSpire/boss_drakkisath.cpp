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
#include "blackrock_spire.h"

enum Spells
{
    // Ascension's kit (db.exil.es/npc/10363), which records no timers
    SPELL_FLAMESTRIKE               = 2100015,
    SPELL_CLEAVE                    = 2102501,
    SPELL_CONFLAGRATION             = 2102208,
    SPELL_THUNDERCLAP               = 2102619,
    SPELL_PIERCE_ARMOR              = 2100345,
    SPELL_ENRAGE                    = 2102552,
    SPELL_HEATWAVE                  = 2102203,
    SPELL_HEATWAVE_PATCH            = 2102204,
    SPELL_FIERCE_BLOW               = 975011
};

enum Events
{
    EVENT_FLAMESTRIKE               = 1,
    EVENT_CLEAVE,
    EVENT_CONFLAGRATION,
    EVENT_THUNDERCLAP,
    EVENT_PIERCE_ARMOR,
    EVENT_HEATWAVE,
    EVENT_FIERCE_BLOW,
    EVENT_CHECK_CONFLAGRATION_TARGET,
    EVENT_HEATWAVE_PATCH
};

constexpr float HeatwaveFirstPatchDistance = 3.0f;
constexpr float HeatwavePatchSpacing = 2.0f;
constexpr uint8 HeatwavePatchCount = 14;

struct boss_drakkisath : public BossAI
{
    boss_drakkisath(Creature* creature) : BossAI(creature, DATA_GENERAL_DRAKKISATH)
    {
        _conflagrateThreat = 0.0f;
        _enraged = false;
        _heatwaveAngle = 0.0f;
        _heatwavePatch = 0;
    }

    void Reset() override
    {
        _Reset();
        _enraged = false;
        _heatwaveEvents.Reset();
    }

    void JustEngagedWith(Unit* /*who*/) override
    {
        _JustEngagedWith();
        events.ScheduleEvent(EVENT_PIERCE_ARMOR, 5s);
        events.ScheduleEvent(EVENT_FIERCE_BLOW, 8500ms, 10500ms);
        events.ScheduleEvent(EVENT_FLAMESTRIKE, 6s);
        events.ScheduleEvent(EVENT_CLEAVE, 8s);
        events.ScheduleEvent(EVENT_HEATWAVE, 22s, 24s);
        events.ScheduleEvent(EVENT_CONFLAGRATION, 15s);
        events.ScheduleEvent(EVENT_THUNDERCLAP, 14600ms, 16600ms);
    }

    void DamageTaken(Unit* /*attacker*/, uint32& damage, DamageEffectType /*type*/, SpellSchoolMask /*school*/) override
    {
        if (!_enraged && me->HealthBelowPctDamaged(30, damage))
        {
            _enraged = true;
            DoCastSelf(SPELL_ENRAGE, true);
        }
    }

    void OnSpellFailed(SpellInfo const* spell) override
    {
        BossAI::OnSpellFailed(spell);
        if (spell->Id == SPELL_FIERCE_BLOW)
            events.RescheduleEvent(EVENT_FIERCE_BLOW, 1s);
    }

    void OnSpellCast(SpellInfo const* spell) override
    {
        switch (spell->Id)
        {
            case SPELL_CONFLAGRATION:
                if (Unit* target = ObjectAccessor::GetUnit(*me, _conflagrateTarget))
                {
                    _conflagrateThreat = me->GetThreatMgr().GetThreat(target);
                    me->GetThreatMgr().ModifyThreatByPercent(target, -100);
                    events.ScheduleEvent(EVENT_CHECK_CONFLAGRATION_TARGET, 10s);
                }
                break;
            case SPELL_HEATWAVE:
                if (Unit* target = ObjectAccessor::GetUnit(*me, _heatwaveTarget))
                {
                    _heatwaveOrigin = me->GetPosition();
                    _heatwaveAngle = me->GetAngle(target);
                    _heatwavePatch = 0;
                    _heatwaveEvents.ScheduleEvent(EVENT_HEATWAVE_PATCH, 0ms);
                }
                break;
            default:
                break;
        }
    }

    void PlaceHeatwavePatch()
    {
        float distance = HeatwaveFirstPatchDistance + HeatwavePatchSpacing * _heatwavePatch;
        float x = _heatwaveOrigin.GetPositionX() + distance * std::cos(_heatwaveAngle);
        float y = _heatwaveOrigin.GetPositionY() + distance * std::sin(_heatwaveAngle);
        float z = _heatwaveOrigin.GetPositionZ();
        me->UpdateGroundPositionZ(x, y, z);
        me->CastSpell(x, y, z, SPELL_HEATWAVE_PATCH, true);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        _heatwaveEvents.Update(diff);
        while (_heatwaveEvents.ExecuteEvent() == EVENT_HEATWAVE_PATCH)
        {
            PlaceHeatwavePatch();
            if (++_heatwavePatch < HeatwavePatchCount)
                _heatwaveEvents.ScheduleEvent(EVENT_HEATWAVE_PATCH, 100ms);
        }

        events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_FLAMESTRIKE:
                    if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 40.0f, true))
                        me->CastSpell(target, SPELL_FLAMESTRIKE, TRIGGERED_IGNORE_POWER_AND_REAGENT_COST);
                    events.ScheduleEvent(EVENT_FLAMESTRIKE, 12s, 15s);
                    break;
                case EVENT_CLEAVE:
                    DoCastVictim(SPELL_CLEAVE);
                    events.ScheduleEvent(EVENT_CLEAVE, 8s);
                    break;
                case EVENT_CONFLAGRATION:
                    if (Unit* target = me->GetVictim())
                    {
                        _conflagrateTarget = target->GetGUID();
                        me->CastSpell(target, SPELL_CONFLAGRATION, TRIGGERED_IGNORE_POWER_AND_REAGENT_COST);
                    }
                    events.ScheduleEvent(EVENT_CONFLAGRATION, 18s, 25s);
                    break;
                case EVENT_THUNDERCLAP:
                    DoCastAOE(SPELL_THUNDERCLAP);
                    events.ScheduleEvent(EVENT_THUNDERCLAP, 15s, 17s);
                    break;
                case EVENT_PIERCE_ARMOR:
                    DoCastVictim(SPELL_PIERCE_ARMOR);
                    events.ScheduleEvent(EVENT_PIERCE_ARMOR, 6s);
                    break;
                case EVENT_HEATWAVE:
                    if (Unit* target = me->GetVictim())
                    {
                        _heatwaveTarget = target->GetGUID();
                        DoCast(target, SPELL_HEATWAVE);
                    }
                    events.ScheduleEvent(EVENT_HEATWAVE, 25s, 27s);
                    break;
                case EVENT_FIERCE_BLOW:
                    DoCastVictim(SPELL_FIERCE_BLOW);
                    events.ScheduleEvent(EVENT_FIERCE_BLOW, 9s, 10s);
                    break;
                case EVENT_CHECK_CONFLAGRATION_TARGET:
                    if (Unit* target = ObjectAccessor::GetUnit(*me, _conflagrateTarget))
                        me->GetThreatMgr().AddThreat(target, _conflagrateThreat);
                    break;
            }

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;
        }
        DoMeleeAttackIfReady();
    }

private:
    float _conflagrateThreat;
    ObjectGuid _conflagrateTarget;
    bool _enraged;
    ObjectGuid _heatwaveTarget;
    Position _heatwaveOrigin;
    float _heatwaveAngle;
    uint8 _heatwavePatch;
    EventMap _heatwaveEvents;
};

void AddSC_boss_drakkisath()
{
    RegisterBlackrockSpireCreatureAI(boss_drakkisath);
}
