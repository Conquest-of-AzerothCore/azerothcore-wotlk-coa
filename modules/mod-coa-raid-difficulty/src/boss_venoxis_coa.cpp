/*
 * High Priest Venoxis with Ascension's spells.
 *
 * Kit: Ascension's block 2118000-2118087. Timings: a Bronzebeard kill on video
 * (Ascension's mechanics, read off his cast bar at 10 frames a second), see
 * raid-difficulty-werkzeug/zg-video-zeitplan.json.
 *
 *   Troll form
 *     Holy Nova     first 7s,  every 18s   15 yards around him; heals him and
 *                                          his cobras for 6% of his health
 *     Renew         first 16s, every 24s   on himself, 2% of his health every 3s
 *     Holy Wrath    first 18s, every 15s   on the tank, arcs on
 *     Holy Fire     first 22s, every 10s   random player, hit and burn
 *
 *   Snake form, at 50% (the video: 47-50%)
 *     Toxic Bombardement  first 1s,  every 15s   toxic cloud at a random player
 *     Parasitic Poison    first 3s,  every 15s   random player; dispelled, a
 *                                                Parasitic Serpent breaks out
 *     Venom Spit          first 5s,  every 10s   everyone in front, stacks
 *                                                Virulent Poison
 *     Corpse Explosion    first 17s, every 40s   every snake corpse nearby
 *                                                bursts and leaves acid
 *     Poisonous Fangs     passive, his hits apply Virulent Poison
 *
 * Decided here, not in the data:
 *   - Holy Wrath jumps up to 4 times, 10 yards each, +50% per jump minus 2%
 *     per player above 10 (the tooltip's rule);
 *   - the transform is his own Aspect of Hethiss (2118023) instead of the
 *     stock snake spell;
 *   - Thrash and the frenzy at 20% stay from stock.
 */

#include "CreatureScript.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"

#include <list>

using namespace coa_zg;

namespace
{
    enum Says
    {
        SAY_TRANSFORM = 1,
        SAY_DEATH     = 2
    };

    enum Spells
    {
        SPELL_THRASH               = 3391,
        SPELL_FRENZY               = 8269,

        SPELL_RENEW                = 2118001,
        SPELL_HOLY_NOVA            = 2118002,
        SPELL_HOLY_NOVA_HIT        = 2118003,
        SPELL_HOLY_NOVA_HEAL       = 2118007,
        INFO_HOLY_FIRE             = 2118008,
        SPELL_HOLY_FIRE            = 2118012,
        SPELL_HOLY_FIRE_DOT        = 2118013,
        SPELL_HOLY_FIRE_HIT        = 2118014,
        INFO_HOLY_WRATH            = 2118016,
        SPELL_HOLY_WRATH           = 2118020,
        SPELL_HOLY_WRATH_HIT       = 2118021,
        SPELL_ASPECT_OF_HETHISS    = 2118023,
        SPELL_POISONOUS_FANGS      = 2118025,
        SPELL_VIRULENT_POISON      = 2118026,
        SPELL_VENOM_SPIT           = 2118030,
        SPELL_VENOM_SPIT_HIT       = 2118031,
        SPELL_TOXIC_BOMBARDEMENT   = 2118035,
        SPELL_PARASITIC_POISON     = 2118040,
        SPELL_PARASITIC_POISON_DOT = 2118041,
        SPELL_CORPSE_EXPLOSION     = 2118045,
        SPELL_ACID_BURST           = 2118078,
        SPELL_ACID_POOL            = 2118082,
    };

    enum Npcs
    {
        NPC_RAZZASHI_COBRA    = 11373,
        NPC_PARASITIC_SERPENT = 14884,
        NPC_WORLD_TRIGGER     = 12999
    };

    enum Events
    {
        EVENT_THRASH = 1,
        EVENT_HOLY_NOVA,
        EVENT_RENEW,
        EVENT_HOLY_WRATH,
        EVENT_HOLY_FIRE,
        EVENT_TOXIC_BOMBARDEMENT,
        EVENT_PARASITIC_POISON,
        EVENT_VENOM_SPIT,
        EVENT_CORPSE_EXPLOSION,
    };

    enum Phases
    {
        PHASE_TROLL = 1,
        PHASE_SNAKE = 2
    };

    constexpr float HOLY_NOVA_RANGE  = 15.0f;
    constexpr float WRATH_JUMP_RANGE = 10.0f;
    constexpr uint8 WRATH_JUMPS      = 4;
    constexpr float SPIT_RANGE       = 60.0f;
    constexpr float SPIT_ARC         = float(M_PI) / 2;
    constexpr float CORPSE_RANGE     = 80.0f;

    struct boss_venoxis_coa : public BossAI
    {
        boss_venoxis_coa(Creature* creature) : BossAI(creature, DATA_VENOXIS) { }

