/*
 * High Priestess Mar'li with Ascension's spells.
 *
 * Kit: Ascension's block 2118100-2118151. Timings: a Bronzebeard kill on video,
 * see raid-difficulty-werkzeug/zg-video-zeitplan.json. Stock swaps between
 * troll and spider every minute; on Ascension she stays a troll until 50% and
 * a spider after (in the video from 49%, 230s in).
 *
 *   Troll form
 *     Drain Life         first 6s,  every 10s   random player, interruptible
 *     Poison Bolt Volley first 12s, every 15s   everyone, stacking poison
 *     Hatch Eggs         at 17s                  the four nearest eggs hatch
 *     Evolve             first 22s, every 60s   an egg hatches a colossal spider
 *     Infest             first 87s, every 60s   an egg hatches a festering
 *                                               spider that bursts on death
 *
 *   Spider form, at 50%
 *     Acid Spit          first 1s,  every 12s   on the tank, poison and -10% armour
 *     Web Spray          first 15s, every 55s   everyone within 20 yards is
 *                                               slowed, then webbed; then she
 *                                               charges a caster, as in stock
 *     Poison Shock       first 25s, every 25s   20 yards around her
 *     Furious Strikes    passive, her hits speed her up
 *
 * Decided here, not in the data:
 *   - Evolve and Infest act on an egg she hatches for it: the spawn of Evolve
 *     is twice the size with twice the health; the spawn of Infest bursts for
 *     Poison Shock's damage where it dies;
 *   - Drain Life heals her for what each tick deals;
 *   - Poison Shock's timer (the video never shows it); no falloff with range.
 */

#include "CreatureScript.h"
#include "GameObject.h"
#include "ScriptedCreature.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"

#include <list>

using namespace coa_zg;

namespace
{
    enum Says
    {
        SAY_AGGRO        = 0,
        SAY_TRANSFORM    = 1,
        SAY_SPIDER_SPAWN = 2,
        SAY_DEATH        = 3
    };

    enum Spells
    {
        SPELL_THRASH              = 3391,
        SPELL_CHARGE              = 22911,

        INFO_DRAIN_LIFE           = 2118101,
        SPELL_DRAIN_LIFE          = 2118105,
        SPELL_DRAIN_LIFE_TICK     = 2118107,
        SPELL_DRAIN_LIFE_HEAL     = 2118108,
        SPELL_POISON_BOLT_VOLLEY  = 2118109,
        SPELL_POISON_BOLT_HIT     = 2118110,
        SPELL_HATCH_EGGS          = 2118115,
        SPELL_EVOLVE              = 2118116,
        SPELL_ASPECT_OF_SHADRA    = 2118123,
        SPELL_FURIOUS_STRIKES     = 2118125,
        SPELL_ACID_SPIT           = 2118127,
        SPELL_ACID_SPIT_DOT       = 2118128,
        SPELL_CORROSION           = 2118132,
        SPELL_WEB_SPRAY           = 2118133,
        SPELL_POISON_SHOCK        = 2118145,
        SPELL_POISON_SHOCK_HIT    = 2118146,
        SPELL_INFEST              = 2118151,
    };

    enum Misc
    {
        GO_SPIDER_EGGS     = 179985,
        NPC_SPAWN_OF_MARLI = 15041,
        NPC_WORLD_TRIGGER  = 12999
    };

    enum Events
    {
        EVENT_THRASH = 1,
        EVENT_DRAIN_LIFE,
        EVENT_POISON_BOLT_VOLLEY,
        EVENT_HATCH_EGGS,
        EVENT_EVOLVE,
        EVENT_INFEST,
        EVENT_ACID_SPIT,
        EVENT_WEB_SPRAY,
        EVENT_CHARGE,
        EVENT_POISON_SHOCK,
    };

    enum Phases
    {
        PHASE_TROLL  = 1,
        PHASE_SPIDER = 2
    };

    constexpr float VOLLEY_RANGE = 200.0f;
    constexpr uint8 FIRST_HATCH  = 4;

