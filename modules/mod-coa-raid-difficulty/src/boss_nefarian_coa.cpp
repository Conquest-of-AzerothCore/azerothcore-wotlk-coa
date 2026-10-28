/*
 * Lord Victor Nefarius and Nefarian as Ascension rebuilt them.
 *
 * No combat logs exist for Blackwing Lair. The kit is Ascension's (db.exil.es
 * lists it under Nefarius, the DBC block 2111200-2111291 holds it); how it is
 * put together was left to me by the raid designer, and every such choice is
 * named below.
 *
 * The stock choreography stays: the gossip, the 42 drakonids from two tunnels,
 * Nefarian flying in, landing, and raising the bones at 20%. The Upper
 * Blackrock Spire event of the same Nefarius stays untouched as well.
 *
 * Phase 1, Lord Victor Nefarius (kit from the DBC, timings mine):
 *   Shadow Bolt              every 4s    3s cast on a random player; 2600 on
 *                                        Normal from his own damage-info aura
 *   Massive Shadow Flame Bolt every 20s  4s cast; 8-yard blast, burning ground,
 *                                        Shadow Flame on everyone hit
 *   Dark Volley              every 25s   10s of dark missiles raining down
 *   Nefarius' Intent         every 30s   30s curse on everyone: shadow damage,
 *                                        halved healing, and a Veil of Shadow
 *                                        that eats healing. Healing through the
 *                                        veil breaks the curse.
 *   "Stupid, Incompetent and Disappointing Minion"
 *                            every 30s   a random player falls under his control
 *                                        for 15s and cannot die meanwhile
 *   Shadow Prison            every 60s   8s cast - interrupt it, or everyone is
 *                                        disabled for 10s
 *   Blink                    every 30s
 *
 * Phase 2, Nefarian:
 *   Shadow Flame Breath      every 20s   six pulses in a cone, a stack of Shadow
 *                                        Flame each; the Black Dragon Scale Cloak
 *                                        keeps its wearer from catching the stacks.
 *                                        Every finished breath gives him a stack
 *                                        of Nefarian's Resolve: +3% damage dealt
 *                                        and taken.
 *   Bellowing Roar           every 30s   5s cast, then the raid-wide fear
 *   Draconic Cleave          every 8s    Tail Sweep every 20s  Fierce Blow every 8.5s
 *   Dominion                 every 45s   three players lose their soul to a Shadow
 *                                        Clone for 45s. The clone fights the raid,
 *                                        and whatever it is hit for lands on its
 *                                        owner instead. This replaces the class
 *                                        calls, which could not cover the CoA
 *                                        classes anyway.
 *   Berserk                  after 10 minutes of phase 2
 *
 * Phase 3, at 20%: the raised bones march as the Risen Shadow Flame Legion,
 * leaving burning ground and getting faster every second.
 *
 * Damage per difficulty: SpellDifficulty.dbc where the DBC has tier rows, and
 * 20:27:34:40 on top of Normal for the hits it leaves to a script.
 */

#include "CreatureScript.h"
#include "GameObject.h"
#include "InstanceScript.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "TemporarySummon.h"
#include "../../../src/server/scripts/EasternKingdoms/BlackrockMountain/BlackwingLair/blackwing_lair.h"

#include <algorithm>
#include <array>
#include <functional>
#include <list>
#include <vector>

namespace
{
    enum Events
    {
        // Nefarius, UBRS (stock)
        EVENT_PATH_2 = 1,
        EVENT_CHAOS_1,
        EVENT_CHAOS_2,
        EVENT_SUCCESS_1,
        EVENT_SUCCESS_2,
        EVENT_PATH_3,
        EVENT_START_EVENT,
        EVENT_SPAWN_ADDS,

        // Nefarius, BWL
        EVENT_SHADOW_BOLT,
        EVENT_SHADOW_FLAME_BOLT,
        EVENT_DARK_VOLLEY,
        EVENT_INTENT,
        EVENT_MINION,
        EVENT_SHADOW_PRISON,
        EVENT_BLINK,

