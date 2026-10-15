/*
 * Buru the Gorger as Ascension rebuilt him.
 *
 * Kit: Ascension's block 2112400-2112468. No logs or video exist for
 * Ahn'Qiraj; every timer here is designed.
 *
 * From stock: he hunts one player at a time and gathers speed doing it, his
 * eggs around the room, and the last 20% without them.
 *
 * Impenetrable Chitin. He takes 90% less damage and throws a tenth of the rest
 * back. The way through is his own eggs: an egg that bursts next to him hits
 * him with Egg Shrapnel, and three shrapnel stacks crack the shell. Cracked
 * Carapace: +200% damage taken for 30s while it regenerates, and acid spurts
 * from the cracks. Then the chitin is back.
 *
 * An egg bursts when it is killed: Nature damage and knockback within 10
 * yards. Whoever it hits is covered in Brood Blood for 60s: Buru hunts them
 * first, and Creeping Plague stacks on them every 3 seconds. An egg left alone
 * hatches after 60s. Burst eggs grow back after 60s.
 *
 *   Seek Prey       at the pull, again whenever an egg bursts or his prey dies
 *   Dismember       first 5s,  every 8s    his prey, 150% weapon damage and a
 *                                          stacking bleed
 *   Devastate       first 15s, every 20s   4s cast, a lethal cone, the ground
 *                                          under his prey stays torn for 5s
 *   Acidic Blood    every 5s while cracked, three players, a hit and a puddle
 *
 *   Below 20%: the eggs die, the shell cracks for good, Frenzy, and Creeping
 *   Plague on everyone every 6s (stock).
 *
 * Decided here, not in the data: every timer, the 10% reflection, three
 * shrapnel stacks to crack him, 30s cracked (the regeneration aura's length),
 * three acid targets, eggs growing back, and 10 yards as "next to him".
 */

#include "CreatureScript.h"
#include "Containers.h"
#include "InstanceScript.h"
#include "ScriptedCreature.h"
#include "../../../src/server/scripts/Kalimdor/RuinsOfAhnQiraj/ruins_of_ahnqiraj.h"
#include "zg_coa_common.h"

#include <list>

using namespace coa_zg;

namespace
{
    enum Emotes
    {
        EMOTE_TARGET = 0
    };

    enum Spells
    {
        SPELL_GATHERING_SPEED     = 1834,
        SPELL_FULL_SPEED          = 1557,
        SPELL_SUMMON_HATCHLING    = 1881,

        SPELL_CHITIN              = 2112400,
        SPELL_CHITIN_REFLECT      = 2112401,
        SPELL_CRACKED             = 2112402,
        SPELL_REGENERATE          = 2112403,
        SPELL_SEEK_PREY           = 2112404,
        SPELL_DEVASTATE           = 2112405,
        SPELL_DEVASTATE_AREA      = 2112406,
        SPELL_DEVASTATE_HIT       = 2112407,
        SPELL_DISMEMBER           = 2112408,
        SPELL_ACIDIC_BLOOD_HIT    = 2112413,
        SPELL_ACIDIC_BLOOD_POOL   = 2112417,
        SPELL_FRENZY              = 2112421,
        SPELL_HATCHING            = 2112451,
        SPELL_EGGPLOSION          = 2112452,
        SPELL_BROOD_BLOOD         = 2112457,
        SPELL_EGG_SHRAPNEL        = 2112458,
        SPELL_CRACKED_FINAL       = 2112464,
        SPELL_CREEPING_PLAGUE     = 2112465,
    };

    enum Events
    {
        EVENT_DISMEMBER = 1,
        EVENT_GATHERING_SPEED,
        EVENT_DEVASTATE,
        EVENT_ACID,
        EVENT_PLAGUE,
        EVENT_REGROW,
    };

    enum Misc
    {
        NPC_WORLD_TRIGGER = 12999,
        PHASE_EGG         = 1,
        PHASE_TRANSFORM   = 2
    };

