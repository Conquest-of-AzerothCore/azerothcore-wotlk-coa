/*
 * Bloodlord Mandokir with Ascension's spells.
 *
 * Kit: Ascension's block 2118400-2118428. Timings: a Bronzebeard kill on video,
 * see raid-difficulty-werkzeug/zg-video-zeitplan.json. The Berserker Charge is
 * the cleanest timer in the whole video: 25.1s, 22 times in a row.
 *
 * From stock: the start when the Vilebranch Speaker dies, the ride down, Ohgan
 * at his side, the chained spirits that revive the dead, and the gaze. Ohgan,
 * the spirits and the speaker keep their stock scripts.
 *
 *   Berserker Charge  first 10s, every 25s   the nearest player he can see,
 *                                            knocked down; the tank loses his
 *                                            threat, as in stock
 *   Whirlwind         1.5s and 8s after each charge, 6 yards around him
 *   Mortal Strike     first 8s,  every 10s   the tank, -25% healing, stacks 3
 *   Threatening Gaze  first 15s, every 20s   he stares at a player for 4s;
 *                                            whoever gains threat meanwhile
 *                                            is Decapitated
 *   Execute           the tank below 20%, every 7-14s
 *   Level Up!         +4% damage for every player who dies near him
 *   Frenzy            when Ohgan dies
 *
 * Decided here, not in the data:
 *   - Whirlwind tied to the charge: the video shows two per 25s cycle, 6-8s
 *     apart, the first right after the charge;
 *   - the gaze timer; the gaze itself is Ascension's (Threatening Gaze, then
 *     Decapitate) run on the stock rule "gain threat and die";
 *   - the kill-streak auras (First Blood! to Legendary!) at 1, 3, 5, 7 and 10
 *     kills; they are only a counter in the data.
 */

#include "CreatureScript.h"
#include "InstanceScript.h"
#include "ScriptedCreature.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"

#include <list>

using namespace coa_zg;

namespace
{
    enum Says
    {
        SAY_AGGRO       = 0,
        SAY_DING_KILL   = 1,
        SAY_WATCH       = 2,
        SAY_OHGAN_DEAD  = 4,
        SAY_GRATS_JINDO = 0
    };

    enum Spells
    {
        SPELL_SUMMON_PLAYER     = 25104,

        SPELL_MORTAL_STRIKE     = 2118401,
        SPELL_MORTAL_STRIKE_HIT = 2118402,
        SPELL_MORTAL_WOUND      = 2118403,
        SPELL_EXECUTE           = 2118404,
        SPELL_EXECUTE_HIT       = 2118405,
        SPELL_BERSERKER_CHARGE  = 2118406,
        SPELL_WHIRLWIND         = 2118408,
        SPELL_DECAPITATE        = 2118410,
        SPELL_LEAP              = 2118413,
        SPELL_LEVEL_UP          = 2118416,
        SPELL_FIRST_BLOOD       = 2118417,
        SPELL_KILLING_SPREE     = 2118418,
        SPELL_RAMPAGE           = 2118419,
        SPELL_UNSTOPPABLE       = 2118420,
        SPELL_LEGENDARY         = 2118421,
        SPELL_THREATENING_GAZE  = 2118422,
        SPELL_FRENZY            = 2106613,
    };

    enum Events
    {
        EVENT_CHECK_START = 1,
        EVENT_STARTED,
        EVENT_CHARGE,
        EVENT_WHIRLWIND,
        EVENT_MORTAL_STRIKE,
        EVENT_GAZE,
        EVENT_GAZE_END,
        EVENT_EXECUTE,
        EVENT_CHECK_OHGAN,
    };

    enum Misc
    {
        ACTION_REVIVE        = 2,
        MODEL_OHGAN_MOUNT    = 15271,
        POINT_MANDOKIR_END   = 25,
        CHAINED_SPIRIT_COUNT = 20
    };

    constexpr uint8 MORTAL_WOUND_STACKS = 3;

