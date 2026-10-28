/*
 * High Priestess Arlokk with Ascension's spells.
 *
 * Kit: Ascension's block 2118300-2118340. Timings: a Bronzebeard kill on video,
 * see raid-difficulty-werkzeug/zg-video-zeitplan.json.
 *
 * From stock: the prowlers streaming in from both sides, her vanish after 30
 * seconds, the panther phase and the return to troll form, the gong and the
 * despawn when the raid wipes.
 *
 *   Troll form
 *     Shadow Word: Pain  first 2s,  every 20s   the tank
 *     Mark of Arlokk     at 10s                 a player the prowlers hunt;
 *                                               when the mark is gone, it
 *                                               jumps to another player
 *     Kidney Shot        first 15s, every 30s   the tank, 4s stun
 *
 *   Panther form (her Aspect of Bethekk)
 *     Claw Storm         first 5s,  every 20s   spins for 8s, 5 yards around her
 *     Ravage             first 10s, every 15s   the tank, pinned and mauled
 *     Shadowstep         first 12s, every 15s   behind a random player
 *     Razor Claws        passive, her hits bleed
 *
 * Decided here, not in the data:
 *   - Claw Storm, Ravage and Shadowstep timers (each appears once or twice in
 *     the video); Kidney Shot's first cast;
 *   - the mark lasts until it is removed and does not stack; prowlers within
 *     40 yards of the marked player turn on them every 2 seconds.
 */