    struct boss_marli_coa : public BossAI
    {
        boss_marli_coa(Creature* creature) : BossAI(creature, DATA_MARLI) { }

        void Reset() override
        {
            me->RemoveAurasDueToSpell(SPELL_ASPECT_OF_SHADRA);
            me->RemoveAurasDueToSpell(SPELL_FURIOUS_STRIKES);
            _spider = false;
            _festering.clear();

            std::list<GameObject*> eggs;
            me->GetGameObjectListWithEntryInGrid(eggs, GO_SPIDER_EGGS, DEFAULT_VISIBILITY_INSTANCE);
            for (GameObject* egg : eggs)
            {
                egg->Respawn();
                egg->UpdateObjectVisibility();
            }
            BossAI::Reset();
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            Talk(SAY_AGGRO);

            events.SetPhase(PHASE_TROLL);
            events.ScheduleEvent(EVENT_THRASH, 4s, 6s);
            events.ScheduleEvent(EVENT_DRAIN_LIFE, 6s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_POISON_BOLT_VOLLEY, 12s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_HATCH_EGGS, 17s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_EVOLVE, 22s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_INFEST, 87s, 0, PHASE_TROLL);
        }

        void JustDied(Unit* killer) override
        {
            BossAI::JustDied(killer);
            Talk(SAY_DEATH);
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);

            if (_spider || !me->HealthBelowPctDamaged(50, damage))
                return;

            _spider = true;
            me->InterruptNonMeleeSpells(false);
            Talk(SAY_TRANSFORM);
            DoCastSelf(SPELL_ASPECT_OF_SHADRA, true);
            DoCastSelf(SPELL_FURIOUS_STRIKES, true);

            events.SetPhase(PHASE_SPIDER);
            events.ScheduleEvent(EVENT_ACID_SPIT, 1s, 0, PHASE_SPIDER);
            events.ScheduleEvent(EVENT_WEB_SPRAY, 15s, 0, PHASE_SPIDER);
            events.ScheduleEvent(EVENT_POISON_SHOCK, 25s, 0, PHASE_SPIDER);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            switch (spell->Id)
            {
                case SPELL_POISON_BOLT_VOLLEY:
                    for (Player* p : PlayersWithin(me, VOLLEY_RANGE))
                        me->CastSpell(p, SPELL_POISON_BOLT_HIT, true);
                    break;
                case SPELL_HATCH_EGGS:
                    Talk(SAY_SPIDER_SPAWN);
                    for (uint8 i = 0; i < FIRST_HATCH; ++i)
                        HatchEgg();
                    break;
                case SPELL_EVOLVE:
                    if (Creature* spawn = HatchEgg())
                    {
                        spawn->AddAura(SPELL_EVOLVE, spawn);
                        spawn->SetMaxHealth(spawn->GetMaxHealth() * 2);
                        spawn->SetFullHealth();
                    }
                    break;
                case SPELL_INFEST:
                    if (Creature* spawn = HatchEgg())
                    {
                        spawn->AddAura(SPELL_INFEST, spawn);
                        _festering.insert(spawn->GetGUID());
                    }
                    break;
                case SPELL_ACID_SPIT:
                    if (Unit* tank = me->GetVictim())
                    {
                        me->CastSpell(tank, SPELL_ACID_SPIT_DOT, true);
                        me->CastSpell(tank, SPELL_CORROSION, true);
                    }
                    break;
                case SPELL_POISON_SHOCK:
                    me->CastSpell(me, SPELL_POISON_SHOCK_HIT, true);
                    break;
                default:
                    break;
            }
        }

