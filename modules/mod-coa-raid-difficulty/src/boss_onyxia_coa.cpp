/*
 * Onyxia as Ascension ran her, rebuilt from combat logs.
 *
 * This is the stock AzerothCore script with the numbers changed, not a new
 * fight. The logs show that Ascension kept the stock choreography - ground
 * phase, air phase with fireballs and Deep Breath from the stock waypoints,
 * landing with Bellowing Roar - and swapped what happens inside it. Their Deep
 * Breath spells 2108305/2108306 have exactly the shape of the stock breath
 * 17086/17087: same radius, same targets, only other numbers. So the stock
 * movement and breath geometry stay, and everything the logs pin down changes.
 *
 * Measured from four kills, one on each difficulty:
 *
 *   phase changes     at 85% and 35% health, not 65% and 40%
 *   ground spells     Ascension's own ids and intervals; no Wing Buffet, which
 *                     Ascension's Onyxia never cast; Fierce Blow added
 *   air phase         Massive Fireball 2108300 instead of 18392
 *   Deep Breath       stock path, Ascension damage (see spell_onyxia_coa_breath)
 *   landed phase      Bellowing Roar 2108326 every 45s. It carries a camera
 *                     shake and nothing else; the stock lava eruptions never
 *                     appear in a log and are gone.
 *   whelps            20 per wave, every ~99s in the air and every ~55s once
 *                     she has landed. Stock summoned 40, then two at a time.
 *   lair guards       never appear in a log; not summoned.
 *
 * Damage per difficulty is not in here. Every Ascension spell below resolves
 * through SpellDifficulty.dbc, which the core applies by itself.
 */

#include "CreatureScript.h"
#include "ScriptedCreature.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "../../../src/server/scripts/Kalimdor/OnyxiasLair/onyxias_lair.h"

namespace
{
    enum Spells
    {
        // Ascension, from the logs
        SPELL_FIERCE_BLOW           = 975011,
        SPELL_DRACONIC_CLEAVE       = 2108311,
        SPELL_FLAME_BREATH          = 2108321,
        SPELL_TAIL_SWEEP            = 2108312,
        SPELL_MASSIVE_FIREBALL      = 2108300,
        SPELL_BELLOWING_ROAR        = 2108326,
        SPELL_DEEP_BREATH_HIT       = 2108306,  // first of a SpellDifficulty row

        // stock, kept for the geometry
        SPELL_SUMMON_WHELP          = 17646,
        SPELL_BREATH_N_TO_S         = 17086,
        SPELL_BREATH_S_TO_N         = 18351,
        SPELL_BREATH_E_TO_W         = 18576,
        SPELL_BREATH_W_TO_E         = 18609,
        SPELL_BREATH_SE_TO_NW       = 18564,
        SPELL_BREATH_NW_TO_SE       = 18584,
        SPELL_BREATH_SW_TO_NE       = 18596,
        SPELL_BREATH_NE_TO_SW       = 18617,
    };

    // Measured, in milliseconds.
    constexpr Milliseconds FIERCE_BLOW_FIRST     = 7500ms,  FIERCE_BLOW_EVERY     = 19700ms;
    constexpr Milliseconds CLEAVE_FIRST          = 10100ms, CLEAVE_EVERY          = 10100ms;
    constexpr Milliseconds FLAME_BREATH_FIRST    = 20000ms, FLAME_BREATH_EVERY    = 20100ms;
    constexpr Milliseconds TAIL_SWEEP_FIRST      = 27300ms, TAIL_SWEEP_EVERY      = 21300ms;
    constexpr Milliseconds ROAR_EVERY            = 45000ms;
    constexpr Milliseconds WHELPS_AIR_EVERY      = 99000ms;
    constexpr Milliseconds WHELPS_LANDED_EVERY   = 55000ms;
    constexpr uint8        WHELPS_PER_WAVE       = 20;

    constexpr uint8 LIFTOFF_PCT = 85;
    constexpr uint8 LANDING_PCT = 35;

    enum Events
    {
        EVENT_FIERCE_BLOW = 1,
        EVENT_CLEAVE,
        EVENT_FLAME_BREATH,
        EVENT_TAIL_SWEEP,
        EVENT_START_PHASE_2,
        EVENT_FIREBALL_FIRST,
        EVENT_FIREBALL_SECOND,
        EVENT_STEP_CW,
        EVENT_STEP_ACW,
        EVENT_STEP_ACROSS,
        EVENT_BREATH,
        EVENT_START_PHASE_3,
        EVENT_PHASE_3_ATTACK,
        EVENT_ROAR,
        EVENT_WHELP_WAVE,
        EVENT_LIFTOFF,
        EVENT_FLY_S_TO_N,
        EVENT_LAND,
        EVENT_END_MANY_WHELPS_TIME,
    };

