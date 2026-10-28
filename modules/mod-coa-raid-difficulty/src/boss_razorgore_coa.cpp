/*
 * Razorgore the Untamed, rebuilt with Ascension's spells.
 *
 * No combat logs exist for Blackwing Lair, so this fight is designed, not
 * measured. The stock choreography stays whole - the Orb of Domination, the
 * eggs, the waves of adds, the switch to phase two when the last egg breaks.
 * What changes is the kit, which is Ascension's (db.exil.es, Spell.dbc), and
 * the timings, set together with the raid designer:
 *
 *   Mortal Cleave      every 8s    set by the designer
 *   War Stomp          every 20s   set by the designer
 *   Fierce Blow        every 8.5s  the Molten Core median
 *   Fireball Storm     every 15s   under its 20s burn, so the burn can stack
 *                                  as its tooltip says it does
 *   Conflagration      every 30s   as in stock
 *   Untamed Fury       once, when the last egg breaks - the tooltip ties it to
 *                      that moment
 *
 * Most of these casts are dummies. On Ascension a server script turned each
 * one into the spell that actually hits, and that script is not in the client.
 * What it must have done is readable from the dummies' own targeting: Fireball
 * Storm reaches every enemy within 200 yards, Mortal Cleave a 10-yard cone in
 * front, Conflagration the target and its allies within 8 yards. This file
 * does the same.
 *
 * Damage per difficulty comes from SpellDifficulty.dbc through the core.
 */

#include "CreatureScript.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "SpellInfo.h"
#include "../../../src/server/scripts/EasternKingdoms/BlackrockMountain/BlackwingLair/blackwing_lair.h"

#include <functional>
#include <vector>

namespace
{
    enum Say
    {
        SAY_EGGS_BROKEN1            = 0,
        SAY_EGGS_BROKEN3            = 2,
        SAY_DEATH                   = 3,
        EMOTE_TROOPS_RETREAT        = 0
    };

    enum Spells
    {
        // stock, the orb and the phase change
        SPELL_MINDCONTROL_VISUAL    = 45537,
        SPELL_MIND_EXHAUSTION       = 23958,
        SPELL_EXPLODE_ORB           = 20037,
        SPELL_EXPLOSION             = 20038,
        SPELL_WARMING_FLAMES        = 23040,

        // Ascension: the cast, then what it stood for
        SPELL_FIERCE_BLOW           = 975011,
        SPELL_FIREBALL_STORM_CAST   = 2110401,
        SPELL_FIREBALL_STORM        = 2110402,
        SPELL_WAR_STOMP_CAST        = 2110406,
        SPELL_WAR_STOMP             = 2110407,
        SPELL_CONFLAGRATION_CAST    = 2110411,
        SPELL_CONFLAGRATE           = 2110412,
        SPELL_MORTAL_CLEAVE_CAST    = 2110417,
        SPELL_MORTAL_CLEAVE         = 2110418,
        SPELL_MORTAL_WOUND          = 2110419,
        SPELL_UNTAMED_FURY          = 2110420,
    };

    enum Events
    {
        EVENT_MORTAL_CLEAVE = 1,
        EVENT_WAR_STOMP,
        EVENT_FIERCE_BLOW,
        EVENT_FIREBALL_STORM,
        EVENT_CONFLAGRATION,
    };

    constexpr float FIREBALL_STORM_RANGE = 200.0f;
    constexpr float CLEAVE_RANGE         = 10.0f;
    constexpr float CLEAVE_ARC           = float(M_PI) / 2;
    constexpr float CONFLAGRATE_RADIUS   = 8.0f;

    struct boss_razorgore_coa : public BossAI
    {
        boss_razorgore_coa(Creature* creature) : BossAI(creature, DATA_RAZORGORE_THE_UNTAMED) { }