    Position const PosSummonChainedSpirits[CHAINED_SPIRIT_COUNT] =
    {
        { -12167.17f, -1979.330f, 133.0992f, 2.268928f },
        { -12262.74f, -1953.394f, 133.5496f, 0.593412f },
        { -12176.89f, -1983.068f, 133.7841f, 2.129302f },
        { -12226.45f, -1977.933f, 132.7982f, 1.466077f },
        { -12204.74f, -1890.431f, 135.7569f, 4.415683f },
        { -12216.70f, -1891.806f, 136.3496f, 4.677482f },
        { -12236.19f, -1892.034f, 134.1041f, 5.044002f },
        { -12248.24f, -1893.424f, 134.1182f, 5.270895f },
        { -12257.36f, -1897.663f, 133.1484f, 5.462881f },
        { -12265.84f, -1903.077f, 133.1649f, 5.654867f },
        { -12158.69f, -1972.707f, 133.8751f, 2.408554f },
        { -12178.82f, -1891.974f, 134.1786f, 3.944444f },
        { -12193.36f, -1890.039f, 135.1441f, 4.188790f },
        { -12275.59f, -1932.845f, 134.9017f, 0.174533f },
        { -12273.51f, -1941.539f, 136.1262f, 0.314159f },
        { -12247.02f, -1963.497f, 133.9476f, 0.872665f },
        { -12238.68f, -1969.574f, 133.6273f, 1.134464f },
        { -12192.78f, -1982.116f, 132.6966f, 1.919862f },
        { -12210.81f, -1979.316f, 133.8700f, 1.797689f },
        { -12283.51f, -1924.839f, 133.5170f, 0.069813f }
    };

    Position const PosMandokir[2] =
    {
        { -12167.8f, -1927.25f, 153.73f, 3.76991f },
        { -12197.86f, -1949.392f, 130.2745f, 0.0f }
    };

    // From stock: the nearest idle chained spirit revives a fallen player.
    void RevivePlayer(Unit* victim, ObjectGuid& reviveGUID)
    {
        std::list<Creature*> spirits;
        GetCreatureListWithEntryInGrid(spirits, victim, NPC_CHAINED_SPIRIT, 200.0f);
        spirits.sort([victim](Creature const* a, Creature const* b) { return a->GetDistance2d(victim) < b->GetDistance2d(victim); });
        for (Creature* spirit : spirits)
        {
            if (!spirit->isMoving() && !spirit->HasUnitState(UNIT_STATE_CASTING))
            {
                spirit->AI()->SetGUID(reviveGUID);
                spirit->AI()->DoAction(ACTION_REVIVE);
                reviveGUID.Clear();
                break;
            }
        }
    }

    struct boss_mandokir_coa : public BossAI
    {
        boss_mandokir_coa(Creature* creature) : BossAI(creature, DATA_MANDOKIR) { }

        void Reset() override
        {
            BossAI::Reset();
            _kills = 0;
            _useExecute = false;
            _gazed.Clear();
            _gazeThreat = 0.0f;
            _reviveGUID.Clear();

            if (me->GetPositionZ() > 140.0f)
            {
                events.ScheduleEvent(EVENT_CHECK_START, 1s);
                if (Creature* speaker = ObjectAccessor::GetCreature(*me, instance->GetGuidData(NPC_VILEBRANCH_SPEAKER)))
                    if (!speaker->IsAlive())
                        speaker->Respawn(true);
            }

            me->RemoveAurasDueToSpell(SPELL_FRENZY);
            me->RemoveAurasDueToSpell(SPELL_LEVEL_UP);
            for (uint32 streak : { SPELL_FIRST_BLOOD, SPELL_KILLING_SPREE, SPELL_RAMPAGE, SPELL_UNSTOPPABLE, SPELL_LEGENDARY })
                me->RemoveAurasDueToSpell(streak);
            me->SetImmuneToAll(false);
            instance->SetBossState(DATA_OHGAN, NOT_STARTED);
            me->Mount(MODEL_OHGAN_MOUNT);
        }

