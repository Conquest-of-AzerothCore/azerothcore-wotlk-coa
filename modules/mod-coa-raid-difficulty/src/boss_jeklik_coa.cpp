/*
 * High Priestess Jeklik with Ascension's spells.
 *
 * Kit: Ascension's block 2106100-2106143. Timings: a Bronzebeard kill on video,
 * see raid-difficulty-werkzeug/zg-video-zeitplan.json. On Ascension the phases
 * run the other way round from stock: she fights as a troll first and takes
 * bat form at 50% (in the video at 50%, 147s into the fight). Mass Fear, Greater
 * Heal, Call of Hir'eek and Fierce Blow follow the CoA combat log of 2026-08-02.
 *
 *   Troll form, from the pull, on the ground (tester and live videos, 2026-11-04)
 *     Mind Flay         first 4s,  every 14s   on the tank, interruptible
 *     Mass Fear         first 12s, every 44s   everyone within 20 yards
 *     Shadow Word: Pain first 15s, every 27s   random player
 *     Curse of Blood    first 16s, every 31s   random player and those near
 *     Call of Hir'eek   first 22s              six Bloodseeker Bats
 *     Greater Heal      first 21s, every 46s   20% of her health, interruptible
 *
 *   At 50% she drains the Avatar of Hir'eek (see LoaAvatar), taking ~1% damage
 *   while it dies; then the Gift of the Blood God and her bat form.
 *
 *   Bat form, when the avatar dies
 *     Bat-tering Charge  first 2s, every 20s   random player beyond 8 and within 25 yards,
 *                                              knocks back everyone within 10 yards
 *     Terrifying Screech the moment the charge lands, in place, or in its place when no
 *                                              player is in reach (live: 12 of 12 landed charges, 0-9 ms):
 *                                              everyone in the room, and fears everyone
 *                                              within 20 yards
 *     Vampirism          passive, her hits drain life
 *     Bat Riders         Normal and Heroic: two, from stock, throwing liquid fire
 *     Crazed Bat Riders  Mythic and Ascended, in their place: a Crazed Bat Rider (14914) on a
 *                                              Frenzied Gurubashi Bat (14965), first 6s, every 30s
 *                                              (live logs). Both circle stock's rider loop out of
 *                                              reach; the rider throws Liquid Fire at once and every
 *                                              4s. Then the bat dives: Frenzy and melee, while the
 *                                              rider casts Volatile Concoction (6s, interruptible,
 *                                              recast 3-12s after an interrupt) and dies in its blast.
 *
 *   Both forms
 *     Fierce Blow        tank, first 6.7-17.3s, then every 6-10s
 *
 * Decided here, not in the data:
 *   - Call of Hir'eek every 60s (the video shows it once);
 *   - Terrifying Screech falls off with distance, full at her, nothing at 100
 *     yards (the tooltip says "reduced as farther", not by how much);
 *   - its fear (2106137, "all nearby enemies") reaches 20 yards like Mass Fear:
 *     the live logs fear part of the raid, but give no positions;
 *   - the bat riders move from the troll phase to the bat phase with the swap.
 *   - Bat-tering Charge has 100 yards in the DBC; players at 30 yards and more are out of
 *     reach on live (tester, 2026-11-04), so it takes the 25 yards of stock Jeklik's Charge;
 *     testers saw it hit melee players (2026-11-13), so it also takes stock's 8 yard minimum;
 *   - the bat carries its rider on vehicle 108, an estimated stand-in: the live seat is unknown;
 *   - the bat dives at a uniform random 16-56s after the pair spawns (live: 15.9-56.7s);
 *   - the pair flies stock's rider loop at stock's speed, and cannot be attacked before the
 *     dive (live: both take no damage before it);
 *   - the rider stops throwing when the bat dives, and the concoction bursts around the rider;
 *   - the rider is level 60 on the ZG health ladder, like the rest of the instance.
 */

#include "Containers.h"
#include "CreatureScript.h"
#include "ScriptedCreature.h"
#include "Vehicle.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"

using namespace coa_zg;