        // Nefarian
        EVENT_BREATH,
        EVENT_ROAR,
        EVENT_CLEAVE,
        EVENT_TAIL_SWEEP,
        EVENT_FIERCE_BLOW,
        EVENT_DOMINION,
        EVENT_BERSERK,
        EVENT_BREATH_PULSE,
        EVENT_LEGION,
        EVENT_MARCH,
    };

    enum Actions
    {
        ACTION_RESET        = 0,
        ACTION_ADD_KILLED   = 2,
        ACTION_SPAWNER_STOP = 3,
    };

    enum Says
    {
        SAY_CHAOS_SPELL     = 9,
        SAY_SUCCESS         = 10,
        SAY_GAMESBEGIN_1    = 12,
        SAY_GAMESBEGIN_2    = 13,

        SAY_INTRO           = 0,
        SAY_RAISE_SKELETONS = 1,
        SAY_SLAY            = 2,
        SAY_DEATH           = 3,
        SAY_XHEALTH         = 14,
        SAY_SHADOWFLAME     = 15,
    };

    enum Spells
    {
        // stock, kept for the choreography
        SPELL_CHROMATIC_CHAOS       = 16337,
        SPELL_VAELASTRASZZ_SPAWN    = 16354,
        SPELL_NEFARIANS_BARRIER     = 22663,
        SPELL_ROOT_SELF             = 17507,
        SPELL_SHADOWFLAME_INITIAL   = 22992,
        SPELL_RAISE_DRAKONID        = 23362,
        SPELL_SHADOW_COMMAND        = 22667,    // the mind control itself
        SPELL_BELLOWING_ROAR_FEAR   = 22686,
        SPELL_ONYXIA_SCALE_CLOAK    = 22683,

        // Ascension
        SPELL_FIERCE_BLOW           = 975011,
        SPELL_SHADOW_BOLT_CAST      = 2111205,
        SPELL_SHADOW_BOLT_HIT       = 2111201,  // carries the damage info; cast with a custom value
        SPELL_BLINK                 = 2111207,
        SPELL_DARK_VOLLEY           = 2111210,
        SPELL_MINION_CONTROL        = 2111217,
        SPELL_MINION_PROTECT        = 2111219,
        SPELL_SHADOW_PRISON         = 2111240,
        SPELL_SHADOW_FLAME_BOLT_CAST= 2111242,
        SPELL_SHADOW_FLAME_BOLT     = 2111244,
        SPELL_BURNING_GROUND        = 2111248,
        SPELL_BREATH_CAST           = 2111252,
        SPELL_BREATH_HIT            = 2111254,
        SPELL_SHADOW_FLAME          = 2111258,
        SPELL_SCALE_CLOAK           = 2111263,
        SPELL_CLEAVE_CAST           = 2111265,
        SPELL_CLEAVE                = 2111266,
        SPELL_TAIL_SWEEP_HIT        = 2111268,
        SPELL_BELLOWING_ROAR_CAST   = 2111273,
        SPELL_CLONE_ME              = 2111280,
        SPELL_MIMIC_TARGET          = 2111281,
        SPELL_SPIRITUAL_PAIN        = 2111282,
        SPELL_INTENT                = 2111284,
        SPELL_VEIL_OF_SHADOW        = 2111288,
        SPELL_LEGION                = 2111290,
        SPELL_MARCH                 = 2111291,
        SPELL_RESOLVE               = 2111585,
        SPELL_BERSERK               = 2100213,
    };

    enum Misc
    {
        GOSSIP_ID               = 21332,
        GOSSIP_OPTION_ID        = 0,
        NEFARIUS_PATH_2         = 1379671,
        NEFARIUS_PATH_3         = 1379672,
        NEFARIAN_PATH           = 11583,
        GO_DRAKONID_BONES       = 179804,
        GO_PORTCULLIS_ACTIVE    = 164726,
        GO_PORTCULLIS_TOBOSSROOMS = 175186,
        NPC_GYTH                = 10339,
        NPC_SHADOW_CLONE        = 9780021,
        MAX_DRAKONID_KILLED     = 42,
    };

