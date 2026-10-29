#include "Vaelthara.h"

#include "AllCreatureScript.h"
#include "ApexScaling.h"
#include "AscensionClientSpellPatches.h"
#include "Chat.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "CreatureScript.h"
#include "Log.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "Timer.h"
#include "UnitScript.h"

#include <algorithm>
#include <array>
#include <mutex>
#include <unordered_map>

namespace
{
    constexpr uint32 VAELTHARA_ENTRY = 9916223;

    // Field diagnostics. Off for the locked encounter; flip to true to get one
    // state line per second while investigating a live issue.
    constexpr bool VAELTHARA_DIAGNOSTICS = false;

    // ---- Hunger ----------------------------------------------------------
    constexpr uint32 VAELTHARA_HUNGER = 1004200;
    constexpr uint32 VAELTHARA_HUNGER_STARVING = 1004201;
    constexpr uint32 VAELTHARA_HUNGER_FRENZIED = 1004202;
    constexpr uint32 VAELTHARA_HUNGER_GORGED = 1004203;
    constexpr uint32 VAELTHARA_HUNGER_GORGED_IMMUNITY = 1004204;

    constexpr std::array<uint32, 17> VAELTHARA_CLIENT_SPELLS = {
        VAELTHARA_HUNGER, VAELTHARA_HUNGER_STARVING, VAELTHARA_HUNGER_FRENZIED,
        VAELTHARA_HUNGER_GORGED, VAELTHARA_HUNGER_GORGED_IMMUNITY,
        1004210, 1004211, 1004212, 1004213, 1004214, 1004215,
        1004220, 1004221, 2880, 1004230, 1004240, 1004250};

    constexpr uint8 VAELTHARA_HUNGER_BASE = 1;
    constexpr uint8 VAELTHARA_HUNGER_MAX = 20;
    constexpr uint8 VAELTHARA_HUNGER_STARVING_MAX = 4;
    constexpr uint8 VAELTHARA_HUNGER_FRENZIED_AT = 12;
    constexpr uint8 VAELTHARA_HUNGER_GORGED_AT = 20;
    constexpr uint8 VAELTHARA_HUNGER_GORGED_FALLBACK = 12;

    constexpr uint32 VAELTHARA_HUNGER_GRACE_MS = 3000;
    constexpr uint32 VAELTHARA_HUNGER_DECAY_MS = 500;
    constexpr uint32 VAELTHARA_GORGED_DURATION_MS = 10000;
    constexpr uint32 VAELTHARA_GORGED_COOLDOWN_MS = 30000;

    // ---- phases ----------------------------------------------------------
    // P1 100-70: as tuned. P2 70-35: everything comes round sooner and Hunger
    // holds longer. P3 35-0: the Desperation band, where the whole cadence
    // tightens again and the Gorged lockout halves.
    constexpr float VAELTHARA_PHASE2_PCT = 70.0f;
    constexpr float VAELTHARA_PHASE3_PCT = 35.0f;

    constexpr uint32 VAELTHARA_BLOODRUSH_MS_P2 = 10000;
    constexpr uint32 VAELTHARA_BLOODRUSH_MS_P3 = 8000;
    constexpr uint32 VAELTHARA_WHIRL_MS_P2 = 16000;
    constexpr uint32 VAELTHARA_WHIRL_MS_P3 = 12000;
    constexpr uint32 VAELTHARA_STALK_MS_P2 = 30000;
    constexpr uint32 VAELTHARA_STALK_MS_P3 = 25000;
    constexpr uint32 VAELTHARA_HUNGER_DECAY_MS_P2 = 600;
    constexpr uint32 VAELTHARA_HUNGER_DECAY_MS_P3 = 750;
    constexpr uint32 VAELTHARA_GORGED_COOLDOWN_MS_P3 = 20000;

    // Yells, one per transition. Written as narration rather than dialogue, so
    // the line describes her state instead of her speaking.
    constexpr char const* VAELTHARA_YELL_P2 = "Vaelthara's scars flare as she digs her claws in.";
    constexpr char const* VAELTHARA_YELL_P3 = "Vaelthara is cornered, and every instinct turns to the kill.";

    // Two kits are played together: 81 is Enrage's SpellVisual 870 cast kit and
    // is the one that actually renders the aura; 392 is the cast kit of
    // SpellVisual 249 and drives animation 55 (this model's BattleRoar) plus
    // hand-attached glow. 392 alone renders nothing on this model.
    constexpr uint32 VAELTHARA_ENRAGE_KIT = 81;
    constexpr uint32 VAELTHARA_ENRAGE_ANIM_KIT = 392;

    // ---- Owlcat Rend -----------------------------------------------------
    constexpr uint32 VAELTHARA_REND = 1004210;
    // SoundEntries 117796 = sound/spells/spell_dr_rake01..05.ogg
    constexpr uint32 VAELTHARA_SOUND_REND = 117796;
    // A stacked periodic aura does not multiply its tick in this core, so each
    // Festering Wound stack applies the next rank: 20/40/60/80/100 per 1 s.
    constexpr std::array<uint32, 5> VAELTHARA_WOUND_RANKS = {
        1004211, 1004212, 1004213, 1004214, 1004215};
    constexpr uint32 VAELTHARA_REND_EVERY_SWINGS = 3;
    constexpr uint32 VAELTHARA_BLEED_HUNGER_INTERVAL_MS = 2000;
    constexpr uint8 VAELTHARA_WOUND_MAX_STACKS = 5;

    // ---- Bloodrush -------------------------------------------------------
    constexpr uint32 VAELTHARA_BLOODRUSH = 1004220;
    constexpr uint32 VAELTHARA_BLOODRUSH_IMPACT = 1004221;
    constexpr uint32 VAELTHARA_BLOODRUSH_LAND_KIT = 99091; // swipe at her feet
    constexpr uint32 VAELTHARA_WINDED = 2880;              // stock Stun row, renamed Winded
    constexpr uint32 VAELTHARA_WINDED_MS = 5000;

    // ---- Stalk -----------------------------------------------------------
    constexpr uint32 VAELTHARA_STALKED = 1004230;          // marker on the fixated player
    constexpr uint32 VAELTHARA_STALK_FIRST_MS = 20000;     // first stalk after engaging
    constexpr uint32 VAELTHARA_STALK_INTERVAL_MS = 35000;  // then every 35 s
    constexpr uint32 VAELTHARA_STALK_MS = 6000;            // how long she ignores threat
    constexpr float VAELTHARA_STALK_LEASH = 60.0f;         // target escaping past this ends it
    constexpr float VAELTHARA_STALK_THREAT = 1000000.0f;   // Grilek-style fixation weight

