/*
 * Battleguard Sartura as Ascension rebuilt her.
 *
 * Kit: Ascension's block 2116100-2116140. No logs or video exist for
 * Ahn'Qiraj; every timer here is designed.
 *
 * Her Royal Guards are Phantom Dancers now. Sartura leads three cycles, each
 * started by a 2.5s cast; after the three regular steps of a cycle the next
 * one is always its Death step.
 *
 *   Rhythm (her own melee)   Relentless Assault: twice as fast, half damage
 *                            Keen Eyed: cannot be avoided
 *                            Decimate: slow, 200% weapon damage
 *                            Death: fast and unavoidable
 *                            every cut shreds armour (-5%, up to 20 stacks)
 *   Dance (the dancers' blades)  Thousand Cuts: five times as fast, 20% each
 *                            Endless Reach: 50 yards, weaker further out
 *                            Force and Verve: 300% every 3s, knocks up
 *                            Death: 25 yards, fast, knocks up close by
 *   Song (how the dancers move)  Blades: circling her
 *                            Hunt: chasing players, slowly
 *                            Translocation: standing, then appearing next to
 *                            a player every 8s
 *                            Death: chasing fast and appearing next to their
 *                            prey every 5s
 *
 *   The casts come every 10s in turn: Rhythm, Dance, Song, Phantom (a new
 *   Phantom Dancer). All four can be interrupted. Every interruption frustrates
 *   her; the fourth sends her into Furious Outbreak: 30s of Rhythm, Dance and
 *   Song of Death at once.
 *
 *   Enrage at 20% and berserk at 10 minutes stay from stock.
 *
 * Decided here, not in the data: every timer, the order and spacing of the
 * four casts, the dancers' distances and teleport clocks, and Decimate hitting
 * only her target (the split to a second target is left out).
 */

#include "CreatureScript.h"
#include "InstanceScript.h"
#include "ScriptedCreature.h"
#include "../../../src/server/scripts/Kalimdor/TempleOfAhnQiraj/temple_of_ahnqiraj.h"
#include "zg_coa_common.h"

#include <list>

using namespace coa_zg;

namespace
{
    enum Says
    {
        SAY_AGGRO = 0,
        SAY_SLAY  = 1,
        SAY_DEATH = 2
    };

    enum Spells
    {
        SPELL_ENRAGE          = 8269,
        SPELL_BERSERK         = 27680,

        SPELL_BLADEDANCE      = 2116100,
        SPELL_DANCE_THOUSAND  = 2116102,
        SPELL_DANCE_ENDLESS   = 2116104,
        SPELL_DANCE_FORCE     = 2116106,
        SPELL_DANCE_DEATH     = 2116108,
        SPELL_RHYTHM          = 2116110,
        SPELL_RHYTHM_FIRST    = 2116111,   // + rhythm - 1: relentless, keen, decimate, death
        SPELL_SHRED_ARMOR     = 2116129,
        SPELL_SONG_FIRST      = 2116125,   // blades, hunt, translocation
        SPELL_SONG_DEATH      = 2116130,
        SPELL_TRANSLOCATION   = 2116128,
        SPELL_ROYAL_RHYTHM    = 2116131,
        SPELL_ROYAL_DANCE     = 2116132,
        SPELL_ROYAL_SONG      = 2116133,
        SPELL_ROYAL_PHANTOM   = 2116134,
        SPELL_FRUSTRATION     = 2116135,
        SPELL_FURIOUS         = 2116137,
    };

    // Cuts per rhythm: plain, fierce. Rhythm 0 is her opening one.
    uint32 const Cuts[5][2] =
    {
        { 2116115, 2116116 }, { 2116117, 2116118 }, { 2116119, 2116120 },
        { 2116121, 2116122 }, { 2116123, 2116124 }
    };
    Milliseconds const CutEvery[5] = { 2000ms, 1000ms, 2000ms, 3000ms, 1000ms };
    uint32 const Dances[5] = { SPELL_BLADEDANCE, SPELL_DANCE_THOUSAND, SPELL_DANCE_ENDLESS, SPELL_DANCE_FORCE, SPELL_DANCE_DEATH };

    enum Modes
    {
        DEATH_STEP = 4,
        SONG_BLADES = 0, SONG_HUNT = 1, SONG_TRANSLOCATION = 2, SONG_DEATH = 3,
        TYPE_DANCE = 1, TYPE_SONG = 2
    };

    enum Events
    {
        EVENT_CUT = 1,
        EVENT_ROYAL,
        EVENT_BERSERK,
        EVENT_OUTBREAK_END,
        // dancers
        EVENT_MOVE,
        EVENT_JUMP,
    };

    constexpr uint8 SHRED_STACKS  = 20;
    constexpr uint8 FRUSTRATION_MAX = 4;

    struct boss_sartura_coa : public BossAI
    {
        boss_sartura_coa(Creature* creature) : BossAI(creature, DATA_SARTURA) { }