    enum Phases
    {
        PHASE_NONE,
        PHASE_GROUNDED,
        PHASE_AIRPHASE,
        PHASE_LANDED
    };

    enum Points
    {
        POINT_GROUND_SOUTH  = 10,
        POINT_TAKEOFF       = 11,
        POINT_PRE_LAND      = 12,
        POINT_LAND          = 13
    };

    enum Yells
    {
        SAY_AGGRO           = 0,
        SAY_PHASE_2_TRANS   = 2,
        SAY_PHASE_3_TRANS   = 3,
        EMOTE_BREATH        = 4,
        SAY_EVADE           = 5
    };

    struct OnyxiaMove
    {
        uint8 CurrId, DestId;
        uint32 SpellId;
        float X, Y, Z, O;
    };

    // The stock waypoints, unchanged.
    OnyxiaMove const OnyxiaMoveData[] =
    {
        {0, 0, 0, -64.496f, -214.906f, -84.4f, 0.0f},
        {1, 5, SPELL_BREATH_S_TO_N, -64.496f, -214.906f, -60.0f, 0.0f},
        {2, 6, SPELL_BREATH_SW_TO_NE, -59.809f, -190.758f, -60.0f, 7 * M_PI / 4},
        {3, 7, SPELL_BREATH_W_TO_E, -29.450f, -180.600f, -60.0f, M_PI + M_PI / 2},
        {4, 8, SPELL_BREATH_NW_TO_SE, 6.895f, -180.246f, -60.0f, M_PI + M_PI / 4},
        {5, 1, SPELL_BREATH_N_TO_S,  22.876f, -217.152f, -60.0f, M_PI},
        {6, 2, SPELL_BREATH_NE_TO_SW, 10.2191f, -247.912f, -60.0f, 3 * M_PI / 4},
        {7, 3, SPELL_BREATH_E_TO_W, -31.496f, -250.123f, -60.0f, M_PI / 2},
        {8, 4, SPELL_BREATH_SE_TO_NW, -63.5156f, -240.096f, -60.0f, M_PI / 4},
    };

    struct boss_onyxia_coa : public BossAI
    {
        boss_onyxia_coa(Creature* creature) : BossAI(creature, DATA_ONYXIA) { Initialize(); }

        void Initialize()
        {
            _phase = PHASE_NONE;
            _currentWP = 0;
            _whelpsLeft = 0;
            _whelpTimer = 0;
            _manyWhelpsAvailable = false;
        }

        void ScheduleGroundSpells()
        {
            events.ScheduleEvent(EVENT_FIERCE_BLOW, FIERCE_BLOW_FIRST);
            events.ScheduleEvent(EVENT_CLEAVE, CLEAVE_FIRST);
            events.ScheduleEvent(EVENT_FLAME_BREATH, FLAME_BREATH_FIRST);
            events.ScheduleEvent(EVENT_TAIL_SWEEP, TAIL_SWEEP_FIRST);
        }

        void SetPhase(uint8 phase)
        {
            events.Reset();
            _phase = phase;
            switch (phase)
            {
                case PHASE_GROUNDED:
                    ScheduleGroundSpells();
                    break;
                case PHASE_AIRPHASE:
                    events.ScheduleEvent(EVENT_START_PHASE_2, 0ms);
                    break;
                case PHASE_LANDED:
                    events.ScheduleEvent(EVENT_START_PHASE_3, 5s);
                    break;
                default:
                    break;
            }
        }

        void Reset() override
        {
            Initialize();
            SetPhase(PHASE_NONE);
            me->SetReactState(REACT_AGGRESSIVE);
            me->SetCanFly(false);
            me->SetDisableGravity(false);
            me->SetSpeed(MOVE_RUN, me->GetCreatureTemplate()->speed_run, false);
            instance->DoStopTimedAchievement(ACHIEVEMENT_TIMED_TYPE_EVENT, ACHIEV_TIMED_START_EVENT);
            BossAI::Reset();
        }

        void DoAction(int32 param) override
        {
            if (param == ACTION_WHELP_SUMMONED && _manyWhelpsAvailable)
                instance->SetData(DATA_WHELP_SUMMONED, 1);
        }