    constexpr uint32 REFLECT_PCT   = 10;
    constexpr uint8 SHRAPNEL_CRACK = 3;
    constexpr float EGG_RANGE      = 10.0f;
    constexpr float CONE_RANGE     = 10.0f;
    constexpr float CONE_ARC       = float(M_PI) / 2;

    struct boss_buru_coa : public BossAI
    {
        boss_buru_coa(Creature* creature) : BossAI(creature, DATA_BURU) { }

        void Reset() override
        {
            BossAI::Reset();
            for (uint32 s : { SPELL_CHITIN, SPELL_CRACKED, SPELL_REGENERATE, SPELL_EGG_SHRAPNEL, SPELL_CRACKED_FINAL, SPELL_FRENZY })
                me->RemoveAurasDueToSpell(s);
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            BossAI::EnterEvadeMode(why);
            DoCastSelf(SPELL_FULL_SPEED, true);
            _phase = PHASE_EGG;
            instance->SetData(DATA_BURU_PHASE, _phase);
            ManipulateEggs(true);
            instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_BROOD_BLOOD);
        }

        void ManipulateEggs(bool respawn)
        {
            std::list<Creature*> eggs;
            me->GetCreaturesWithEntryInRange(eggs, 150.0f, NPC_BURU_EGG);
            for (Creature* egg : eggs)
                respawn ? egg->Respawn() : Unit::Kill(me, egg);
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            _phase = PHASE_EGG;
            instance->SetData(DATA_BURU_PHASE, _phase);
            ManipulateEggs(true);
            me->RemoveAurasDueToSpell(SPELL_FULL_SPEED);
            me->AddAura(SPELL_CHITIN, me);
            Hunt(who);

            events.ScheduleEvent(EVENT_GATHERING_SPEED, 2s);
            events.ScheduleEvent(EVENT_DISMEMBER, 5s);
            events.ScheduleEvent(EVENT_DEVASTATE, 15s);
            events.ScheduleEvent(EVENT_PLAGUE, 3s);
        }

