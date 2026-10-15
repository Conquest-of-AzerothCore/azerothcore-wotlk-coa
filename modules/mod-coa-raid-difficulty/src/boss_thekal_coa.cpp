/*
 * High Priest Thekal with Ascension's spells.
 *
 * Kit: Ascension's block 2118200-2118243. Timings: a Bronzebeard kill on video,
 * see raid-difficulty-werkzeug/zg-video-zeitplan.json.
 *
 * From stock: the fight with Zealot Lor'Khan and Zealot Zath, his false death,
 * the zealots rising again unless all three fall within 10 seconds, and the
 * tiger phase at full health after. The zealots keep their stock scripts.
 *
 *   Troll form
 *     Mortal Cleave    first 4s,  every 13s   cone in front, -25% healing taken
 *     Disrupting Shout first 9s,  every 20s   20 yards, interrupts
 *     Bloodlust        first 16s, every 30s   himself or a zealot
 *
 *   Tiger form (his Aspect of Shirvallah)
 *     Rending Swipe    first 4s,  every 14s   cone in front, bleeds (Rip)
 *     War Stomp        first 12s, every 40s   50 yards, knocks back
 *     Speed Slash      first 14s, every 40s   runs through the raid for 8s,
 *                                             cutting everyone he passes
 *     Shredding Claws  passive, armour down on hit
 *     Summon Tigers, frenzy every 30s and enrage at 20% from stock
 *
 * Decided here, not in the data:
 *   - which spells belong to which form. The video shows all of them in one
 *     stretch below 75%; the split follows the spell names (troll priest,
 *     tiger claws);
 *   - Speed Slash ends after 8 seconds (its aura never runs out by itself);
 *   - Force Punch and the stock charge are gone, the tiger kit replaces them.
 */

#include "CreatureScript.h"
#include "InstanceScript.h"
#include "ScriptedCreature.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"

using namespace coa_zg;

namespace
{
    enum Says
    {
        SAY_AGGRO  = 0,
        SAY_DEATH  = 1,
        EMOTE_DIES = 2
    };

    enum Spells
    {
        SPELL_SUMMONTIGERS               = 24183,
        SPELL_FRENZY                     = 8269,
        SPELL_RESURRECTION_IMPACT_VISUAL = 24171,

        SPELL_MORTAL_CLEAVE        = 2118201,
        SPELL_MORTAL_CLEAVE_HIT    = 2118202,
        SPELL_MORTAL_WOUND         = 2118203,
        SPELL_BLOODLUST            = 2118204,
        SPELL_DISRUPTING_SHOUT     = 2118205,
        SPELL_DISRUPTING_SHOUT_HIT = 2118206,
        SPELL_ASPECT_OF_SHIRVALLAH = 2118223,
        SPELL_SHREDDING_CLAWS      = 2118225,
        SPELL_WAR_STOMP            = 2118227,
        SPELL_WAR_STOMP_HIT        = 2118228,
        SPELL_SPEED_SLASH          = 2118232,
        SPELL_RENDING_SWIPE        = 2118238,
        SPELL_RENDING_SWIPE_HIT    = 2118239,
        SPELL_RIP                  = 2118240,
    };

    enum Actions
    {
        ACTION_RESSURRECT = 1
    };

    constexpr uint32 GROUP_TROLL = 1;

    constexpr float CLEAVE_RANGE = 10.0f;
    constexpr float CLEAVE_ARC   = float(M_PI) / 2;

    struct boss_thekal_coa : public BossAI
    {
        boss_thekal_coa(Creature* creature) : BossAI(creature, DATA_THEKAL) { }

        void Initialize()
        {
            _wasDead = false;
            _lorkhanDied = false;
            _zathDied = false;
            _tiger = false;
        }

