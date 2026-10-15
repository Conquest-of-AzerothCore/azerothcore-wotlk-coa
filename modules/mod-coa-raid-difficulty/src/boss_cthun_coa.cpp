/*
 * C'Thun as Ascension rebuilt him.
 *
 * Kit: Ascension's blocks 2117000-2117154. Timings: Ascension's own DBM
 * module for C'Thun, the one Ahn'Qiraj module they adapted (DBM-AQ40
 * CThun.lua). Where it gives none, the timer is designed.
 *
 * From stock: the eye and its dark glare sweeping the room, the portals, the
 * body rising when the eye falls, the stomach with its two flesh tentacles and
 * the ways in and out of it, and C'Thun weakened when both flesh tentacles die.
 *
 * God of Madness. The eye and the body share their health with every
 * tentacle: whenever one dies, C'Thun suffers its health as damage, shield or
 * no shield.
 *
 * Phase 1, the Eye (DBM timers)
 *   Eye Beam              every 3s    Nature damage, leaping to allies within 12
 *                                     yards, +15% per leap
 *   Eldritch Revelations  first 30s, every 30s; 37.5s after a glare begins
 *                         3s cast: whoever faces the eye for the next three
 *                         seconds is shown a dark future (8s stun)
 *   Dark Glare            first 55s, every 89s, 35s long. Each glare adds a
 *                         stack of Abyssal Gaze; the tenth glare never ends.
 *   Eye Tentacles         first 45s, every 45s, cycling Shadow, Fire, Nature:
 *                         Miasma (a pulsing area under a player, shadow damage
 *                         taken +10% per pulse), Eradicate (a fire channel that
 *                         grows every second), Consume (drains life to C'Thun,
 *                         -1% stats per second)
 *   Lesser tentacles      every 15s, cycling Manipulator (Sensory Overload:
 *                         forced to run for 5s), Devastator (stock claw
 *                         tentacle), Malignant (grabs a player and squeezes 3%
 *                         of their health every second)
 *
 * Phase 2, the Body
 *   Impenetrable Force Shield (-99% damage) and the Breath of the Old God on
 *   everyone outside the stomach.
 *   From Beneath You It Devours  first 20s, every 41s: a mouth tentacle hunts a
 *                         player for up to 30s; if it reaches them it swallows
 *                         them and everyone within 8 yards into the stomach
 *   Digestive Acid        in the stomach, 1% of current health per second,
 *                         healing C'Thun for ten times that share of the
 *                         victim's maximum health
 *   Giant Claw Tentacle   first 14s, every 60s: Devastating Smash (3s cast,
 *                         everyone within 100 yards, +10%
 *                         physical damage taken, stacking) every 20s, and
 *                         Crushing Blows in a cone. The smash hits at full
 *                         strength at any range: its tooltip's falloff needs
 *                         the script that is gone.
 *   Giant Eye Tentacle    first 44s, every 60s: Lesser Eye Beam every 2.1s
 *                         and Lesser Eldritch Revelations (look away) every 20s
 *   Eye Tentacles         first 6s, every 45s, as in phase 1
 *   Weakening             both flesh tentacles dead: +100% damage taken,
 *                         stunned, 30s (DBM; stock had 45). After it: giant
 *                         claw in 10s, giant eye in 40s, stomach in 15s,
 *                         eye tentacles in 15s (DBM)
 *   Insidious Whispers    first 30s, every 45s: 5s warning, then a player is
 *                         his for 15s and cannot die meanwhile
 *   Beyond Comprehension  first 20s, every 30s: a player loses a growing share
 *                         of current health each second until healed to full
 *   Offering of the Old God  first 40s, every 40s: a player deals +100%
 *                         damage for each ally within 10 yards, who deal 50%
 *                         less; dispelling it refuses the offer
 *
 * Decided here, not in the data: the three phase-2 afflictions' timers, the
 * mouth tentacle's speed (70% of a player's) and reach, the eye beam's five
 * leaps, how the lesser tentacles differ, Beyond Comprehension's growth (1% more
 * each second), and keeping the stock dark glare's damage (Ascension's glare hit
 * is 91 on Normal, a number made for a script that is gone). Morig the Peon,
 * who waits in the stomach on Ascension, is left out.
 */

#include "AreaTriggerScript.h"
#include "Containers.h"
#include "TaskScheduler.h"
#include "CreatureScript.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "../../../src/server/scripts/Kalimdor/TempleOfAhnQiraj/temple_of_ahnqiraj.h"
#include "zg_coa_common.h"

#include <map>

using namespace coa_zg;

namespace
{
    enum Spells
    {
        // stock
        SPELL_FREEZE_ANIM          = 16245,
        SPELL_DARK_GLARE           = 26029,
        SPELL_RED_COLORATION       = 22518,
        SPELL_GROUND_RUPTURE       = 26139,
        SPELL_HAMSTRING            = 26141,
        SPELL_TRANSFORM            = 26232,
        SPELL_MASSIVE_GROUND_RUPTURE = 26478,
        SPELL_THRASH               = 3391,
        SPELL_MOUTH_TENTACLE       = 26332,
        SPELL_DIGESTIVE_ACID       = 26476,
        SPELL_SUBMERGE_VISUAL      = 26234,
        SPELL_BIRTH                = 26262,
        SPELL_ROCKY_GROUND_IMPACT  = 26271,