        void JustDied(Unit* /*killer*/) override
        {
            std::list<Creature*> spirits;
            GetCreatureListWithEntryInGrid(spirits, me, NPC_CHAINED_SPIRIT, 200.0f);
            for (Creature* spirit : spirits)
                spirit->DespawnOrUnsummon();
            instance->SetBossState(DATA_MANDOKIR, DONE);
            instance->SaveToDB();
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            _JustEngagedWith();
            events.ScheduleEvent(EVENT_MORTAL_STRIKE, 8s);
            events.ScheduleEvent(EVENT_CHARGE, 10s);
            events.ScheduleEvent(EVENT_GAZE, 15s);
            events.ScheduleEvent(EVENT_CHECK_OHGAN, 1s);

            me->SetHomePosition(me->GetPositionX(), me->GetPositionY(), me->GetPositionZ(), me->GetOrientation());
            Talk(SAY_AGGRO);
            me->Dismount();
            me->SummonCreature(NPC_OHGAN, me->GetPositionX() - 3, me->GetPositionY(), me->GetPositionZ(), me->GetOrientation(), TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT, 35000);
            for (Position const& pos : PosSummonChainedSpirits)
                me->SummonCreature(NPC_CHAINED_SPIRIT, pos, TEMPSUMMON_CORPSE_DESPAWN);
            DoZoneInCombat();
        }

        // Every player who dies near him levels him up.
        void KilledUnit(Unit* victim) override
        {
            if (!victim->IsPlayer())
                return;

            _reviveGUID = victim->GetGUID();
            RevivePlayer(victim, _reviveGUID);

            AddStack(me, me, SPELL_LEVEL_UP);
            ++_kills;
            uint32 streak = 0;
            switch (_kills)
            {
                case 1:  streak = SPELL_FIRST_BLOOD;   break;
                case 3:  streak = SPELL_KILLING_SPREE; break;
                case 5:  streak = SPELL_RAMPAGE;       break;
                case 7:  streak = SPELL_UNSTOPPABLE;   break;
                case 10: streak = SPELL_LEGENDARY;     break;
                default: break;
            }
            if (streak)
            {
                DoCastSelf(streak, true);
                Talk(SAY_DING_KILL);
                if (_kills == 3)
                    if (Creature* jindo = ObjectAccessor::GetCreature(*me, instance->GetGuidData(DATA_JINDO)))
                        if (jindo->IsAlive())
                            jindo->AI()->Talk(SAY_GRATS_JINDO);
            }
        }

        void SetGUID(ObjectGuid const& guid, int32 /*type*/) override
        {
            _reviveGUID = guid;
        }

        void MovementInform(uint32 type, uint32 id) override
        {
            if (type == WAYPOINT_MOTION_TYPE)
            {
                me->SetWalk(false);
                if (id == POINT_MANDOKIR_END)
                {
                    me->SetHomePosition(PosMandokir[0]);
                    instance->SetBossState(DATA_MANDOKIR, NOT_STARTED);
                }
            }
        }

        // What the gazed player does while he stares counts.
        void CalculateThreat(Unit* hatedUnit, float& threat, SpellInfo const* threatSpell) override
        {
            if (_gazed != hatedUnit->GetGUID())
                return;
            if (!(threatSpell && (threatSpell->HasAura(SPELL_AURA_DAMAGE_SHIELD) || threatSpell->HasAttribute(SPELL_ATTR0_CU_NO_INITIAL_THREAT))))
                _gazeThreat += threat;
        }

        void DamageDealt(Unit* doneTo, uint32& damage, DamageEffectType /*type*/, SpellSchoolMask /*school*/) override
        {
            if (!doneTo || doneTo != me->GetVictim())
                return;
            if (doneTo->HealthBelowPctDamaged(20, damage))
            {
                if (!_useExecute)
                {
                    _useExecute = true;
                    events.ScheduleEvent(EVENT_EXECUTE, 1s);
                }
            }
            else if (_useExecute)
            {
                _useExecute = false;
                events.CancelEvent(EVENT_EXECUTE);
            }
        }

        bool OnTeleportUnreacheablePlayer(Player* player) override
        {
            DoCast(player, SPELL_SUMMON_PLAYER, true);
            return true;
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            Unit* tank = me->GetVictim();
            if (!tank)
                return;
            if (spell->Id == SPELL_MORTAL_STRIKE)
            {
                me->CastSpell(tank, SPELL_MORTAL_STRIKE_HIT, true);
                AddStack(me, tank, SPELL_MORTAL_WOUND, MORTAL_WOUND_STACKS);
            }
            else if (spell->Id == SPELL_EXECUTE)
                me->CastSpell(tank, SPELL_EXECUTE_HIT, true);
        }