        void JustEngagedWith(Unit* who) override
        {
            Talk(SAY_AGGRO);
            SetPhase(PHASE_GROUNDED);
            instance->DoStopTimedAchievement(ACHIEVEMENT_TIMED_TYPE_EVENT, ACHIEV_TIMED_START_EVENT);
            instance->DoStartTimedAchievement(ACHIEVEMENT_TIMED_TYPE_EVENT, ACHIEV_TIMED_START_EVENT);
            BossAI::JustEngagedWith(who);
            // No lair guard: none appears in any log.
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);

            if (_phase == PHASE_GROUNDED && me->HealthBelowPctDamaged(LIFTOFF_PCT, damage))
                SetPhase(PHASE_AIRPHASE);
            else if (_phase == PHASE_AIRPHASE && me->HealthBelowPctDamaged(LANDING_PCT, damage))
            {
                me->InterruptNonMeleeSpells(false);
                SetPhase(PHASE_LANDED);
            }
        }

        void JustSummoned(Creature* summon) override
        {
            summons.Summon(summon);
            if (summon->GetEntry() != NPC_ONYXIAN_WHELP)
                return;

            if (Unit* target = summon->SelectNearestTarget(300.0f))
            {
                summon->AI()->AttackStart(target);
                DoZoneInCombat(summon);
            }
        }

        void MovementInform(uint32 type, uint32 id) override
        {
            if (type != POINT_MOTION_TYPE && type != EFFECT_MOTION_TYPE)
                return;

            if (id < 9)
            {
                if (id > 0 && _phase == PHASE_AIRPHASE)
                {
                    me->SetFacingTo(OnyxiaMoveData[id].O);
                    me->SetSpeed(MOVE_RUN, 1.6f, false);
                    _currentWP = id;
                    events.ScheduleEvent(EVENT_FIREBALL_FIRST, 1s);
                }
                return;
            }

            switch (id)
            {
                case POINT_GROUND_SOUTH:
                    me->SetFacingTo(OnyxiaMoveData[0].O);
                    events.ScheduleEvent(EVENT_LIFTOFF, 0ms);
                    break;
                case POINT_TAKEOFF:
                    me->SetFacingTo(OnyxiaMoveData[1].O);
                    events.ScheduleEvent(EVENT_FLY_S_TO_N, 0ms);
                    break;
                case POINT_PRE_LAND:
                    me->SetFacingTo(OnyxiaMoveData[1].O);
                    events.ScheduleEvent(EVENT_LAND, 0ms);
                    break;
                case POINT_LAND:
                    me->SetCanFly(false);
                    me->SetDisableGravity(false);
                    me->SetSpeed(MOVE_RUN, me->GetCreatureTemplate()->speed_run, false);
                    events.ScheduleEvent(EVENT_PHASE_3_ATTACK, 0ms);
                    break;
                default:
                    break;
            }
        }

        // One whelp at each of the two side caves, as in stock.
        void SummonWhelpPair()
        {
            float angle = rand_norm() * 2 * M_PI;
            float dist  = rand_norm() * 4.0f;
            me->CastSpell(-33.18f + std::cos(angle) * dist, -258.80f + std::sin(angle) * dist, -89.0f, SPELL_SUMMON_WHELP, true);
            me->CastSpell(-32.535f + std::cos(angle) * dist, -170.190f + std::sin(angle) * dist, -89.0f, SPELL_SUMMON_WHELP, true);
        }

        // A wave comes out a pair at a time, 600ms apart, like the stock spam.
        void UpdateWhelpWave(uint32 diff)
        {
            if (!_whelpsLeft)
                return;

            _whelpTimer -= int32(diff);
            if (_whelpTimer > 0)
                return;

            SummonWhelpPair();
            _whelpsLeft = _whelpsLeft > 2 ? _whelpsLeft - 2 : 0;
            _whelpTimer += 600;
        }

        void StartWhelpWave()
        {
            _whelpsLeft = WHELPS_PER_WAVE;
            _whelpTimer = 0;
        }

        bool CheckInRoom() override
        {
            if (me->GetDistance2d(me->GetHomePosition().GetPositionX(), me->GetHomePosition().GetPositionY()) > 95.0f)
            {
                Talk(SAY_EVADE);
                EnterEvadeMode();
                return false;
            }
            return true;
        }