        void Reset() override
        {
            _Reset();
            Initialize();
            scheduler.CancelAll();
            me->SetStandState(UNIT_STAND_STATE_STAND);
            me->SetReactState(REACT_AGGRESSIVE);
            me->RemoveAurasDueToSpell(SPELL_FRENZY);
            me->RemoveAurasDueToSpell(SPELL_ASPECT_OF_SHIRVALLAH);
            me->RemoveAurasDueToSpell(SPELL_SHREDDING_CLAWS);
            me->RemoveAurasDueToSpell(SPELL_SPEED_SLASH);
            me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
            me->LoadEquipment(1, true);

            if (Creature* zealot = instance->GetCreature(DATA_LORKHAN))
                zealot->AI()->Reset();
            if (Creature* zealot = instance->GetCreature(DATA_ZATH))
                zealot->AI()->Reset();
        }

        void JustDied(Unit* /*killer*/) override
        {
            _JustDied();
            Talk(SAY_DEATH);
            if (Creature* zealot = instance->GetCreature(DATA_LORKHAN))
                zealot->Kill(zealot, zealot);
            if (Creature* zealot = instance->GetCreature(DATA_ZATH))
                zealot->Kill(zealot, zealot);
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            _JustEngagedWith();
            scheduler.CancelAll();
            ScheduleTroll();
        }

        void ScheduleTroll()
        {
            scheduler.Schedule(4s, GROUP_TROLL, [this](TaskContext context)
            {
                DoCastVictim(SPELL_MORTAL_CLEAVE);
                context.Repeat(13s);
            }).Schedule(9s, GROUP_TROLL, [this](TaskContext context)
            {
                DoCastSelf(SPELL_DISRUPTING_SHOUT);
                context.Repeat(20s);
            }).Schedule(16s, GROUP_TROLL, [this](TaskContext context)
            {
                Bloodlust();
                context.Repeat(30s);
            });
        }

        void ScheduleTiger()
        {
            scheduler.Schedule(4s, [this](TaskContext context)
            {
                DoCastVictim(SPELL_RENDING_SWIPE);
                context.Repeat(14s);
            }).Schedule(12s, [this](TaskContext context)
            {
                DoCastSelf(SPELL_WAR_STOMP);
                context.Repeat(40s);
            }).Schedule(14s, [this](TaskContext context)
            {
                DoCastSelf(SPELL_SPEED_SLASH);
                context.Schedule(10s, [this](TaskContext)
                {
                    me->RemoveAurasDueToSpell(SPELL_SPEED_SLASH);
                });
                context.Repeat(40s);
            }).Schedule(30s, [this](TaskContext context)
            {
                DoCastSelf(SPELL_FRENZY);
                context.Repeat();
            }).Schedule(25s, [this](TaskContext context)
            {
                DoCastVictim(SPELL_SUMMONTIGERS, true);
                context.Repeat(10s, 14s);
            });
            ScheduleHealthCheckEvent(20, [this]
            {
                DoCastSelf(SPELL_FRENZY);
            });
        }

        // Bloodlust goes on whoever of the three is lowest.
        void Bloodlust()
        {
            Unit* target = me;
            for (uint32 data : { DATA_LORKHAN, DATA_ZATH })
                if (Creature* zealot = instance->GetCreature(data))
                    if (zealot->IsAlive() && zealot->IsInCombat() && zealot->GetHealthPct() < target->GetHealthPct())
                        target = zealot;
            DoCast(target, SPELL_BLOODLUST);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            switch (spell->Id)
            {
                case SPELL_MORTAL_CLEAVE:
                    for (Player* p : PlayersInFront(me, CLEAVE_RANGE, CLEAVE_ARC))
                    {
                        me->CastSpell(p, SPELL_MORTAL_CLEAVE_HIT, true);
                        me->CastSpell(p, SPELL_MORTAL_WOUND, true);
                    }
                    break;
                case SPELL_RENDING_SWIPE:
                    for (Player* p : PlayersInFront(me, CLEAVE_RANGE, CLEAVE_ARC))
                    {
                        me->CastSpell(p, SPELL_RENDING_SWIPE_HIT, true);
                        me->CastSpell(p, SPELL_RIP, true);
                    }
                    break;
                case SPELL_DISRUPTING_SHOUT:
                    me->CastSpell(me, SPELL_DISRUPTING_SHOUT_HIT, true);
                    break;
                case SPELL_WAR_STOMP:
                    me->CastSpell(me, SPELL_WAR_STOMP_HIT, true);
                    break;
                default:
                    break;
            }
        }