    // ---- Whirling Claws --------------------------------------------------
    constexpr uint32 VAELTHARA_WHIRL = 1004240;            // 400 physical sweep
    constexpr uint32 VAELTHARA_WHIRL_KIT = 99099;          // hymdall whirlwind at her feet
    constexpr float VAELTHARA_WHIRL_RADIUS = 12.0f;
    constexpr float VAELTHARA_WHIRL_KNOCKBACK_SPEED = 21.0f;
    constexpr float VAELTHARA_WHIRL_KNOCKBACK_UP = 9.5f;
    constexpr uint32 VAELTHARA_WHIRL_FIRST_MS = 12000;
    constexpr uint32 VAELTHARA_WHIRL_INTERVAL_MS = 20000;
    constexpr uint32 VAELTHARA_SOUND_WHIRL = 195372;       // spell_dr_swipe_revamp_cast_01..03.ogg

    // ---- Desperation -----------------------------------------------------
    constexpr uint32 VAELTHARA_DESPERATE = 1004250;        // +30% damage, +20% speed
    constexpr float VAELTHARA_DESPERATE_PCT = 35.0f;       // health threshold
    constexpr uint32 VAELTHARA_SOUND_BLOODRUSH = 283882;   // spell_leapingrush_02.ogg
    constexpr uint32 VAELTHARA_BLOODRUSH_FIRST_MS = 8000;
    constexpr uint32 VAELTHARA_BLOODRUSH_INTERVAL_MS = 12000;
    constexpr float VAELTHARA_BLOODRUSH_MIN_DIST = 3.0f;
    constexpr float VAELTHARA_BLOODRUSH_MAX_DIST = 40.0f;
    constexpr float VAELTHARA_BLOODRUSH_RADIUS = 4.0f;
    constexpr float VAELTHARA_BLOODRUSH_SPEED = 18.0f;
    constexpr float VAELTHARA_BLOODRUSH_JUMP_Z = 10.0f;

    enum VaeltharaHungerState : uint8
    {
        HUNGER_FED = 0,
        HUNGER_STARVING = 1,
        HUNGER_FRENZIED = 2,
        HUNGER_GORGED = 3,
    };

    // ---- Voice -----------------------------------------------------------
    // Owlcat voice = CreatureSoundData 5197, SoundEntries 62719 pre-aggro,
    // 62720 aggro, 62714 attack, 62716 wound, 62717 wound crit, 62718 death.
    // Those rows exist in SoundEntries.dbc, but a hash-table probe of all 78
    // archives in the client found 0 of the 82 referenced
    // sound\creature\owlcat\*.ogg files, so the original kit is silent here.
    // Flip this to true once the files are present; the ids are already wired.
    constexpr bool VAELTHARA_USE_ORIGINAL_OWLCAT_VOICE = false;

    constexpr uint32 VAELTHARA_SOUND_PRE_AGGRO_OWLCAT = 62719;
    constexpr uint32 VAELTHARA_SOUND_AGGRO_OWLCAT = 62720;
    constexpr uint32 VAELTHARA_SOUND_ATTACK_OWLCAT = 62714;
    constexpr uint32 VAELTHARA_SOUND_WOUND_OWLCAT = 62716;
    constexpr uint32 VAELTHARA_SOUND_DEATH_OWLCAT = 62718;

    // Audible stand-in while the owlcat files are absent.
    constexpr uint32 VAELTHARA_SOUND_PRE_AGGRO_STANDIN = 3604; // owl pre-aggro
    constexpr uint32 VAELTHARA_SOUND_AGGRO_STANDIN = 3605;     // owl aggro
    constexpr uint32 VAELTHARA_SOUND_ATTACK_STANDIN = 643;     // tiger attack
    constexpr uint32 VAELTHARA_SOUND_WOUND_STANDIN = 644;      // tiger wound
    constexpr uint32 VAELTHARA_SOUND_DEATH_STANDIN = 646;      // tiger death

    constexpr uint32 VAELTHARA_SOUND_PRE_AGGRO =
        VAELTHARA_USE_ORIGINAL_OWLCAT_VOICE ? VAELTHARA_SOUND_PRE_AGGRO_OWLCAT : VAELTHARA_SOUND_PRE_AGGRO_STANDIN;
    constexpr uint32 VAELTHARA_SOUND_AGGRO =
        VAELTHARA_USE_ORIGINAL_OWLCAT_VOICE ? VAELTHARA_SOUND_AGGRO_OWLCAT : VAELTHARA_SOUND_AGGRO_STANDIN;
    constexpr uint32 VAELTHARA_SOUND_ATTACK =
        VAELTHARA_USE_ORIGINAL_OWLCAT_VOICE ? VAELTHARA_SOUND_ATTACK_OWLCAT : VAELTHARA_SOUND_ATTACK_STANDIN;
    constexpr uint32 VAELTHARA_SOUND_WOUND =
        VAELTHARA_USE_ORIGINAL_OWLCAT_VOICE ? VAELTHARA_SOUND_WOUND_OWLCAT : VAELTHARA_SOUND_WOUND_STANDIN;
    constexpr uint32 VAELTHARA_SOUND_DEATH =
        VAELTHARA_USE_ORIGINAL_OWLCAT_VOICE ? VAELTHARA_SOUND_DEATH_OWLCAT : VAELTHARA_SOUND_DEATH_STANDIN;

    // ---- Animation -------------------------------------------------------
    // Owlcat model sequences (patch-CO.MPQ):
    //   55 BattleRoar, 61 Eat, 69 Dance, 75 Kneel, 96-101 sit/sleep,
    //   123 UseStandingLoop. Emote 1010 maps to animation 55.
    constexpr uint32 VAELTHARA_EMOTE_BATTLE_ROAR = 1010;

    constexpr uint32 VAELTHARA_ATTACK_SOUND_INTERVAL_MS = 1700;
    constexpr uint32 VAELTHARA_WOUND_SOUND_INTERVAL_MS = 1500;
    constexpr uint32 VAELTHARA_PRE_AGGRO_INTERVAL_MS = 20000;
    constexpr float VAELTHARA_PRE_AGGRO_RADIUS = 25.0f;

    struct VaeltharaState
    {
        // voice
        bool inCombat = false;
        bool deathSoundPlayed = false;
        uint32 lastHealth = 0;
        uint32 nextAttackSound = 0;
        uint32 nextWoundSound = 0;
        uint32 nextPreAggroSound = 0;

        // hunger
        uint8 hunger = VAELTHARA_HUNGER_BASE;
        uint8 appliedHunger = 0;
        uint8 hungerState = HUNGER_FED;
        uint32 lastContact = 0;
        uint32 nextDecay = 0;
        bool gorgedActive = false;
        uint32 gorgedEnds = 0;
        uint32 gorgedReadyAt = 0;

        uint32 nextDiagnostic = 0;

        // rend
        uint32 swingCounter = 0;
        bool rendPending = false;
        uint32 nextBleedHunger = 0;
        std::unordered_map<uint32, uint8> woundStacks;

        // bloodrush
        uint32 nextBloodrush = 0;
        bool bloodrushInAir = false;
        uint32 nextWindedAt = 0;

        // stalk
        uint32 nextStalk = 0;
        ObjectGuid stalkTarget;
        uint32 stalkEnds = 0;
        bool stalkThreatPushed = false;
        float stalkThreatBefore = 0.0f;

        // whirl
        uint32 nextWhirl = 0;