namespace
{
    enum Says
    {
        SAY_AGGRO         = 0,
        SAY_CALL_RIDERS   = 1,
        SAY_DEATH         = 2,
        EMOTE_SUMMON_BATS = 3,
        EMOTE_GREAT_HEAL  = 4
    };

    enum Spells
    {
        SPELL_GREEN_CHANNELING    = 13540,

        INFO_MIND_FLAY            = 2106101,
        SPELL_MIND_FLAY           = 2106105,
        INFO_SHADOW_WORD_PAIN     = 2106108,
        SPELL_SHADOW_WORD_PAIN    = 2106112,
        SPELL_SHADOW_WORD_PAIN_DOT = 2106113,
        SPELL_MASS_FEAR           = 2106114,
        SPELL_MASS_FEAR_HIT       = 2106115,
        SPELL_GREATER_HEAL        = 2106116,
        SPELL_CURSE_OF_BLOOD      = 2106117,
        SPELL_CURSE_OF_BLOOD_HIT  = 2106118,
        SPELL_CALL_OF_HIREEK      = 2106120,
        SPELL_DRAIN_POWER         = 2106121,
        SPELL_ASPECT_OF_HIREEK    = 2106122,
        SPELL_GIFT_OF_THE_BLOOD_GOD = 2106123,
        SPELL_BATTERING_CHARGE    = 2106125,
        SPELL_BATTERING_STUN      = 2106126,
        SPELL_BATTERING_IMPACT    = 2106127,
        SPELL_SCREECH             = 2106131,
        INFO_SCREECH              = 2106132,
        SPELL_SCREECH_HIT         = 2106136,
        SPELL_SCREECH_FEAR        = 2106137,
        SPELL_VAMPIRISM           = 2106138,
        SPELL_FRENZY              = 2106160,
        SPELL_THROW_LIQUID_FIRE   = 2106170,
        SPELL_VOLATILE_CONCOCTION = 2106175,
        SPELL_CONCOCTION_BLAST    = 2106176,
    };

    enum Npcs
    {
        NPC_BLOODSEEKER_BAT = 11368,
        NPC_FRENZIED_BAT    = 14965,
        NPC_BATRIDER        = 14750,
        NPC_CRAZED_BAT_RIDER = 14914,
        NPC_AVATAR_OF_HIREEK = 666992
    };

    enum Actions
    {
        ACTION_DIVE = 1
    };

    enum Events
    {
        EVENT_MIND_FLAY = 1,
        EVENT_MASS_FEAR,
        EVENT_SHADOW_WORD_PAIN,
        EVENT_CURSE_OF_BLOOD,
        EVENT_CALL_OF_HIREEK,
        EVENT_GREATER_HEAL,
        EVENT_BATTERING_CHARGE,
        EVENT_SCREECH,
        EVENT_BAT_RIDER,
        EVENT_FIERCE_BLOW,
        EVENT_BAT_WAVE,
        EVENT_CRAZED_RIDERS,
    };

    enum Phases
    {
        PHASE_TROLL = 1,
        PHASE_BAT   = 2
    };

    constexpr float MASS_FEAR_RANGE    = 20.0f;
    constexpr float SCREECH_RANGE      = 100.0f;
    constexpr float SCREECH_FEAR_RANGE = 20.0f;
    constexpr float BATTERING_CHARGE_MIN_RANGE = 8.0f;
    constexpr float BATTERING_CHARGE_MAX_RANGE = 25.0f;
    constexpr float LIQUID_FIRE_RANGE  = 100.0f;
    constexpr uint8 CRAZED_RIDERS_MIN_SPAWN_MODE = 2;
    constexpr uint32 CRAZED_RIDERS_VEHICLE = 108;
    constexpr uint32 CRAZED_RIDERS_CORPSE_DESPAWN_MS = 15000;
    constexpr uint32 PATH_BATRIDER_LOOP = 147500;
    constexpr float BATRIDER_LOOP_SPEED = 5.0f;
    constexpr Milliseconds BAT_WAVE_FIRST = 52s;
    constexpr Milliseconds BAT_WAVE_INTERVAL = 30s;
    constexpr Milliseconds CRAZED_RIDERS_FIRST = 6s;
    constexpr Milliseconds CRAZED_RIDERS_INTERVAL = 30s;
    constexpr Milliseconds DIVE_MIN = 16s;
    constexpr Milliseconds DIVE_MAX = 56s;
    constexpr Milliseconds LIQUID_FIRE_INTERVAL = 4s;
    constexpr Milliseconds CONCOCTION_RECAST_MIN = 3s;
    constexpr Milliseconds CONCOCTION_RECAST_MAX = 12s;
    constexpr Milliseconds CONCOCTION_DEATH_DELAY = 200ms;