        void Reset() override
        {
            _Reset();
            _charmerGUID.Clear();
            _conflagrateTarget.Clear();
            secondPhase = false;
            summons.DespawnAll();
            instance->SetData(DATA_EGG_EVENT, NOT_STARTED);
        }

        void JustDied(Unit* /*killer*/) override
        {
            if (secondPhase)
            {
                _JustDied();
                return;
            }

            // Stock: a death in phase one is a failed attempt; respawn shortly.
            me->SetCorpseRemoveTime(25);
            me->SetRespawnTime(30);
            me->SaveRespawnTime();
            me->SetLootRecipient(nullptr);
            instance->SetData(DATA_EGG_EVENT, FAIL);
        }

        bool CanAIAttack(Unit const* target) const override
        {
            return !(target->IsCreature() && !secondPhase);
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            _JustEngagedWith();

            events.ScheduleEvent(EVENT_MORTAL_CLEAVE, 5s);
            events.ScheduleEvent(EVENT_FIERCE_BLOW, 6s);
            events.ScheduleEvent(EVENT_FIREBALL_STORM, 8s);
            events.ScheduleEvent(EVENT_WAR_STOMP, 12s);
            events.ScheduleEvent(EVENT_CONFLAGRATION, 15s);

            instance->SetData(DATA_EGG_EVENT, IN_PROGRESS);
        }

        void DoChangePhase()
        {
            secondPhase = true;
            _charmerGUID.Clear();
            me->RemoveAllAuras();

            DoCastSelf(SPELL_WARMING_FLAMES, true);
            // "Razorgore falls into a rage over all of his eggs getting destroyed."
            DoCastSelf(SPELL_UNTAMED_FURY, true);

            if (Creature* troops = instance->GetCreature(DATA_NEFARIAN_TROOPS))
                troops->AI()->Talk(EMOTE_TROOPS_RETREAT);

            for (ObjectGuid const& guid : _summonGUIDS)
                if (Creature* creature = ObjectAccessor::GetCreature(*me, guid))
                    if (creature->IsAlive())
                    {
                        creature->CombatStop(true);
                        creature->SetReactState(REACT_PASSIVE);
                        creature->GetMotionMaster()->MovePoint(0, Position(-7560.568848f, -1028.553345f, 408.491211f, 0.523858f));
                    }
        }

        void SetGUID(ObjectGuid const& guid, int32 /*id*/) override
        {
            _charmerGUID = guid;
        }

        void OnCharmed(bool apply) override
        {
            Unit* charmer = ObjectAccessor::GetUnit(*me, _charmerGUID);
            if (!charmer)
                return;

            if (apply)
            {
                charmer->CastSpell(charmer, SPELL_MIND_EXHAUSTION, true);
                charmer->CastSpell(me, SPELL_MINDCONTROL_VISUAL, false);
            }
            else
            {
                charmer->RemoveAurasDueToSpell(SPELL_MINDCONTROL_VISUAL);
                me->EngageWithTarget(charmer);
                me->AddThreat(charmer, 100.0f);
                me->AI()->AttackStart(charmer);
            }
        }

        void DoAction(int32 action) override
        {
            if (action == ACTION_PHASE_TWO)
                DoChangePhase();

            if (action == TALK_EGG_BROKEN_RAND)
                Talk(urand(SAY_EGGS_BROKEN1, SAY_EGGS_BROKEN3));
        }

        void JustSummoned(Creature* summon) override
        {
            _summonGUIDS.push_back(summon->GetGUID());
            summon->SetOwnerGUID(me->GetGUID());
            summons.Summon(summon);
        }

        void SummonMovementInform(Creature* summon, uint32 movementType, uint32 /*pathId*/) override
        {
            if (movementType == POINT_MOTION_TYPE)
                summon->DespawnOrUnsummon();
        }