    Position const spawnerPositions[2] =
    {
        {-7599.32f, -1191.72f, 475.545f, 3.05f},
        {-7526.27f, -1135.04f, 473.445f, 5.76f}
    };
    Position const NefarianSpawn = { -7348.849f, -1495.134f, 552.5152f, 1.798f };

    constexpr uint32 SHADOW_BOLT_BASE = 2600;   // his "Shadow Bolt Damage Info" aura
    constexpr std::array<float, 4> TIER = { 1.0f, 1.35f, 1.7f, 2.0f };
    constexpr float CONE_ARC        = float(M_PI) / 2;
    constexpr float BREATH_RANGE    = 30.0f;
    constexpr float CLEAVE_RANGE    = 20.0f;
    constexpr float TAIL_RANGE      = 30.0f;
    constexpr float BOLT_RADIUS     = 8.0f;
    constexpr uint8 BREATH_PULSES   = 6;
    constexpr uint8 DOMINION_COUNT  = 3;
    constexpr int32 SHADOW_FLAME_MAX= 100;

    int32 Scaled(Unit* caster, uint32 base)
    {
        uint8 const mode = uint8(caster->GetMap()->GetSpawnMode());
        return int32(base * TIER[std::min<uint8>(mode, 3)]);
    }

    void AddStack(Unit* caster, Unit* target, uint32 spellId, int32 max)
    {
        uint32 const id = sSpellMgr->GetSpellIdForDifficulty(spellId, caster);
        Aura* aura = target->GetAura(id);
        if (!aura)
        {
            caster->CastSpell(target, id, true);
            return;
        }
        aura->SetStackAmount(uint8(std::min<int32>(aura->GetStackAmount() + 1, max)));
        aura->RefreshDuration();
    }

    std::vector<Player*> PlayersOf(Creature* me, std::function<bool(Player*)> const& accept)
    {
        std::vector<Player*> out;
        me->GetMap()->DoForAllPlayers([&](Player* player)
        {
            if (player->IsAlive() && !player->IsGameMaster() && accept(player))
                out.push_back(player);
        });
        return out;
    }

    // ------------------------------------------------------------ Nefarius
    struct boss_victor_nefarius_coa : public BossAI
    {
        boss_victor_nefarius_coa(Creature* creature) : BossAI(creature, DATA_NEFARIAN)
        {
            _killedAdds = 0;
            _right = instance->GetData(DATA_NEFARIAN_RIGHT_TUNNEL);
            _left = instance->GetData(DATA_NEFARIAN_LEFT_TUNNEL);
            if (!_left || !_right)
            {
                // Stock weekly mechanic: two drakonid colours for the whole save.
                std::vector<uint32> spawners = { NPC_BLACK_SPAWNER, NPC_BLUE_SPAWNER, NPC_BRONZE_SPAWNER, NPC_GREEN_SPAWNER, NPC_RED_SPAWNER };
                Acore::Containers::RandomResize(spawners, 2);
                _right = spawners[0];
                _left = spawners[1];
                instance->SetData(DATA_NEFARIAN_LEFT_TUNNEL, _left);
                instance->SetData(DATA_NEFARIAN_RIGHT_TUNNEL, _right);
            }
        }

        void Reset() override
        {
            _killedAdds = 0;
            if (me->GetMapId() != MAP_BLACKWING_LAIR)
                return;

            if (Creature* nefarian = me->FindNearestCreature(NPC_NEFARIAN, 1000.0f, true))
            {
                if (nefarian->GetMotionMaster()->GetCurrentMovementGeneratorType() == WAYPOINT_MOTION_TYPE)
                    nefarian->DespawnOrUnsummon();
                std::list<GameObject*> bones;
                me->GetGameObjectListWithEntryInGrid(bones, GO_DRAKONID_BONES, DEFAULT_VISIBILITY_INSTANCE);
                for (GameObject* b : bones)
                    b->DespawnOrUnsummon();
            }
            else
                _Reset();

            me->SetVisible(true);
            me->SetPhaseMask(1, true);
            me->SetNpcFlag(UNIT_NPC_FLAG_GOSSIP);
            me->SetFaction(FACTION_FRIENDLY);
            me->SetStandState(UNIT_STAND_STATE_SIT_HIGH_CHAIR);
            me->RemoveAura(SPELL_NEFARIANS_BARRIER);
            me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        }