    Position const SpawnBat[6] =
    {
        { -12291.6220f, -1380.2640f, 144.8304f, 5.483f },
        { -12289.6220f, -1380.2640f, 144.8304f, 5.483f },
        { -12293.6220f, -1380.2640f, 144.8304f, 5.483f },
        { -12291.6220f, -1380.2640f, 144.8304f, 5.483f },
        { -12289.6220f, -1380.2640f, 144.8304f, 5.483f },
        { -12293.6220f, -1380.2640f, 144.8304f, 5.483f }
    };
    Position const SpawnBatRider = { -12301.689f, -1371.2921f, 145.09244f, 0.0f };
    Position const JeklikGroundHomePosition = { -12273.9f, -1407.77f, 132.223f, 2.28638f };

    struct boss_jeklik_coa : public BossAI
    {
        boss_jeklik_coa(Creature* creature) : BossAI(creature, DATA_JEKLIK) { }

        void Reset() override
        {
            BossAI::Reset();
            me->SetHomePosition(JeklikGroundHomePosition);
            me->SetDisableGravity(false);
            me->SetReactState(REACT_AGGRESSIVE);
            me->SetCombatMovement(true);
            me->RemoveAurasDueToSpell(SPELL_ASPECT_OF_HIREEK);
            me->RemoveAurasDueToSpell(SPELL_VAMPIRISM);
            me->RemoveAurasDueToSpell(SPELL_GIFT_OF_THE_BLOOD_GOD);
            _avatar.Restore(me);
            _bat = false;
            _riders = 0;
            _screechOnLanding = false;
            DoCastSelf(SPELL_GREEN_CHANNELING, true);
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            Talk(SAY_AGGRO);
            DoZoneInCombat();
            me->InterruptSpell(CURRENT_CHANNELED_SPELL);
            me->RemoveAurasDueToSpell(SPELL_GREEN_CHANNELING);
            StartTrollPhase();
        }

        void StartTrollPhase()
        {
            events.SetPhase(PHASE_TROLL);
            events.ScheduleEvent(EVENT_MIND_FLAY, 4s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_MASS_FEAR, 12s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_SHADOW_WORD_PAIN, 15s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_CURSE_OF_BLOOD, 16s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_CALL_OF_HIREEK, 22s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_GREATER_HEAL, 21s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_FIERCE_BLOW, FIERCE_BLOW_FIRST_MIN, FIERCE_BLOW_FIRST_MAX);
            events.ScheduleEvent(EVENT_BAT_WAVE, BAT_WAVE_FIRST);
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            if (why != EvadeReason::EVADE_REASON_NO_PATH)
                me->DespawnOnEvade(5s);
            _avatar.Release(me);
            BossAI::EnterEvadeMode(why);
        }

        void JustDied(Unit* killer) override
        {
            BossAI::JustDied(killer);
            _avatar.Release(me);
            Talk(SAY_DEATH);
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);

            if (_bat || !me->HealthBelowPctDamaged(50, damage))
                return;

            _bat = true;
            if (!_avatar.Drain(me))
                TakeBatForm();
        }

        void TakeBatForm()
        {
            me->InterruptNonMeleeSpells(false);
            DoCastSelf(SPELL_GIFT_OF_THE_BLOOD_GOD, true);
            DoCastSelf(SPELL_ASPECT_OF_HIREEK, true);
            DoCastSelf(SPELL_VAMPIRISM, true);
            DoResetThreatList();
            _screechOnLanding = false;

            events.SetPhase(PHASE_BAT);
            events.ScheduleEvent(EVENT_BATTERING_CHARGE, 2s, 0, PHASE_BAT);
            if (me->GetMap()->GetSpawnMode() >= CRAZED_RIDERS_MIN_SPAWN_MODE)
                events.ScheduleEvent(EVENT_CRAZED_RIDERS, CRAZED_RIDERS_FIRST, 0, PHASE_BAT);
            else
                events.ScheduleEvent(EVENT_BAT_RIDER, 10s, 0, PHASE_BAT);
        }