        void CastAtRandomPlayer(uint32 spell)
        {
            if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 200.0f, true))
            {
                me->SetFacingToObject(target);
                DoCast(target, spell);
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim() || !CheckInRoom())
                return;

            events.Update(diff);
            UpdateWhelpWave(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            switch (events.ExecuteEvent())
            {
                case EVENT_FIERCE_BLOW:
                    DoCastVictim(SPELL_FIERCE_BLOW);
                    events.Repeat(FIERCE_BLOW_EVERY);
                    break;
                case EVENT_CLEAVE:
                    DoCastVictim(SPELL_DRACONIC_CLEAVE);
                    events.Repeat(CLEAVE_EVERY);
                    break;
                case EVENT_FLAME_BREATH:
                    DoCastVictim(SPELL_FLAME_BREATH);
                    events.Repeat(FLAME_BREATH_EVERY);
                    break;
                case EVENT_TAIL_SWEEP:
                    DoCastAOE(SPELL_TAIL_SWEEP);
                    events.Repeat(TAIL_SWEEP_EVERY);
                    break;
                case EVENT_START_PHASE_2:
                    me->AttackStop();
                    me->SetReactState(REACT_PASSIVE);
                    me->StopMoving();
                    DoResetThreatList();
                    me->GetMotionMaster()->MovePoint(POINT_GROUND_SOUTH, OnyxiaMoveData[0].X, OnyxiaMoveData[0].Y, OnyxiaMoveData[0].Z);
                    break;
                case EVENT_LIFTOFF:
                    Talk(SAY_PHASE_2_TRANS);
                    me->SendMeleeAttackStop(me->GetVictim());
                    me->GetMotionMaster()->MoveIdle();
                    me->DisableSpline();
                    me->SetCanFly(true);
                    me->SetDisableGravity(true);
                    me->SetOrientation(OnyxiaMoveData[0].O);
                    me->SendMovementFlagUpdate();
                    me->GetMotionMaster()->MoveTakeoff(POINT_TAKEOFF, OnyxiaMoveData[1].X + 1.0f, OnyxiaMoveData[1].Y, OnyxiaMoveData[1].Z, 12.0f);
                    _manyWhelpsAvailable = true;
                    events.RescheduleEvent(EVENT_END_MANY_WHELPS_TIME, 10s);
                    break;
                case EVENT_END_MANY_WHELPS_TIME:
                    _manyWhelpsAvailable = false;
                    break;
                case EVENT_FLY_S_TO_N:
                    me->SetSpeed(MOVE_RUN, 2.95f, false);
                    me->GetMotionMaster()->MovePoint(5, OnyxiaMoveData[5].X, OnyxiaMoveData[5].Y, OnyxiaMoveData[5].Z);
                    StartWhelpWave();
                    events.ScheduleEvent(EVENT_WHELP_WAVE, WHELPS_AIR_EVERY);
                    break;
                case EVENT_WHELP_WAVE:
                    StartWhelpWave();
                    events.Repeat(_phase == PHASE_LANDED ? WHELPS_LANDED_EVERY : WHELPS_AIR_EVERY);
                    break;
                case EVENT_LAND:
                    Talk(SAY_PHASE_3_TRANS);
                    me->SendMeleeAttackStop(me->GetVictim());
                    me->GetMotionMaster()->MoveLand(POINT_LAND, OnyxiaMoveData[0].X + 1.0f, OnyxiaMoveData[0].Y, OnyxiaMoveData[0].Z, 12.0f);
                    DoResetThreatList();
                    break;
                case EVENT_FIREBALL_FIRST:
                    CastAtRandomPlayer(SPELL_MASSIVE_FIREBALL);
                    events.ScheduleEvent(EVENT_FIREBALL_SECOND, 4s);
                    break;
                case EVENT_FIREBALL_SECOND:
                    CastAtRandomPlayer(SPELL_MASSIVE_FIREBALL);
                    switch (urand(0, 2))
                    {
                        case 0: events.ScheduleEvent(EVENT_STEP_CW, 4s); break;
                        case 1: events.ScheduleEvent(EVENT_STEP_ACW, 4s); break;
                        default: events.ScheduleEvent(EVENT_STEP_ACROSS, 4s); break;
                    }
                    break;
                case EVENT_STEP_CW:
                {
                    uint8 wp = _currentWP + 1;
                    if (wp > 8)
                        wp = 1;
                    me->GetMotionMaster()->MovePoint(wp, OnyxiaMoveData[wp].X, OnyxiaMoveData[wp].Y, OnyxiaMoveData[wp].Z);
                    break;
                }
                case EVENT_STEP_ACW:
                {
                    uint8 wp = _currentWP - 1;
                    if (wp < 1)
                        wp = 8;
                    me->GetMotionMaster()->MovePoint(wp, OnyxiaMoveData[wp].X, OnyxiaMoveData[wp].Y, OnyxiaMoveData[wp].Z);
                    break;
                }
                case EVENT_STEP_ACROSS:
                    Talk(EMOTE_BREATH);
                    me->SetFacingTo(OnyxiaMoveData[_currentWP].O);
                    DoCastAOE(OnyxiaMoveData[_currentWP].SpellId);
                    events.ScheduleEvent(EVENT_BREATH, 8250ms);
                    break;
                case EVENT_BREATH:
                {
                    uint8 wp = OnyxiaMoveData[_currentWP].DestId;
                    me->SetSpeed(MOVE_RUN, 2.95f, false);
                    me->GetMotionMaster()->MovePoint(wp, OnyxiaMoveData[wp].X, OnyxiaMoveData[wp].Y, OnyxiaMoveData[wp].Z);
                    break;
                }
                case EVENT_START_PHASE_3:
                    me->SetSpeed(MOVE_RUN, 2.95f, false);
                    me->GetMotionMaster()->MovePoint(POINT_PRE_LAND, OnyxiaMoveData[1].X, OnyxiaMoveData[1].Y, OnyxiaMoveData[1].Z);
                    break;
                case EVENT_PHASE_3_ATTACK:
                    me->SetReactState(REACT_AGGRESSIVE);
                    if (Unit* target = SelectTarget(SelectTargetMethod::MaxThreat, 0, 0, false))
                        AttackStart(target);
                    DoCastAOE(SPELL_BELLOWING_ROAR);
                    ScheduleGroundSpells();
                    events.ScheduleEvent(EVENT_ROAR, ROAR_EVERY);
                    // The whelps keep coming after the landing, faster.
                    events.ScheduleEvent(EVENT_WHELP_WAVE, WHELPS_LANDED_EVERY);
                    break;
                case EVENT_ROAR:
                    DoCastAOE(SPELL_BELLOWING_ROAR);
                    events.Repeat(ROAR_EVERY);
                    break;
                default:
                    break;
            }

            DoMeleeAttackIfReady();
        }

        void SpellHitTarget(Unit* target, SpellInfo const* spell) override
        {
            // Same achievement check as stock: Deep Breath is a chain of
            // triggered spells with no shared id, recognised by shape.
            if (target->IsPlayer() && spell->DurationEntry && spell->DurationEntry->ID == 328
                && spell->Effects[EFFECT_1].TargetA.GetTarget() == TARGET_UNIT_CASTER
                && (spell->Effects[EFFECT_1].Amplitude == 50 || spell->Effects[EFFECT_1].Amplitude == 215))
            {
                instance->SetData(DATA_DEEP_BREATH_FAILED, 1);
            }
        }

    private:
        uint8 _phase;
        int8  _currentWP;
        uint8 _whelpsLeft;
        int32 _whelpTimer;
        bool  _manyWhelpsAvailable;
    };

    /*
     * The stock breath trail, with Ascension's damage.
     *
     * Ascension's Deep Breath hit is 2108306 and its tier variants, radius 18
     * yards, the same shape as the stock trail spell 17087. The path the stock
     * breath draws across the room stays; only the damage of each trail hit is
     * replaced by what 2108306 deals on this map's difficulty.
     */
    class spell_onyxia_coa_breath : public SpellScript
    {
        PrepareSpellScript(spell_onyxia_coa_breath);

        void SetDamage(SpellEffIndex /*effIndex*/)
        {
            Unit* caster = GetCaster();
            if (!caster || caster->GetEntry() % 100000 != NPC_ONYXIA)
                return;

            uint32 const id = sSpellMgr->GetSpellIdForDifficulty(SPELL_DEEP_BREATH_HIT, caster);
            if (SpellInfo const* info = sSpellMgr->GetSpellInfo(id))
                SetHitDamage(info->Effects[EFFECT_0].CalcValue(caster));
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_onyxia_coa_breath::SetDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        }
    };
}

void AddCoaOnyxiaScripts()
{
    RegisterOnyxiasLairCreatureAI(boss_onyxia_coa);
    RegisterSpellScript(spell_onyxia_coa_breath);
}