        // Ascension
        SPELL_EYE_BEAM             = 2117000,
        SPELL_EYE_BEAM_HIT         = 2117000,
        SPELL_ABYSSAL_GAZE         = 2117011,
        SPELL_ELDRITCH             = 2117015,
        SPELL_TERROR               = 2117017,
        SPELL_WHISPERS_MC          = 2117018,
        SPELL_WHISPERS_GUARD       = 2117019,
        SPELL_BEYOND               = 2117020,
        SPELL_BEYOND_HIT           = 2117022,
        SPELL_OFFERING             = 2117023,
        SPELL_GOD_OF_MADNESS       = 2117026,
        SPELL_WHISPERS_WARN        = 2117028,
        SPELL_WHISPERS_RELEASE     = 2117086,
        SPELL_MIASMA               = 2117050,
        SPELL_ERADICATE            = 2117055,
        SPELL_CONSUME              = 2117060,
        SPELL_WITHERED             = 2117065,
        SPELL_CONSUME_HEAL         = 2117066,
        SPELL_RUPTURE_SMALL        = 2117068,
        SPELL_MALIGNANT_GRASP      = 2117070,
        SPELL_SQUEEZE              = 2117071,
        SPELL_DEVASTATING_SMASH    = 2117076,
        SPELL_CRUSHING_BLOWS       = 2117077,
        SPELL_LESSER_ELDRITCH      = 2117079,
        SPELL_LESSER_EYE_BEAM      = 2117081,
        SPELL_SENSORY_OVERLOAD     = 2117085,
        SPELL_FORCE_SHIELD         = 2117102,
        SPELL_BREATH_OLD_GOD       = 2117103,
        SPELL_WEAKENING            = 2117107,
        SPELL_DIGESTION_HIT        = 2117112,
        SPELL_DIGESTION_HEAL       = 2117113,
        SPELL_DEVOURS              = 2117117,
        SPELL_DEVOURS_GRAB         = 2117118,
    };

    enum Actions
    {
        ACTION_SPAWN_EYE_TENTACLES = 1,
        ACTION_START_PHASE_TWO     = 1,
        ACTION_TENTACLE_TYPE       = 2,
    };

    enum Misc
    {
        GROUP_BEAM_PHASE    = 1,
        MAX_TENTACLE_GROUPS = 5,
        NPC_TRIGGER         = 15384,
        NPC_EXIT_TRIGGER    = 15800,
        NPC_WORLD_TRIGGER   = 12999,
        EMOTE_WEAKENED      = 0,
        RANDOM_SOUND_WHISPER = 8663,
        TYPE_TENTACLE_KIND  = 1,
        TENT_SHADOW = 0, TENT_FIRE = 1, TENT_NATURE = 2,
        LESSER_MANIPULATOR = 0, LESSER_DEVASTATOR = 1, LESSER_MALIGNANT = 2,
        ENDLESS_GLARE       = 10
    };

    Position const StomachPosition = { -8562.0f, 2037.0f, -70.0f, 5.05f };
    Position const FleshTentaclePos[2] =
    {
        { -8571.0f, 1990.0f, -98.0f, 1.22f },
        { -8525.0f, 1994.0f, -98.0f, 2.12f },
    };

    constexpr float BEAM_LEAP     = 12.0f;
    constexpr uint8 BEAM_LEAPS    = 5;
    constexpr float FACING_ARC    = float(M_PI) / 2;
    constexpr float MOUTH_REACH   = 2.5f;
    constexpr float SWALLOW_RANGE = 8.0f;

    bool InStomach(Unit const* unit)
    {
        return unit->HasAura(SPELL_DIGESTIVE_ACID) || unit->GetPositionZ() < 0.0f;
    }

    class NotInStomachSelector
    {
    public:
        bool operator()(Unit* unit) const { return unit->IsPlayer() && !InStomach(unit); }
    };

    // A chain that leaps to the nearest ally, 15% harder each time.
    void ChainBeam(Creature* caster, Unit* first, uint32 spell)
    {
        Player* current = first ? first->ToPlayer() : nullptr;
        if (!current)
            return;
        float amount = float(Info(caster, spell));
        std::vector<Player*> hit;
        for (uint8 i = 0; current && i <= BEAM_LEAPS; ++i)
        {
            Hit(caster, current, spell, int32(amount));
            hit.push_back(current);
            amount *= 1.15f;
            current = NextInChain(caster, current, BEAM_LEAP, hit);
        }
    }

    // Whoever is facing the caster (and not in the stomach) sees the horror.
    void Revelation(Creature* caster, float range)
    {
        for (Player* p : Players(caster, [&](Player* x) { return !InStomach(x) && caster->IsWithinDist(x, range); }))
            if (p->isInFront(caster, FACING_ARC))
                caster->CastSpell(p, SPELL_TERROR, true);
    }

    // God of Madness: a slain tentacle's health is taken from C'Thun.
    void TentacleFell(InstanceScript* instance, Creature* tentacle)
    {
        if (!instance || !tentacle)
            return;
        uint32 const entry = tentacle->GetEntry();
        if (entry == NPC_CTHUN_PORTAL || entry == NPC_SMALL_PORTAL || entry == NPC_GIANT_PORTAL || entry == NPC_WORLD_TRIGGER)
            return;
        for (uint32 data : { DATA_EYE_OF_CTHUN, DATA_CTHUN })
            if (Creature* god = instance->GetCreature(data))
                if (god->IsAlive() && god->IsInCombat() && god->IsVisible() && god->GetHealth() > 1)
                {
                    uint32 const dmg = std::min<uint32>(tentacle->GetMaxHealth(), god->GetHealth() - 1);
                    Unit::DealDamage(tentacle, god, dmg, nullptr, DIRECT_DAMAGE, SPELL_SCHOOL_MASK_SHADOW, nullptr, false);
                    return;   // the eye while it lives, the body after
                }
    }