        void JustDied(Unit* killer) override
        {
            instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_BROOD_BLOOD);
            BossAI::JustDied(killer);
        }

        void KilledUnit(Unit* victim) override
        {
            if (victim->IsPlayer())
                Hunt(nullptr);
        }

        // Prefer a player covered in Brood Blood.
        void Hunt(Unit* forced)
        {
            if (_phase != PHASE_EGG && forced == nullptr)
                return;
            Unit* prey = forced;
            if (!prey)
            {
                std::vector<Player*> blooded = Players(me, [](Player* p) { return p->HasAura(SPELL_BROOD_BLOOD); });
                prey = blooded.empty() ? SelectTarget(SelectTargetMethod::Random, 0, 0.0f, true)
                                       : Acore::Containers::SelectRandomContainerElement(blooded);
            }
            if (!prey)
                return;

            if (Unit* old = ObjectAccessor::GetUnit(*me, _prey))
                old->RemoveAurasDueToSpell(SPELL_SEEK_PREY);
            _prey = prey->GetGUID();
            me->RemoveAurasDueToSpell(SPELL_GATHERING_SPEED);
            events.RescheduleEvent(EVENT_GATHERING_SPEED, 2s);
            DoResetThreatList();
            AttackStart(prey);
            me->AddThreat(prey, 1000000.0f);
            me->AddAura(SPELL_SEEK_PREY, prey);
            Talk(EMOTE_TARGET, prey);
        }

        // An egg burst: shrapnel if he stood close, and a new prey.
        void EggBurst(Creature* egg)
        {
            if (_phase == PHASE_EGG && !me->HasAura(SPELL_CRACKED) && me->IsWithinDistInMap(egg, EGG_RANGE))
            {
                AddStack(me, me, SPELL_EGG_SHRAPNEL);
                Aura* shrapnel = me->GetAura(SPELL_EGG_SHRAPNEL);
                if (shrapnel && shrapnel->GetStackAmount() >= SHRAPNEL_CRACK)
                    Crack();
            }
            Hunt(nullptr);
        }

        void Crack()
        {
            me->RemoveAurasDueToSpell(SPELL_EGG_SHRAPNEL);
            me->RemoveAurasDueToSpell(SPELL_CHITIN);
            me->AddAura(SPELL_CRACKED, me);
            DoCastSelf(SPELL_REGENERATE, true);
            events.ScheduleEvent(EVENT_ACID, 2s);
            events.ScheduleEvent(EVENT_REGROW, 30s);
        }

        void Regrow()
        {
            events.CancelEvent(EVENT_ACID);
            me->RemoveAurasDueToSpell(SPELL_CRACKED);
            if (_phase == PHASE_EGG)
                me->AddAura(SPELL_CHITIN, me);
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);

            // The chitin throws part of what gets through back.
            if (attacker && attacker != me && damage && me->HasAura(SPELL_CHITIN) && attacker->IsPlayer())
                Hit(me, attacker, SPELL_CHITIN_REFLECT, int32(damage * REFLECT_PCT / 100));

            if (_phase == PHASE_EGG && me->HealthBelowPctDamaged(20, damage))
            {
                _phase = PHASE_TRANSFORM;
                instance->SetData(DATA_BURU_PHASE, _phase);
                ManipulateEggs(false);
                events.Reset();
                me->RemoveAurasDueToSpell(SPELL_CHITIN);
                me->RemoveAurasDueToSpell(SPELL_CRACKED);
                me->RemoveAurasDueToSpell(SPELL_GATHERING_SPEED);
                if (Unit* prey = ObjectAccessor::GetUnit(*me, _prey))
                    prey->RemoveAurasDueToSpell(SPELL_SEEK_PREY);
                DoCastSelf(SPELL_FULL_SPEED, true);
                me->AddAura(SPELL_CRACKED_FINAL, me);
                DoCastSelf(SPELL_FRENZY, true);
                DoResetThreatList();
                events.ScheduleEvent(EVENT_DISMEMBER, 5s);
                events.ScheduleEvent(EVENT_PLAGUE, 2s);
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);
            if (spell->Id != SPELL_DEVASTATE)
                return;
            for (Player* p : PlayersInFront(me, CONE_RANGE, CONE_ARC))
                me->CastSpell(p, SPELL_DEVASTATE_HIT, true);
            if (Unit* prey = me->GetVictim())
                SpotCast(prey->GetPosition(), SPELL_DEVASTATE_AREA, 5000);
        }

        void SpotCast(Position const& pos, uint32 spell, uint32 lifeMs)
        {
            if (Creature* spot = me->SummonCreature(NPC_WORLD_TRIGGER, pos, TEMPSUMMON_TIMED_DESPAWN, lifeMs))
            {
                spot->SetFaction(me->GetFaction());
                spot->CastSpell(spot, spell, true, nullptr, nullptr, me->GetGUID());
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
                    case EVENT_GATHERING_SPEED:
                        DoCastSelf(SPELL_GATHERING_SPEED);
                        events.ScheduleEvent(EVENT_GATHERING_SPEED, 9s);
                        break;
                    case EVENT_DISMEMBER:
                        DoCastVictim(SPELL_DISMEMBER);
                        events.ScheduleEvent(EVENT_DISMEMBER, 8s);
                        break;
                    case EVENT_DEVASTATE:
                        DoCastVictim(SPELL_DEVASTATE);
                        events.ScheduleEvent(EVENT_DEVASTATE, 20s);
                        break;
                    case EVENT_ACID:
                    {
                        std::vector<Player*> targets = PlayersWithin(me, 50.0f);
                        Acore::Containers::RandomResize(targets, 3);
                        for (Player* p : targets)
                        {
                            me->CastSpell(p, SPELL_ACIDIC_BLOOD_HIT, true);
                            SpotCast(p->GetPosition(), SPELL_ACIDIC_BLOOD_POOL, 30000);
                        }
                        events.ScheduleEvent(EVENT_ACID, 5s);
                        break;
                    }
                    case EVENT_REGROW:
                        Regrow();
                        break;
                    case EVENT_PLAGUE:
                        if (_phase == PHASE_EGG)
                        {
                            for (Player* p : Players(me, [](Player* x) { return x->HasAura(SPELL_BROOD_BLOOD); }))
                                AddStack(me, p, SPELL_CREEPING_PLAGUE);
                            events.ScheduleEvent(EVENT_PLAGUE, 3s);
                        }
                        else
                        {
                            for (Player* p : Players(me, [](Player*) { return true; }))
                                AddStack(me, p, SPELL_CREEPING_PLAGUE);
                            events.ScheduleEvent(EVENT_PLAGUE, 6s);
                        }
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
        uint8 _phase = PHASE_EGG;
        ObjectGuid _prey;
    };

    // Buru's eggs: burst when killed, hatch if left alone for 60 seconds.
    struct npc_buru_egg_coa : public ScriptedAI
    {
        npc_buru_egg_coa(Creature* creature) : ScriptedAI(creature)
        {
            _instance = me->GetInstanceScript();
            me->SetCombatMovement(false);
            me->SetReactState(REACT_PASSIVE);
        }

        void Reset() override
        {
            _hatching = false;
        }

        void JustEngagedWith(Unit* attacker) override
        {
            if (Creature* buru = _instance->GetCreature(DATA_BURU))
                if (!buru->IsInCombat())
                    buru->AI()->AttackStart(attacker);
        }

        void JustSummoned(Creature* who) override
        {
            if (who->GetEntry() != NPC_HATCHLING)
                return;
            if (Creature* buru = _instance->GetCreature(DATA_BURU))
                if (Unit* target = buru->AI()->SelectTarget(SelectTargetMethod::Random))
                    who->AI()->AttackStart(target);
        }

        void JustDied(Unit* killer) override
        {
            Creature* buru = _instance->GetCreature(DATA_BURU);
            if (killer && killer != buru)
            {
                // Burst: shrapnel, and blood on everyone it hits.
                me->CastSpell(me, SPELL_EGGPLOSION, true);
                for (Player* p : PlayersWithin(me, EGG_RANGE))
                    me->AddAura(SPELL_BROOD_BLOOD, p);
                if (buru && buru->IsAlive())
                    if (auto* ai = dynamic_cast<boss_buru_coa*>(buru->AI()))
                        ai->EggBurst(me);
            }
            me->DespawnOrUnsummon(5s, 60s);
        }

        // The 60-second Hatching cast finished: the egg was left alone.
        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_HATCHING)
                return;
            DoCastSelf(SPELL_SUMMON_HATCHLING, true);
            me->DespawnOrUnsummon(1s, 60s);
        }

        void UpdateAI(uint32 /*diff*/) override
        {
            Creature* buru = _instance->GetCreature(DATA_BURU);
            bool const fight = buru && buru->IsInCombat() && _instance->GetData(DATA_BURU_PHASE) == PHASE_EGG;
            if (fight && !_hatching)
            {
                _hatching = true;
                DoCastSelf(SPELL_HATCHING);
            }
            else if (!fight && _hatching)
            {
                _hatching = false;
                me->InterruptNonMeleeSpells(false);
            }
        }

    private:
        InstanceScript* _instance;
        bool _hatching = false;
    };
}

void AddCoaBuruScripts()
{
    RegisterRuinsOfAhnQirajCreatureAI(boss_buru_coa);
    RegisterRuinsOfAhnQirajCreatureAI(npc_buru_egg_coa);
}