        void DamageTaken(Unit*, uint32& damage, DamageEffectType, SpellSchoolMask) override
        {
            if (!secondPhase && damage >= me->GetHealth())
            {
                Talk(SAY_DEATH);
                DoCastAOE(SPELL_EXPLODE_ORB);
                DoCastAOE(SPELL_EXPLOSION);
            }
        }

        // Every living player the predicate accepts.
        std::vector<Player*> Players(std::function<bool(Player*)> const& accept)
        {
            std::vector<Player*> out;
            me->GetMap()->DoForAllPlayers([&](Player* player)
            {
                if (player->IsAlive() && !player->IsGameMaster() && accept(player))
                    out.push_back(player);
            });
            return out;
        }

        // A dummy finished casting: do what Ascension's script did with it.
        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            switch (spell->Id)
            {
                case SPELL_FIREBALL_STORM_CAST:
                    for (Player* player : Players([&](Player* p) { return me->IsWithinDistInMap(p, FIREBALL_STORM_RANGE); }))
                        me->CastSpell(player, SPELL_FIREBALL_STORM, true);
                    break;
                case SPELL_WAR_STOMP_CAST:
                    me->CastSpell(me, SPELL_WAR_STOMP, true);
                    break;
                case SPELL_MORTAL_CLEAVE_CAST:
                    for (Player* player : Players([&](Player* p)
                        { return me->IsWithinDistInMap(p, CLEAVE_RANGE) && me->isInFront(p, CLEAVE_ARC); }))
                    {
                        me->CastSpell(player, SPELL_MORTAL_CLEAVE, true);
                        me->CastSpell(player, SPELL_MORTAL_WOUND, true);
                    }
                    break;
                case SPELL_CONFLAGRATION_CAST:
                    if (Unit* target = ObjectAccessor::GetUnit(*me, _conflagrateTarget))
                        for (Player* player : Players([&](Player* p)
                            { return p == target || p->IsWithinDistInMap(target, CONFLAGRATE_RADIUS); }))
                            me->CastSpell(player, SPELL_CONFLAGRATE, true);
                    _conflagrateTarget.Clear();
                    break;
                default:
                    break;
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            if (!me->IsCharmed())
                events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_MORTAL_CLEAVE:
                        DoCastVictim(SPELL_MORTAL_CLEAVE_CAST);
                        events.ScheduleEvent(EVENT_MORTAL_CLEAVE, 8s);
                        break;
                    case EVENT_WAR_STOMP:
                        DoCastVictim(SPELL_WAR_STOMP_CAST);
                        events.ScheduleEvent(EVENT_WAR_STOMP, 20s);
                        break;
                    case EVENT_FIERCE_BLOW:
                        DoCastVictim(SPELL_FIERCE_BLOW);
                        events.ScheduleEvent(EVENT_FIERCE_BLOW, 8500ms);
                        break;
                    case EVENT_FIREBALL_STORM:
                        DoCastVictim(SPELL_FIREBALL_STORM_CAST);
                        events.ScheduleEvent(EVENT_FIREBALL_STORM, 15s);
                        break;
                    case EVENT_CONFLAGRATION:
                        // A random player other than the tank; the tank if alone.
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 0.0f, true, false))
                        {
                            _conflagrateTarget = target->GetGUID();
                            DoCast(target, SPELL_CONFLAGRATION_CAST);
                        }
                        else if (Unit* victim = me->GetVictim())
                        {
                            _conflagrateTarget = victim->GetGUID();
                            DoCast(victim, SPELL_CONFLAGRATION_CAST);
                        }
                        events.ScheduleEvent(EVENT_CONFLAGRATION, 30s);
                        break;
                }

                // One cast at a time; a second would cut the first short.
                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    private:
        bool secondPhase = false;
        ObjectGuid _charmerGUID;
        ObjectGuid _conflagrateTarget;
        GuidVector _summonGUIDS;
    };
}

void AddCoaRazorgoreScripts()
{
    RegisterBlackwingLairCreatureAI(boss_razorgore_coa);
}
