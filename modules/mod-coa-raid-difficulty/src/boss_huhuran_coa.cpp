/*
 * Princess Huhuran as Ascension rebuilt her.
 *
 * Kit: Ascension's block 2116500-2116511 (the rest of the block belongs to the
 * Vekniss hive around her). No logs or video exist for Ahn'Qiraj; every timer
 * here is designed.
 *
 *   Pheromones      first 15s, every 30s   she sprays a random player for 10s;
 *                                          that player's attacks strike her
 *                                          Soft Spot: +750% damage from them
 *   Acidic Spew     first 5s,  every 10s   the tank, Nature damage and -20%
 *                                          armour, stacks to 5
 *   Poison Volley   first 12s, every 25s   everyone within 50 yards, a
 *                                          stacking poison
 *   Frenzy          first 20s, every 20s   10s: +50% damage and attack speed,
 *                                          for good below 30%
 *   Berserk         at 10 minutes (stock)
 *
 * Decided here, not in the data: every timer, 10s of pheromones on one player,
 * Frenzy's 10s, and leaving out Qiraji Flying (it would lift her off the floor).
 */

#include "CreatureScript.h"
#include "ScriptedCreature.h"
#include "../../../src/server/scripts/Kalimdor/TempleOfAhnQiraj/temple_of_ahnqiraj.h"
#include "zg_coa_common.h"

using namespace coa_zg;

namespace
{
    enum Spells
    {
        SPELL_BERSERK       = 26662,
        SPELL_PHEROMONES    = 2116500,
        SPELL_SOFT_SPOT     = 2116501,
        SPELL_ACIDIC_SPEW   = 2116503,
        SPELL_POISON_VOLLEY = 2116507,
        SPELL_FRENZY        = 2116511,
    };

    enum Events
    {
        EVENT_PHEROMONES = 1,
        EVENT_PHEROMONES_END,
        EVENT_SPEW,
        EVENT_VOLLEY,
        EVENT_FRENZY,
        EVENT_FRENZY_END,
        EVENT_BERSERK,
    };

    constexpr uint8 SPEW_STACKS = 5;

    struct boss_huhuran_coa : public BossAI
    {
        boss_huhuran_coa(Creature* creature) : BossAI(creature, DATA_HUHURAN) { }

        void Reset() override
        {
            BossAI::Reset();
            _lastStand = false;
            ClearPheromones();
            me->RemoveAurasDueToSpell(SPELL_FRENZY);
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            events.ScheduleEvent(EVENT_SPEW, 5s);
            events.ScheduleEvent(EVENT_VOLLEY, 12s);
            events.ScheduleEvent(EVENT_PHEROMONES, 15s);
            events.ScheduleEvent(EVENT_FRENZY, 20s);
            events.ScheduleEvent(EVENT_BERSERK, 10min);
        }

        void JustDied(Unit* killer) override
        {
            ClearPheromones();
            BossAI::JustDied(killer);
        }

        void ClearPheromones()
        {
            if (Unit* marked = ObjectAccessor::GetUnit(*me, _marked))
                marked->RemoveAurasDueToSpell(SPELL_PHEROMONES);
            _marked.Clear();
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            // The sprayed player finds her Soft Spot.
            if (attacker && damage && attacker->GetGUID() == _marked && attacker->HasAura(SPELL_PHEROMONES))
                damage += damage * uint32(Info(me, SPELL_SOFT_SPOT)) / 100;

            BossAI::DamageTaken(attacker, damage, type, school);

            if (!_lastStand && me->HealthBelowPctDamaged(30, damage))
            {
                _lastStand = true;
                events.CancelEvent(EVENT_FRENZY);
                events.CancelEvent(EVENT_FRENZY_END);
                DoCastSelf(SPELL_FRENZY, true);
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_PHEROMONES:
                        ClearPheromones();
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 60.0f, true))
                        {
                            me->AddAura(SPELL_PHEROMONES, target);
                            _marked = target->GetGUID();
                            events.ScheduleEvent(EVENT_PHEROMONES_END, 10s);
                        }
                        events.ScheduleEvent(EVENT_PHEROMONES, 30s);
                        break;
                    case EVENT_PHEROMONES_END:
                        ClearPheromones();
                        break;
                    case EVENT_SPEW:
                        if (Unit* tank = me->GetVictim())
                        {
                            Aura* spew = tank->GetAura(sSpellMgr->GetSpellIdForDifficulty(SPELL_ACIDIC_SPEW, me), me->GetGUID());
                            uint8 const stacks = spew ? spew->GetStackAmount() : 0;
                            DoCast(tank, SPELL_ACIDIC_SPEW, true);
                            if (Aura* after = tank->GetAura(sSpellMgr->GetSpellIdForDifficulty(SPELL_ACIDIC_SPEW, me), me->GetGUID()))
                                after->SetStackAmount(std::min<uint8>(stacks + 1, SPEW_STACKS));
                        }
                        events.ScheduleEvent(EVENT_SPEW, 10s);
                        break;
                    case EVENT_VOLLEY:
                        DoCastSelf(SPELL_POISON_VOLLEY, true);
                        events.ScheduleEvent(EVENT_VOLLEY, 25s);
                        break;
                    case EVENT_FRENZY:
                        DoCastSelf(SPELL_FRENZY, true);
                        events.ScheduleEvent(EVENT_FRENZY_END, 10s);
                        events.ScheduleEvent(EVENT_FRENZY, 20s);
                        break;
                    case EVENT_FRENZY_END:
                        if (!_lastStand)
                            me->RemoveAurasDueToSpell(SPELL_FRENZY);
                        break;
                    case EVENT_BERSERK:
                        DoCastSelf(SPELL_BERSERK, true);
                        break;
                    default:
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    private:
        bool _lastStand = false;
        ObjectGuid _marked;
    };
}

void AddCoaHuhuranScripts()
{
    RegisterTempleOfAhnQirajCreatureAI(boss_huhuran_coa);
}