        // desperation
        bool desperate = false;

        // phases
        uint8 phase = 1;

        // pool sizing, same blueprint as the other apex bosses
        ApexScaling::Probe probe;
    };

    // Shared between the creature script (state machine) and the unit script
    // (melee damage hook), so a landed hit can feed the meter. Both run on the map
    // thread of the instance she is in; the lock keeps a second instance's thread
    // (or a hook running elsewhere) from rehashing the map under a reader.
    std::recursive_mutex g_vaeltharaStateMutex;
    std::unordered_map<uint32, VaeltharaState> g_vaeltharaStates;

    // "Is this player fighting her?" She can hold a victim without a threat
    // entry (an owned creature targets through its owner), so threat alone is
    // not enough; a bystander matches neither branch.
    static bool IsFighting(Creature* creature, Player* player)
    {
        if (!creature || !player)
            return false;
        if (creature->GetVictim() == player)
            return true;
        return creature->GetThreatMgr().GetThreat(player, true) > 0.0f;
    }

    // Her combat brain. The core cannot supply one: CreatureAI::AttackedBy is
    // commented out upstream, so a defensive creature never calls AttackStart
    // when something hits it. Without this she stands through the whole fight,
    // never builds threat, and drops combat the moment the attacker pauses -
    // then walks on along her patrol. She stays REACT_DEFENSIVE, so she still
    // never starts a fight on her own.
    class VaeltharaAI : public CreatureAI
    {
    public:
        explicit VaeltharaAI(Creature* creature) : CreatureAI(creature) { }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType /*damageType*/,
            SpellSchoolMask /*schoolMask*/) override
        {
            if (!attacker || !attacker->IsAlive() || !me->IsAlive())
                return;

            std::lock_guard<std::recursive_mutex> lock(g_vaeltharaStateMutex);

            auto itr = g_vaeltharaStates.find(me->GetGUID().GetCounter());
            if (itr != g_vaeltharaStates.end())
                ApexScaling::ObserveProbe(itr->second.probe, damage);

            if (!me->IsInCombat() || !me->GetVictim())
                ApexScaling::StartApexPull(me, attacker);

            me->AddThreat(attacker, 1.0f);
        }

        void UpdateAI(uint32 /*diff*/) override
        {
            std::lock_guard<std::recursive_mutex> lock(g_vaeltharaStateMutex);

            if (me->IsInCombat())
            {
                // Damage normally extends the leash for ~15 s, after which
                // CanCreatureAttack rejects anything beyond CreatureLeashRadius
                // of her spawn and SelectVictim evades. Holding the extension
                // open keeps a fight alive while the player kites her along her
                // own path instead of ending it mid-pull.
                me->UpdateLeashExtensionTime();

                // While stalking she ignores the threat list entirely and stays
                // glued to the fixated player.
                auto const stalked = g_vaeltharaStates.find(me->GetGUID().GetCounter());
                if (stalked != g_vaeltharaStates.end() && !stalked->second.stalkTarget.IsEmpty())
                {
                    if (Player* fixated = ObjectAccessor::GetPlayer(*me, stalked->second.stalkTarget))
                    {
                        if (fixated->IsAlive() && me->CanCreatureAttack(fixated))
                        {
                            if (me->GetVictim() != fixated)
                                AttackStart(fixated);
                            DoMeleeAttackIfReady();
                            return;
                        }
                    }
                }

                if (!me->GetVictim())
                    if (Player* engaged = FindEngagedPlayer())
                        AttackStart(engaged);
            }

            if (!UpdateVictim())
                return;

            DoMeleeAttackIfReady();
        }

