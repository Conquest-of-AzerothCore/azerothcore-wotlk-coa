/*
 * High Priestess Arlokk with Ascension's spells.
 *
 * Kit: Ascension's block 2118300-2118340. Timings: a Bronzebeard kill on video,
 * see raid-difficulty-werkzeug/zg-video-zeitplan.json. Claw Storm's repeat and
 * Fierce Blow follow the CoA combat log of 2026-08-02.
 *
 * From stock: the prowlers streaming in from both sides, the gong and the
 * despawn when the raid wipes.
 *
 *   Troll form
 *     Shadow Word: Pain  first 2s,  every 20s   the tank
 *     Mark of Arlokk     at 10s                 a player the prowlers hunt;
 *                                               when the mark is gone, it
 *                                               jumps to another player
 *     Kidney Shot        first 15s, every 30s   the tank, 4s stun
 *
 *   Panther form (her Aspect of Bethekk), a 55s cycle
 *     Mark and Vanish    at the change          she marks a player and vanishes
 *                                               for 10s (tester, live)
 *     Shadowstep, Ravage 11s after the change,  behind a random player, then
 *                        every 55s              pins and mauls that player
 *     Shadowstep,        18s after each Ravage  behind a random player, then
 *     Claw Storm                                spins for 8s, 5 yards around her
 *     Vanish             26s after each Ravage  10s out of sight
 *     Razor Claws        passive, her melee hits and Ravage bleed; Claw Storm
 *                        does not (tester, live)
 *
 *   Both forms
 *     Fierce Blow        first 6.7-17.3s, every 6-10s   on the tank
 *
 *   At 50% she drains the Avatar of Bethekk (see LoaAvatar), taking ~1% damage
 *   while it dies, then gains the Gift of the Blood God. At the same moment she
 *   takes panther form for the rest of the fight, with no return to troll form
 *   (tester, live). Her bleeds and marks end with her death, and a player's
 *   Razor Claws bleeds end with that player's death (the DBC keeps them
 *   through death, so a battle-resurrected player bled out again; tester).
 *
 * Decided here, not in the data:
 *   - the panther cycle's timings (the video shows two Ravages, each after a
 *     Shadowstep) and that Ravage hits the player she stepped behind; Kidney
 *     Shot's first cast;
 *   - the mark lasts until it is removed and does not stack; prowlers within
 *     40 yards of the marked player turn on them every 2 seconds.
 */

#include "CreatureScript.h"
#include "GameObject.h"
#include "GlobalScript.h"
#include "InstanceScript.h"
#include "ScriptedCreature.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"