        void JustReachedHome() override { Reset(); }

        void JustSummoned(Creature* summon) override
        {
            if (summon->GetEntry() != NPC_NEFARIAN)
                BossAI::JustSummoned(summon);
        }

        void SummonedCreatureDies(Creature* summon, Unit* /*unit*/) override
        {
            if (summon->GetEntry() == NPC_NEFARIAN)
            {
                summons.DespawnEntry(_left);
                summons.DespawnEntry(_right);
                me->KillSelf();
            }
        }

        void DoAction(int32 action) override
        {
            if (action == ACTION_RESET)
            {
                me->RemoveAura(SPELL_ROOT_SELF);
                summons.DespawnAll();
            }

            if (action == ACTION_ADD_KILLED && ++_killedAdds == MAX_DRAKONID_KILLED)
            {
                if (Creature* nefarian = me->SummonCreature(NPC_NEFARIAN, NefarianSpawn))
                {
                    nefarian->setActive(true);
                    nefarian->SetCanFly(true);
                    nefarian->SetDisableGravity(true);
                    nefarian->GetMotionMaster()->MoveWaypoint(NEFARIAN_PATH, false);
                }
                events.Reset();
                me->InterruptNonMeleeSpells(false);
                DoCastSelf(SPELL_ROOT_SELF, true);
                me->SetVisible(false);
                EntryCheckPredicate right(_right);
                summons.DoAction(ACTION_SPAWNER_STOP, right);
                EntryCheckPredicate left(_left);
                summons.DoAction(ACTION_SPAWNER_STOP, left);
            }
        }

        void JustDied(Unit* /*killer*/) override
        {
            instance->SetBossState(DATA_NEFARIAN, DONE);
            instance->SaveToDB();
        }

        void BeginEvent()
        {
            _JustEngagedWith();
            Talk(SAY_GAMESBEGIN_2);
            DoCast(me, SPELL_NEFARIANS_BARRIER);
            me->SetCombatMovement(false);
            me->SetImmuneToPC(false);
            AttackStart(SelectTarget(SelectTargetMethod::Random, 0, 200.f, true));

            events.ScheduleEvent(EVENT_BLINK, 500ms);
            events.ScheduleEvent(EVENT_SHADOW_BOLT, 3s);
            events.ScheduleEvent(EVENT_SPAWN_ADDS, 10s);
            events.ScheduleEvent(EVENT_SHADOW_FLAME_BOLT, 20s);
            events.ScheduleEvent(EVENT_DARK_VOLLEY, 25s);
            events.ScheduleEvent(EVENT_INTENT, 30s);
            events.ScheduleEvent(EVENT_MINION, 35s);
            events.ScheduleEvent(EVENT_SHADOW_PRISON, 60s);
        }

