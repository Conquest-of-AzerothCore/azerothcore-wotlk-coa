/*
 * High Priestess Mar'li with Ascension's spells.
 *
 * Kit: Ascension's block 2118100-2118151. Timings: a Bronzebeard kill on video,
 * see raid-difficulty-werkzeug/zg-video-zeitplan.json. Stock swaps between
 * troll and spider every minute; on Ascension she stays a troll until 50% and
 * a spider after (in the video from 49%, 230s in). The spider form's cycle
 * (Web Spray, Burrow, Poison Shock every 45s) and Fierce Blow follow the CoA
 * combat log of 2026-08-02.
 *
 *   Troll form
 *     Drain Life         first 6s,  every 10s   random player, interruptible
 *     Poison Bolt Volley first 12s, every 15s   everyone, stacking poison
 *     Hatch Eggs         at 17s                  the four nearest eggs hatch;
 *                                               on Ascended every 30s after
 *                                               (a DBM bar in the live video
 *                                               of 2026-08-04)
 *     Evolve             first 22s, every 60s   an egg hatches a colossal spider
 *     Infest             first 87s, every 60s   an egg hatches a festering
 *                                               spider that bursts on death
 *
 *   At 50% she drains the Avatar of Shadra (see LoaAvatar), taking ~1% damage
 *   while it dies; then the Gift of the Blood God and her spider form.
 *
 *   Spider form, when the avatar dies
 *     Acid Spit          first 1s,  every 12s   on the tank, poison and -10% armour
 *     Web Spray          first 15s, every 45s   everyone within 20 yards is
 *                                               slowed, then webbed; then she
 *                                               charges a caster, as in stock
 *     Burrow             first 20.5s, every 45s under ground for 3s, untargetable
 *     Poison Shock       first 27s, every 45s   Poison Nova, 20 yards around her,
 *                                               less the farther away
 *     Furious Strikes    passive, her hits speed her up
 *
 *   Both forms
 *     Fierce Blow        tank, first 6.7-17.3s, then every 6-10s
 *
 * Decided here, not in the data:
 *   - Evolve and Infest act on an egg she hatches for it: the spawn of Evolve
 *     is twice the size with twice the health; the spawn of Infest bursts for
 *     Poison Shock's damage where it dies;
 *   - Drain Life heals her for what each tick deals;
 *   - Poison Nova falls off evenly to nothing at 20 yards (the tooltip says
 *     reduced, not by how much).
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
        SPELL_DRAIN_POWER         = 2118122,
        SPELL_ASPECT_OF_SHADRA    = 2118123,
        SPELL_GIFT_OF_THE_BLOOD_GOD = 2118124,
        SPELL_FURIOUS_STRIKES     = 2118125,
        SPELL_ACID_SPIT           = 2118127,
        SPELL_ACID_SPIT_DOT       = 2118128,
        SPELL_CORROSION           = 2118132,
        SPELL_WEB_SPRAY           = 2118133,
        SPELL_POISON_SHOCK        = 2118145,
        SPELL_POISON_SHOCK_HIT    = 2118146,
        SPELL_BURROW              = 2118140,
        SPELL_POISON_NOVA         = 2118150,
        SPELL_INFEST              = 2118151,
    };

    enum Misc
    {
        GO_SPIDER_EGGS     = 179985,
        NPC_SPAWN_OF_MARLI = 15041,
        NPC_WORLD_TRIGGER  = 12999,
        NPC_AVATAR_OF_SHADRA = 666990
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
        EVENT_BURROW,
        EVENT_EMERGE,
        EVENT_FIERCE_BLOW,
    };

    enum Phases
    {
        PHASE_TROLL  = 1,
        PHASE_SPIDER = 2
    };

    constexpr float VOLLEY_RANGE   = 200.0f;
    constexpr uint8 EGGS_PER_HATCH = 4;
    constexpr float NOVA_RANGE     = 20.0f;
    constexpr Milliseconds BURROW_LENGTH        = 3s;
    constexpr Milliseconds ASCENDED_HATCH_EVERY = 30s;

    struct boss_marli_coa : public BossAI
    {
        boss_marli_coa(Creature* creature) : BossAI(creature, DATA_MARLI) { }

        void Reset() override
        {
            me->RemoveAurasDueToSpell(SPELL_ASPECT_OF_SHADRA);
            me->RemoveAurasDueToSpell(SPELL_FURIOUS_STRIKES);
            me->RemoveAurasDueToSpell(SPELL_GIFT_OF_THE_BLOOD_GOD);
            _avatar.Restore(me);
            _spider = false;
            _festering.clear();
            Emerge();

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
            _avatar.Restore(me);

            events.SetPhase(PHASE_TROLL);
            events.ScheduleEvent(EVENT_THRASH, 4s, 6s);
            events.ScheduleEvent(EVENT_DRAIN_LIFE, 6s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_POISON_BOLT_VOLLEY, 12s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_HATCH_EGGS, 17s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_EVOLVE, 22s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_INFEST, 87s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_FIERCE_BLOW, FIERCE_BLOW_FIRST_MIN, FIERCE_BLOW_FIRST_MAX);
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

            if (_spider || !me->HealthBelowPctDamaged(50, damage))
                return;

            _spider = true;
            if (!_avatar.Drain(me))
                TakeSpiderForm();
        }

        void TakeSpiderForm()
        {
            me->InterruptNonMeleeSpells(false);
            Talk(SAY_TRANSFORM);
            DoCastSelf(SPELL_GIFT_OF_THE_BLOOD_GOD, true);
            DoCastSelf(SPELL_ASPECT_OF_SHADRA, true);
            DoCastSelf(SPELL_FURIOUS_STRIKES, true);

            events.SetPhase(PHASE_SPIDER);
            events.ScheduleEvent(EVENT_ACID_SPIT, 1s, 0, PHASE_SPIDER);
            events.ScheduleEvent(EVENT_WEB_SPRAY, 15s, 0, PHASE_SPIDER);
            events.ScheduleEvent(EVENT_BURROW, 20500ms, 0, PHASE_SPIDER);
            events.ScheduleEvent(EVENT_POISON_SHOCK, 27s, 0, PHASE_SPIDER);
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
                    for (uint8 i = 0; i < EGGS_PER_HATCH; ++i)
                        HatchEgg();
                    break;
                case SPELL_ACID_SPIT:
                    if (Unit* tank = me->GetVictim())
                    {
                        me->CastSpell(tank, SPELL_ACID_SPIT_DOT, true);
                        me->CastSpell(tank, SPELL_CORROSION, true);
                    }
                    break;
                case SPELL_POISON_SHOCK:
                {
                    int32 const full = Info(me, SPELL_POISON_SHOCK_HIT);
                    for (Player* p : PlayersWithin(me, NOVA_RANGE))
                        Hit(me, p, SPELL_POISON_NOVA, int32(full * (1.0f - me->GetDistance(p) / NOVA_RANGE)));
                    break;
                }
                case SPELL_BURROW:
                    me->AttackStop();
                    me->SetReactState(REACT_PASSIVE);
                    me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
                    events.ScheduleEvent(EVENT_EMERGE, BURROW_LENGTH, 0, PHASE_SPIDER);
                    break;
                default:
                    break;
            }
        }

        void SpellHitTarget(Unit* target, SpellInfo const* spell) override
        {
            switch (spell->Id)
            {
                case SPELL_EVOLVE:
                    target->SetMaxHealth(target->GetMaxHealth() * 2);
                    target->SetFullHealth();
                    break;
                case SPELL_INFEST:
                    _festering.insert(target->GetGUID());
                    break;
                // Drain Life heals her for what each tick deals.
                case SPELL_DRAIN_LIFE_TICK:
                {
                    int32 heal = Info(me, INFO_DRAIN_LIFE);
                    me->CastCustomSpell(me, SPELL_DRAIN_LIFE_HEAL, &heal, nullptr, nullptr, true);
                    break;
                }
                default:
                    break;
            }
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

        void Emerge()
        {
            me->RemoveAurasDueToSpell(SPELL_BURROW);
            me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
            me->SetReactState(REACT_AGGRESSIVE);
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

            if (_avatar.Consumed(me))
                TakeSpiderForm();

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
                        if (me->GetMap()->GetSpawnMode() == RAID_DIFFICULTY_25MAN_HEROIC)
                            events.ScheduleEvent(EVENT_HATCH_EGGS, ASCENDED_HATCH_EVERY, 0, PHASE_TROLL);
                        break;
                    case EVENT_EVOLVE:
                        if (Creature* spawn = HatchEgg())
                            DoCast(spawn, SPELL_EVOLVE);
                        events.ScheduleEvent(EVENT_EVOLVE, 60s, 0, PHASE_TROLL);
                        break;
                    case EVENT_INFEST:
                        if (Creature* spawn = HatchEgg())
                            DoCast(spawn, SPELL_INFEST);
                        events.ScheduleEvent(EVENT_INFEST, 60s, 0, PHASE_TROLL);
                        break;
                    case EVENT_ACID_SPIT:
                        DoCastVictim(SPELL_ACID_SPIT);
                        events.ScheduleEvent(EVENT_ACID_SPIT, 12s, 0, PHASE_SPIDER);
                        break;
                    case EVENT_WEB_SPRAY:
                        DoCastSelf(SPELL_WEB_SPRAY);
                        events.ScheduleEvent(EVENT_CHARGE, 5s, 0, PHASE_SPIDER);
                        events.ScheduleEvent(EVENT_WEB_SPRAY, 45s, 0, PHASE_SPIDER);
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
                        events.ScheduleEvent(EVENT_POISON_SHOCK, 45s, 0, PHASE_SPIDER);
                        break;
                    case EVENT_BURROW:
                        DoCastSelf(SPELL_BURROW);
                        events.ScheduleEvent(EVENT_BURROW, 45s, 0, PHASE_SPIDER);
                        break;
                    case EVENT_EMERGE:
                        Emerge();
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    private:
        bool _spider = false;
        LoaAvatar _avatar{ NPC_AVATAR_OF_SHADRA, SPELL_DRAIN_POWER };
        GuidSet _festering;
    };
}

void AddCoaMarliScripts()
{
    RegisterZulGurubCreatureAI(boss_marli_coa);
}