        void SummonCrazedRiders()
        {
            TempSummon* bat = me->GetMap()->SummonCreature(NPC_FRENZIED_BAT, SpawnBatRider, nullptr,
                CRAZED_RIDERS_CORPSE_DESPAWN_MS, me, 0, CRAZED_RIDERS_VEHICLE);
            if (!bat)
                return;
            bat->SetTempSummonType(TEMPSUMMON_CORPSE_TIMED_DESPAWN);
            if (Creature* rider = me->SummonCreature(NPC_CRAZED_BAT_RIDER, SpawnBatRider, TEMPSUMMON_CORPSE_TIMED_DESPAWN,
                CRAZED_RIDERS_CORPSE_DESPAWN_MS))
                rider->EnterVehicle(bat, 0);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            Unit* target = ObjectAccessor::GetUnit(*me, _target);
            switch (spell->Id)
            {
                case SPELL_MASS_FEAR:
                    for (Player* p : PlayersWithin(me, MASS_FEAR_RANGE))
                        me->CastSpell(p, SPELL_MASS_FEAR_HIT, true);
                    break;
                case SPELL_SHADOW_WORD_PAIN:
                    Hit(me, target, SPELL_SHADOW_WORD_PAIN_DOT, Info(me, INFO_SHADOW_WORD_PAIN));
                    break;
                case SPELL_CURSE_OF_BLOOD:
                    if (target)
                        me->CastSpell(target, SPELL_CURSE_OF_BLOOD_HIT, true);
                    break;
                case SPELL_CALL_OF_HIREEK:
                    CallOfHireek();
                    break;
                case SPELL_SCREECH:
                {
                    int32 const full = Info(me, INFO_SCREECH);
                    for (Player* p : PlayersWithin(me, SCREECH_RANGE))
                        Hit(me, p, SPELL_SCREECH_HIT, int32(full * (1.0f - me->GetDistance(p) / SCREECH_RANGE)), 1);
                    for (Player* p : PlayersWithin(me, SCREECH_FEAR_RANGE))
                        me->CastSpell(p, SPELL_SCREECH_FEAR, true);
                    break;
                }
                default:
                    break;
            }
        }

        // The charge stuns its target; the impact around it is its own spell.
        void SpellHitTarget(Unit* target, SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_BATTERING_STUN)
                return;