#include "CreatureScript.h"
#include "GameObject.h"
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
        SAY_AGGRO         = 0,
        SAY_FEAST_PROWLER = 1,
        SAY_DEATH         = 2
    };

    enum Spells
    {
        SPELL_SUMMON_PROWLER     = 24246,
        SPELL_VANISH_VISUAL      = 24222,
        SPELL_VANISH             = 24223,
        SPELL_SUPER_INVIS        = 24235,

        INFO_SHADOW_WORD_PAIN    = 2118301,
        SPELL_SHADOW_WORD_PAIN   = 2118305,
        SPELL_SHADOW_WORD_PAIN_DOT = 2118306,
        SPELL_KIDNEY_SHOT        = 2118307,
        SPELL_SHADOWSTEP         = 2118308,
        SPELL_MARK_OF_ARLOKK     = 2118310,
        SPELL_MARK_OF_ARLOKK_AURA = 2118311,
        SPELL_ASPECT_OF_BETHEKK  = 2118323,
        SPELL_RAZOR_CLAWS        = 2118325,
        SPELL_RAVAGE             = 2118330,
        SPELL_CLAW_STORM         = 2118336,
    };

    enum Events
    {
        EVENT_SHADOW_WORD_PAIN = 1,
        EVENT_KIDNEY_SHOT,
        EVENT_MARK_OF_ARLOKK,
        EVENT_MARK_CHECK,
        EVENT_SUMMON_PROWLERS,
        EVENT_TRANSFORM,
        EVENT_VANISH,
        EVENT_VANISH_2,
        EVENT_VISIBLE,
        EVENT_CLAW_STORM,
        EVENT_RAVAGE,
        EVENT_SHADOWSTEP,
        EVENT_TRANSFORM_BACK,
    };

    enum Phases
    {
        PHASE_ALL   = 0,
        PHASE_ONE   = 1,
        PHASE_TWO   = 2
    };

    constexpr uint32 WEAPON_DAGGER       = 10616;
    constexpr uint8 MAX_PROWLERS_PER_SIDE = 15;
    constexpr float MARK_PULL_RANGE      = 40.0f;

    Position const PosMoveOnSpawn = { -11561.9f, -1627.868f, 41.29941f, 0.0f };

    struct boss_arlokk_coa : public BossAI
    {
        boss_arlokk_coa(Creature* creature) : BossAI(creature, DATA_ARLOKK) { }

        void Reset() override
        {
            _Reset();
            _summonCountA = 0;
            _summonCountB = 0;
            _marking = false;
            me->RemoveAurasDueToSpell(SPELL_ASPECT_OF_BETHEKK);
            me->RemoveAurasDueToSpell(SPELL_RAZOR_CLAWS);
            me->SetUInt32Value(UNIT_VIRTUAL_ITEM_SLOT_ID + 0, WEAPON_DAGGER);
            me->SetUInt32Value(UNIT_VIRTUAL_ITEM_SLOT_ID + 1, WEAPON_DAGGER);
            me->SetWalk(false);
            me->SetHomePosition(PosMoveOnSpawn);
            me->GetMotionMaster()->MoveTargetedHome();
        }

        void JustDied(Unit* /*killer*/) override
        {
            _JustDied();
            Talk(SAY_DEATH);
            ClearMarks();
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            _JustEngagedWith();
            Talk(SAY_AGGRO);

            events.SetPhase(PHASE_ONE);
            ScheduleTroll(2s);
            events.ScheduleEvent(EVENT_SUMMON_PROWLERS, 6s, 0, PHASE_ALL);
            events.ScheduleEvent(EVENT_MARK_OF_ARLOKK, 10s, 0, PHASE_ALL);

            // The panther spawners, split by side as in stock.
            std::list<Creature*> triggers;
            GetCreatureListWithEntryInGrid(triggers, me, NPC_PANTHER_TRIGGER, 100.0f);
            uint8 sideA = 0, sideB = 0;
            for (Creature* trigger : triggers)
            {
                if (trigger->GetPositionY() < -1625.0f)
                {
                    if (sideA < 5)
                        _sideA[sideA++] = trigger->GetGUID();
                }
                else if (sideB < 5)
                    _sideB[sideB++] = trigger->GetGUID();
            }
        }

        void ScheduleTroll(Milliseconds swp)
        {
            events.ScheduleEvent(EVENT_SHADOW_WORD_PAIN, swp, 0, PHASE_ONE);
            events.ScheduleEvent(EVENT_KIDNEY_SHOT, 15s, 0, PHASE_ONE);
            events.ScheduleEvent(EVENT_TRANSFORM, 30s, 0, PHASE_ONE);
        }

        void JustReachedHome() override
        {
            if (GameObject* gong = ObjectAccessor::GetGameObject(*me, instance->GetGuidData(GO_GONG_OF_BETHEKK)))
                gong->RemoveGameObjectFlag(GO_FLAG_NOT_SELECTABLE);
            me->DespawnOrUnsummon();
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            BossAI::EnterEvadeMode(why);
            ClearMarks();
            std::list<Creature*> panthers;
            GetCreatureListWithEntryInGrid(panthers, me, NPC_ZULIAN_PROWLER, 200.0f);
            for (Creature* panther : panthers)
                panther->DespawnOrUnsummon();
        }

        // A prowler died on side 1 or 2.
        void SetData(uint32 id, uint32 /*value*/) override
        {
            if (id == 1 && _summonCountA)
                --_summonCountA;
            else if (id == 2 && _summonCountB)
                --_summonCountB;
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            Unit* target = ObjectAccessor::GetUnit(*me, _target);
            if (spell->Id == SPELL_SHADOW_WORD_PAIN)
                Hit(me, target, SPELL_SHADOW_WORD_PAIN_DOT, Info(me, INFO_SHADOW_WORD_PAIN));
            else if (spell->Id == SPELL_MARK_OF_ARLOKK && target)
            {
                me->AddAura(SPELL_MARK_OF_ARLOKK_AURA, target);
                Talk(SAY_FEAST_PROWLER, target);
            }
        }

        Player* Marked()
        {
            for (Player* p : Players(me, [](Player* x) { return x->HasAura(SPELL_MARK_OF_ARLOKK_AURA); }))
                return p;
            return nullptr;
        }

        void ClearMarks()
        {
            me->GetMap()->DoForAllPlayers([](Player* p) { p->RemoveAurasDueToSpell(SPELL_MARK_OF_ARLOKK_AURA); });
        }

        void Mark()
        {
            if (Unit* target = SelectTarget(SelectTargetMethod::Random, 1, 100.0f, true))
            {
                _target = target->GetGUID();
                DoCast(target, SPELL_MARK_OF_ARLOKK, true);
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
                    case EVENT_SHADOW_WORD_PAIN:
                        if (Unit* tank = me->GetVictim())
                        {
                            _target = tank->GetGUID();
                            DoCast(tank, SPELL_SHADOW_WORD_PAIN);
                        }
                        events.ScheduleEvent(EVENT_SHADOW_WORD_PAIN, 20s, 0, PHASE_ONE);
                        break;
                    case EVENT_KIDNEY_SHOT:
                        DoCastVictim(SPELL_KIDNEY_SHOT);
                        events.ScheduleEvent(EVENT_KIDNEY_SHOT, 30s, 0, PHASE_ONE);
                        break;
                    case EVENT_MARK_OF_ARLOKK:
                        _marking = true;
                        Mark();
                        events.ScheduleEvent(EVENT_MARK_CHECK, 2s, 0, PHASE_ALL);
                        break;
                    case EVENT_MARK_CHECK:
                        if (Player* marked = Marked())
                        {
                            std::list<Creature*> prowlers;
                            GetCreatureListWithEntryInGrid(prowlers, marked, NPC_ZULIAN_PROWLER, MARK_PULL_RANGE);
                            for (Creature* prowler : prowlers)
                                if (prowler->IsAlive() && prowler->GetVictim() != marked)
                                {
                                    prowler->GetThreatMgr().AddThreat(marked, 100000.0f);
                                    prowler->AI()->AttackStart(marked);
                                }
                        }
                        else if (_marking)
                            Mark();   // the mark jumps
                        events.ScheduleEvent(EVENT_MARK_CHECK, 2s, 0, PHASE_ALL);
                        break;
                    case EVENT_SUMMON_PROWLERS:
                        if (_summonCountA < MAX_PROWLERS_PER_SIDE)
                            if (Unit* trigger = ObjectAccessor::GetUnit(*me, _sideA[urand(0, 4)]))
                            {
                                trigger->CastSpell(trigger, SPELL_SUMMON_PROWLER);
                                ++_summonCountA;
                            }
                        if (_summonCountB < MAX_PROWLERS_PER_SIDE)
                            if (Unit* trigger = ObjectAccessor::GetUnit(*me, _sideB[urand(0, 4)]))
                            {
                                trigger->CastSpell(trigger, SPELL_SUMMON_PROWLER);
                                ++_summonCountB;
                            }
                        events.ScheduleEvent(EVENT_SUMMON_PROWLERS, 6s, 0, PHASE_ALL);
                        break;
                    case EVENT_TRANSFORM:
                        DoCastSelf(SPELL_ASPECT_OF_BETHEKK, true);
                        me->SetUInt32Value(UNIT_VIRTUAL_ITEM_SLOT_ID + 0, EQUIP_UNEQUIP);
                        me->SetUInt32Value(UNIT_VIRTUAL_ITEM_SLOT_ID + 1, EQUIP_UNEQUIP);
                        me->AttackStop();
                        DoResetThreatList();
                        me->SetReactState(REACT_PASSIVE);
                        me->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE);
                        DoCastSelf(SPELL_VANISH_VISUAL);
                        DoCastSelf(SPELL_VANISH);
                        events.ScheduleEvent(EVENT_VANISH, 1s, 0, PHASE_ONE);
                        break;
                    case EVENT_VANISH:
                        DoCastSelf(SPELL_SUPER_INVIS);
                        me->SetWalk(false);
                        me->GetMotionMaster()->MovePoint(0, frand(-11551.0f, -11508.0f), frand(-1638.0f, -1617.0f), me->GetPositionZ());
                        events.ScheduleEvent(EVENT_VANISH_2, 9s, 0, PHASE_ONE);
                        break;
                    case EVENT_VANISH_2:
                        DoCastSelf(SPELL_VANISH);
                        DoCastSelf(SPELL_SUPER_INVIS);
                        events.ScheduleEvent(EVENT_VISIBLE, 41s, 47s, 0, PHASE_ONE);
                        break;
                    case EVENT_VISIBLE:
                        me->SetReactState(REACT_AGGRESSIVE);
                        me->RemoveUnitFlag(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE);
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0))
                            AttackStart(target);
                        me->RemoveAurasDueToSpell(SPELL_SUPER_INVIS);
                        me->RemoveAurasDueToSpell(SPELL_VANISH);
                        DoCastSelf(SPELL_RAZOR_CLAWS, true);
                        events.SetPhase(PHASE_TWO);
                        events.ScheduleEvent(EVENT_CLAW_STORM, 5s, 0, PHASE_TWO);
                        events.ScheduleEvent(EVENT_RAVAGE, 10s, 0, PHASE_TWO);
                        events.ScheduleEvent(EVENT_SHADOWSTEP, 12s, 0, PHASE_TWO);
                        events.ScheduleEvent(EVENT_TRANSFORM_BACK, 30s, 40s, 0, PHASE_TWO);
                        break;
                    case EVENT_CLAW_STORM:
                        DoCastSelf(SPELL_CLAW_STORM);
                        events.ScheduleEvent(EVENT_CLAW_STORM, 20s, 0, PHASE_TWO);
                        break;
                    case EVENT_RAVAGE:
                        DoCastVictim(SPELL_RAVAGE, true);
                        events.ScheduleEvent(EVENT_RAVAGE, 15s, 0, PHASE_TWO);
                        break;
                    case EVENT_SHADOWSTEP:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 40.0f, true))
                        {
                            DoCast(target, SPELL_SHADOWSTEP);
                            AttackStart(target);
                        }
                        events.ScheduleEvent(EVENT_SHADOWSTEP, 15s, 0, PHASE_TWO);
                        break;
                    case EVENT_TRANSFORM_BACK:
                        me->RemoveAurasDueToSpell(SPELL_ASPECT_OF_BETHEKK);
                        me->RemoveAurasDueToSpell(SPELL_RAZOR_CLAWS);
                        DoCastSelf(SPELL_VANISH_VISUAL);
                        me->SetUInt32Value(UNIT_VIRTUAL_ITEM_SLOT_ID + 0, WEAPON_DAGGER);
                        me->SetUInt32Value(UNIT_VIRTUAL_ITEM_SLOT_ID + 1, WEAPON_DAGGER);
                        events.SetPhase(PHASE_ONE);
                        ScheduleTroll(4s);
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
        uint8 _summonCountA = 0;
        uint8 _summonCountB = 0;
        bool _marking = false;
        ObjectGuid _sideA[5];
        ObjectGuid _sideB[5];
        ObjectGuid _target;
    };
}

void AddCoaArlokkScripts()
{
    RegisterZulGurubCreatureAI(boss_arlokk_coa);
}