        void InitializeAI() override
        {
            me->m_CombatDistance = 60.0f;
            me->m_SightDistance = 60.0f;
            BossAI::InitializeAI();
        }

        void Reset() override
        {
            BossAI::Reset();
            _enraged = false;
            _rhythm = 0; _dance = 0; _song = 0;
            _rhythmStep = 0; _danceStep = 0; _songStep = 0;
            _royal = 0; _cuts = 0;
            for (uint32 s : { SPELL_FRUSTRATION, SPELL_FURIOUS, SPELL_RHYTHM })
                me->RemoveAurasDueToSpell(s);
            for (uint8 i = 0; i < 4; ++i)
                me->RemoveAurasDueToSpell(SPELL_RHYTHM_FIRST + i);
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            Talk(SAY_AGGRO);
            me->AddAura(SPELL_RHYTHM, me);
            Broadcast();
            events.ScheduleEvent(EVENT_CUT, 2s);
            events.ScheduleEvent(EVENT_ROYAL, 10s);
            events.ScheduleEvent(EVENT_BERSERK, 10min);
        }

        void JustDied(Unit* killer) override
        {
            BossAI::JustDied(killer);
            Talk(SAY_DEATH);
        }

        void KilledUnit(Unit* /*victim*/) override
        {
            Talk(SAY_SLAY);
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);
            if (!_enraged && me->HealthBelowPctDamaged(20, damage))
            {
                _enraged = true;
                DoCastSelf(SPELL_ENRAGE, true);
            }
        }

        bool Furious() const { return me->HasAura(SPELL_FURIOUS); }
        uint8 Rhythm() const { return Furious() ? DEATH_STEP : _rhythm; }
        uint8 Dance() const { return Furious() ? DEATH_STEP : _dance; }
        uint8 Song() const { return Furious() ? SONG_DEATH : _song; }

        // Every dancer follows her current dance and song.
        void Broadcast()
        {
            std::list<Creature*> dancers;
            me->GetCreatureListWithEntryInGrid(dancers, NPC_SARTURA_ROYAL_GUARD, 150.0f);
            for (Creature* dancer : dancers)
                if (dancer->IsAlive() && dancer->AI())
                {
                    dancer->AI()->SetData(TYPE_DANCE, Dance());
                    dancer->AI()->SetData(TYPE_SONG, Song());
                    if (!dancer->IsInCombat())
                        dancer->SetInCombatWithZone();
                }
            for (uint8 i = 0; i < 4; ++i)
                me->RemoveAurasDueToSpell(SPELL_RHYTHM_FIRST + i);
            if (Rhythm())
                me->AddAura(SPELL_RHYTHM_FIRST + Rhythm() - 1, me);
        }