            me->CastSpell(target, SPELL_BATTERING_IMPACT, true);
            if (_screechOnLanding && !me->HasUnitState(UNIT_STATE_CHARGING))
            {
                _screechOnLanding = false;
                events.ScheduleEvent(EVENT_SCREECH, 0ms, 0, PHASE_BAT);
            }
        }

        void MovementInform(uint32 type, uint32 id) override
        {
            if (type != POINT_MOTION_TYPE || (id != ::EVENT_CHARGE && id != EVENT_CHARGE_PREPATH) || !_screechOnLanding)
                return;

            _screechOnLanding = false;
            me->StopMoving();
            DoCastSelf(SPELL_SCREECH);
        }

        void CallOfHireek()
        {
            Talk(EMOTE_SUMMON_BATS);
            SummonBats(NPC_BLOODSEEKER_BAT, std::size(SpawnBat));
        }

        void SummonBats(uint32 entry, size_t count)
        {
            Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true);
            for (size_t i = 0; i < count; ++i)
            {
                Position const& pos = SpawnBat[i % std::size(SpawnBat)];
                if (Creature* bat = me->SummonCreature(entry, pos, TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT, 15000))
                    if (target)
                        bat->AI()->AttackStart(target);
            }
        }

        bool CastOnRandom(uint32 spell, bool notTank = false)
        {
            if (Unit* target = SelectTarget(SelectTargetMethod::Random, notTank ? 1 : 0, 100.0f, true))
            {
                _target = target->GetGUID();
                DoCast(target, spell);
                return true;
            }
            return false;
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            if (_avatar.Consumed(me))
                TakeBatForm();

            events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_MIND_FLAY:
                        if (Unit* tank = me->GetVictim())
                        {
                            int32 tick = Info(me, INFO_MIND_FLAY);
                            me->CastCustomSpell(tank, SPELL_MIND_FLAY, nullptr, &tick, nullptr, false);
                        }
                        events.ScheduleEvent(EVENT_MIND_FLAY, 14s, 0, PHASE_TROLL);
                        break;
                    case EVENT_MASS_FEAR:
                        DoCastSelf(SPELL_MASS_FEAR);
                        events.ScheduleEvent(EVENT_MASS_FEAR, 44s, 0, PHASE_TROLL);
                        break;
                    case EVENT_SHADOW_WORD_PAIN:
                        CastOnRandom(SPELL_SHADOW_WORD_PAIN);
                        events.ScheduleEvent(EVENT_SHADOW_WORD_PAIN, 27s, 0, PHASE_TROLL);
                        break;
                    case EVENT_CURSE_OF_BLOOD:
                        CastOnRandom(SPELL_CURSE_OF_BLOOD);
                        events.ScheduleEvent(EVENT_CURSE_OF_BLOOD, 31s, 0, PHASE_TROLL);
                        break;
                    case EVENT_CALL_OF_HIREEK:
                        DoCastSelf(SPELL_CALL_OF_HIREEK);
                        break;
                    case EVENT_BAT_WAVE:
                        SummonBats(NPC_BLOODSEEKER_BAT, std::size(SpawnBat));
                        events.ScheduleEvent(EVENT_BAT_WAVE, BAT_WAVE_INTERVAL);
                        break;
                    case EVENT_CRAZED_RIDERS:
                        SummonCrazedRiders();
                        events.ScheduleEvent(EVENT_CRAZED_RIDERS, CRAZED_RIDERS_INTERVAL, 0, PHASE_BAT);
                        break;
                    case EVENT_GREATER_HEAL:
                        Talk(EMOTE_GREAT_HEAL);
                        DoCastSelf(SPELL_GREATER_HEAL);
                        events.ScheduleEvent(EVENT_GREATER_HEAL, 46s, 0, PHASE_TROLL);
                        break;
                    case EVENT_BATTERING_CHARGE:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, [this](Unit* u)
                            {
                                return u->IsPlayer() && !me->IsWithinDist(u, BATTERING_CHARGE_MIN_RANGE)
                                    && me->IsWithinDist(u, BATTERING_CHARGE_MAX_RANGE);
                            }))
                            _screechOnLanding = DoCast(target, SPELL_BATTERING_CHARGE) == SPELL_CAST_OK;
                        else
                            events.ScheduleEvent(EVENT_SCREECH, 0ms, 0, PHASE_BAT);
                        events.ScheduleEvent(EVENT_BATTERING_CHARGE, 20s, 0, PHASE_BAT);
                        break;
                    case EVENT_SCREECH:
                        DoCastSelf(SPELL_SCREECH);
                        break;
                    case EVENT_BAT_RIDER:
                        if (_riders < 2)
                        {
                            Talk(SAY_CALL_RIDERS);
                            if (me->SummonCreature(NPC_BATRIDER, SpawnBatRider, TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT))
                                ++_riders;
                            if (_riders < 2)
                                events.ScheduleEvent(EVENT_BAT_RIDER, 10s, 15s, 0, PHASE_BAT);
                        }
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    private:
        bool _bat = false;
        uint8 _riders = 0;
        bool _screechOnLanding = false;
        LoaAvatar _avatar{ NPC_AVATAR_OF_HIREEK, SPELL_DRAIN_POWER };
        ObjectGuid _target;
    };

    void SetOutOfReach(Creature* creature, bool apply)
    {
        if (apply)
            creature->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        else
            creature->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        creature->SetImmuneToPC(apply, true);
        creature->SetImmuneToNPC(apply, true);
    }

    struct npc_frenzied_bat_coa : public ScriptedAI
    {
        npc_frenzied_bat_coa(Creature* creature) : ScriptedAI(creature), _carrier(creature->IsVehicle())
        {
            if (!_carrier)
                return;
            SetOutOfReach(me, true);
            me->SetReactState(REACT_PASSIVE);
            me->SetSpeed(MOVE_WALK, BATRIDER_LOOP_SPEED, true);
            FlyLoop();
            scheduler.Schedule(DIVE_MIN, DIVE_MAX, [this](TaskContext) { Dive(); });
        }

        void FlyLoop()
        {
            me->SetCanFly(true);
            me->GetMotionMaster()->MovePath(PATH_BATRIDER_LOOP);
        }

        void Dive()
        {
            _dived = true;
            SetOutOfReach(me, false);
            me->SetReactState(REACT_AGGRESSIVE);
            me->GetMotionMaster()->Clear();
            DoCastSelf(SPELL_FRENZY, true);
            DoZoneInCombat();
            std::vector<Player*> const players = PlayersWithin(me, LIQUID_FIRE_RANGE);
            if (!players.empty())
                AttackStart(Acore::Containers::SelectRandomContainerElement(players));
            if (Unit* rider = me->GetVehicleKit()->GetPassenger(0))
                if (Creature* creature = rider->ToCreature())
                    if (creature->IsAIEnabled)
                        creature->AI()->DoAction(ACTION_DIVE);
        }

        void UpdateAI(uint32 diff) override
        {
            if (_carrier && !_dived)
            {
                scheduler.Update(diff);
                if (!_dived && !me->isMoving())
                    FlyLoop();
                return;
            }

            if (!UpdateVictim())
                return;

            DoMeleeAttackIfReady();
        }

    private:
        bool const _carrier;
        bool _dived = false;
    };

    struct npc_crazed_bat_rider_coa : public ScriptedAI
    {
        npc_crazed_bat_rider_coa(Creature* creature) : ScriptedAI(creature)
        {
            SetOutOfReach(me, true);
            me->SetReactState(REACT_PASSIVE);
            scheduler.Schedule(0ms, [this](TaskContext context)
            {
                ThrowLiquidFire();
                context.Repeat(LIQUID_FIRE_INTERVAL);
            });
        }

        void ThrowLiquidFire()
        {
            std::vector<Player*> const players = PlayersWithin(me, LIQUID_FIRE_RANGE);
            if (players.empty())
                return;
            Player* target = Acore::Containers::SelectRandomContainerElement(players);
            me->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(),
                SPELL_THROW_LIQUID_FIRE, false);
        }

        void DoAction(int32 action) override
        {
            if (action != ACTION_DIVE || _dived)
                return;
            _dived = true;
            scheduler.CancelAll();
            SetOutOfReach(me, false);
            DoZoneInCombat();
            me->InterruptNonMeleeSpells(false);
            DoCastSelf(SPELL_VOLATILE_CONCOCTION);
        }

        void OnSpellFailed(SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_VOLATILE_CONCOCTION || _bursting)
                return;
            scheduler.Schedule(CONCOCTION_RECAST_MIN, CONCOCTION_RECAST_MAX, [this](TaskContext)
            {
                DoCastSelf(SPELL_VOLATILE_CONCOCTION);
            });
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_VOLATILE_CONCOCTION || _bursting)
                return;
            _bursting = true;
            me->CastSpell(me->GetPositionX(), me->GetPositionY(), me->GetPositionZ(), SPELL_CONCOCTION_BLAST, true);
            scheduler.Schedule(CONCOCTION_DEATH_DELAY, [this](TaskContext) { me->KillSelf(); });
        }

        void UpdateAI(uint32 diff) override
        {
            scheduler.Update(diff);
        }

    private:
        bool _dived = false;
        bool _bursting = false;
    };
}

void AddCoaJeklikScripts()
{
    RegisterZulGurubCreatureAI(boss_jeklik_coa);
    RegisterZulGurubCreatureAI(npc_frenzied_bat_coa);
    RegisterZulGurubCreatureAI(npc_crazed_bat_rider_coa);
}