    private:
        Player* FindEngagedPlayer() const
        {
            Player* best = nullptr;
            float bestDist = 0.0f;
            Map::PlayerList const& players = me->GetMap()->GetPlayers();
            for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
            {
                Player* player = itr->GetSource();
                if (!player || !player->IsAlive() || !player->InSamePhase(me))
                    continue;
                if (!IsFighting(me, player))
                    continue;

                float const dist = me->GetExactDist2d(player);
                if (!best || dist < bestDist)
                {
                    best = player;
                    bestDist = dist;
                }
            }
            return best;
        }
    };

    class VaeltharaAIScript : public CreatureScript
    {
    public:
        VaeltharaAIScript() : CreatureScript("VaeltharaAIScript") { }

        CreatureAI* GetAI(Creature* creature) const override
        {
            if (!creature || creature->GetEntry() != VAELTHARA_ENTRY)
                return nullptr;

            return new VaeltharaAI(creature);
        }
    };

    class VaeltharaCreatureScript : public AllCreatureScript
    {
    public:
        VaeltharaCreatureScript() : AllCreatureScript("VaeltharaCreatureScript") { }

        void OnCreatureAddWorld(Creature* creature) override
        {
            if (!creature || creature->GetEntry() != VAELTHARA_ENTRY)
                return;

            std::lock_guard<std::recursive_mutex> lock(g_vaeltharaStateMutex);

            ApexScaling::TuneHitbox(creature);
            creature->SetReactState(REACT_DEFENSIVE);

            VaeltharaState& state = g_vaeltharaStates[creature->GetGUID().GetCounter()];
            state = VaeltharaState();
            state.lastContact = getMSTime();
            ApplyHunger(creature, state);

            LOG_INFO("coa", "VAELTHARA: {} added, react={} reach={:.2f} size={:.2f} hunger={}",
                creature->GetGUID().ToString(), uint32(creature->GetReactState()),
                creature->GetCombatReach(), creature->GetObjectSize(), state.hunger);
        }

        void OnCreatureRemoveWorld(Creature* creature) override
        {
            if (creature && creature->GetEntry() == VAELTHARA_ENTRY)
            {
                std::lock_guard<std::recursive_mutex> lock(g_vaeltharaStateMutex);
                g_vaeltharaStates.erase(creature->GetGUID().GetCounter());
            }
        }

        void OnAllCreatureUpdate(Creature* creature, uint32) override
        {
            if (!creature || creature->GetEntry() != VAELTHARA_ENTRY)
                return;

            std::lock_guard<std::recursive_mutex> lock(g_vaeltharaStateMutex);

            // Her patrol spans far more than the 30-yard home leash, so keep home
            // on the current patrol point until she is engaged.
            if (!creature->IsInCombat())
                creature->SetHomePosition(creature->GetPositionX(), creature->GetPositionY(),
                    creature->GetPositionZ(), creature->GetOrientation());

            VaeltharaState& state = g_vaeltharaStates[creature->GetGUID().GetCounter()];
            uint32 const now = getMSTime();

            if (!creature->IsAlive())
            {
                if (!state.deathSoundPlayed)
                {
                    PlaySound(creature, VAELTHARA_SOUND_DEATH, "death");
                    state.deathSoundPlayed = true;
                }
                state.inCombat = false;
                ResetHunger(creature, state, now);
                return;
            }

            state.deathSoundPlayed = false;

            if (creature->IsInEvadeMode())
            {
                ResetHunger(creature, state, now);
                state.inCombat = false;
                return;
            }

            // A lost chase generator leaves the patrol on top and she keeps walking
            // her route while in combat.
            ApexScaling::KeepApexChase(creature);
            ApexScaling::TuneHitbox(creature);

            UpdateHunger(creature, state, now);
            UpdateVoice(creature, state, now);

            // Same pool blueprint as Nytharos: start from a deliberately large pool,
            // measure the group for fifteen seconds, then size the fight from that.
            if (creature->IsInCombat())
            {
                if (!state.probe.Base)
                {
                    ApexScaling::ResetProbe(state.probe, creature);
                    ApexScaling::ScaleHealth(creature, state.probe.Base, 0.0f);
                }

                ApexScaling::ResolveProbe(state.probe, creature);
            }
            else if (state.probe.Base && !ApexScaling::StillEngaged(creature))
            {
                // The pull is genuinely over: put the pool back where it started so
                // the next group is measured fresh. A momentary evade with players
                // still standing there keeps the pool it was sized at.
                ApexScaling::RestoreHealth(creature, state.probe.Base);
                state.probe = ApexScaling::Probe();
            }

            if (VAELTHARA_DIAGNOSTICS)
                LogDiagnostic(creature, state, now);
        }

    private:
        // ---- phases ------------------------------------------------------
        static uint8 PhaseFor(Creature* creature)
        {
            float const pct = creature->GetHealthPct();
            if (pct <= VAELTHARA_PHASE3_PCT)
                return 3;
            if (pct <= VAELTHARA_PHASE2_PCT)
                return 2;
            return 1;
        }

        static uint32 BloodrushInterval(uint8 phase)
        {
            if (phase >= 3) return VAELTHARA_BLOODRUSH_MS_P3;
            if (phase == 2) return VAELTHARA_BLOODRUSH_MS_P2;
            return VAELTHARA_BLOODRUSH_INTERVAL_MS;
        }

        static uint32 WhirlInterval(uint8 phase)
        {
            if (phase >= 3) return VAELTHARA_WHIRL_MS_P3;
            if (phase == 2) return VAELTHARA_WHIRL_MS_P2;
            return VAELTHARA_WHIRL_INTERVAL_MS;
        }

        static uint32 StalkInterval(uint8 phase)
        {
            if (phase >= 3) return VAELTHARA_STALK_MS_P3;
            if (phase == 2) return VAELTHARA_STALK_MS_P2;
            return VAELTHARA_STALK_INTERVAL_MS;
        }

        static uint32 DecayInterval(uint8 phase)
        {
            if (phase >= 3) return VAELTHARA_HUNGER_DECAY_MS_P3;
            if (phase == 2) return VAELTHARA_HUNGER_DECAY_MS_P2;
            return VAELTHARA_HUNGER_DECAY_MS;
        }

        static uint32 GorgedCooldown(uint8 phase)
        {
            return phase >= 3 ? VAELTHARA_GORGED_COOLDOWN_MS_P3 : VAELTHARA_GORGED_COOLDOWN_MS;
        }

        static void UpdatePhase(Creature* creature, VaeltharaState& state, uint32 now)
        {
            uint8 const phase = PhaseFor(creature);
            if (phase == state.phase)
                return;

            state.phase = phase;

            // Pull any pending timer in, so the new cadence takes effect now
            // instead of after the old, longer interval has run out.
            state.nextBloodrush = std::min(state.nextBloodrush, now + BloodrushInterval(phase));
            state.nextWhirl = std::min(state.nextWhirl, now + WhirlInterval(phase));
            state.nextStalk = std::min(state.nextStalk, now + StalkInterval(phase));

            // Phase one is the silent default: no yell on the way back up.
            if (!creature->IsInCombat() || phase == 1)
                return;

            creature->Yell(phase == 3 ? VAELTHARA_YELL_P3 : VAELTHARA_YELL_P2, LANG_UNIVERSAL);
            LOG_INFO("coa", "VAELTHARA: phase {} at {:.0f}%", uint32(phase), creature->GetHealthPct());
        }

        static void DoDesperation(Creature* creature, VaeltharaState& state)
        {
            // Cornered: below 35% she fights harder until she is back above it.
            if (!state.desperate && creature->GetHealthPct() <= VAELTHARA_DESPERATE_PCT)
            {
                state.desperate = true;
                creature->CastSpell(creature, VAELTHARA_DESPERATE, true);
                LOG_INFO("coa", "VAELTHARA: desperate at {:.0f}%", creature->GetHealthPct());
            }
            else if (state.desperate && creature->GetHealthPct() > VAELTHARA_DESPERATE_PCT)
            {
                state.desperate = false;
                creature->RemoveAurasDueToSpell(VAELTHARA_DESPERATE);
                LOG_INFO("coa", "VAELTHARA: desperation faded at {:.0f}%", creature->GetHealthPct());
            }
        }

        // ---- hunger ------------------------------------------------------
        static void ResetHunger(Creature* creature, VaeltharaState& state, uint32 now)
        {
            state.gorgedActive = false;
            state.gorgedEnds = 0;
            state.hunger = VAELTHARA_HUNGER_BASE;
            state.lastContact = now;
            state.nextDecay = 0;
            state.nextBloodrush = now + VAELTHARA_BLOODRUSH_FIRST_MS;
            state.nextStalk = now + VAELTHARA_STALK_FIRST_MS;
            state.stalkTarget.Clear();
            state.stalkEnds = 0;
            state.stalkThreatPushed = false;
            state.nextWhirl = now + VAELTHARA_WHIRL_FIRST_MS;
            state.desperate = false;
            state.phase = 1;
            creature->RemoveAurasDueToSpell(VAELTHARA_DESPERATE);
            ApplyHunger(creature, state);
        }

        static void UpdateHunger(Creature* creature, VaeltharaState& state, uint32 now)
        {
            // Hunger is fed by VaeltharaUnitScript::ModifyMeleeDamage, which only
            // runs when a swing resolves into damage. A miss, dodge, parry or
            // full absorb never reaches that hook.

            // Phase transitions drive cadence, decay and the two yells.
            UpdatePhase(creature, state, now);
            DoDesperation(creature, state);

            // Only a stun or root that catches her mid-leap winds her, and only
            // when she is not in the Gorged immunity window. A stun while she is
            // grounded is handled by the client and does not wind her.
            if (state.bloodrushInAir &&
                now >= state.nextWindedAt &&
                !creature->HasAura(VAELTHARA_WINDED) &&
                !creature->HasAura(VAELTHARA_HUNGER_GORGED_IMMUNITY) &&
                (creature->HasUnitState(UNIT_STATE_STUNNED) || creature->HasUnitState(UNIT_STATE_ROOT)))
            {
                LOG_INFO("coa", "VAELTHARA: bloodrush interrupted mid-air, winded");
                ApplyWinded(creature, state, now);
            }

            // Gorged window.
            if (state.gorgedActive)
            {
                if (now >= state.gorgedEnds)
                {
                    state.gorgedActive = false;
                    state.hunger = VAELTHARA_HUNGER_GORGED_FALLBACK;
                    state.lastContact = now;
                }
            }
            else if (state.hunger >= VAELTHARA_HUNGER_GORGED_AT &&
                     now >= state.gorgedReadyAt)
            {
                state.gorgedActive = true;
                state.gorgedEnds = now + VAELTHARA_GORGED_DURATION_MS;
                state.gorgedReadyAt = now + GorgedCooldown(state.phase);

                creature->SendPlaySpellVisual(VAELTHARA_ENRAGE_KIT);
                creature->SendPlaySpellVisual(VAELTHARA_ENRAGE_ANIM_KIT);
                LOG_INFO("coa", "VAELTHARA: gorged for {} ms", VAELTHARA_GORGED_DURATION_MS);
            }

            // Owlcat Rend: every third landed swing, cast Rend and advance the
            // target's Festering Wound to the next rank.
            if (state.rendPending)
            {
                state.rendPending = false;
                Unit* victim = creature->GetVictim();
                if (victim && victim->IsAlive() && victim->IsPlayer())
                {
                    uint32 const victimId = victim->GetGUID().GetCounter();
                    uint8 stack = 1;
                    auto itr = state.woundStacks.find(victimId);
                    if (itr != state.woundStacks.end())
                    {
                        bool const active = victim->HasAura(VAELTHARA_WOUND_RANKS[0]) ||
                            victim->HasAura(VAELTHARA_WOUND_RANKS[1]) ||
                            victim->HasAura(VAELTHARA_WOUND_RANKS[2]) ||
                            victim->HasAura(VAELTHARA_WOUND_RANKS[3]) ||
                            victim->HasAura(VAELTHARA_WOUND_RANKS[4]);
                        if (active)
                            stack = std::min<uint8>(VAELTHARA_WOUND_MAX_STACKS, uint8(itr->second + 1));
                    }

                    creature->PlayDirectSound(VAELTHARA_SOUND_REND);
                    creature->CastSpell(victim, VAELTHARA_REND, true);
                    ApexScaling::ApplyHit(creature, victim,
                        {ApexScaling::ABILITY_PCT, 1, 0}, ApexScaling::CARRIER_PHYSICAL);

                    for (uint32 rank : VAELTHARA_WOUND_RANKS)
                        victim->RemoveAurasDueToSpell(rank);
                    creature->CastSpell(victim, VAELTHARA_WOUND_RANKS[stack - 1], true);
                    state.woundStacks[victimId] = stack;

                    LOG_INFO("coa", "VAELTHARA: rend on {} stack {} (swing {})",
                        victim->GetName(), uint32(stack), state.swingCounter);
                }
            }

            // Stalk runs before the normal lunge: it fires its own Bloodrush on
            // the fixated player, which resets the cadence below.
            UpdateStalk(creature, state, now);
            UpdateWhirl(creature, state, now);

            // Bloodrush: a straight-line lunge at the victim's position. She
            // jumps (kit 99092 anim 38), lands with the swipe guardian effect
            // and hits everything inside the landing radius.
            if (now >= state.nextBloodrush && creature->IsInCombat())
            {
                // Pick the farthest valid player so the lunge is a real leap
                // even when the tank is standing on top of her.
                Player* leapTarget = nullptr;
                float bestDist = 0.0f;
                Map::PlayerList const& players = creature->GetMap()->GetPlayers();
                for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
                {
                    Player* player = itr->GetSource();
                    if (!player || !player->IsAlive() || !player->InSamePhase(creature))
                        continue;

                    // Only people actually fighting her; she must not lunge at
                    // bystanders while the fight is on. Threat is the authority:
                    // the player's own combat flag can lag behind a melee start.
                    if (!IsFighting(creature, player))
                        continue;

                    float const dist = creature->GetExactDist2d(player);
                    if (dist < VAELTHARA_BLOODRUSH_MIN_DIST || dist > VAELTHARA_BLOODRUSH_MAX_DIST)
                        continue;

                    if (dist > bestDist)
                    {
                        bestDist = dist;
                        leapTarget = player;
                    }
                }

                if (leapTarget)
                {
                    DoBloodrush(creature, state, leapTarget, now);
                }
                else
                {
                    state.nextBloodrush = now + 1000;
                }
            }

            // Festering Wound feeds her: +1 Hunger per bleeding player, every
            // tick. Decay is deliberately independent of this.
            if (now >= state.nextBleedHunger)
            {
                state.nextBleedHunger = now + VAELTHARA_BLEED_HUNGER_INTERVAL_MS;

                uint32 bleeding = 0;
                Map::PlayerList const& players = creature->GetMap()->GetPlayers();
                for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
                {
                    Player* player = itr->GetSource();
                    if (!player || !player->IsAlive())
                        continue;
                    for (uint32 rank : VAELTHARA_WOUND_RANKS)
                    {
                        if (player->HasAura(rank))
                        {
                            ++bleeding;
                            break;
                        }
                    }
                }

                if (bleeding && !state.gorgedActive)
                    state.hunger = std::min<uint32>(VAELTHARA_HUNGER_MAX, state.hunger + bleeding);
            }

            // Decay after the grace period.
            if (!state.gorgedActive && now >= state.lastContact + VAELTHARA_HUNGER_GRACE_MS &&
                state.hunger > VAELTHARA_HUNGER_BASE)
            {
                if (state.nextDecay == 0)
                    state.nextDecay = now;
                else if (now >= state.nextDecay)
                {
                    --state.hunger;
                    state.nextDecay = now + DecayInterval(state.phase);
                }
            }
            else
            {
                state.nextDecay = 0;
            }

            ApplyHunger(creature, state);
        }

        // ---- stalk ---------------------------------------------------------
        static void DoBloodrush(Creature* creature, VaeltharaState& state, Player* target, uint32 now)
        {
            if (!target || !target->IsAlive())
                return;

            state.nextBloodrush = now + BloodrushInterval(state.phase);

            float const tx = target->GetPositionX();
            float const ty = target->GetPositionY();
            float const tz = target->GetPositionZ();
            uint32 travel = uint32(creature->GetExactDist2d(tx, ty) * 1000.0f / VAELTHARA_BLOODRUSH_SPEED) + 100;
            travel = std::max<uint32>(travel, 250);

            creature->PlayDirectSound(VAELTHARA_SOUND_BLOODRUSH);
            creature->CastSpell(target, VAELTHARA_BLOODRUSH, true);
            // A real jump arc: the client animates the leap and landing.
            creature->GetMotionMaster()->MoveJump(tx, ty, tz, VAELTHARA_BLOODRUSH_SPEED, VAELTHARA_BLOODRUSH_JUMP_Z);
            LOG_INFO("coa", "VAELTHARA: bloodrush {} yards over {} ms", creature->GetExactDist2d(tx, ty), travel);

            state.bloodrushInAir = true;

            creature->m_Events.AddEventAtOffset([creature, tx, ty, tz]()
            {
                if (!creature || !creature->IsAlive())
                    return;

                std::lock_guard<std::recursive_mutex> lock(g_vaeltharaStateMutex);

                auto const found = g_vaeltharaStates.find(creature->GetGUID().GetCounter());
                if (found == g_vaeltharaStates.end() || !found->second.bloodrushInAir)
                    return; // interrupted mid-leap; Winded replaced the landing
                found->second.bloodrushInAir = false;

                // Played on her own body so the swipe lands at her feet.
                creature->SendPlaySpellVisual(VAELTHARA_BLOODRUSH_LAND_KIT);

                Map::PlayerList const& players = creature->GetMap()->GetPlayers();
                std::vector<Player*> caught;
                for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
                {
                    Player* player = itr->GetSource();
                    if (!player || !player->IsAlive() || !player->InSamePhase(creature))
                        continue;

                    float const dx = player->GetPositionX() - tx;
                    float const dy = player->GetPositionY() - ty;
                    float const dz = player->GetPositionZ() - tz;
                    if (dx * dx + dy * dy + dz * dz <= VAELTHARA_BLOODRUSH_RADIUS * VAELTHARA_BLOODRUSH_RADIUS)
                    {
                        creature->CastSpell(player, VAELTHARA_BLOODRUSH_IMPACT, true);
                        caught.push_back(player);
                    }
                }

                ApexScaling::ApplyAoe(creature, caught,
                    {ApexScaling::HEAVY_PCT, 1, 0}, ApexScaling::ABILITY_BUDGET,
                    ApexScaling::ABILITY_CAP_PCT, ApexScaling::CARRIER_PHYSICAL);

                // The jump generator owned the active slot while she was airborne;
                // give the chase back as soon as she lands.
                if (Unit* victim = creature->GetVictim())
                    creature->GetMotionMaster()->MoveChase(victim);
            }, Milliseconds(travel));
        }

        static void SendStalkMessage(Creature* creature, Player* victim)
        {
            std::string text = "Vaelthara's eyes fix on ";
            text += victim->GetName();
            text += ".";

            // Boss emote so the client draws it centered, but only for the players
            // actually fighting her (threat list / current victim), not bystanders.
            Map::PlayerList const& players = creature->GetMap()->GetPlayers();
            for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
            {
                Player* player = itr->GetSource();
                if (!player || !player->GetSession())
                    continue;
                if (!IsFighting(creature, player))
                    continue;

                WorldPacket data;
                ChatHandler::BuildChatPacket(data, CHAT_MSG_RAID_BOSS_EMOTE, LANG_UNIVERSAL, creature, player, text);
                player->GetSession()->SendPacket(&data);
            }
        }

        static void EndStalk(Creature* creature, VaeltharaState& state, uint32 now, bool early)
        {
            if (state.stalkTarget)
            {
                if (Player* target = ObjectAccessor::GetPlayer(*creature, state.stalkTarget))
                {
                    if (state.stalkThreatPushed)
                    {
                        // Restore exactly what he had before the fixate: take the current
                        // value and subtract the difference, so no residue is left behind.
                        float const current = creature->GetThreatMgr().GetThreat(target, true);
                        creature->GetThreatMgr().AddThreat(target, state.stalkThreatBefore - current);
                    }
                    target->RemoveAurasDueToSpell(VAELTHARA_STALKED);
                }

                LOG_INFO("coa", "VAELTHARA: stalk ended ({})", early ? "target lost" : "expired");
            }

            state.stalkTarget.Clear();
            state.stalkThreatPushed = false;
            state.stalkEnds = 0;
            state.nextStalk = now + StalkInterval(state.phase);
        }

        static void StartStalk(Creature* creature, VaeltharaState& state, uint32 now)
        {
            std::vector<Player*> candidates;
            Map::PlayerList const& players = creature->GetMap()->GetPlayers();
            for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
            {
                Player* player = itr->GetSource();
                if (!player || !player->IsAlive())
                    continue;
                if (!player->InSamePhase(creature))
                    continue;
                if (!IsFighting(creature, player))
                    continue;

                // Range is capped so the leap can reach them, but there is no
                // minimum: the melee player is a valid stalk target and gets a
                // short hop instead of being skipped.
                if (creature->GetExactDist2d(player) > VAELTHARA_BLOODRUSH_MAX_DIST)
                    continue;

                candidates.push_back(player);
            }

            if (candidates.empty())
            {
                state.nextStalk = now + 5000;
                return;
            }

            // She must not fixate the player she is already fighting: with the
            // current victim in the pool every pick looks like "the tank again"
            // the moment the fixate expires and threat pulls her back.
            if (candidates.size() > 1)
            {
                Player* current = creature->GetVictim() && creature->GetVictim()->IsPlayer()
                    ? creature->GetVictim()->ToPlayer() : nullptr;
                if (current)
                {
                    for (auto itr = candidates.begin(); itr != candidates.end(); ++itr)
                    {
                        if (*itr == current)
                        {
                            candidates.erase(itr);
                            break;
                        }
                    }
                }
            }
            // Random on purpose: never the lowest health, never the tank by rule.
            Player* target = candidates[urand(0, uint32(candidates.size()) - 1)];

            state.stalkTarget = target->GetGUID();
            state.stalkEnds = now + VAELTHARA_STALK_MS;
            state.nextStalk = now + StalkInterval(state.phase);
            state.stalkThreatPushed = true;

            // Grilek's fixation: out-weigh the whole threat list for the window. The value he
            // had before is kept so it can be restored exactly when the window closes.
            state.stalkThreatBefore = creature->GetThreatMgr().GetThreat(target, true);
            creature->GetThreatMgr().AddThreat(target, VAELTHARA_STALK_THREAT);
            creature->CastSpell(target, VAELTHARA_STALKED, true);
            SendStalkMessage(creature, target);
            creature->AI()->AttackStart(target);
            DoBloodrush(creature, state, target, now);

            LOG_INFO("coa", "VAELTHARA: stalk on {}", target->GetName());
        }

        static void UpdateStalk(Creature* creature, VaeltharaState& state, uint32 now)
        {
            if (!creature->IsInCombat())
            {
                if (state.stalkTarget)
                    EndStalk(creature, state, now, true);

                // The twenty second clock starts when the fight does, not when
                // she spawned, so re-engaging always gets a fresh first stalk.
                state.nextStalk = now + VAELTHARA_STALK_FIRST_MS;
                return;
            }

            if (state.stalkTarget)
            {
                Player* target = ObjectAccessor::GetPlayer(*creature, state.stalkTarget);
                bool const lost = !target || !target->IsAlive() || !target->InSamePhase(creature) ||
                    creature->GetExactDist2d(target) > VAELTHARA_STALK_LEASH;

                if (lost || now >= state.stalkEnds)
                    EndStalk(creature, state, now, lost);
                return;
            }

            if (!creature->IsInCombat() || now < state.nextStalk)
                return;

            StartStalk(creature, state, now);
        }

        // ---- whirling claws -------------------------------------------------
        static void UpdateWhirl(Creature* creature, VaeltharaState& state, uint32 now)
        {
            if (!creature->IsInCombat())
            {
                state.nextWhirl = now + VAELTHARA_WHIRL_FIRST_MS;
                return;
            }

            if (now < state.nextWhirl)
                return;

            // Never during the leap: the landing is its own moment.
            if (state.bloodrushInAir)
            {
                state.nextWhirl = now + 1000;
                return;
            }

            DoWhirl(creature, now);
            state.nextWhirl = now + WhirlInterval(state.phase);
        }

        static void DoWhirl(Creature* creature, uint32 now)
        {
            creature->PlayDirectSound(VAELTHARA_SOUND_WHIRL);

            // Played on her own body, base attachment: the shockwave rings out
            // along the ground at her feet.
            creature->SendPlaySpellVisual(VAELTHARA_WHIRL_KIT);

            float const x = creature->GetPositionX();
            float const y = creature->GetPositionY();

            Map::PlayerList const& players = creature->GetMap()->GetPlayers();
            std::vector<Player*> caught;
            for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
            {
                Player* player = itr->GetSource();
                if (!player || !player->IsAlive() || !player->InSamePhase(creature))
                    continue;
                if (creature->GetExactDist2d(player) > VAELTHARA_WHIRL_RADIUS)
                    continue;
                if (!IsFighting(creature, player))
                    continue;

                creature->CastSpell(player, VAELTHARA_WHIRL, true);
                caught.push_back(player);
                // Punted straight away from her body, high enough to clear the ring.
                player->KnockbackFrom(x, y, VAELTHARA_WHIRL_KNOCKBACK_SPEED, VAELTHARA_WHIRL_KNOCKBACK_UP);
            }

            // Same percentage model as the other apex bosses: each victim takes a
            // share of its own pool, batched against a group budget.
            ApexScaling::ApplyAoe(creature, caught,
                {ApexScaling::ABILITY_PCT, 1, 0}, ApexScaling::ABILITY_BUDGET,
                ApexScaling::ABILITY_CAP_PCT, ApexScaling::CARRIER_PHYSICAL);

            LOG_INFO("coa", "VAELTHARA: whirling claws");
        }

        static void ApplyWinded(Creature* creature, VaeltharaState& state, uint32 now)
        {
            state.nextWindedAt = now + VAELTHARA_WINDED_MS + 1000;

            // Caught mid-leap: drop the jump and put her back on the ground
            // instead of leaving her hanging in the air for the whole stun.
            if (state.bloodrushInAir)
            {
                state.bloodrushInAir = false;
                creature->StopMoving();

                float x = creature->GetPositionX();
                float y = creature->GetPositionY();
                float z = creature->GetPositionZ();
                creature->UpdateGroundPositionZ(x, y, z);
                creature->NearTeleportTo(x, y, z, creature->GetOrientation());

                // MoveChase mutates the active slot, which drops the interrupted jump.
                // Clear() would also drop the chase and leave the patrol on top.
                if (Unit* victim = creature->GetVictim())
                    creature->GetMotionMaster()->MoveChase(victim);
            }

            // 2880 is a stock Stun the client already owns, so it draws the
            // debuff icon and head swirl; our spell_dbc row for the same id
            // renames it Winded and holds the five second duration.
            creature->CastSpell(creature, VAELTHARA_WINDED, true);
        }

        static void ApplyHunger(Creature* creature, VaeltharaState& state)
        {
            uint8 desired = HUNGER_FED;
            if (state.gorgedActive)
                desired = HUNGER_GORGED;
            else if (state.hunger >= VAELTHARA_HUNGER_FRENZIED_AT)
                desired = HUNGER_FRENZIED;
            else if (state.hunger <= VAELTHARA_HUNGER_STARVING_MAX)
                desired = HUNGER_STARVING;

            if (desired != state.hungerState)
            {
                creature->RemoveAurasDueToSpell(VAELTHARA_HUNGER_STARVING);
                creature->RemoveAurasDueToSpell(VAELTHARA_HUNGER_FRENZIED);
                creature->RemoveAurasDueToSpell(VAELTHARA_HUNGER_GORGED);
                creature->RemoveAurasDueToSpell(VAELTHARA_HUNGER_GORGED_IMMUNITY);

                switch (desired)
                {
                    case HUNGER_STARVING:
                        creature->AddAura(VAELTHARA_HUNGER_STARVING, creature);
                        break;
                    case HUNGER_FRENZIED:
                        creature->AddAura(VAELTHARA_HUNGER_FRENZIED, creature);
                        creature->SendPlaySpellVisual(VAELTHARA_ENRAGE_KIT);
                        creature->SendPlaySpellVisual(VAELTHARA_ENRAGE_ANIM_KIT);
                        break;
                    case HUNGER_GORGED:
                        creature->AddAura(VAELTHARA_HUNGER_GORGED, creature);
                        creature->AddAura(VAELTHARA_HUNGER_GORGED_IMMUNITY, creature);
                        break;
                    default:
                        break;
                }

                LOG_INFO("coa", "VAELTHARA: hunger state {} -> {} at {} stacks",
                    uint32(state.hungerState), uint32(desired), uint32(state.hunger));
                state.hungerState = desired;
            }

            if (state.appliedHunger != state.hunger || !creature->HasAura(VAELTHARA_HUNGER))
            {
                creature->SetAuraStack(VAELTHARA_HUNGER, creature, state.hunger);
                state.appliedHunger = state.hunger;
            }
        }

        // ---- voice -------------------------------------------------------
        static void UpdateVoice(Creature* creature, VaeltharaState& state, uint32 now)
        {
            if (!creature->IsInCombat())
            {
                state.inCombat = false;
                state.lastHealth = creature->GetHealth();

                if (creature->GetReactState() == REACT_AGGRESSIVE)
                    creature->SetReactState(REACT_DEFENSIVE);

                // Scan only when the line is actually due; this runs for every
                // idle boss otherwise, on every update.
                if (now < state.nextPreAggroSound)
                    return;

                Player* nearest = NearestPlayer(creature, VAELTHARA_PRE_AGGRO_RADIUS);
                if (nearest)
                {
                    PlaySound(creature, VAELTHARA_SOUND_PRE_AGGRO, "pre-aggro");
                    state.nextPreAggroSound = now + VAELTHARA_PRE_AGGRO_INTERVAL_MS;
                }
                return;
            }

            if (!state.inCombat)
            {
                state.inCombat = true;
                creature->SetReactState(REACT_DEFENSIVE);
                PlaySound(creature, VAELTHARA_SOUND_AGGRO, "aggro");
                creature->HandleEmoteCommand(VAELTHARA_EMOTE_BATTLE_ROAR);
                LOG_INFO("coa", "VAELTHARA: emote {} (BattleRoar)", VAELTHARA_EMOTE_BATTLE_ROAR);
                state.lastHealth = creature->GetHealth();
                state.nextAttackSound = now + VAELTHARA_ATTACK_SOUND_INTERVAL_MS;
                state.nextWoundSound = now;
            }

            if (creature->GetVictim() && now >= state.nextAttackSound)
            {
                PlaySound(creature, VAELTHARA_SOUND_ATTACK, "attack");
                state.nextAttackSound = now + VAELTHARA_ATTACK_SOUND_INTERVAL_MS;
            }

            if (state.lastHealth > creature->GetHealth() && now >= state.nextWoundSound)
            {
                PlaySound(creature, VAELTHARA_SOUND_WOUND, "wound");
                state.nextWoundSound = now + VAELTHARA_WOUND_SOUND_INTERVAL_MS;
            }

            state.lastHealth = creature->GetHealth();
        }

        static void PlaySound(Creature* creature, uint32 soundId, char const* label)
        {
            creature->PlayDirectSound(soundId);
            LOG_INFO("coa", "VAELTHARA: sound {} played ({})", soundId, label);
        }

        static Player* NearestPlayer(Creature* creature, float radius)
        {
            Player* nearest = nullptr;
            float best = radius;
            Map::PlayerList const& players = creature->GetMap()->GetPlayers();
            for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
            {
                Player* player = itr->GetSource();
                if (!player || !player->IsAlive() || !player->InSamePhase(creature))
                    continue;

                float const dist = creature->GetDistance(player);
                if (dist < best)
                {
                    best = dist;
                    nearest = player;
                }
            }
            return nearest;
        }

        static void LogDiagnostic(Creature* creature, VaeltharaState& state, uint32 now)
        {
            if (now < state.nextDiagnostic)
                return;
            state.nextDiagnostic = now + 1000;

            Player* nearest = NearestPlayer(creature, 100.0f);
            if (!nearest && !creature->IsInCombat())
                return;

            LOG_INFO("coa",
                "VAELTHARA diag combat={} engaged={} victim={} nearest={} dist={:.1f} melee={} react={} motion={} evade={} hunger={} hstate={} gorged={} hp={:.1f} pos={:.1f},{:.1f},{:.1f} scale={:.2f} speed={:.2f}",
                creature->IsInCombat(),
                creature->IsEngaged(),
                creature->GetVictim() ? creature->GetVictim()->GetName() : "none",
                nearest ? nearest->GetName() : "none",
                nearest ? creature->GetDistance(nearest) : -1.0f,
                nearest ? creature->IsWithinMeleeRange(nearest) : false,
                uint32(creature->GetReactState()),
                uint32(creature->GetMotionMaster()->GetCurrentMovementGeneratorType()),
                creature->IsInEvadeMode(),
                uint32(state.hunger),
                uint32(state.hungerState),
                state.gorgedActive,
                creature->GetHealthPct(),
                creature->GetPositionX(),
                creature->GetPositionY(),
                creature->GetPositionZ(),
                creature->GetObjectScale(),
                creature->GetSpeed(MOVE_RUN));
        }
    };

    // Melee damage that actually resolves. ModifyMeleeDamage is not called for
    // a miss, dodge, parry or fully absorbed swing, so the meter only climbs on
    // hits that land.
    class VaeltharaUnitScript : public UnitScript
    {
    public:
        VaeltharaUnitScript() : UnitScript("VaeltharaUnitScript", true,
            {UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_ON_BEFORE_ROLL_MELEE_OUTCOME_AGAINST,
             UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK}) { }

        // Her autos have to land. At equal level the roll still carries the 5%
        // base miss plus the victim's dodge, parry and block, which starves the
        // Hunger meter and the Rend ladder through no fault of the player. The
        // hook exposes every chance before the roll, so her swings land clean.
        void OnBeforeRollMeleeOutcomeAgainst(Unit const* attacker, Unit const* victim, WeaponAttackType attType,
            int32& attackerMaxSkillValueForLevel, int32& victimMaxSkillValueForLevel,
            int32& attackerWeaponSkill, int32& victimDefenseSkill,
            int32& crit_chance, int32& miss_chance, int32& dodge_chance, int32& parry_chance,
            int32& block_chance) override
        {
            if (!attacker || !victim || !attacker->IsCreature() || attacker->GetEntry() != VAELTHARA_ENTRY)
                return;

            miss_chance = 0;
            dodge_chance = 0;
            parry_chance = 0;
            block_chance = 0;
        }

        void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
        {
            if (!attacker || !target || damage == 0)
                return;

            if (!attacker->IsCreature() || attacker->GetEntry() != VAELTHARA_ENTRY)
                return;

            std::lock_guard<std::recursive_mutex> lock(g_vaeltharaStateMutex);

            auto itr = g_vaeltharaStates.find(attacker->GetGUID().GetCounter());
            if (itr == g_vaeltharaStates.end())
                return;

            VaeltharaState& state = itr->second;
            if (state.gorgedActive)
                return;

            // Same blueprint as the other apex bosses: an auto is a share of the
            // victim's own pool, so plate and cloth are hit equally hard in relative
            // terms while armour, block, dodge and cooldowns still filter the hit.
            damage = std::max<uint32>(1, uint32(float(target->GetMaxHealth()) * 0.03f));

            if (state.hunger < VAELTHARA_HUNGER_MAX)
                ++state.hunger;
            state.lastContact = getMSTime();

            // Every third landed swing schedules a Rend; the cast itself happens
            // on the creature update so we never cast from inside damage handling.
            if (++state.swingCounter % VAELTHARA_REND_EVERY_SWINGS == 0)
                state.rendPending = true;
        }

        // Her spells keep their debuffs, visuals and sounds. The flat damage is
        // removed here and re-applied as a share of the victim's pool, so armour
        // and resistances still filter the real hit.
        void ModifySpellDamageTaken(Unit* /*target*/, Unit* attacker, int32& damage,
            SpellInfo const* spellInfo) override
        {
            if (!attacker || !spellInfo || !attacker->IsCreature() ||
                attacker->GetEntry() != VAELTHARA_ENTRY)
                return;

            if (IsDamagingSpell(spellInfo->Id))
                damage = 0;
        }

        // Bleeds tick by percentage too: this hook runs before armour and bonus
        // mitigation, so the tick scales with the victim's pool and still gets
        // filtered downstream.
        void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage,
            SpellInfo const* /*spellInfo*/) override
        {
            if (!target || !attacker || !attacker->IsCreature() ||
                attacker->GetEntry() != VAELTHARA_ENTRY)
                return;

            damage = std::max<uint32>(1,
                uint32(float(target->GetMaxHealth()) * ApexScaling::PERIODIC_PCT));
        }

    private:
        static bool IsDamagingSpell(uint32 spellId)
        {
            if (spellId == VAELTHARA_WHIRL || spellId == VAELTHARA_REND ||
                spellId == VAELTHARA_BLOODRUSH_IMPACT)
                return true;

            for (uint32 rank : VAELTHARA_WOUND_RANKS)
                if (spellId == rank)
                    return true;

            return false;
        }
    };
}

void AddVaeltharaScripts()
{
    for (uint32 spellId : VAELTHARA_CLIENT_SPELLS)
        Ascension::ClientSpellPatches::Instance().Register(spellId);

    new VaeltharaAIScript();
    new VaeltharaCreatureScript();
    new VaeltharaUnitScript();
}