        void SetData(uint32 type, uint32 data) override
        {
            if (type == 1 && data == 1)
            {
                me->StopMoving();
                events.ScheduleEvent(EVENT_PATH_2, 9s);
            }
            if (type == 1 && data == 2)
                events.ScheduleEvent(EVENT_SUCCESS_1, 5s);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            if (spell->Id == SPELL_SHADOW_BOLT_CAST)
            {
                if (Unit* target = ObjectAccessor::GetUnit(*me, _boltTarget))
                {
                    int32 damage = Scaled(me, SHADOW_BOLT_BASE);
                    me->CastCustomSpell(target, SPELL_SHADOW_BOLT_HIT, &damage, nullptr, nullptr, true);
                }
            }
            else if (spell->Id == SPELL_SHADOW_FLAME_BOLT_CAST)
            {
                me->CastSpell(_boltSpot.GetPositionX(), _boltSpot.GetPositionY(), _boltSpot.GetPositionZ(), SPELL_SHADOW_FLAME_BOLT, true);
                me->CastSpell(_boltSpot.GetPositionX(), _boltSpot.GetPositionY(), _boltSpot.GetPositionZ(), SPELL_BURNING_GROUND, true);
                for (Player* p : PlayersOf(me, [&](Player* x) { return x->IsWithinDist3d(&_boltSpot, BOLT_RADIUS); }))
                    AddStack(me, p, SPELL_SHADOW_FLAME, SHADOW_FLAME_MAX);
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
            {
                // The Upper Blackrock Spire event, unchanged.
                events.Update(diff);
                while (uint32 eventId = events.ExecuteEvent())
                {
                    switch (eventId)
                    {
                        case EVENT_PATH_2:
                            me->GetMotionMaster()->MoveWaypoint(NEFARIUS_PATH_2, false);
                            events.ScheduleEvent(EVENT_CHAOS_1, 7s);
                            break;
                        case EVENT_CHAOS_1:
                            if (Creature* gyth = me->FindNearestCreature(NPC_GYTH, 75.0f, true))
                            {
                                me->SetFacingToObject(gyth);
                                Talk(SAY_CHAOS_SPELL);
                            }
                            events.ScheduleEvent(EVENT_CHAOS_2, 2s);
                            break;
                        case EVENT_CHAOS_2:
                            DoCast(SPELL_CHROMATIC_CHAOS);
                            me->SetFacingTo(1.570796f);
                            break;
                        case EVENT_SUCCESS_1:
                            if (Unit* player = me->SelectNearestPlayer(60.0f))
                            {
                                me->SetFacingToObject(player);
                                Talk(SAY_SUCCESS);
                                if (GameObject* p1 = me->FindNearestGameObject(GO_PORTCULLIS_ACTIVE, 65.0f))
                                    p1->SetGoState(GO_STATE_ACTIVE);
                                if (GameObject* p2 = me->FindNearestGameObject(GO_PORTCULLIS_TOBOSSROOMS, 80.0f))
                                    p2->SetGoState(GO_STATE_ACTIVE);
                            }
                            events.ScheduleEvent(EVENT_SUCCESS_2, 4s);
                            break;
                        case EVENT_SUCCESS_2:
                            DoCast(me, SPELL_VAELASTRASZZ_SPAWN);
                            me->DespawnOrUnsummon(1s);
                            break;
                        case EVENT_PATH_3:
                            me->GetMotionMaster()->MoveWaypoint(NEFARIUS_PATH_3, false);
                            break;
                        case EVENT_START_EVENT:
                            BeginEvent();
                            break;
                    }
                }
                return;
            }

            if (_killedAdds >= MAX_DRAKONID_KILLED)
                return;

            events.Update(diff);
            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_SHADOW_BOLT:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 150.0f, true))
                        {
                            _boltTarget = target->GetGUID();
                            DoCast(target, SPELL_SHADOW_BOLT_CAST);
                        }
                        events.ScheduleEvent(EVENT_SHADOW_BOLT, 4s);
                        break;
                    case EVENT_SHADOW_FLAME_BOLT:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 150.0f, true))
                        {
                            _boltSpot = target->GetPosition();
                            DoCast(target, SPELL_SHADOW_FLAME_BOLT_CAST);
                        }
                        events.ScheduleEvent(EVENT_SHADOW_FLAME_BOLT, 20s);
                        break;
                    case EVENT_DARK_VOLLEY:
                        DoCastVictim(SPELL_DARK_VOLLEY);
                        events.ScheduleEvent(EVENT_DARK_VOLLEY, 25s);
                        break;
                    case EVENT_INTENT:
                        DoCastSelf(SPELL_INTENT, true);
                        events.ScheduleEvent(EVENT_INTENT, 30s);
                        break;
                    case EVENT_MINION:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 40.0f, true))
                        {
                            DoCast(target, SPELL_SHADOW_COMMAND, true);
                            me->CastSpell(target, SPELL_MINION_CONTROL, true);
                            me->CastSpell(target, SPELL_MINION_PROTECT, true);
                        }
                        events.ScheduleEvent(EVENT_MINION, 30s);
                        break;
                    case EVENT_SHADOW_PRISON:
                        DoCastSelf(SPELL_SHADOW_PRISON);
                        events.ScheduleEvent(EVENT_SHADOW_PRISON, 60s);
                        break;
                    case EVENT_BLINK:
                        DoCastSelf(SPELL_BLINK);
                        events.ScheduleEvent(EVENT_BLINK, 30s);
                        break;
                    case EVENT_SPAWN_ADDS:
                        me->SummonCreature(_left, spawnerPositions[0]);
                        me->SummonCreature(_right, spawnerPositions[1]);
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    return;
            }
        }

        void sGossipSelect(Player* player, uint32 sender, uint32 action) override
        {
            if (sender != GOSSIP_ID || action != GOSSIP_OPTION_ID)
                return;
            InstanceScript* inst = player->GetInstanceScript();
            if (!inst || inst->GetBossState(DATA_NEFARIAN) == DONE)
                return;

            CloseGossipMenuFor(player);
            Talk(SAY_GAMESBEGIN_1);
            events.ScheduleEvent(EVENT_START_EVENT, 4s);
            me->SetFaction(FACTION_DRAGONFLIGHT_BLACK);
            me->RemoveNpcFlag(UNIT_NPC_FLAG_GOSSIP);
            me->SetStandState(UNIT_STAND_STATE_STAND);
            me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
            me->SetImmuneToPC(true);
        }

    private:
        uint32 _killedAdds;
        uint32 _right;
        uint32 _left;
        ObjectGuid _boltTarget;
        Position _boltSpot;
    };

    // ------------------------------------------------------------ Nefarian
    struct boss_nefarian_coa : public BossAI
    {
        boss_nefarian_coa(Creature* creature) : BossAI(creature, DATA_NEFARIAN) { }

        void Reset() override
        {
            me->SetReactState(REACT_PASSIVE);
            me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
            me->SetCanFly(true);
            me->SetDisableGravity(true);
            _clock.Reset();
            _legion.clear();
            if (_introDone)
            {
                _Reset();
                if (Creature* victor = me->FindNearestCreature(NPC_VICTOR_NEFARIUS, 200.f, true))
                    if (victor->AI())
                        victor->AI()->DoAction(ACTION_RESET);
                me->DespawnOrUnsummon();
            }

            ScheduleHealthCheckEvent(20, [&]
            {
                DoCastSelf(SPELL_RAISE_DRAKONID, true);
                Talk(SAY_RAISE_SKELETONS);
                _clock.ScheduleEvent(EVENT_LEGION, 2s);
            });
            ScheduleHealthCheckEvent(5, [&] { Talk(SAY_XHEALTH); });
        }

        void JustEngagedWith(Unit* /*who*/) override { }

        void JustDied(Unit* /*killer*/) override
        {
            _JustDied();
            Talk(SAY_DEATH);
        }

        void KilledUnit(Unit* victim) override
        {
            if (!(rand32() % 5))
                Talk(SAY_SLAY, victim);
        }

        void JustSummoned(Creature* summon) override
        {
            BossAI::JustSummoned(summon);
            if (summon->GetEntry() == NPC_BONE_CONSTRUCT)
                MakeLegion(summon);
        }

        // Phase 3: the raised bones march as the Risen Shadow Flame Legion.
        void MakeLegion(Creature* risen)
        {
            if (std::find(_legion.begin(), _legion.end(), risen->GetGUID()) != _legion.end())
                return;
            risen->CastSpell(risen, SPELL_LEGION, true);
            _legion.push_back(risen->GetGUID());
            if (!_clock.HasTimeUntilEvent(EVENT_MARCH))
                _clock.ScheduleEvent(EVENT_MARCH, 1s);
        }

        void MovementInform(uint32 type, uint32 id) override
        {
            if (type != WAYPOINT_MOTION_TYPE)
                return;
            if (id == 4)
                Talk(SAY_INTRO);
            if (id == 6)
            {
                DoCastAOE(SPELL_SHADOWFLAME_INITIAL);
                Talk(SAY_SHADOWFLAME);
            }
        }

        void PathEndReached(uint32 /*pathId*/) override
        {
            me->HandleEmoteCommand(EMOTE_ONESHOT_LAND);
            me->SetCanFly(false);
            me->SetDisableGravity(false);
            Position land = me->GetPosition();
            me->GetMotionMaster()->MoveLand(0, land, 8.5f);
            me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
            me->GetMotionMaster()->MoveIdle();
            me->SetReactState(REACT_AGGRESSIVE);
            DoZoneInCombat();
            if (me->GetVictim())
                AttackStart(me->GetVictim());

            events.ScheduleEvent(EVENT_FIERCE_BLOW, 6s);
            events.ScheduleEvent(EVENT_CLEAVE, 8s);
            events.ScheduleEvent(EVENT_BREATH, 12s);
            events.ScheduleEvent(EVENT_TAIL_SWEEP, 20s);
            events.ScheduleEvent(EVENT_ROAR, 30s);
            events.ScheduleEvent(EVENT_DOMINION, 45s);
            events.ScheduleEvent(EVENT_BERSERK, 10min);
            _introDone = true;
        }

        bool Cloaked(Player* p) const
        {
            return p->HasAura(SPELL_ONYXIA_SCALE_CLOAK) || p->HasAura(SPELL_SCALE_CLOAK);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            switch (spell->Id)
            {
                case SPELL_BREATH_CAST:
                    _pulses = BREATH_PULSES;
                    _clock.ScheduleEvent(EVENT_BREATH_PULSE, 0ms);
                    break;
                case SPELL_BELLOWING_ROAR_CAST:
                    DoCastAOE(SPELL_BELLOWING_ROAR_FEAR, true);
                    break;
                case SPELL_CLEAVE_CAST:
                    for (Player* p : PlayersOf(me, [&](Player* x) { return me->IsWithinDistInMap(x, CLEAVE_RANGE) && me->isInFront(x, CONE_ARC); }))
                        me->CastSpell(p, SPELL_CLEAVE, true);
                    break;
                default:
                    break;
            }
        }

        void BreathPulse()
        {
            for (Player* p : PlayersOf(me, [&](Player* x) { return me->IsWithinDistInMap(x, BREATH_RANGE) && me->isInFront(x, CONE_ARC); }))
            {
                me->CastSpell(p, SPELL_BREATH_HIT, true);
                if (!Cloaked(p))
                    AddStack(me, p, SPELL_SHADOW_FLAME, SHADOW_FLAME_MAX);
            }
            if (--_pulses)
                _clock.ScheduleEvent(EVENT_BREATH_PULSE, 500ms);
            else
                AddStack(me, me, SPELL_RESOLVE, 100);   // one per finished breath
        }

        void TailSweep()
        {
            for (Player* p : PlayersOf(me, [&](Player* x) { return me->IsWithinDistInMap(x, TAIL_RANGE) && !me->isInFront(x, float(M_PI) * 1.5f); }))
            {
                me->CastSpell(p, SPELL_TAIL_SWEEP_HIT, true);
                p->KnockbackFrom(me->GetPositionX(), me->GetPositionY(), 15.0f, 7.0f);
            }
        }

        void Dominion()
        {
            std::vector<Player*> pool = PlayersOf(me, [&](Player* x) { return x != me->GetVictim(); });
            Acore::Containers::RandomResize(pool, DOMINION_COUNT);
            for (Player* p : pool)
            {
                Position pos = p->GetPosition();
                if (Creature* clone = me->SummonCreature(NPC_SHADOW_CLONE, pos, TEMPSUMMON_TIMED_DESPAWN, 45000))
                {
                    clone->AI()->SetGUID(p->GetGUID(), 0);
                    me->CastSpell(p, SPELL_MIMIC_TARGET, true);
                }
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            events.Update(diff);
            _clock.Update(diff);

            while (uint32 tick = _clock.ExecuteEvent())
            {
                switch (tick)
                {
                    case EVENT_BREATH_PULSE:
                        BreathPulse();
                        break;
                    case EVENT_LEGION:
                    {
                        std::list<Creature*> risen;
                        me->GetCreatureListWithEntryInGrid(risen, NPC_BONE_CONSTRUCT, 200.0f);
                        for (Creature* c : risen)
                            if (c->IsAlive())
                                MakeLegion(c);
                        break;
                    }
                    case EVENT_MARCH:
                        // "During his march the Fallen Hero accelerates."
                        for (ObjectGuid const& guid : _legion)
                            if (Creature* c = ObjectAccessor::GetCreature(*me, guid))
                                if (c->IsAlive())
                                    AddStack(c, c, SPELL_MARCH, 100);
                        _clock.ScheduleEvent(EVENT_MARCH, 1s);
                        break;
                }
            }

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_FIERCE_BLOW:
                        DoCastVictim(SPELL_FIERCE_BLOW);
                        events.ScheduleEvent(EVENT_FIERCE_BLOW, 8500ms);
                        break;
                    case EVENT_CLEAVE:
                        DoCastVictim(SPELL_CLEAVE_CAST);
                        events.ScheduleEvent(EVENT_CLEAVE, 8s);
                        break;
                    case EVENT_BREATH:
                        DoCastVictim(SPELL_BREATH_CAST);
                        events.ScheduleEvent(EVENT_BREATH, 20s);
                        break;
                    case EVENT_TAIL_SWEEP:
                        TailSweep();
                        events.ScheduleEvent(EVENT_TAIL_SWEEP, 20s);
                        break;
                    case EVENT_ROAR:
                        DoCastSelf(SPELL_BELLOWING_ROAR_CAST);
                        events.ScheduleEvent(EVENT_ROAR, 30s);
                        break;
                    case EVENT_DOMINION:
                        Dominion();
                        events.ScheduleEvent(EVENT_DOMINION, 45s);
                        break;
                    case EVENT_BERSERK:
                        DoCastSelf(SPELL_BERSERK, true);
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    private:
        bool _introDone = false;
        uint8 _pulses = 0;
        EventMap _clock;
        std::vector<ObjectGuid> _legion;
    };

    /*
     * A Shadow Clone from Dominion. It wears its owner's shape and fights the
     * raid for 45 seconds. Damage it takes is not its own: Spiritual Pain
     * hands every hit on to the owner, and the clone keeps its health.
     */
    struct npc_nefarian_shadow_clone : public ScriptedAI
    {
        npc_nefarian_shadow_clone(Creature* creature) : ScriptedAI(creature) { }

        void SetGUID(ObjectGuid const& guid, int32 /*id*/) override
        {
            _owner = guid;
            Player* owner = ObjectAccessor::GetPlayer(*me, _owner);
            if (!owner)
                return;

            me->SetDisplayId(owner->GetDisplayId());
            me->SetMaxHealth(owner->GetMaxHealth());
            me->SetFullHealth();
            me->CastSpell(me, SPELL_CLONE_ME, true);
            DoZoneInCombat();
            if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                AttackStart(target);
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType, SpellSchoolMask) override
        {
            if (!damage)
                return;
            if (Player* owner = ObjectAccessor::GetPlayer(*me, _owner))
                if (owner->IsAlive() && attacker != owner)
                {
                    int32 pain = int32(damage);
                    me->CastCustomSpell(owner, SPELL_SPIRITUAL_PAIN, &pain, nullptr, nullptr, true);
                }
            damage = 0;
        }

        void UpdateAI(uint32 /*diff*/) override
        {
            if (!UpdateVictim())
                return;
            DoMeleeAttackIfReady();
        }

    private:
        ObjectGuid _owner;
    };

    // Healing through the Veil of Shadow breaks Nefarius' Intent.
    class spell_nefarius_coa_veil : public AuraScript
    {
        PrepareAuraScript(spell_nefarius_coa_veil);

        void AfterRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_ENEMY_SPELL)
                if (Unit* target = GetTarget())
                    target->RemoveAurasDueToSpell(SPELL_INTENT);
        }

        void Register() override
        {
            AfterEffectRemove += AuraEffectRemoveFn(spell_nefarius_coa_veil::AfterRemove, EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
        }
    };
}

void AddCoaNefarianScripts()
{
    RegisterBlackwingLairCreatureAI(boss_victor_nefarius_coa);
    RegisterBlackwingLairCreatureAI(boss_nefarian_coa);
    RegisterBlackwingLairCreatureAI(npc_nefarian_shadow_clone);
    RegisterSpellScript(spell_nefarius_coa_veil);
}