        // Three regular steps, then Death, then around again.
        static void Next(uint8& mode, uint8& step, uint8 regular, uint8 death, uint8 firstRegular)
        {
            if (step == regular)
            {
                mode = death;
                step = 0;
            }
            else
                mode = firstRegular + step++;
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);
            switch (spell->Id)
            {
                case SPELL_ROYAL_RHYTHM:
                    Next(_rhythm, _rhythmStep, 3, DEATH_STEP, 1);
                    break;
                case SPELL_ROYAL_DANCE:
                    Next(_dance, _danceStep, 3, DEATH_STEP, 1);
                    break;
                case SPELL_ROYAL_SONG:
                    // She starts on Blades, so the cycle runs Hunt, Translocation, Blades.
                    Next(_song, _songStep, 3, SONG_DEATH, 1);
                    if (_song == 3 && _songStep)
                        _song = SONG_BLADES;
                    break;
                case SPELL_ROYAL_PHANTOM:
                    if (Creature* dancer = me->SummonCreature(NPC_SARTURA_ROYAL_GUARD, me->GetRandomNearPosition(10.0f), TEMPSUMMON_CORPSE_TIMED_DESPAWN, 10000))
                        dancer->SetInCombatWithZone();
                    break;
                default:
                    return;
            }
            Broadcast();
        }

        // An interrupted royal cast frustrates her.
        void OnSpellFailed(SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_ROYAL_RHYTHM && spell->Id != SPELL_ROYAL_DANCE && spell->Id != SPELL_ROYAL_SONG && spell->Id != SPELL_ROYAL_PHANTOM)
                return;
            AddStack(me, me, SPELL_FRUSTRATION);
            Aura* frustration = me->GetAura(SPELL_FRUSTRATION);
            if (frustration && frustration->GetStackAmount() >= FRUSTRATION_MAX)
            {
                me->RemoveAurasDueToSpell(SPELL_FRUSTRATION);
                DoCastSelf(SPELL_FURIOUS, true);
                events.ScheduleEvent(EVENT_OUTBREAK_END, 30s);
                Broadcast();
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
                    case EVENT_CUT:
                        if (Unit* tank = me->GetVictim())
                            if (me->IsWithinMeleeRange(tank))
                            {
                                me->CastSpell(tank, Cuts[Rhythm()][++_cuts % 4 ? 0 : 1], true);
                                AddStack(me, tank, SPELL_SHRED_ARMOR, SHRED_STACKS);
                            }
                        events.ScheduleEvent(EVENT_CUT, CutEvery[Rhythm()]);
                        break;
                    case EVENT_ROYAL:
                    {
                        uint32 const casts[4] = { SPELL_ROYAL_RHYTHM, SPELL_ROYAL_DANCE, SPELL_ROYAL_SONG, SPELL_ROYAL_PHANTOM };
                        DoCastSelf(casts[_royal++ % 4]);
                        events.ScheduleEvent(EVENT_ROYAL, 10s);
                        break;
                    }
                    case EVENT_OUTBREAK_END:
                        Broadcast();
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
            // Her melee is the Rhythm's cuts; no plain swings.
        }

    private:
        bool _enraged = false;
        uint8 _rhythm = 0, _dance = 0, _song = 0;
        uint8 _rhythmStep = 0, _danceStep = 0, _songStep = 0;
        uint32 _royal = 0, _cuts = 0;
    };

    // Sartura's Royal Guard, now a Phantom Dancer.
    struct npc_sartura_phantom_coa : public ScriptedAI
    {
        npc_sartura_phantom_coa(Creature* creature) : ScriptedAI(creature), _instance(creature->GetInstanceScript()) { }

        void Reset() override
        {
            _events.Reset();
            _dance = 0;
            _song = SONG_BLADES;
            for (uint32 d : Dances)
                me->RemoveAurasDueToSpell(d);
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            ApplyDance();
            _events.ScheduleEvent(EVENT_MOVE, 1s);
            _events.ScheduleEvent(EVENT_JUMP, 8s);
        }

        void SetData(uint32 type, uint32 value) override
        {
            if (type == TYPE_DANCE && value != _dance)
            {
                _dance = uint8(value);
                ApplyDance();
            }
            else if (type == TYPE_SONG && value != _song)
            {
                _song = uint8(value);
                _events.RescheduleEvent(EVENT_MOVE, 100ms);
                _events.RescheduleEvent(EVENT_JUMP, _song == SONG_DEATH ? 5s : 8s);
            }
        }

        void ApplyDance()
        {
            for (uint32 d : Dances)
                me->RemoveAurasDueToSpell(d);
            me->AddAura(Dances[_dance], me);
        }

        Creature* Sartura() const
        {
            return _instance ? _instance->GetCreature(DATA_SARTURA) : nullptr;
        }

        void Move()
        {
            me->SetWalk(false);
            switch (_song)
            {
                case SONG_BLADES:
                    if (Creature* sartura = Sartura())
                    {
                        Position pos = sartura->GetPosition();
                        sartura->MovePosition(pos, 12.0f, frand(0.0f, 2 * float(M_PI)));
                        me->GetMotionMaster()->MovePoint(0, pos);
                    }
                    me->SetSpeed(MOVE_RUN, 1.0f);
                    break;
                case SONG_HUNT:
                    me->SetSpeed(MOVE_RUN, 0.6f);
                    if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 80.0f, true))
                        me->GetMotionMaster()->MoveChase(target);
                    break;
                case SONG_TRANSLOCATION:
                    me->GetMotionMaster()->Clear();
                    me->StopMoving();
                    break;
                case SONG_DEATH:
                    me->SetSpeed(MOVE_RUN, 1.5f);
                    if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 80.0f, true))
                        me->GetMotionMaster()->MoveChase(target);
                    break;
            }
        }

        void Jump()
        {
            if (_song != SONG_TRANSLOCATION && _song != SONG_DEATH)
                return;
            Unit* target = _song == SONG_DEATH && me->GetVictim() ? me->GetVictim() : SelectTarget(SelectTargetMethod::Random, 0, 80.0f, true);
            if (!target)
                return;
            Position pos = target->GetPosition();
            target->MovePosition(pos, 3.0f, frand(0.0f, 2 * float(M_PI)));
            me->CastSpell(me, SPELL_TRANSLOCATION, true);
            me->NearTeleportTo(pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), me->GetOrientation());
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            _events.Update(diff);
            while (uint32 eventId = _events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_MOVE:
                        Move();
                        _events.ScheduleEvent(EVENT_MOVE, _song == SONG_BLADES ? 4s : 6s);
                        break;
                    case EVENT_JUMP:
                        Jump();
                        _events.ScheduleEvent(EVENT_JUMP, _song == SONG_DEATH ? 5s : 8s);
                        break;
                    default:
                        break;
                }
            }
            // The blades do the damage; the dancers do not swing.
        }

    private:
        InstanceScript* _instance;
        EventMap _events;
        uint8 _dance = 0;
        uint8 _song = SONG_BLADES;
    };
}

void AddCoaSarturaScripts()
{
    RegisterTempleOfAhnQirajCreatureAI(boss_sartura_coa);
    RegisterTempleOfAhnQirajCreatureAI(npc_sartura_phantom_coa);
}