        void Reset() override
        {
            BossAI::Reset();
            me->RemoveAllAuras();
            _snake = false;
            _frenzied = false;
            _burst.clear();
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);

            events.SetPhase(PHASE_TROLL);
            events.ScheduleEvent(EVENT_THRASH, 8s);
            events.ScheduleEvent(EVENT_HOLY_NOVA, 7s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_RENEW, 16s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_HOLY_WRATH, 18s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_HOLY_FIRE, 22s, 0, PHASE_TROLL);
        }

        void JustDied(Unit* killer) override
        {
            BossAI::JustDied(killer);
            Talk(SAY_DEATH);
            me->RemoveAllAuras();
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);

            if (!_snake && me->HealthBelowPctDamaged(50, damage))
            {
                _snake = true;
                me->InterruptNonMeleeSpells(false);
                DoCastSelf(SPELL_ASPECT_OF_HETHISS, true);
                DoCastSelf(SPELL_POISONOUS_FANGS, true);
                Talk(SAY_TRANSFORM);
                DoResetThreatList();

                events.SetPhase(PHASE_SNAKE);
                events.ScheduleEvent(EVENT_TOXIC_BOMBARDEMENT, 1s, 0, PHASE_SNAKE);
                events.ScheduleEvent(EVENT_PARASITIC_POISON, 3s, 0, PHASE_SNAKE);
                events.ScheduleEvent(EVENT_VENOM_SPIT, 5s, 0, PHASE_SNAKE);
                events.ScheduleEvent(EVENT_CORPSE_EXPLOSION, 17s, 0, PHASE_SNAKE);
            }