    // ---- the Eye ----------------------------------------------------------------

    struct boss_eye_of_cthun_coa : public BossAI
    {
        boss_eye_of_cthun_coa(Creature* creature) : BossAI(creature, DATA_CTHUN)
        {
            me->SetCombatMovement(false);
            me->m_SightDistance = 90.0f;
        }

        void Reset() override
        {
            _glareTick = 0;
            _glareAngle = 0.0f;
            _clockWise = false;
            _eyeTentacleCounter = 0;
            _tentacleKind = TENT_SHADOW;
            _lesserKind = LESSER_MANIPULATOR;
            me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
            me->SetVisible(true);
            me->RemoveAurasDueToSpell(SPELL_ABYSSAL_GAZE);
            if (Creature* portal = me->FindNearestCreature(NPC_CTHUN_PORTAL, 10.0f))
                portal->SetReactState(REACT_PASSIVE);
            BossAI::Reset();
        }

        void JustDied(Unit* /*killer*/) override
        {
            if (Creature* cthun = instance->GetCreature(DATA_CTHUN))
                cthun->AI()->DoAction(ACTION_START_PHASE_TWO);
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            me->AddAura(SPELL_GOD_OF_MADNESS, me);
            ScheduleBeamPhase(true);
        }

        void MoveInLineOfSight(Unit* who) override
        {
            if (who->IsPlayer() && !me->IsInCombat())
                if (me->IsWithinLOSInMap(who) && me->IsWithinDist2d(who, 90.0f) && who->GetPositionZ() > 100.0f)
                    AttackStart(who);
        }

        // Eye tentacles: stock rings, Ascension's three kinds in turn.
        void DoAction(int32 action) override
        {
            if (action != ACTION_SPAWN_EYE_TENTACLES)
                return;
            _spawningKind = _tentacleKind;
            me->SummonCreatureGroup(_eyeTentacleCounter);
            _eyeTentacleCounter = (_eyeTentacleCounter + 1) % MAX_TENTACLE_GROUPS;
            _tentacleKind = (_tentacleKind + 1) % 3;
        }

        void JustSummoned(Creature* summon) override
        {
            summons.Summon(summon);
            if (summon->GetEntry() == NPC_EYE_TENTACLE && summon->AI())
                summon->AI()->SetData(TYPE_TENTACLE_KIND, _spawningKind);
            if (Creature* cthun = instance->GetCreature(DATA_CTHUN))
                cthun->AI()->JustSummoned(summon);
        }

        void SummonedCreatureDies(Creature* summon, Unit* killer) override
        {
            BossAI::SummonedCreatureDies(summon, killer);
            TentacleFell(instance, summon);
        }

        void SpawnLesser()
        {
            Unit* target = SelectTarget(SelectTargetMethod::Random, 0, NotInStomachSelector());
            if (!target)
                return;
            if (Creature* tentacle = me->SummonCreature(NPC_CLAW_TENTACLE, *target, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 5000))
            {
                tentacle->AI()->SetData(TYPE_TENTACLE_KIND, _lesserKind);
                tentacle->AI()->AttackStart(target);
            }
            _lesserKind = (_lesserKind + 1) % 3;
        }