#include <algorithm>
#include <array>
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

        INFO_SHADOW_WORD_PAIN    = 2118301,
        SPELL_SHADOW_WORD_PAIN   = 2118305,
        SPELL_SHADOW_WORD_PAIN_DOT = 2118306,
        SPELL_KIDNEY_SHOT        = 2118307,
        SPELL_SHADOWSTEP         = 2118308,
        SPELL_MARK_OF_ARLOKK     = 2118310,
        SPELL_MARK_OF_ARLOKK_AURA = 2118311,
        SPELL_VANISH             = 2118312,
        SPELL_DRAIN_POWER        = 2118322,
        SPELL_ASPECT_OF_BETHEKK  = 2118323,
        SPELL_GIFT_OF_THE_BLOOD_GOD = 2118324,
        SPELL_RAZOR_CLAWS        = 2118325,
        SPELL_RAZOR_CLAWS_BLEED  = 2118326,
        SPELL_RAVAGE             = 2118330,
        SPELL_RAVAGE_HIT         = 2118331,
        SPELL_CLAW_STORM         = 2118336,
    };

    enum Events
    {
        EVENT_SHADOW_WORD_PAIN = 1,
        EVENT_KIDNEY_SHOT,
        EVENT_MARK_OF_ARLOKK,
        EVENT_MARK_CHECK,
        EVENT_SUMMON_PROWLERS,
        EVENT_VANISH,
        EVENT_REAPPEAR,
        EVENT_STEP_TO_RAVAGE,
        EVENT_STEP_TO_CLAW_STORM,
        EVENT_RAVAGE,
        EVENT_CLAW_STORM,
        EVENT_FIERCE_BLOW,
    };

    enum Phases
    {
        PHASE_ALL   = 0,
        PHASE_ONE   = 1,
        PHASE_TWO   = 2
    };

    constexpr uint32 NPC_AVATAR_OF_BETHEKK = 666988;
    constexpr uint32 WEAPON_DAGGER       = 10616;
    constexpr uint8 MAX_PROWLERS_PER_SIDE = 15;
    constexpr float MARK_PULL_RANGE      = 40.0f;
    constexpr float SHADOWSTEP_RANGE     = 40.0f;

    constexpr Milliseconds VANISH_STEALTH          = 10s;
    constexpr Milliseconds FIRST_PANTHER_STEP      = 11s;
    constexpr Milliseconds CLAW_STORM_AFTER_RAVAGE = 18s;
    constexpr Milliseconds VANISH_AFTER_RAVAGE     = 26s;
    constexpr Milliseconds PANTHER_CYCLE           = 55s;
    constexpr Milliseconds STEP_LANDING            = 250ms;

    constexpr std::array<uint32, 4> RAZOR_CLAWS_BLEEDS = { 2118326, 2118327, 2118328, 2118329 };
    constexpr std::array<uint32, 4> CLAW_STORM_HITS    = { 2118337, 2118338, 2118339, 2118340 };

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
            _drained = false;
            _avatar.Restore(me);
            me->SetReactState(REACT_AGGRESSIVE);
            me->RemoveAurasDueToSpell(SPELL_VANISH);
            me->RemoveAurasDueToSpell(SPELL_GIFT_OF_THE_BLOOD_GOD);
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
            _avatar.Release(me);
            Talk(SAY_DEATH);
            ClearMarks();
            me->GetMap()->DoForAllPlayers([](Player* p)
            {
                for (uint32 bleed : RAZOR_CLAWS_BLEEDS)
                    p->RemoveAurasDueToSpell(bleed);
            });
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            _JustEngagedWith();
            Talk(SAY_AGGRO);
            _avatar.Restore(me);

            events.SetPhase(PHASE_ONE);
            events.ScheduleEvent(EVENT_SHADOW_WORD_PAIN, 2s, 0, PHASE_ONE);
            events.ScheduleEvent(EVENT_KIDNEY_SHOT, 15s, 0, PHASE_ONE);
            events.ScheduleEvent(EVENT_SUMMON_PROWLERS, 6s, 0, PHASE_ALL);
            events.ScheduleEvent(EVENT_MARK_OF_ARLOKK, 10s, 0, PHASE_ALL);
            events.ScheduleEvent(EVENT_FIERCE_BLOW, FIERCE_BLOW_FIRST_MIN, FIERCE_BLOW_FIRST_MAX, 0, PHASE_ALL);

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

        void JustReachedHome() override
        {
            if (GameObject* gong = ObjectAccessor::GetGameObject(*me, instance->GetGuidData(GO_GONG_OF_BETHEKK)))
                gong->RemoveGameObjectFlag(GO_FLAG_NOT_SELECTABLE);
            me->DespawnOrUnsummon();
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            BossAI::EnterEvadeMode(why);
            _avatar.Release(me);
            ClearMarks();
            std::list<Creature*> panthers;
            GetCreatureListWithEntryInGrid(panthers, me, NPC_ZULIAN_PROWLER, 200.0f);
            for (Creature* panther : panthers)
                panther->DespawnOrUnsummon();
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);

            if (_drained || !me->HealthBelowPctDamaged(50, damage))
                return;

            _drained = true;
            if (!_avatar.Drain(me))
                BecomePanther();
        }

        void BecomePanther()
        {
            DoCastSelf(SPELL_GIFT_OF_THE_BLOOD_GOD, true);
            DoCastSelf(SPELL_ASPECT_OF_BETHEKK, true);
            DoCastSelf(SPELL_RAZOR_CLAWS, true);
            me->SetUInt32Value(UNIT_VIRTUAL_ITEM_SLOT_ID + 0, EQUIP_UNEQUIP);
            me->SetUInt32Value(UNIT_VIRTUAL_ITEM_SLOT_ID + 1, EQUIP_UNEQUIP);
            events.SetPhase(PHASE_TWO);
            _marking = true;
            Mark();
            events.ScheduleEvent(EVENT_VANISH, 0ms, 0, PHASE_TWO);
            events.ScheduleEvent(EVENT_STEP_TO_RAVAGE, FIRST_PANTHER_STEP, 0, PHASE_TWO);
        }

        void Vanish()
        {
            me->AttackStop();
            me->SetReactState(REACT_PASSIVE);
            events.ScheduleEvent(EVENT_REAPPEAR, VANISH_STEALTH, 0, PHASE_TWO);
        }

        void Reappear()
        {
            events.CancelEvent(EVENT_REAPPEAR);
            if (!me->HasReactState(REACT_PASSIVE))
                return;
            me->RemoveAurasDueToSpell(SPELL_VANISH);
            me->SetReactState(REACT_AGGRESSIVE);
            if (Unit* target = SelectTarget(SelectTargetMethod::MaxThreat, 0))
                AttackStart(target);
        }

        void StepBehindRandomPlayer(uint32 followUp)
        {
            Reappear();
            _afterStep = followUp;
            if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, SHADOWSTEP_RANGE, true))
            {
                _stepTarget = target->GetGUID();
                DoCast(target, SPELL_SHADOWSTEP);
            }
            else
            {
                _stepTarget = me->GetVictim() ? me->GetVictim()->GetGUID() : ObjectGuid::Empty;
                events.ScheduleEvent(followUp, 0ms, 0, PHASE_TWO);
            }
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
            else if (spell->Id == SPELL_VANISH)
                Vanish();
            else if (spell->Id == SPELL_SHADOWSTEP)
            {
                if (Unit* stepTarget = ObjectAccessor::GetUnit(*me, _stepTarget))
                    AttackStart(stepTarget);
                events.ScheduleEvent(_afterStep, STEP_LANDING, 0, PHASE_TWO);
            }
        }

        void SpellHitTarget(Unit* target, SpellInfo const* spell) override
        {
            if (target && spell->Id == SPELL_RAVAGE_HIT)
                me->CastSpell(target, SPELL_RAZOR_CLAWS_BLEED, true);
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
            ClearMarks();
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

            if (_avatar.Consumed(me))
                BecomePanther();

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
                    case EVENT_VANISH:
                        DoCastSelf(SPELL_VANISH);
                        break;
                    case EVENT_REAPPEAR:
                        Reappear();
                        break;
                    case EVENT_STEP_TO_RAVAGE:
                        StepBehindRandomPlayer(EVENT_RAVAGE);
                        events.ScheduleEvent(EVENT_STEP_TO_CLAW_STORM, CLAW_STORM_AFTER_RAVAGE, 0, PHASE_TWO);
                        events.ScheduleEvent(EVENT_VANISH, VANISH_AFTER_RAVAGE, 0, PHASE_TWO);
                        events.ScheduleEvent(EVENT_STEP_TO_RAVAGE, PANTHER_CYCLE, 0, PHASE_TWO);
                        break;
                    case EVENT_STEP_TO_CLAW_STORM:
                        StepBehindRandomPlayer(EVENT_CLAW_STORM);
                        break;
                    case EVENT_RAVAGE:
                        if (Unit* target = ObjectAccessor::GetUnit(*me, _stepTarget); target && target->IsAlive())
                            DoCast(target, SPELL_RAVAGE, true);
                        else
                            DoCastVictim(SPELL_RAVAGE, true);
                        break;
                    case EVENT_CLAW_STORM:
                        DoCastSelf(SPELL_CLAW_STORM);
                        break;
                    case EVENT_FIERCE_BLOW:
                        DoCastVictim(SPELL_FIERCE_BLOW);
                        events.Repeat(FIERCE_BLOW_MIN, FIERCE_BLOW_MAX);
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
        bool _drained = false;
        LoaAvatar _avatar{ NPC_AVATAR_OF_BETHEKK, SPELL_DRAIN_POWER };
        ObjectGuid _sideA[5];
        ObjectGuid _sideB[5];
        ObjectGuid _target;
        ObjectGuid _stepTarget;
        uint32 _afterStep = EVENT_RAVAGE;
    };

    class spell_arlokk_coa_razor_claws : public AuraScript
    {
        PrepareAuraScript(spell_arlokk_coa_razor_claws);

        bool CheckProc(ProcEventInfo& eventInfo)
        {
            SpellInfo const* spell = eventInfo.GetSpellInfo();
            return !spell || std::find(CLAW_STORM_HITS.begin(), CLAW_STORM_HITS.end(), spell->Id) == CLAW_STORM_HITS.end();
        }

        void Register() override
        {
            DoCheckProc += AuraCheckProcFn(spell_arlokk_coa_razor_claws::CheckProc);
        }
    };

    class ArlokkRazorClawsBleedsEndOnDeath final : public GlobalScript
    {
    public:
        ArlokkRazorClawsBleedsEndOnDeath()
            : GlobalScript("ArlokkRazorClawsBleedsEndOnDeath", { GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR }) { }

        void OnLoadSpellCustomAttr(SpellInfo* info) override
        {
            if (std::find(RAZOR_CLAWS_BLEEDS.begin(), RAZOR_CLAWS_BLEEDS.end(), info->Id) != RAZOR_CLAWS_BLEEDS.end())
                info->AttributesEx3 &= ~SPELL_ATTR3_ALLOW_AURA_WHILE_DEAD;
        }
    };
}

void AddCoaArlokkScripts()
{
    RegisterZulGurubCreatureAI(boss_arlokk_coa);
    RegisterSpellScript(spell_arlokk_coa_razor_claws);
    new ArlokkRazorClawsBleedsEndOnDeath();
}