            if (!_frenzied && me->HealthBelowPctDamaged(20, damage))
            {
                _frenzied = true;
                DoCastSelf(SPELL_FRENZY, true);
            }
        }

        // The casts are dummies; what they do happens when they finish.
        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            switch (spell->Id)
            {
                case SPELL_HOLY_NOVA:
                    HolyNova();
                    break;
                case SPELL_HOLY_WRATH:
                    HolyWrath();
                    break;
                case SPELL_HOLY_FIRE:
                    if (Unit* target = ObjectAccessor::GetUnit(*me, _target))
                    {
                        Hit(me, target, SPELL_HOLY_FIRE_HIT, Info(me, INFO_HOLY_FIRE, 0));
                        Hit(me, target, SPELL_HOLY_FIRE_DOT, Info(me, INFO_HOLY_FIRE, 1));
                    }
                    break;
                case SPELL_VENOM_SPIT:
                    for (Player* p : PlayersInFront(me, SPIT_RANGE, SPIT_ARC))
                    {
                        me->CastSpell(p, SPELL_VENOM_SPIT_HIT, true);
                        AddStack(me, p, SPELL_VIRULENT_POISON);
                    }
                    break;
                case SPELL_PARASITIC_POISON:
                    if (Unit* target = ObjectAccessor::GetUnit(*me, _target))
                        me->CastSpell(target, SPELL_PARASITIC_POISON_DOT, true);
                    break;
                case SPELL_CORPSE_EXPLOSION:
                    CorpseExplosion();
                    break;
                default:
                    break;
            }
        }

        void HolyNova()
        {
            for (Player* p : PlayersWithin(me, HOLY_NOVA_RANGE))
                me->CastSpell(p, SPELL_HOLY_NOVA_HIT, true);

            int32 heal = int32(me->CountPctFromMaxHealth(6));
            std::list<Creature*> allies;
            me->GetCreatureListWithEntryInGrid(allies, NPC_RAZZASHI_COBRA, HOLY_NOVA_RANGE);
            allies.push_back(me);
            for (Creature* ally : allies)
                if (ally->IsAlive())
                    me->CastCustomSpell(ally, SPELL_HOLY_NOVA_HEAL, &heal, nullptr, nullptr, true);
        }

        void HolyWrath()
        {
            Unit* first = ObjectAccessor::GetUnit(*me, _target);
            Player* current = first ? first->ToPlayer() : nullptr;
            if (!current)
                return;

            int32 const players = int32(Players(me, [](Player*) { return true; }).size());
            float const step = 1.0f + std::max(0, (Info(me, INFO_HOLY_WRATH, 1) - 1) - 2 * std::max(0, players - 10)) / 100.0f;
            float amount = float(Info(me, INFO_HOLY_WRATH, 0));

            std::vector<Player*> hit;
            for (uint8 i = 0; current && i <= WRATH_JUMPS; ++i)
            {
                Hit(me, current, SPELL_HOLY_WRATH_HIT, int32(amount));
                hit.push_back(current);
                amount *= step;
                current = NextInChain(me, current, WRATH_JUMP_RANGE, hit);
            }
        }

        // Every snake corpse nearby bursts once and leaves a pool of acid.
        void CorpseExplosion()
        {
            std::list<Creature*> corpses;
            me->GetCreatureListWithEntryInGrid(corpses, NPC_RAZZASHI_COBRA, CORPSE_RANGE);
            std::list<Creature*> serpents;
            me->GetCreatureListWithEntryInGrid(serpents, NPC_PARASITIC_SERPENT, CORPSE_RANGE);
            corpses.splice(corpses.end(), serpents);

            for (Creature* corpse : corpses)
            {
                if (corpse->IsAlive() || _burst.count(corpse->GetGUID()))
                    continue;
                _burst.insert(corpse->GetGUID());

                if (Creature* spot = me->SummonCreature(NPC_WORLD_TRIGGER, corpse->GetPosition(), TEMPSUMMON_MANUAL_DESPAWN))
                {
                    spot->SetFaction(me->GetFaction());
                    spot->CastSpell(spot, SPELL_ACID_BURST, true, nullptr, nullptr, me->GetGUID());
                    spot->CastSpell(spot, SPELL_ACID_POOL, true, nullptr, nullptr, me->GetGUID());
                }
                corpse->DespawnOrUnsummon(1s);
            }
        }

        void CastOnRandom(uint32 spell)
        {
            if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
            {
                _target = target->GetGUID();
                DoCast(target, spell);
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
                    case EVENT_THRASH:
                        DoCastSelf(SPELL_THRASH, true);
                        events.ScheduleEvent(EVENT_THRASH, 10s, 20s);
                        break;
                    case EVENT_HOLY_NOVA:
                        DoCastSelf(SPELL_HOLY_NOVA);
                        events.ScheduleEvent(EVENT_HOLY_NOVA, 18s, 0, PHASE_TROLL);
                        break;
                    case EVENT_RENEW:
                    {
                        int32 heal = int32(me->CountPctFromMaxHealth(2));
                        me->CastCustomSpell(me, SPELL_RENEW, &heal, nullptr, nullptr, false);
                        events.ScheduleEvent(EVENT_RENEW, 24s, 0, PHASE_TROLL);
                        break;
                    }
                    case EVENT_HOLY_WRATH:
                        if (Unit* tank = me->GetVictim())
                        {
                            _target = tank->GetGUID();
                            DoCast(tank, SPELL_HOLY_WRATH);
                        }
                        events.ScheduleEvent(EVENT_HOLY_WRATH, 15s, 0, PHASE_TROLL);
                        break;
                    case EVENT_HOLY_FIRE:
                        CastOnRandom(SPELL_HOLY_FIRE);
                        events.ScheduleEvent(EVENT_HOLY_FIRE, 10s, 0, PHASE_TROLL);
                        break;
                    case EVENT_TOXIC_BOMBARDEMENT:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                            me->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(), SPELL_TOXIC_BOMBARDEMENT, false);
                        events.ScheduleEvent(EVENT_TOXIC_BOMBARDEMENT, 15s, 0, PHASE_SNAKE);
                        break;
                    case EVENT_PARASITIC_POISON:
                        CastOnRandom(SPELL_PARASITIC_POISON);
                        events.ScheduleEvent(EVENT_PARASITIC_POISON, 15s, 0, PHASE_SNAKE);
                        break;
                    case EVENT_VENOM_SPIT:
                        DoCastVictim(SPELL_VENOM_SPIT);
                        events.ScheduleEvent(EVENT_VENOM_SPIT, 10s, 0, PHASE_SNAKE);
                        break;
                    case EVENT_CORPSE_EXPLOSION:
                        DoCastSelf(SPELL_CORPSE_EXPLOSION);
                        events.ScheduleEvent(EVENT_CORPSE_EXPLOSION, 40s, 0, PHASE_SNAKE);
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    private:
        bool _snake = false;
        bool _frenzied = false;
        ObjectGuid _target;
        GuidSet _burst;
    };

    // Parasitic Poison: removed by any means before it runs out, a Parasitic
    // Serpent breaks out of the target.
    class spell_venoxis_coa_parasitic_poison : public AuraScript
    {
        PrepareAuraScript(spell_venoxis_coa_parasitic_poison);

        void AfterRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE)
                return;
            Unit* target = GetTarget();
            Unit* caster = GetCaster();
            if (!target || !caster || !caster->IsAlive())
                return;
            if (Creature* boss = caster->ToCreature())
                if (Creature* serpent = boss->SummonCreature(NPC_PARASITIC_SERPENT, target->GetPosition(), TEMPSUMMON_CORPSE_TIMED_DESPAWN, 120000))
                    serpent->AI()->AttackStart(target);
        }

        void Register() override
        {
            AfterEffectRemove += AuraEffectRemoveFn(spell_venoxis_coa_parasitic_poison::AfterRemove, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL);
        }
    };
}

void AddCoaVenoxisScripts()
{
    RegisterZulGurubCreatureAI(boss_venoxis_coa);
    RegisterSpellScript(spell_venoxis_coa_parasitic_poison);
}