        void ScheduleBeamPhase(bool onEngage)
        {
            scheduler.Schedule(3s, GROUP_BEAM_PHASE, [this](TaskContext task)
            {
                if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, NotInStomachSelector()))
                {
                    _beamTarget = target->GetGUID();
                    _glareAngle = me->GetAngle(target);
                    DoCast(target, SPELL_EYE_BEAM);
                }
                task.Repeat(3s);
            }).Schedule(15s, GROUP_BEAM_PHASE, [this](TaskContext task)
            {
                SpawnLesser();
                task.Repeat(15s);
            }).Schedule(onEngage ? 45s : 15s, GROUP_BEAM_PHASE, [this](TaskContext task)
            {
                DoAction(ACTION_SPAWN_EYE_TENTACLES);
                task.Repeat(45s);
            }).Schedule(onEngage ? 30s : 37500ms, GROUP_BEAM_PHASE, [this](TaskContext task)
            {
                DoCastSelf(SPELL_ELDRITCH);
                task.Repeat(30s);
            }).Schedule(onEngage ? 55s : 89s, [this](TaskContext)
            {
                StartGlare();
            });
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);
            if (spell->Id == SPELL_EYE_BEAM)
                ChainBeam(me, ObjectAccessor::GetUnit(*me, _beamTarget), SPELL_EYE_BEAM_HIT);
            else if (spell->Id == SPELL_ELDRITCH)
            {
                // Three pulses over the channel's three seconds.
                for (uint8 i = 0; i < 3; ++i)
                    scheduler.Schedule(Seconds(i), [this](TaskContext) { Revelation(me, 200.0f); });
            }
        }

        // From stock: freeze, turn red, sweep the room for 35 seconds.
        void StartGlare()
        {
            scheduler.CancelGroup(GROUP_BEAM_PHASE);
            AddStack(me, me, SPELL_ABYSSAL_GAZE);
            Aura* gaze = me->GetAura(SPELL_ABYSSAL_GAZE);
            bool const endless = gaze && gaze->GetStackAmount() >= ENDLESS_GLARE;

            me->StopMoving();
            me->SetReactState(REACT_PASSIVE);
            me->InterruptNonMeleeSpells(false);
            me->SetTarget(ObjectGuid::Empty);
            DoCastSelf(SPELL_FREEZE_ANIM, true);

            scheduler.Schedule(1s, [this, endless](TaskContext)
            {
                _glareTick = 0;
                _clockWise = RAND(true, false);
                DoCastSelf(SPELL_RED_COLORATION, true);
                me->SetFacingTo(_glareAngle);

                scheduler.Schedule(3s, [this, endless](TaskContext tasker)
                {
                    me->SetTarget(ObjectGuid::Empty);
                    me->StopMoving();
                    float const angle = _clockWise ? _glareAngle + _glareTick * float(M_PI) / 35 : _glareAngle - _glareTick * float(M_PI) / 35;
                    me->SetFacingTo(angle);
                    me->SetOrientation(angle);
                    DoCastSelf(SPELL_DARK_GLARE);
                    ++_glareTick;

                    if (!endless && tasker.GetRepeatCounter() >= 35)
                    {
                        scheduler.CancelAll();
                        me->SetReactState(REACT_AGGRESSIVE);
                        me->RemoveAurasDueToSpell(SPELL_RED_COLORATION);
                        me->RemoveAurasDueToSpell(SPELL_FREEZE_ANIM);
                        ScheduleBeamPhase(false);
                    }
                    else
                        tasker.Repeat(1s);
                });
            });
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);
            if (damage < me->GetHealth() || !me->GetHealth())
                return;

            // From stock: the eye does not die, it gives way to the body.
            me->InterruptNonMeleeSpells(false);
            me->RemoveAurasDueToSpell(SPELL_RED_COLORATION);
            me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
            me->SetTarget();
            me->SetHealth(0);
            damage = 0;
            me->InterruptNonMeleeSpells(true);
            me->RemoveAllAuras();
            scheduler.CancelAll();
            me->m_Events.AddEventAtOffset([this]()
            {
                if (Creature* cthun = instance->GetCreature(DATA_CTHUN))
                    cthun->AI()->DoAction(ACTION_START_PHASE_TWO);
            }, 3s);
        }

    private:
        uint32 _glareTick = 0;
        float _glareAngle = 0.0f;
        bool _clockWise = false;
        uint32 _eyeTentacleCounter = 0;
        uint8 _tentacleKind = TENT_SHADOW;
        uint8 _spawningKind = TENT_SHADOW;
        uint8 _lesserKind = LESSER_MANIPULATOR;
        ObjectGuid _beamTarget;
    };

    // ---- the Body ---------------------------------------------------------------

    struct boss_cthun_coa : public BossAI
    {
        boss_cthun_coa(Creature* creature) : BossAI(creature, DATA_CTHUN)
        {
            me->SetCombatMovement(false);
        }

        void Reset() override
        {
            _whisperTimer = 90000;
            _fleshKilled = 0;
            _mouths.clear();
            _beyond.clear();
            _afflictions.CancelAll();
            me->RemoveAurasDueToSpell(SPELL_TRANSFORM);
            me->RemoveAurasDueToSpell(SPELL_FORCE_SHIELD);
            me->RemoveAurasDueToSpell(SPELL_WEAKENING);
            me->RemoveAurasDueToSpell(SPELL_BREATH_OLD_GOD);
            me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
            BossAI::Reset();
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            DoZoneInCombat();
        }

        void DoAction(int32 action) override
        {
            if (action != ACTION_START_PHASE_TWO)
                return;
            DoCastSelf(SPELL_TRANSFORM);
            me->m_Events.AddEventAtOffset([this]()
            {
                DoCastSelf(SPELL_TRANSFORM);
                me->AddAura(SPELL_FORCE_SHIELD, me);
                me->AddAura(SPELL_GOD_OF_MADNESS, me);
                DoCastSelf(SPELL_BREATH_OLD_GOD, true);
                me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
                DoZoneInCombat();
            }, 500ms);
            for (Position const& pos : FleshTentaclePos)
                me->SummonCreature(NPC_FLESH_TENTACLE, pos, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 5000);
            ScheduleBody(20s, 14s, 44s, 6s);
            ScheduleAfflictions();
        }

        void ScheduleBody(Milliseconds stomach, Milliseconds claw, Milliseconds eye, Milliseconds tentacles)
        {
            scheduler.Schedule(stomach, [this](TaskContext context)
            {
                Devour();
                context.Repeat(41s);
            }).Schedule(tentacles, [this](TaskContext context)
            {
                SpawnEyeTentacles();
                context.Repeat(45s);
            }).Schedule(claw, [this](TaskContext context)
            {
                if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, NotInStomachSelector()))
                    if (Creature* spawned = me->SummonCreature(NPC_GIANT_CLAW_TENTACLE, *target, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 5000))
                        spawned->AI()->AttackStart(target);
                context.Repeat(60s);
            }).Schedule(eye, [this](TaskContext context)
            {
                if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, NotInStomachSelector()))
                    if (Creature* spawned = me->SummonCreature(NPC_GIANT_EYE_TENTACLE, *target, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 5000))
                        spawned->AI()->AttackStart(target);
                context.Repeat(60s);
            }).Schedule(1s, [this](TaskContext context)
            {
                Digest();
                context.Repeat(1s);
            });
        }

        void ScheduleAfflictions()
        {
            _afflictions.Schedule(30s, [this](TaskContext context)
            {
                if (Unit* target = SelectTarget(SelectTargetMethod::Random, 1, NotInStomachSelector()))
                {
                    me->CastSpell(target, SPELL_WHISPERS_WARN, true);
                    ObjectGuid const guid = target->GetGUID();
                    _afflictions.Schedule(5s, [this, guid](TaskContext)
                    {
                        if (Unit* t = ObjectAccessor::GetUnit(*me, guid))
                            if (t->IsAlive())
                            {
                                me->CastSpell(t, SPELL_WHISPERS_MC, true);
                                me->CastSpell(t, SPELL_WHISPERS_GUARD, true);
                                _afflictions.Schedule(15s, [this, guid](TaskContext)
                                {
                                    if (Unit* u = ObjectAccessor::GetUnit(*me, guid))
                                    {
                                        u->RemoveAurasDueToSpell(SPELL_WHISPERS_MC);
                                        u->RemoveAurasDueToSpell(SPELL_WHISPERS_GUARD);
                                        if (u->IsAlive())
                                            me->CastSpell(u, SPELL_WHISPERS_RELEASE, true);
                                    }
                                });
                            }
                    });
                }
                context.Repeat(45s);
            }).Schedule(20s, [this](TaskContext context)
            {
                if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, NotInStomachSelector()))
                {
                    me->AddAura(SPELL_BEYOND, target);
                    _beyond[target->GetGUID()] = 1;
                }
                context.Repeat(30s);
            }).Schedule(40s, [this](TaskContext context)
            {
                if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, NotInStomachSelector()))
                    me->CastSpell(target, SPELL_OFFERING, true);
                context.Repeat(40s);
            }).Schedule(1s, [this](TaskContext context)
            {
                Comprehend();
                context.Repeat(1s);
            });
        }

        // Beyond Comprehension: a growing share of current health, until full.
        void Comprehend()
        {
            for (auto it = _beyond.begin(); it != _beyond.end();)
            {
                Unit* target = ObjectAccessor::GetUnit(*me, it->first);
                if (!target || !target->IsAlive() || !target->HasAura(SPELL_BEYOND) || target->IsFullHealth())
                {
                    if (target)
                        target->RemoveAurasDueToSpell(SPELL_BEYOND);
                    it = _beyond.erase(it);
                    continue;
                }
                Hit(me, target, SPELL_BEYOND_HIT, int32(target->CountPctFromCurHealth(it->second)));
                ++it->second;
                ++it;
            }
        }

        void SpawnEyeTentacles()
        {
            if (Creature* eye = instance->GetCreature(DATA_EYE_OF_CTHUN))
                eye->AI()->DoAction(ACTION_SPAWN_EYE_TENTACLES);
        }

        // From Beneath You It Devours: a mouth hunts a player.
        void Devour()
        {
            Unit* target = SelectTarget(SelectTargetMethod::Random, 0, NotInStomachSelector());
            if (!target)
                return;
            me->CastSpell(target, SPELL_DEVOURS, true);
            if (Creature* mouth = me->SummonCreature(NPC_WORLD_TRIGGER, target->GetRandomNearPosition(20.0f), TEMPSUMMON_TIMED_DESPAWN, 30000))
            {
                mouth->SetFaction(me->GetFaction());
                mouth->SetSpeed(MOVE_RUN, 0.7f);
                mouth->SetWalk(false);
                mouth->GetMotionMaster()->MoveFollow(target, 0.0f, 0.0f);
                _mouths.push_back({ mouth->GetGUID(), target->GetGUID() });
            }
        }

        // Every second: the mouths close in; the stomach digests.
        void Digest()
        {
            for (auto it = _mouths.begin(); it != _mouths.end();)
            {
                Creature* mouth = ObjectAccessor::GetCreature(*me, it->mouth);
                Unit* prey = ObjectAccessor::GetUnit(*me, it->prey);
                if (!mouth || !prey || !prey->IsAlive() || InStomach(prey))
                {
                    if (mouth)
                        mouth->DespawnOrUnsummon();
                    if (prey)
                        prey->RemoveAurasDueToSpell(SPELL_DEVOURS);
                    it = _mouths.erase(it);
                    continue;
                }
                mouth->CastSpell(mouth, SPELL_RUPTURE_SMALL, true);
                if (mouth->IsWithinDist(prey, MOUTH_REACH))
                {
                    Swallow(prey);
                    mouth->DespawnOrUnsummon();
                    it = _mouths.erase(it);
                    continue;
                }
                ++it;
            }

            for (Player* p : Players(me, [](Player* x) { return x->HasAura(SPELL_DIGESTIVE_ACID); }))
            {
                Hit(me, p, SPELL_DIGESTION_HIT, int32(p->CountPctFromCurHealth(1)));
                int32 heal = int32(p->CountPctFromMaxHealth(10));
                me->CastCustomSpell(me, SPELL_DIGESTION_HEAL, &heal, nullptr, nullptr, true);
            }
        }

        // The prey and everyone within 8 yards go to the stomach (stock way in).
        void Swallow(Unit* prey)
        {
            prey->RemoveAurasDueToSpell(SPELL_DEVOURS);
            std::vector<Player*> eaten = Players(me, [&](Player* x) { return !InStomach(x) && prey->IsWithinDist(x, SWALLOW_RANGE); });
            for (Player* p : eaten)
            {
                me->CastSpell(p, SPELL_DEVOURS_GRAB, true);
                p->CastSpell(p, SPELL_MOUTH_TENTACLE, true);
                ObjectGuid const guid = p->GetGUID();
                p->m_Events.AddEventAtOffset([this, guid]()
                {
                    if (Player* q = ObjectAccessor::GetPlayer(*me, guid))
                    {
                        DoTeleportPlayer(q, StomachPosition.GetPositionX(), StomachPosition.GetPositionY(), StomachPosition.GetPositionZ(), StomachPosition.GetOrientation());
                        q->m_Events.AddEventAtOffset([this, guid]()
                        {
                            if (Player* r = ObjectAccessor::GetPlayer(*me, guid))
                                DoCast(r, SPELL_DIGESTIVE_ACID, true);
                        }, 2s);
                    }
                }, 3800ms);
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
            {
                if (_whisperTimer <= diff)
                {
                    me->GetMap()->DoForAllPlayers([](Player* player) { player->PlayDirectSound(RANDOM_SOUND_WHISPER, player); });
                    _whisperTimer = urand(90000, 300000);
                }
                else
                    _whisperTimer -= diff;
                return;
            }
            me->SetTarget();
            scheduler.Update(diff);
            _afflictions.Update(diff);
        }

        void JustDied(Unit* killer) override
        {
            BossAI::JustDied(killer);
            if (Creature* portal = me->FindNearestCreature(NPC_CTHUN_PORTAL, 10.0f))
                portal->DespawnOrUnsummon();
            if (Creature* eye = instance->GetCreature(DATA_EYE_OF_CTHUN))
                eye->DespawnOrUnsummon();
        }

        void SummonedCreatureDies(Creature* creature, Unit* killer) override
        {
            BossAI::SummonedCreatureDies(creature, killer);
            TentacleFell(instance, creature);

            if (creature->GetEntry() != NPC_FLESH_TENTACLE)
                return;
            creature->CastSpell(creature, SPELL_ROCKY_GROUND_IMPACT, true);
            if (++_fleshKilled < 2)
                return;

            // Both flesh tentacles: C'Thun drops his shield for 30 seconds.
            _fleshKilled = 0;
            scheduler.CancelAll();
            Talk(EMOTE_WEAKENED);
            me->RemoveAurasDueToSpell(SPELL_FORCE_SHIELD);
            DoCastSelf(SPELL_WEAKENING, true);
            scheduler.Schedule(30s, [this](TaskContext)
            {
                me->RemoveAurasDueToSpell(SPELL_WEAKENING);
                me->AddAura(SPELL_FORCE_SHIELD, me);
                for (Position const& pos : FleshTentaclePos)
                    me->SummonCreature(NPC_FLESH_TENTACLE, pos, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 5000);
                ScheduleBody(15s, 10s, 40s, 15s);
            });
        }

    private:
        struct Mouth
        {
            ObjectGuid mouth;
            ObjectGuid prey;
        };

        uint32 _whisperTimer = 90000;
        uint8 _fleshKilled = 0;
        TaskScheduler _afflictions;
        std::vector<Mouth> _mouths;
        std::map<ObjectGuid, uint32> _beyond;
    };

    // ---- tentacles ----------------------------------------------------------------

    // Portal under a tentacle, as stock.
    ObjectGuid OpenPortal(Creature* me, uint32 portalEntry)
    {
        if (Creature* portal = me->SummonCreature(portalEntry, *me, TEMPSUMMON_CORPSE_DESPAWN))
        {
            portal->SetReactState(REACT_PASSIVE);
            if (me->ToTempSummon())
                if (Unit* summoner = me->ToTempSummon()->GetSummonerUnit())
                    if (Creature* creature = summoner->ToCreature())
                        creature->AI()->JustSummoned(portal);
            return portal->GetGUID();
        }
        return ObjectGuid::Empty;
    }

    struct npc_eye_tentacle_coa : public ScriptedAI
    {
        npc_eye_tentacle_coa(Creature* creature) : ScriptedAI(creature)
        {
            _portal = OpenPortal(me, NPC_SMALL_PORTAL);
            me->SetCombatMovement(false);
        }

        void JustDied(Unit* /*killer*/) override
        {
            if (Unit* portal = ObjectAccessor::GetUnit(*me, _portal))
                portal->KillSelf();
            if (Unit* target = ObjectAccessor::GetUnit(*me, _channelTarget))
                for (uint32 s : { SPELL_ERADICATE, SPELL_CONSUME })
                    target->RemoveAurasDueToSpell(sSpellMgr->GetSpellIdForDifficulty(s, me), me->GetGUID());
        }

        void SetData(uint32 type, uint32 value) override
        {
            if (type == TYPE_TENTACLE_KIND)
                _kind = uint8(value);
        }

        void Reset() override
        {
            DoZoneInCombat();
            scheduler.Schedule(500ms, [this](TaskContext) { DoCastAOE(SPELL_GROUND_RUPTURE); })
                     .Schedule(5min, [this](TaskContext) { me->DespawnOrUnsummon(); });
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            scheduler.Schedule(2s, [this](TaskContext context)
            {
                Channel();
                context.Repeat(1s);
            });
        }

        // One channel for the tentacle's life; a new target when the old one is gone.
        void Channel()
        {
            Unit* target = ObjectAccessor::GetUnit(*me, _channelTarget);
            bool const fresh = !target || !target->IsAlive() || InStomach(target);
            if (fresh)
            {
                target = SelectTarget(SelectTargetMethod::Random, 0, NotInStomachSelector());
                if (!target)
                    return;
                _channelTarget = target->GetGUID();
                _ticks = 0;
            }
            ++_ticks;

            switch (_kind)
            {
                case TENT_SHADOW:
                    if (fresh)
                        if (Creature* spot = me->SummonCreature(NPC_WORLD_TRIGGER, target->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, 20000))
                        {
                            spot->SetFaction(me->GetFaction());
                            spot->AddAura(SPELL_MIASMA, spot);
                        }
                    if (_ticks >= 20)
                        _channelTarget.Clear();
                    break;
                case TENT_FIRE:
                {
                    uint32 const id = sSpellMgr->GetSpellIdForDifficulty(SPELL_ERADICATE, me);
                    if (!target->HasAura(id, me->GetGUID()))
                        me->AddAura(id, target);
                    if (AuraEffect* eff = target->GetAuraEffect(id, EFFECT_0, me->GetGUID()))
                        eff->ChangeAmount(Info(me, SPELL_ERADICATE) * int32(1 + _ticks / 3));
                    break;
                }
                case TENT_NATURE:
                {
                    int32 const drain = Info(me, SPELL_CONSUME);
                    uint32 const consume = sSpellMgr->GetSpellIdForDifficulty(SPELL_CONSUME, me);
                    if (!target->HasAura(consume, me->GetGUID()))
                        me->AddAura(consume, target);
                    SpellDamage(me, target, consume, uint32(drain), SPELL_SCHOOL_MASK_NATURE);
                    AddStack(me, target, SPELL_WITHERED, 99);
                    if (InstanceScript* instance = me->GetInstanceScript())
                        for (uint32 data : { DATA_EYE_OF_CTHUN, DATA_CTHUN })
                            if (Creature* god = instance->GetCreature(data))
                                if (god->IsAlive() && god->IsVisible())
                                {
                                    int32 heal = drain;
                                    god->CastCustomSpell(god, SPELL_CONSUME_HEAL, &heal, nullptr, nullptr, true);
                                }
                    break;
                }
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;
            scheduler.Update(diff);
        }

    private:
        ObjectGuid _portal;
        ObjectGuid _channelTarget;
        uint8 _kind = TENT_SHADOW;
        uint32 _ticks = 0;
    };

    // The lesser tentacles of phase 1: Manipulator, Devastator, Malignant.
    struct npc_claw_tentacle_coa : public ScriptedAI
    {
        npc_claw_tentacle_coa(Creature* creature) : ScriptedAI(creature)
        {
            me->SetCombatMovement(false);
            _portal = OpenPortal(me, NPC_SMALL_PORTAL);
        }

        void SetData(uint32 type, uint32 value) override
        {
            if (type == TYPE_TENTACLE_KIND)
                _kind = uint8(value);
        }

        void JustDied(Unit* /*killer*/) override
        {
            if (Unit* portal = ObjectAccessor::GetUnit(*me, _portal))
                portal->KillSelf();
            if (Unit* held = ObjectAccessor::GetUnit(*me, _held))
            {
                held->RemoveAurasDueToSpell(SPELL_MALIGNANT_GRASP);
                held->RemoveAurasDueToSpell(sSpellMgr->GetSpellIdForDifficulty(SPELL_SQUEEZE, me));
            }
        }

        void Reset() override
        {
            scheduler.Schedule(500ms, [this](TaskContext) { DoCastAOE(SPELL_GROUND_RUPTURE); })
                     .Schedule(5min, [this](TaskContext) { me->DespawnOrUnsummon(); });
        }

        void JustEngagedWith(Unit* who) override
        {
            DoZoneInCombat();
            switch (_kind)
            {
                case LESSER_MANIPULATOR:
                    scheduler.Schedule(3s, [this](TaskContext context)
                    {
                        for (Player* p : PlayersWithin(me, 15.0f))
                            if (!InStomach(p))
                                me->CastSpell(p, SPELL_SENSORY_OVERLOAD, true);
                        context.Repeat(8s);
                    });
                    break;
                case LESSER_MALIGNANT:
                    if (who && who->IsPlayer())
                    {
                        _held = who->GetGUID();
                        me->CastSpell(who, SPELL_MALIGNANT_GRASP, true);
                        me->CastSpell(who, SPELL_SQUEEZE, true);
                    }
                    break;
                default:    // Devastator: the stock claw
                    scheduler.Schedule(2s, [this](TaskContext context)
                    {
                        DoCastVictim(SPELL_HAMSTRING);
                        context.Repeat(5s);
                    });
                    break;
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;
            scheduler.Update(diff);
            DoMeleeAttackIfReady();
        }

    private:
        ObjectGuid _portal;
        ObjectGuid _held;
        uint8 _kind = LESSER_DEVASTATOR;
    };

    struct npc_giant_claw_tentacle_coa : public ScriptedAI
    {
        npc_giant_claw_tentacle_coa(Creature* creature) : ScriptedAI(creature)
        {
            me->SetCombatMovement(false);
            _portal = OpenPortal(me, NPC_GIANT_PORTAL);
        }

        void JustDied(Unit* /*killer*/) override
        {
            if (Unit* portal = ObjectAccessor::GetUnit(*me, _portal))
                portal->KillSelf();
        }

        void Reset() override
        {
            scheduler.Schedule(500ms, [this](TaskContext) { DoCastAOE(SPELL_MASSIVE_GROUND_RUPTURE); });
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            DoZoneInCombat();
            me->AddAura(SPELL_CRUSHING_BLOWS, me);
            ScheduleTasks();
        }

        void ScheduleTasks()
        {
            scheduler.Schedule(10s, [this](TaskContext task)
            {
                if (Unit* target = me->GetVictim())
                    if (!target->IsWithinMeleeRange(me))
                    {
                        if (Player* newTarget = me->SelectNearestPlayer(5.0f))
                            AttackStart(newTarget);
                        else
                            Submerge();
                    }
                task.Repeat();
            }).Schedule(2s, [this](TaskContext context)
            {
                DoCastVictim(SPELL_HAMSTRING);
                context.Repeat(10s);
            }).Schedule(5s, [this](TaskContext context)
            {
                DoCastSelf(SPELL_THRASH);
                context.Repeat(10s);
            }).Schedule(8s, [this](TaskContext context)
            {
                DoCastSelf(SPELL_DEVASTATING_SMASH);
                context.Repeat(20s);
            }).Schedule(3s, [this](TaskContext)
            {
                _canAttack = true;
            });
        }

        void Submerge()
        {
            if (me->SelectNearestPlayer(5.0f))
                return;
            if (Creature* p = ObjectAccessor::GetCreature(*me, _portal))
                p->DespawnOrUnsummon();
            DoCastSelf(SPELL_SUBMERGE_VISUAL);
            me->SetHealth(me->GetMaxHealth());
            me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
            scheduler.CancelAll();
            _canAttack = false;
            scheduler.Schedule(5s, [this](TaskContext) { Emerge(); });
        }

        void Emerge()
        {
            if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, NotInStomachSelector()))
            {
                Position pos = target->GetPosition();
                me->NearTeleportTo(pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), 0);
                if (Creature* portal = me->SummonCreature(NPC_GIANT_PORTAL, pos, TEMPSUMMON_CORPSE_DESPAWN))
                {
                    portal->SetReactState(REACT_PASSIVE);
                    _portal = portal->GetGUID();
                }
                me->RemoveAurasDueToSpell(SPELL_SUBMERGE_VISUAL);
                DoCastSelf(SPELL_BIRTH);
                DoCastAOE(SPELL_MASSIVE_GROUND_RUPTURE, true);
                me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
                ScheduleTasks();
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;
            scheduler.Update(diff);
            if (_canAttack && !me->HasUnitState(UNIT_STATE_CASTING))
                DoMeleeAttackIfReady();
        }

    private:
        ObjectGuid _portal;
        bool _canAttack = false;
    };

    struct npc_giant_eye_tentacle_coa : public ScriptedAI
    {
        npc_giant_eye_tentacle_coa(Creature* creature) : ScriptedAI(creature)
        {
            me->SetCombatMovement(false);
            _portal = OpenPortal(me, NPC_GIANT_PORTAL);
        }

        void JustDied(Unit* /*killer*/) override
        {
            if (Unit* portal = ObjectAccessor::GetUnit(*me, _portal))
                portal->KillSelf();
        }

        void Reset() override
        {
            scheduler.Schedule(500ms, [this](TaskContext) { DoCastAOE(SPELL_MASSIVE_GROUND_RUPTURE); })
                .Schedule(1s, 5s, [this](TaskContext context)
                {
                    if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, NotInStomachSelector()))
                    {
                        _beamTarget = target->GetGUID();
                        DoCast(target, SPELL_LESSER_EYE_BEAM);
                    }
                    context.Repeat(2100ms);
                }).Schedule(10s, [this](TaskContext context)
                {
                    DoCastSelf(SPELL_LESSER_ELDRITCH);
                    context.Repeat(20s);
                });
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id == SPELL_LESSER_EYE_BEAM)
                ChainBeam(me, ObjectAccessor::GetUnit(*me, _beamTarget), SPELL_LESSER_EYE_BEAM);
            else if (spell->Id == SPELL_LESSER_ELDRITCH)
                Revelation(me, 40.0f);
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            DoZoneInCombat();
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;
            scheduler.Update(diff);
        }

    private:
        ObjectGuid _portal;
        ObjectGuid _beamTarget;
    };
}

void AddCoaCThunScripts()
{
    RegisterTempleOfAhnQirajCreatureAI(boss_eye_of_cthun_coa);
    RegisterTempleOfAhnQirajCreatureAI(boss_cthun_coa);
    RegisterTempleOfAhnQirajCreatureAI(npc_eye_tentacle_coa);
    RegisterTempleOfAhnQirajCreatureAI(npc_claw_tentacle_coa);
    RegisterTempleOfAhnQirajCreatureAI(npc_giant_claw_tentacle_coa);
    RegisterTempleOfAhnQirajCreatureAI(npc_giant_eye_tentacle_coa);
}
