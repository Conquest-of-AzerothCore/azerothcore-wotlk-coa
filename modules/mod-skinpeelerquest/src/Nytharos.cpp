#include "Nytharos.h"

#include "ApexScaling.h"
#include "AscensionClientSpellPatches.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "CreatureScript.h"
#include "Log.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "UnitScript.h"
#include "Player.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include "Timer.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace
{
    std::unordered_map<ObjectGuid, ObjectGuid> g_spoutInitialTargets;
    std::vector<ObjectGuid> g_spoutSummons;

    constexpr uint32 NYTHAROS_ENTRY = 9916224;

    // Full Oracle voice kit (creature\oracle\*.ogg). The oracle2 display rows
    // ship soundId 0, so nothing plays on its own and every line is driven here.
    constexpr uint32 NY_SOUND_AGGRO = 195112;   // oraclebattleroar / oracleemoteroar
    constexpr uint32 NY_SOUND_ATTACK = 195099;  // oracleattacka-h
    constexpr uint32 NY_SOUND_WOUND = 195113;   // oraclewounda-g
    constexpr uint32 NY_SOUND_DEATH = 47138;    // oracledeath

    constexpr uint32 NY_ATTACK_SOUND_MS = 2500;
    constexpr uint32 NY_WOUND_SOUND_MS = 2000;

    constexpr uint32 NY_EMOTE_ROAR = 1010;      // BattleRoar

    // ---- Crushing Depths -------------------------------------------------
    // 4 s non-interruptible channel, 360 degrees within 7 yards. The spell
    // applies a 0.7 s periodic aura for 200 a tick, so the damage is spread
    // across the channel. The wave sits at his feet and the client plays the
    // directed channel animation from the spell's ChannelKit.
    constexpr uint32 NY_CRUSHING_DEPTHS = 1004270;
    constexpr uint32 NY_SOUND_WAVE = 12994;     // Missile_wave_Water

    constexpr uint32 NY_CRUSH_MELEE_MS = 10000; // melee window after the channel
    constexpr uint32 NY_CRUSH_FIRST_MS = 10000;

    // ---- Waterspouts -----------------------------------------------------
    // Instant cast: omni pose, then four tornado dummies that chase players at
    // 55% run speed for fifteen seconds, hitting for 250 and a 30% slow within
    // three yards.
    constexpr uint32 NY_TORNADO_ENTRY = 9916216;
    constexpr uint32 NY_SPOUT_VISUAL = 1004290;     // state aura, kit 99110
    constexpr uint32 NY_SPOUT_KIT = 99110;          // effect 145178 tornado model
    constexpr uint32 NY_SPOUT_DMG = 1004291;        // 250 nature
    constexpr uint32 NY_SPOUT_SLOW = 1004292;       // -30% for 2 s
    constexpr uint32 NY_SOUND_TORNADO = 10045;    // custom one-shot streamed SoundEntries row
    constexpr uint32 NY_EMOTE_CAST_OMNI = 463;      // ONESHOT_SPELL_CAST_OMNI

    constexpr uint32 NY_SPOUT_LIFE_MS = 15000;

    // ---- fight loop ------------------------------------------------------
    // One pressure layer at a time: positioning (Crushing Depths), then spread
    // (Waterspouts), then tempo (Tidal Bulwark), with a guaranteed melee
    // window in between. Nothing overlaps, so the screen stays readable.
    constexpr std::array<uint32, 3> NY_PHASE_MELEE_MS = {10000, 8000, 8000};
    constexpr std::array<uint32, 3> NY_PHASE_SPOUT_COUNT = {4, 5, 6};
    constexpr std::array<float, 3> NY_PHASE_BULWARK_PCT = {0.12f, 0.138f, 0.15f};
    constexpr std::array<uint32, 3> NY_PHASE_PULSE_MS = {3000, 3000, 2000};

    constexpr char const* NY_YELL_PULL_1 = "The bay around Nytharos falls silent.";
    constexpr char const* NY_YELL_PULL_2 = "Nytharos turns, and the shallows turn with him.";
    constexpr char const* NY_YELL_P2_1 = "The bay begins to churn in earnest.";
    constexpr char const* NY_YELL_P2_2 = "Nytharos calls deeper, and the water answers faster.";
    constexpr char const* NY_YELL_P3_1 =
        "The drowned oracle's voice carries through the water, and the whole bay answers.";
    constexpr char const* NY_YELL_P3_2 = "The tide stops retreating. It only advances now.";

    constexpr float NY_SPOUT_CONTACT = 4.0f;
    constexpr uint32 NY_SPOUT_DAMAGE = 250;
    constexpr float NY_SPOUT_SPEED = 0.62f;

    // ---- scaling ---------------------------------------------------------
    // Every point of damage is a share of the victim's own health pool, applied
    // through a carrier spell so armour, resistances, absorbs, crit and the
    // combat log all stay on the engine's path.
    constexpr uint32 NY_CARRIER_PHYSICAL = 1004310;
    constexpr uint32 NY_CARRIER_NATURE = 1004311;

    constexpr float NY_AUTO_PCT = 0.03f;            // pre-armour, per swing
    constexpr uint32 NY_AUTO_FLOOR = 1;
    constexpr uint32 NY_AUTO_CEILING = 1200;

    constexpr uint32 NY_CRUSH_TICK_MS = 700;
    constexpr float NY_CRUSH_TICK_PCT = 0.025f;     // each victim, per tick
    constexpr float NY_CRUSH_TICK_BUDGET = 0.07f;   // total per tick, averaged pool
    constexpr uint32 NY_CRUSH_TICK_FLOOR = 1;
    constexpr uint32 NY_CRUSH_TICK_CEILING = 900;
    constexpr float NY_CRUSH_TARGET_CAP = 0.35f;
    constexpr float NY_CRUSH_RADIUS = 7.0f;

    constexpr float NY_SPOUT_PCT = 0.06f;
    constexpr uint32 NY_SPOUT_FLOOR = 1;
    constexpr uint32 NY_SPOUT_CEILING = 700;

    // Health scaling reference: a fresh level 60 sits far below this, a BiS set
    // far above it. The curve is calibrated in the harness, not on paper.
    constexpr float NY_HEALTH_REFERENCE = 6000.0f;

    // The pool is sized from measured output after the pull: sample the group's real damage
    // for this long, then aim the pool at the target kill time.
    constexpr uint32 NY_PROBE_MS = 15000;
    constexpr float NY_TARGET_TTK_S = 240.0f;
    // The probe samples an opening burst: cooldowns are up and there is no movement.
    // Sustained output over a real fight is lower, so the pool is sized against that.
    constexpr float NY_SUSTAIN_FACTOR = 0.85f;
    constexpr float NY_POOL_MIN_FACTOR = 0.75f;
    constexpr float NY_POOL_MAX_FACTOR = 40.0f;
    constexpr float NY_SPOUT_AGGRO_RANGE = 20.0f;   // meets a player, then chases
    constexpr float NY_SPOUT_WANDER = 12.0f;
    constexpr float NY_SPOUT_DETECT = 25.0f;        // random drift radius
    constexpr float NY_SPOUT_SPAWN_MIN = 15.0f;
    constexpr float NY_SPOUT_SPAWN_MAX = 25.0f;

    // ---- Tidal Bulwark ---------------------------------------------------
    // 8 second absorb equal to 12% of his maximum health. Broken by damage; if
    // it survives the whole window he heals the full amount instead.
    constexpr uint32 NY_BULWARK = 1004300;
    constexpr uint32 NY_BULWARK_KIT = 99114;        // waterbubble state kit
    constexpr uint32 NY_BULWARK_SHELL = 9916217;    // follower creature wearing the bubble
    constexpr float NY_BULWARK_SHELL_Z = 2.2f;      // torso height, clears the run bob
    constexpr uint32 NY_BULWARK_MS = 8000;

    // ---- shield knockbacks -----------------------------------------------
    // No damage. While Tidal Bulwark is up it pulses everyone within reach out
    // far enough to reset the melee scrum, so the shield window alternates
    // between "pushed out" and "walk back in and hit him".
    constexpr float NY_KNOCK_RANGE = 10.0f;
    constexpr float NY_KNOCK_SPEED = 20.0f;
    constexpr float NY_KNOCK_UP = 10.0f;
    constexpr uint32 NY_SOUND_KNOCK = 1090;     // char/footsteps/EnterWaterSmallA

    constexpr std::array<uint32, 7> NYTHAROS_CLIENT_SPELLS = {
        NY_CRUSHING_DEPTHS, NY_SPOUT_VISUAL, NY_SPOUT_DMG, NY_SPOUT_SLOW, NY_BULWARK,
        NY_CARRIER_PHYSICAL, NY_CARRIER_NATURE};

    // Minimum gap between the starts of any two abilities, so they do not stack
    // on top of each other and turn the screen into soup.
    constexpr uint32 NY_ABILITY_GAP_MS = 6000;

    struct NytharosState
    {
        uint32 nextAttackSound = 0;
        uint32 nextWoundSound = 0;
        bool crushCasting = false;

        uint32 bulwarkEnds = 0;
        uint32 bulwarkAmount = 0;
        uint32 bulwarkRemaining = 0;
        float bulwarkVisX = 0.0f;
        float bulwarkVisY = 0.0f;
        bool bulwarkActive = false;

        uint32 nextKnockPulse = 0;

        uint8 phase = 1;
        uint8 loopStep = 0;          // 0 depths, 1 spouts, 2 bulwark
        uint32 meleeUntil = 0;       // no ability may start before this

        uint32 baseMaxHealth = 0;
        uint32 nextCrushTick = 0;
        uint32 spoutsUntil = 0;
        uint32 secondSpoutSoundAt = 0;

        uint32 probeStart = 0;
        uint64 probeDamage = 0;
        bool probeDone = false;
    };

    // His brain is per creature, but the state map is process-wide; the lock keeps a
    // second instance's thread from rehashing the map under a reader.
    std::recursive_mutex g_nytharosStateMutex;
    std::unordered_map<uint32, NytharosState> g_nytharosStates;

    class NytharosAI : public CreatureAI
    {
    public:
        explicit NytharosAI(Creature* creature) : CreatureAI(creature) { }

        void InitializeAI() override
        {
            std::lock_guard<std::recursive_mutex> lock(g_nytharosStateMutex);

            me->SetReactState(REACT_DEFENSIVE);
            ApexScaling::TuneHitbox(me);

            NytharosState& state = g_nytharosStates[me->GetGUID().GetCounter()];
            state = NytharosState();
            // Create health, not the current maximum: our own scaling writes the maximum,
            // so reading it back would compound the factor on every re-initialisation.
            state.baseMaxHealth = me->GetCreateHealth() ? me->GetCreateHealth() : me->GetMaxHealth();

            CreatureAI::InitializeAI();
        }

        void Reset() override
        {
            std::lock_guard<std::recursive_mutex> lock(g_nytharosStateMutex);

            DespawnSpouts();

            NytharosState& state = g_nytharosStates[me->GetGUID().GetCounter()];
            uint32 const base = state.baseMaxHealth;
            state = NytharosState();
            state.baseMaxHealth = base;

            ApexScaling::RestoreHealth(me, base);
            ApexScaling::TuneHitbox(me);
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            DespawnSpouts();
            CreatureAI::EnterEvadeMode(why);
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            std::lock_guard<std::recursive_mutex> lock(g_nytharosStateMutex);

            me->PlayDirectSound(NY_SOUND_AGGRO);
            me->HandleEmoteCommand(NY_EMOTE_ROAR);

            NytharosState& state = g_nytharosStates[me->GetGUID().GetCounter()];
            uint32 const base = state.baseMaxHealth ? state.baseMaxHealth : me->GetMaxHealth();
            state = NytharosState();
            state.baseMaxHealth = base;

            // He opens with a plain melee window; the loop starts after it.
            state.phase = 1;
            state.loopStep = 0;
            state.meleeUntil = getMSTime() + NY_CRUSH_FIRST_MS;

            ApexScaling::ScaleHealth(me, state.baseMaxHealth, NY_HEALTH_REFERENCE);

            me->Yell(NY_YELL_PULL_1, LANG_UNIVERSAL);
            me->Yell(NY_YELL_PULL_2, LANG_UNIVERSAL);

            LOG_INFO("coa", "NYTHAROS: engaged");
        }

        void JustDied(Unit* /*killer*/) override
        {
            DespawnSpouts();
            me->PlayDirectSound(NY_SOUND_DEATH);
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType /*type*/,
            SpellSchoolMask /*school*/) override
        {
            if (!attacker || !attacker->IsAlive() || !me->IsAlive())
                return;

            std::lock_guard<std::recursive_mutex> lock(g_nytharosStateMutex);

            if (!me->IsInCombat() || !me->GetVictim())
                ApexScaling::StartApexPull(me, attacker);

            me->AddThreat(attacker, 1.0f);

            // Drain the shield by hand and keep the aura's amount in step, so the
            // absorb bar on his health bar actually counts down and the shield
            // can be broken.
            NytharosState& state = g_nytharosStates[me->GetGUID().GetCounter()];
            if (state.bulwarkActive && state.bulwarkRemaining && damage)
            {
                uint32 const absorbed = std::min(damage, state.bulwarkRemaining);
                damage -= absorbed;
                state.bulwarkRemaining -= absorbed;

                if (Aura* aura = me->GetAura(NY_BULWARK))
                {
                    if (AuraEffect* eff = aura->GetEffect(0))
                        eff->ChangeAmount(int32(state.bulwarkRemaining));
                }

                if (!state.bulwarkRemaining)
                {
                    state.bulwarkActive = false;
                    state.loopStep = 0;
                    state.meleeUntil = getMSTime() + NY_PHASE_MELEE_MS[PhaseIndex(state)];
                    me->RemoveAurasDueToSpell(NY_BULWARK);
                    LOG_INFO("coa", "NYTHAROS: bulwark broken");
                }
            }

            uint32 const now = getMSTime();

            // Probe the group's real output for the pool sizing below. Every source counts:
            // melee, ranged, spells, DoTs, pets and procs all arrive here as damage.
            if (!state.probeDone)
            {
                if (!state.probeStart)
                    state.probeStart = now;

                state.probeDamage += damage;
            }

            if (now >= state.nextWoundSound)
            {
                state.nextWoundSound = now + NY_WOUND_SOUND_MS;
                me->PlayDirectSound(NY_SOUND_WOUND);
            }
        }

        void UpdateAI(uint32 /*diff*/) override
        {
            std::lock_guard<std::recursive_mutex> lock(g_nytharosStateMutex);

            // The patrol ring runs well past the 30-yard home leash, so an attack
            // anywhere on it was rejected as out of the leash area. Keep home on
            // his current patrol point until he is engaged; the fight itself is
            // then leashed to wherever the pull happened, as usual.
            if (!me->IsInCombat())
                me->SetHomePosition(me->GetPositionX(), me->GetPositionY(),
                    me->GetPositionZ(), me->GetOrientation());

            ApexScaling::KeepApexChase(me);
            ApexScaling::TuneHitbox(me);

            if (!UpdateVictim())
                return;

            uint32 const now = getMSTime();
            NytharosState& state = g_nytharosStates[me->GetGUID().GetCounter()];

            if (state.secondSpoutSoundAt && now >= state.secondSpoutSoundAt)
            {
                state.secondSpoutSoundAt = 0;
                me->PlayRadiusSound(NY_SOUND_TORNADO, 100.0f);
            }

            UpdatePhase(state);
            UpdateProbe(state, now);
            RunLoop(state, now);

            if (now >= state.nextAttackSound && me->IsWithinMeleeRange(me->GetVictim()))
            {
                state.nextAttackSound = now + NY_ATTACK_SOUND_MS;
                me->PlayDirectSound(NY_SOUND_ATTACK);
            }

            if (!me->HasUnitState(UNIT_STATE_CASTING))
                DoMeleeAttackIfReady();
        }

    private:
        // The pool is sized from the damage the group actually produces, not from a stat
        // proxy: melee, ranged, spells, DoTs, pets and procs all land in this number, so
        // every class and every build is measured the same way.
        void UpdateProbe(NytharosState& state, uint32 now)
        {
            if (state.probeDone || !state.probeStart || now < state.probeStart + NY_PROBE_MS)
                return;

            state.probeDone = true;

            float const seconds = float(NY_PROBE_MS) / 1000.0f;
            float const dps = float(state.probeDamage) / seconds;
            uint32 const base = state.baseMaxHealth ? state.baseMaxHealth : me->GetMaxHealth();

            uint32 const floorHealth = uint32(float(base) * NY_POOL_MIN_FACTOR);
            uint32 const ceilingHealth = uint32(float(base) * NY_POOL_MAX_FACTOR);
            uint32 const target = std::clamp<uint32>(uint32(dps * NY_SUSTAIN_FACTOR * NY_TARGET_TTK_S),
                std::max<uint32>(floorHealth, base / 2), ceilingHealth);

            // Keep the fraction of the bar the group has already removed.
            float const fraction = std::max(0.01f, me->GetHealthPct() / 100.0f);
            me->SetMaxHealth(target);
            me->SetHealth(std::max<uint32>(1, uint32(float(target) * fraction)));

            LOG_INFO("coa", "NYTHAROS: probe {:.0f} damage over {:.0f}s = {:.0f} dps -> pool {} (base {})",
                float(state.probeDamage), seconds, dps, target, base);
        }

        static uint32 PhaseIndex(NytharosState const& state)
        {
            return std::min<uint32>(state.phase - 1, 2);
        }

        void UpdatePhase(NytharosState& state)
        {
            float const pct = me->GetHealthPct();
            uint8 const phase = pct <= 33.0f ? 3 : (pct <= 66.0f ? 2 : 1);
            if (phase == state.phase)
                return;

            state.phase = phase;

            if (phase == 2)
            {
                me->Yell(NY_YELL_P2_1, LANG_UNIVERSAL);
                me->Yell(NY_YELL_P2_2, LANG_UNIVERSAL);
            }
            else
            {
                me->Yell(NY_YELL_P3_1, LANG_UNIVERSAL);
                me->Yell(NY_YELL_P3_2, LANG_UNIVERSAL);
            }

            LOG_INFO("coa", "NYTHAROS: phase {}", phase);
        }

        // The whole fight is one loop, and each step owns the arena until it is
        // finished. Nothing starts while another layer is running.
        void RunLoop(NytharosState& state, uint32 now)
        {
            if (state.crushCasting)
            {
                // The client drives the pose and the wave from the spell's
                // ChannelKit (SpellVisual 99107 -> kit 99104, AnimID 124).
                if (!me->HasUnitState(UNIT_STATE_CASTING))
                {
                    state.crushCasting = false;
                    state.meleeUntil = now + NY_PHASE_MELEE_MS[PhaseIndex(state)];
                    state.loopStep = 1;
                    LOG_INFO("coa", "NYTHAROS: channel end, melee window {} ms",
                        NY_PHASE_MELEE_MS[PhaseIndex(state)]);
                    return;
                }

                // Damage is a share of each victim's pool, split across whoever
                // is standing in it, so the healer's load does not grow with the
                // group: alone you eat the budget, in five you eat a fifth.
                if (now >= state.nextCrushTick)
                {
                    state.nextCrushTick = now + NY_CRUSH_TICK_MS;
                    std::vector<Player*> targets = ApexScaling::EngagedPlayers(me, NY_CRUSH_RADIUS);
                    ApexScaling::ApplyAoe(me, targets,
                        {NY_CRUSH_TICK_PCT, NY_CRUSH_TICK_FLOOR, NY_CRUSH_TICK_CEILING},
                        NY_CRUSH_TICK_BUDGET, NY_CRUSH_TARGET_CAP, NY_CARRIER_NATURE);
                }
                return;
            }

            if (state.bulwarkActive)
            {
                UpdateBulwarkActive(state, now);
                return;
            }

            if (now < state.meleeUntil)
                return;

            // The spout step is bounded by its own clock, not by whether the
            // summons are still findable: a spout that outlives its timer would
            // otherwise stall the loop and the shield step would never run.
            if (now < state.spoutsUntil)
                return;

            switch (state.loopStep)
            {
                case 0: StartCrushingDepths(state); break;
                case 1: StartSpouts(state, now); break;
                default: StartBulwark(state, now); break;
            }
        }

        void StartCrushingDepths(NytharosState& state)
        {
            state.crushCasting = true;
            state.nextCrushTick = getMSTime() + NY_CRUSH_TICK_MS;

            me->CastSpell(me, NY_CRUSHING_DEPTHS, false);
            me->PlayDirectSound(NY_SOUND_WAVE);

            LOG_INFO("coa", "NYTHAROS: crushing depths");
        }

        void StartSpouts(NytharosState& state, uint32 now)
        {
            uint32 const count = NY_PHASE_SPOUT_COUNT[PhaseIndex(state)];
            state.loopStep = 2;
            state.spoutsUntil = now + NY_SPOUT_LIFE_MS;

            me->HandleEmoteCommand(NY_EMOTE_CAST_OMNI);
            me->PlayRadiusSound(NY_SOUND_TORNADO, 100.0f);
            state.secondSpoutSoundAt = now + 7500;

            std::vector<Player*> targets;
            Map::PlayerList const& players = me->GetMap()->GetPlayers();
            for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
            {
                Player* player = itr->GetSource();
                if (!player || !player->IsAlive() || !player->InSamePhase(me))
                    continue;
                targets.push_back(player);
            }

            uint32 const offset = targets.empty() ? 0 : urand(0, uint32(targets.size()) - 1);

            for (uint32 i = 0; i < count; ++i)
            {
                float const angle = float(i) * (2.0f * float(M_PI) / float(count))
                    + frand(0.0f, 1.0f);
                float const dist = frand(NY_SPOUT_SPAWN_MIN, NY_SPOUT_SPAWN_MAX);
                float const x = me->GetPositionX() + std::cos(angle) * dist;
                float const y = me->GetPositionY() + std::sin(angle) * dist;
                float const z = me->GetPositionZ();

                Creature* spout = me->SummonCreature(NY_TORNADO_ENTRY, x, y, z, me->GetOrientation(),
                    TEMPSUMMON_TIMED_DESPAWN, NY_SPOUT_LIFE_MS);
                if (spout)
                {
                    g_spoutSummons.push_back(spout->GetGUID());
                    if (!targets.empty())
                        g_spoutInitialTargets[spout->GetGUID()] = targets[(offset + i) % targets.size()]->GetGUID();
                }
            }

            LOG_INFO("coa", "NYTHAROS: waterspouts x{}", count);
        }

    private:
        void DespawnSpouts()
        {
            for (ObjectGuid const& guid : g_spoutSummons)
                if (Creature* spout = ObjectAccessor::GetCreature(*me, guid))
                {
                    spout->PlayDirectSound(0);
                    spout->PlayDistanceSound(0);
                    spout->DespawnOrUnsummon();
                }
            g_spoutSummons.clear();
        }

        void DoKnockPulse()
        {
            me->PlayDirectSound(NY_SOUND_KNOCK);

            float const x = me->GetPositionX();
            float const y = me->GetPositionY();

            Map::PlayerList const& players = me->GetMap()->GetPlayers();
            for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
            {
                Player* player = itr->GetSource();
                if (!player || !player->IsAlive() || !player->InSamePhase(me))
                    continue;
                if (me->GetExactDist2d(player) > NY_KNOCK_RANGE)
                    continue;

                player->KnockbackFrom(x, y, NY_KNOCK_SPEED, NY_KNOCK_UP);
            }
        }

        void UpdateBulwarkActive(NytharosState& state, uint32 now)
        {
            // The shield itself pulses people out, so the window alternates
            // between being shoved away and running back in to break it.
            if (now >= state.nextKnockPulse)
            {
                state.nextKnockPulse = now + NY_PHASE_PULSE_MS[PhaseIndex(state)];
                DoKnockPulse();
            }

            // The absorb aura disappears either because it was eaten or because
            // the window closed. Only the latter heals him.
            if (me->HasAura(NY_BULWARK))
                return;

            bool const expired = now + 400 >= state.bulwarkEnds;

            state.bulwarkActive = false;
            state.loopStep = 0;
            state.meleeUntil = now + NY_PHASE_MELEE_MS[PhaseIndex(state)];

            if (expired)
            {
                // Half of what is left, not the full absorb: a group that cannot
                // break the shield must still make progress, or the heal cancels
                // every point of damage the fight produces and the attempt stalls.
                uint32 const healed = state.bulwarkRemaining / 2;
                me->ModifyHealth(int32(healed));
                LOG_INFO("coa", "NYTHAROS: bulwark survived, healed {}", healed);
            }
            else
            {
                LOG_INFO("coa", "NYTHAROS: bulwark broken");
            }
        }

        void StartBulwark(NytharosState& state, uint32 now)
        {
            LOG_INFO("coa", "NYTHAROS: bulwark start");
            state.bulwarkAmount = std::max<uint32>(1,
                uint32(float(me->GetMaxHealth()) * NY_PHASE_BULWARK_PCT[PhaseIndex(state)]));
            state.bulwarkRemaining = state.bulwarkAmount;
            state.bulwarkEnds = now + NY_BULWARK_MS;
            state.bulwarkActive = true;
            state.nextKnockPulse = now;
            state.bulwarkVisX = me->GetPositionX();
            state.bulwarkVisY = me->GetPositionY();

            // Plain cast, not TRIGGERED_FULL_MASK: the aura then travels through
            // the normal spell path, which is what makes the client treat its
            // StateKit as a unit aura visual instead of a world effect.
            me->CastCustomSpell(NY_BULWARK, SPELLVALUE_BASE_POINT0, int32(state.bulwarkAmount),
                me, TRIGGERED_NONE);

            LOG_INFO("coa", "NYTHAROS: bulwark absorbing {}", state.bulwarkAmount);
        }
    };

    class NytharosTornadoAI : public CreatureAI
    {
    public:
        explicit NytharosTornadoAI(Creature* creature) : CreatureAI(creature) { }

        void InitializeAI() override
        {
            me->SetReactState(REACT_PASSIVE);
            me->SetSpeed(MOVE_RUN, NY_SPOUT_SPEED);
            me->CastSpell(me, NY_SPOUT_VISUAL, true);
            me->SendPlaySpellVisual(NY_SPOUT_KIT);

            _expireAt = getMSTime() + NY_SPOUT_LIFE_MS;
            _nextMove = 0;
            _nextSound = getMSTime() + 300;
            _nextContact = 0;

            _originX = me->GetPositionX();
            _originY = me->GetPositionY();

            auto const initial = g_spoutInitialTargets.find(me->GetGUID());
            if (initial != g_spoutInitialTargets.end())
            {
                _chaseTarget = initial->second;
                g_spoutInitialTargets.erase(initial);
            }

            CreatureAI::InitializeAI();
        }

        void UpdateAI(uint32 /*diff*/) override
        {
            uint32 const now = getMSTime();

            if (now >= _expireAt)
            {
                g_spoutSummons.erase(std::remove(g_spoutSummons.begin(), g_spoutSummons.end(), me->GetGUID()),
                    g_spoutSummons.end());
                me->PlayDirectSound(0);
                me->PlayDistanceSound(0);
                me->DespawnOrUnsummon();
                return;
            }

            // Contact is checked every tick so the slow lands the instant a
            // player touches the spout, not on a one second beat.
            DoContact(now);

            if (now >= _nextMove)
            {
                _nextMove = now + 1000;
                Chase();
            }
        }

    private:
        uint32 _expireAt = 0;
        uint32 _nextMove = 0;
        uint32 _nextSound = 0;
        uint32 _nextContact = 0;
        ObjectGuid _chaseTarget;
        float _originX = 0.0f;
        float _originY = 0.0f;

        void Chase()
        {
            // Locked on? Keep pressing that player, from this spout's own side.
            if (!_chaseTarget.IsEmpty())
            {
                Player* target = ObjectAccessor::GetPlayer(*me, _chaseTarget);
                if (target && target->IsAlive() && me->GetExactDist2d(target) < 80.0f)
                {
                    float const side = float(me->GetGUID().GetCounter() % 8) * (2.0f * float(M_PI) / 8.0f);
                    me->GetMotionMaster()->MovePoint(0,
                        target->GetPositionX() + std::cos(side) * 2.0f,
                        target->GetPositionY() + std::sin(side) * 2.0f,
                        target->GetPositionZ());
                    return;
                }
                _chaseTarget.Clear();
            }

            // Nobody locked yet: patrol until someone comes within reach, then
            // take the player furthest from where this spout spawned - that is
            // the backline (ranged and healers) by construction. A tank or melee
            // standing there is fair game like anyone else.
            std::vector<Player*> candidates;
            Map::PlayerList const& players = me->GetMap()->GetPlayers();
            for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
            {
                Player* player = itr->GetSource();
                if (!player || !player->IsAlive() || !player->InSamePhase(me))
                    continue;
                if (me->GetExactDist2d(player) > NY_SPOUT_DETECT)
                    continue;
                candidates.push_back(player);
            }

            if (!candidates.empty())
            {
                Player* pick = candidates.front();
                float bestDepth = -1.0f;
                for (Player* player : candidates)
                {
                    float const depth = player->GetExactDist2d(_originX, _originY);
                    if (depth > bestDepth)
                    {
                        bestDepth = depth;
                        pick = player;
                    }
                }

                _chaseTarget = pick->GetGUID();

                // Approach from this spout's own side so several of them never
                // converge on the same point, even against a single player.
                float const side = float(me->GetGUID().GetCounter() % 8) * (2.0f * float(M_PI) / 8.0f);
                me->GetMotionMaster()->MovePoint(0,
                    pick->GetPositionX() + std::cos(side) * 2.0f,
                    pick->GetPositionY() + std::sin(side) * 2.0f,
                    pick->GetPositionZ());
                return;
            }

            // Nothing in reach: patrol.
            float const angle = frand(0.0f, 2.0f * float(M_PI));
            float const dist = frand(4.0f, NY_SPOUT_WANDER);
            me->GetMotionMaster()->MovePoint(0,
                me->GetPositionX() + std::cos(angle) * dist,
                me->GetPositionY() + std::sin(angle) * dist,
                me->GetPositionZ());
        }

        void DoContact(uint32 now)
        {
            // Damage once a second; the slow is refreshed every tick so it is
            // on the player the moment they touch the spout.
            bool const damageTick = now >= _nextContact;
            if (damageTick)
                _nextContact = now + 1000;

            Map::PlayerList const& players = me->GetMap()->GetPlayers();
            for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
            {
                Player* player = itr->GetSource();
                if (!player || !player->IsAlive() || !player->InSamePhase(me))
                    continue;
                if (me->GetExactDist2d(player) > NY_SPOUT_CONTACT)
                    continue;

                // Only apply when it is not already up, otherwise every tick
                // refreshes it and floods the combat log.
                if (!player->HasAura(NY_SPOUT_SLOW))
                    player->AddAura(NY_SPOUT_SLOW, player);

                if (!damageTick)
                    continue;

                // Applied by Nytharos rather than this dummy: a triggered cast
                // from an unselectable summon resolves for nothing, and routing it
                // through his carrier spell is what keeps absorbs and the combat
                // log correct. The amount is a share of the victim's own pool.
                if (Creature* boss = me->FindNearestCreature(NYTHAROS_ENTRY, 90.0f))
                    ApexScaling::ApplyHit(boss, player,
                        {NY_SPOUT_PCT, NY_SPOUT_FLOOR, NY_SPOUT_CEILING}, NY_CARRIER_NATURE);
            }
        }

    };

    class NytharosTornadoScript : public CreatureScript
    {
    public:
        NytharosTornadoScript() : CreatureScript("NytharosTornadoScript") { }

        CreatureAI* GetAI(Creature* creature) const override
        {
            if (!creature || creature->GetEntry() != NY_TORNADO_ENTRY)
                return nullptr;

            return new NytharosTornadoAI(creature);
        }
    };

    // The shell rides Nytharos. A creature body follows nothing but its own
    // position, so it is re-parked on him continuously - that is what makes it
    // survive jumps, dashes and knockbacks.
    class NytharosShellAI : public CreatureAI
    {
    public:
        explicit NytharosShellAI(Creature* creature) : CreatureAI(creature) { }

        void InitializeAI() override
        {
            me->SetReactState(REACT_PASSIVE);
            me->SetVisible(true);
            CreatureAI::InitializeAI();
        }

        void UpdateAI(uint32 /*diff*/) override
        {
            Creature* nytharos = me->FindNearestCreature(NYTHAROS_ENTRY, 120.0f, true);
            if (!nytharos || !nytharos->IsAlive())
            {
                me->DespawnOrUnsummon();
                return;
            }

            me->NearTeleportTo(nytharos->GetPositionX(), nytharos->GetPositionY(),
                nytharos->GetPositionZ() + NY_BULWARK_SHELL_Z, nytharos->GetOrientation());
        }
    };

    class NytharosShellScript : public CreatureScript
    {
    public:
        NytharosShellScript() : CreatureScript("NytharosShellScript") { }

        CreatureAI* GetAI(Creature* creature) const override
        {
            if (!creature || creature->GetEntry() != NY_BULWARK_SHELL)
                return nullptr;

            return new NytharosShellAI(creature);
        }
    };

    class NytharosCreatureScript : public CreatureScript
    {
    public:
        NytharosCreatureScript() : CreatureScript("NytharosCreatureScript") { }

        CreatureAI* GetAI(Creature* creature) const override
        {
            if (!creature || creature->GetEntry() != NYTHAROS_ENTRY)
                return nullptr;

            return new NytharosAI(creature);
        }
    };

    class NytharosUnitScript : public UnitScript
    {
    public:
        NytharosUnitScript() : UnitScript("NytharosUnitScript", true,
            {UNITHOOK_MODIFY_MELEE_DAMAGE}) { }

        // Runs before armour is applied, so the swing is a share of the victim's
        // pool and still goes through mitigation, block and crit afterwards.
        void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
        {
            if (!target || !attacker || !attacker->IsCreature() ||
                attacker->GetEntry() != NYTHAROS_ENTRY)
                return;

            damage = ApexScaling::Amount(target,
                {NY_AUTO_PCT, NY_AUTO_FLOOR, NY_AUTO_CEILING});
        }
    };
}

void AddNytharosScripts()
{
    for (uint32 spellId : NYTHAROS_CLIENT_SPELLS)
        Ascension::ClientSpellPatches::Instance().Register(spellId);

    new NytharosCreatureScript();
    new NytharosTornadoScript();
    new NytharosShellScript();
    new NytharosUnitScript();
}
