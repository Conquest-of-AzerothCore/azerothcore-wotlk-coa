/*
 * High Priestess Jeklik with Ascension's spells.
 *
 * Kit: Ascension's block 2106100-2106143. Timings: a Bronzebeard kill on video,
 * see raid-difficulty-werkzeug/zg-video-zeitplan.json. On Ascension the phases
 * run the other way round from stock: she fights as a troll first and takes
 * bat form at 50% (in the video at 50%, 147s into the fight).
 *
 *   Troll form, from landing
 *     Mind Flay         first 4s,  every 14s   on the tank, interruptible
 *     Mass Fear         first 12s, every 48s   everyone within 20 yards
 *     Shadow Word: Pain first 15s, every 27s   random player
 *     Curse of Blood    first 16s, every 31s   random player and those near
 *     Call of Hir'eek   first 20s              six Bloodseeker Bats
 *     Greater Heal      first 29s, every 46s   20% of her health, interruptible
 *
 *   Bat form, at 50%
 *     Bat-tering Charge  first 2s, every 20s   random player, knocks back
 *                                              everyone within 10 yards
 *     Terrifying Screech first 4s, every 20s   everyone in the room
 *     Vampirism          passive, her hits drain life
 *     Bat Riders         two, from stock, throwing liquid fire
 *
 * Decided here, not in the data:
 *   - Call of Hir'eek every 60s (the video shows it once);
 *   - Terrifying Screech falls off with distance, full at her, nothing at 100
 *     yards (the tooltip says "reduced as farther", not by how much);
 *   - the bat riders move from the troll phase to the bat phase with the swap.
 */

#include "CreatureScript.h"
#include "MoveSplineInit.h"
#include "ScriptedCreature.h"
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
        SPELL_BAT_FORM            = 23966,

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
        SPELL_ASPECT_OF_HIREEK    = 2106122,
        SPELL_BATTERING_CHARGE    = 2106125,
        SPELL_BATTERING_STUN      = 2106126,
        SPELL_BATTERING_IMPACT    = 2106127,
        SPELL_SCREECH             = 2106131,
        INFO_SCREECH              = 2106132,
        SPELL_SCREECH_HIT         = 2106136,
        SPELL_VAMPIRISM           = 2106138,
    };

    enum Npcs
    {
        NPC_BLOODSEEKER_BAT = 11368,
        NPC_BATRIDER        = 14750
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
    };

    enum Phases
    {
        PHASE_TROLL = 1,
        PHASE_BAT   = 2
    };

    constexpr uint32 PATH_JEKLIK_INTRO = 145170;
    constexpr float MASS_FEAR_RANGE    = 20.0f;
    constexpr float SCREECH_RANGE      = 100.0f;

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
    Position const JeklikCaveHomePosition = { -12291.9f, -1380.08f, 144.902f, 2.28638f };

    struct boss_jeklik_coa : public BossAI
    {
        boss_jeklik_coa(Creature* creature) : BossAI(creature, DATA_JEKLIK) { }

        void Reset() override
        {
            BossAI::Reset();
            me->SetHomePosition(JeklikCaveHomePosition);
            me->SetDisableGravity(false);
            me->SetReactState(REACT_PASSIVE);
            me->SetCombatMovement(false);
            me->RemoveAurasDueToSpell(SPELL_ASPECT_OF_HIREEK);
            me->RemoveAurasDueToSpell(SPELL_VAMPIRISM);
            _bat = false;
            _riders = 0;
            DoCastSelf(SPELL_GREEN_CHANNELING, true);
        }

        // From stock: she flies down from her cave in bat form.
        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            Talk(SAY_AGGRO);
            DoZoneInCombat();
            me->RemoveAurasDueToSpell(SPELL_GREEN_CHANNELING);
            me->SetDisableGravity(true);
            DoCastSelf(SPELL_BAT_FORM, true);
            me->GetMotionMaster()->MoveWaypoint(PATH_JEKLIK_INTRO, false);
        }

        void PathEndReached(uint32 pathId) override
        {
            BossAI::PathEndReached(pathId);
            me->RemoveAurasDueToSpell(SPELL_BAT_FORM);
            me->SetDisableGravity(false);
            me->SetCombatMovement(true);
            me->SetReactState(REACT_AGGRESSIVE);

            events.SetPhase(PHASE_TROLL);
            events.ScheduleEvent(EVENT_MIND_FLAY, 4s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_MASS_FEAR, 12s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_SHADOW_WORD_PAIN, 15s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_CURSE_OF_BLOOD, 16s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_CALL_OF_HIREEK, 20s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_GREATER_HEAL, 29s, 0, PHASE_TROLL);
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            if (why != EvadeReason::EVADE_REASON_NO_PATH)
                me->DespawnOnEvade(5s);
            BossAI::EnterEvadeMode(why);
        }

        void JustDied(Unit* killer) override
        {
            BossAI::JustDied(killer);
            Talk(SAY_DEATH);
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);

            if (_bat || !me->HealthBelowPctDamaged(50, damage))
                return;

            _bat = true;
            me->InterruptNonMeleeSpells(false);
            DoCastSelf(SPELL_ASPECT_OF_HIREEK, true);
            DoCastSelf(SPELL_VAMPIRISM, true);
            DoResetThreatList();

            events.SetPhase(PHASE_BAT);
            events.ScheduleEvent(EVENT_BATTERING_CHARGE, 2s, 0, PHASE_BAT);
            events.ScheduleEvent(EVENT_SCREECH, 4s, 0, PHASE_BAT);
            events.ScheduleEvent(EVENT_BAT_RIDER, 10s, 0, PHASE_BAT);
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
                    break;
                }
                default:
                    break;
            }
        }

        // The charge stuns its target; the impact around it is its own spell.
        void SpellHitTarget(Unit* target, SpellInfo const* spell) override
        {
            if (spell->Id == SPELL_BATTERING_STUN)
                me->CastSpell(target, SPELL_BATTERING_IMPACT, true);
        }

        void CallOfHireek()
        {
            Talk(EMOTE_SUMMON_BATS);
            Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true);
            for (Position const& pos : SpawnBat)
                if (Creature* bat = me->SummonCreature(NPC_BLOODSEEKER_BAT, pos, TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT, 15000))
                    if (target)
                        bat->AI()->AttackStart(target);
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
                        events.ScheduleEvent(EVENT_MASS_FEAR, 48s, 0, PHASE_TROLL);
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
                        events.ScheduleEvent(EVENT_CALL_OF_HIREEK, 60s, 0, PHASE_TROLL);
                        break;
                    case EVENT_GREATER_HEAL:
                        Talk(EMOTE_GREAT_HEAL);
                        DoCastSelf(SPELL_GREATER_HEAL);
                        events.ScheduleEvent(EVENT_GREATER_HEAL, 46s, 0, PHASE_TROLL);
                        break;
                    case EVENT_BATTERING_CHARGE:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, [this](Unit* u) { return u->IsPlayer() && !me->IsWithinMeleeRange(u); }))
                            DoCast(target, SPELL_BATTERING_CHARGE);
                        events.ScheduleEvent(EVENT_BATTERING_CHARGE, 20s, 0, PHASE_BAT);
                        break;
                    case EVENT_SCREECH:
                        DoCastSelf(SPELL_SCREECH);
                        events.ScheduleEvent(EVENT_SCREECH, 20s, 0, PHASE_BAT);
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
        ObjectGuid _target;
    };
}

void AddCoaJeklikScripts()
{
    RegisterZulGurubCreatureAI(boss_jeklik_coa);
}