        // Drain Life heals her for what each tick deals.
        void SpellHitTarget(Unit* /*target*/, SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_DRAIN_LIFE_TICK)
                return;
            int32 heal = Info(me, INFO_DRAIN_LIFE);
            me->CastCustomSpell(me, SPELL_DRAIN_LIFE_HEAL, &heal, nullptr, nullptr, true);
        }

        // A festering spawn bursts where it dies.
        void SummonedCreatureDies(Creature* summon, Unit* killer) override
        {
            BossAI::SummonedCreatureDies(summon, killer);
            if (!_festering.erase(summon->GetGUID()))
                return;
            if (Creature* spot = me->SummonCreature(NPC_WORLD_TRIGGER, summon->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, 5000))
            {
                spot->SetFaction(me->GetFaction());
                spot->CastSpell(spot, SPELL_POISON_SHOCK_HIT, true, nullptr, nullptr, me->GetGUID());
            }
        }

        // The nearest egg still standing hatches a Spawn of Mar'li.
        Creature* HatchEgg()
        {
            std::list<GameObject*> eggs;
            me->GetGameObjectListWithEntryInGrid(eggs, GO_SPIDER_EGGS, 100.0f);
            GameObject* nearest = nullptr;
            for (GameObject* egg : eggs)
                if (egg->isSpawned() && (!nearest || me->GetDistance(egg) < me->GetDistance(nearest)))
                    nearest = egg;
            if (!nearest)
                return nullptr;

            Creature* spawn = me->SummonCreature(NPC_SPAWN_OF_MARLI, nearest->GetPosition(), TEMPSUMMON_CORPSE_TIMED_DESPAWN, 60000);
            nearest->SetLootState(GO_JUST_DEACTIVATED);
            if (spawn)
                spawn->SetInCombatWithZone();
            return spawn;
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
                    case EVENT_THRASH:
                        DoCastVictim(SPELL_THRASH);
                        events.ScheduleEvent(EVENT_THRASH, 10s, 20s);
                        break;
                    case EVENT_DRAIN_LIFE:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                        {
                            int32 tick = Info(me, INFO_DRAIN_LIFE);
                            me->CastCustomSpell(target, SPELL_DRAIN_LIFE, nullptr, &tick, nullptr, false);
                        }
                        events.ScheduleEvent(EVENT_DRAIN_LIFE, 10s, 0, PHASE_TROLL);
                        break;
                    case EVENT_POISON_BOLT_VOLLEY:
                        DoCastSelf(SPELL_POISON_BOLT_VOLLEY);
                        events.ScheduleEvent(EVENT_POISON_BOLT_VOLLEY, 15s, 0, PHASE_TROLL);
                        break;
                    case EVENT_HATCH_EGGS:
                        DoCastSelf(SPELL_HATCH_EGGS);
                        break;
                    case EVENT_EVOLVE:
                        DoCastSelf(SPELL_EVOLVE);
                        events.ScheduleEvent(EVENT_EVOLVE, 60s, 0, PHASE_TROLL);
                        break;
                    case EVENT_INFEST:
                        DoCastSelf(SPELL_INFEST);
                        events.ScheduleEvent(EVENT_INFEST, 60s, 0, PHASE_TROLL);
                        break;
                    case EVENT_ACID_SPIT:
                        DoCastVictim(SPELL_ACID_SPIT);
                        events.ScheduleEvent(EVENT_ACID_SPIT, 12s, 0, PHASE_SPIDER);
                        break;
                    case EVENT_WEB_SPRAY:
                        DoCastSelf(SPELL_WEB_SPRAY);
                        events.ScheduleEvent(EVENT_CHARGE, 5s, 0, PHASE_SPIDER);
                        events.ScheduleEvent(EVENT_WEB_SPRAY, 55s, 0, PHASE_SPIDER);
                        break;
                    case EVENT_CHARGE:
                        // From stock: after the webs she goes for a caster out of reach.
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, [this](Unit* u)
                            {
                                return u->IsPlayer() && u->getPowerType() == POWER_MANA && !me->IsWithinMeleeRange(u) && u != me->GetVictim();
                            }))
                        {
                            DoCast(target, SPELL_CHARGE);
                            AttackStart(target);
                        }
                        break;
                    case EVENT_POISON_SHOCK:
                        DoCastSelf(SPELL_POISON_SHOCK);
                        events.ScheduleEvent(EVENT_POISON_SHOCK, 25s, 0, PHASE_SPIDER);
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    private:
        bool _spider = false;
        GuidSet _festering;
    };
}

void AddCoaMarliScripts()
{
    RegisterZulGurubCreatureAI(boss_marli_coa);
}