        void SetData(uint32 /*type*/, uint32 data) override
        {
            UpdateZealotStatus(data, true);
            CheckPhaseTransition();

            scheduler.Schedule(10s, [this, data](TaskContext /*context*/)
            {
                if (!_lorkhanDied || !_zathDied || !_wasDead)
                    ReviveZealot(data);
            });
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            if (!_tiger && damage >= me->GetHealth())
            {
                damage = me->GetHealth() - 1;
                if (!_wasDead)
                {
                    me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
                    me->SetReactState(REACT_PASSIVE);
                    me->SetStandState(UNIT_STAND_STATE_DEAD);
                    me->AttackStop();
                    me->InterruptNonMeleeSpells(false);
                    scheduler.CancelGroup(GROUP_TROLL);
                    DoResetThreatList();
                    _wasDead = true;
                    CheckPhaseTransition();
                    Talk(EMOTE_DIES);
                }
            }
            BossAI::DamageTaken(attacker, damage, type, school);
        }

        void DoAction(int32 action) override
        {
            if (action == ACTION_RESSURRECT)
            {
                me->SetUInt32Value(UNIT_FIELD_BYTES_1, 0);
                me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
                me->RestoreFaction();
                me->SetReactState(REACT_AGGRESSIVE);
                me->SetFullHealth();
                _wasDead = false;
                ScheduleTroll();
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            scheduler.Update(diff, [this]
            {
                if (!_wasDead || _tiger)
                    DoMeleeAttackIfReady();
            });
        }

        void ReviveZealot(uint32 zealotData)
        {
            if (Creature* zealot = instance->GetCreature(zealotData))
            {
                zealot->Respawn(true);
                zealot->SetInCombatWithZone();
                UpdateZealotStatus(zealotData, false);
            }
        }

        void UpdateZealotStatus(uint32 data, bool dead)
        {
            if (data == DATA_LORKHAN)
                _lorkhanDied = dead;
            else if (data == DATA_ZATH)
                _zathDied = dead;
        }

        void CheckPhaseTransition()
        {
            if (_wasDead && _lorkhanDied && _zathDied)
            {
                scheduler.CancelAll();
                scheduler.Schedule(3s, [this](TaskContext /*context*/)
                {
                    me->SetStandState(UNIT_STAND_STATE_STAND);
                    DoCastSelf(SPELL_RESURRECTION_IMPACT_VISUAL, true);
                    scheduler.Schedule(50ms, [this](TaskContext /*context*/)
                    {
                        Talk(SAY_AGGRO);
                    });
                    scheduler.Schedule(6s, [this](TaskContext /*context*/)
                    {
                        _tiger = true;
                        DoCastSelf(SPELL_ASPECT_OF_SHIRVALLAH, true);
                        DoCastSelf(SPELL_SHREDDING_CLAWS, true);
                        me->LoadEquipment(0, true);
                        me->SetFullHealth();
                        me->SetReactState(REACT_AGGRESSIVE);
                        me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
                        ScheduleTiger();
                    });
                });
            }
            else
            {
                scheduler.Schedule(10s, [this](TaskContext /*context*/)
                {
                    if (!(_wasDead && _lorkhanDied && _zathDied))
                        DoAction(ACTION_RESSURRECT);
                });
            }
        }

    private:
        bool _lorkhanDied = false;
        bool _zathDied = false;
        bool _wasDead = false;
        bool _tiger = false;
    };
}

void AddCoaThekalScripts()
{
    RegisterZulGurubCreatureAI(boss_thekal_coa);
}