        void UpdateAI(uint32 diff) override
        {
            events.Update(diff);

            if (!UpdateVictim())
            {
                // From stock: waiting for the speaker, then the ride down.
                if (instance->GetBossState(DATA_MANDOKIR) == NOT_STARTED || instance->GetBossState(DATA_MANDOKIR) == SPECIAL)
                {
                    while (uint32 eventId = events.ExecuteEvent())
                    {
                        if (eventId == EVENT_CHECK_START)
                        {
                            if (instance->GetBossState(DATA_MANDOKIR) == SPECIAL)
                            {
                                me->GetMotionMaster()->MovePoint(0, PosMandokir[1].m_positionX, PosMandokir[1].m_positionY, PosMandokir[1].m_positionZ);
                                events.ScheduleEvent(EVENT_STARTED, 6s);
                            }
                            else
                                events.ScheduleEvent(EVENT_CHECK_START, 1s);
                        }
                        else if (eventId == EVENT_STARTED)
                        {
                            me->SetImmuneToAll(false);
                            me->SetInCombatWithZone();
                        }
                    }
                }
                return;
            }

            if (me->HasUnitState(UNIT_STATE_CASTING) || me->HasUnitState(UNIT_STATE_CHARGING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_CHARGE:
                        if (Unit* target = SelectTarget(SelectTargetMethod::MinDistance, 0, [this](Unit const* u)
                            {
                                return u->IsPlayer() && !me->IsWithinMeleeRange(u) && me->IsWithinLOSInMap(u);
                            }))
                        {
                            DoCast(target, SPELL_BERSERKER_CHARGE);
                            if (Unit* mainTarget = SelectTarget(SelectTargetMethod::MaxThreat, 0, 100.0f))
                                me->GetThreatMgr().ModifyThreatByPercent(mainTarget, -100);
                        }
                        events.ScheduleEvent(EVENT_WHIRLWIND, 1500ms);
                        events.ScheduleEvent(EVENT_WHIRLWIND, 8s);
                        events.ScheduleEvent(EVENT_CHARGE, 25s);
                        break;
                    case EVENT_WHIRLWIND:
                        DoCastSelf(SPELL_WHIRLWIND);
                        break;
                    case EVENT_MORTAL_STRIKE:
                        DoCastVictim(SPELL_MORTAL_STRIKE);
                        events.ScheduleEvent(EVENT_MORTAL_STRIKE, 10s);
                        break;
                    case EVENT_GAZE:
                        if (Unit* player = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                        {
                            me->CastSpell(player, SPELL_THREATENING_GAZE, true);
                            Talk(SAY_WATCH, player);
                            _gazed = player->GetGUID();
                            _gazeThreat = 0.0f;
                            events.ScheduleEvent(EVENT_GAZE_END, 4s);
                        }
                        events.ScheduleEvent(EVENT_GAZE, 20s);
                        break;
                    case EVENT_GAZE_END:
                        if (Unit* target = ObjectAccessor::GetUnit(*me, _gazed))
                            if (_gazeThreat > 0.0f && target->IsAlive())
                            {
                                me->CastSpell(target, SPELL_LEAP, true);
                                me->CastSpell(target, SPELL_DECAPITATE, true);
                            }
                        _gazed.Clear();
                        break;
                    case EVENT_EXECUTE:
                        DoCastVictim(SPELL_EXECUTE);
                        events.ScheduleEvent(EVENT_EXECUTE, 7s, 14s);
                        break;
                    case EVENT_CHECK_OHGAN:
                        if (instance->GetBossState(DATA_OHGAN) == DONE)
                        {
                            DoCastSelf(SPELL_FRENZY, true);
                            Talk(SAY_OHGAN_DEAD);
                        }
                        else
                            events.ScheduleEvent(EVENT_CHECK_OHGAN, 1s);
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
        uint8 _kills = 0;
        bool _useExecute = false;
        ObjectGuid _gazed;
        float _gazeThreat = 0.0f;
        ObjectGuid _reviveGUID;
    };
}

void AddCoaMandokirScripts()
{
    RegisterZulGurubCreatureAI(boss_mandokir_coa);
}
