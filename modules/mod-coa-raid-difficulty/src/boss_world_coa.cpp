/*
 * Azuregos and Lord Kazzak as Ascension ran them, rebuilt from combat logs.
 *
 * One kill of each is in the logs (Azuregos 16 minutes with 24 players, Kazzak
 * 11 minutes with 23). Kit, timers and targets below are measured; where the
 * logs show an effect but not the cast behind it, the effect is what is
 * scheduled.
 *
 * Azuregos
 *   Draconic Strike         every 13.2s   tank
 *   Draconic Cleave         every 16.9s   20-yard cone
 *   Fierce Draconic Strike  every 24.8s   tank
 *   Freezing Breath         every 20s     2s cast, six pulses in a 30-yard cone:
 *                                         frost damage and -15% speed per pulse;
 *                                         six stacks freeze the target solid
 *   Chill                   every 31s     the stock aura, kept by Ascension
 *   Blizzard                every 25s     2s cast at a player; 10 seconds of ice
 *                                         shards at that spot
 *   Reflection              every 62s     the stock spell reflection
 *   Ice Spikes              every 60s     six players: a 4s warning, then the
 *                                         spike, thrown into the air
 *   Mark of Frost           on death      whoever dies is marked; a marked player
 *                                         Azuregos hits again is frozen for 3 min.
 *                                         That is the one Prison of Frost in the
 *                                         log, not a health trigger.
 *
 * Lord Kazzak
 *   Thunderclap             every 9.9s    around him, nature damage and a slow
 *   Massive Cleave          every 8.2s    1s cast, 20-yard cone
 *   Mark of Kazzak          every 10.1s   a random player loses 250 mana a second
 *                                         for 60s; with none left they explode
 *   Void Bolt               every 10.6s   the tank
 *   Shadow Bolt Volley      every 5.1s
 *   Twisted Reflection      every 15.1s   a random player; his hits on them heal
 *                                         him, up to 50,000 a hit
 *   DOOM!                   every 46s     a random player explodes after 4s,
 *                                         2500 in 15 yards, throwing allies away
 *   Fierce Blow             every 8.7s    tank
 *   Capture Soul            on death      a dying player heals him for up to 75,000
 *
 * Not in the logs, therefore not here: Azuregos' Warp (it sits in his spell
 * block but never fired), Kazzak's berserk.
 *
 * Health: both kills ended at the same pool - 38.76 and 38.78 million with 24
 * and 23 players. Flex would have put them 4% apart; they are 0.04% apart. So
 * the pool is fixed by default, and coa_world_boss can switch a boss to health
 * per player counted around him on the pull instead.
 */

#include "Containers.h"
#include "CreatureScript.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

#include <algorithm>
#include <functional>
#include <set>
#include <unordered_map>
#include <vector>

namespace
{
    // ------------------------------------------------------- world boss health
    struct WorldBossHealth
    {
        uint32 health;      // fixed pool; used when perPlayer is 0
        uint32 perPlayer;   // > 0: this times the players around him on pull
        float radius;
        uint32 minPlayers;
        uint32 maxPlayers;
    };

    std::unordered_map<uint32, WorldBossHealth> g_worldHealth;

    void LoadWorldHealth()
    {
        g_worldHealth.clear();
        if (QueryResult result = WorldDatabase.Query(
                "SELECT entry, health, per_player, radius, min_players, max_players FROM coa_world_boss"))
        {
            do
            {
                Field* f = result->Fetch();
                g_worldHealth[f[0].Get<uint32>()] = { f[1].Get<uint32>(), f[2].Get<uint32>(), f[3].Get<float>(),
                                                      f[4].Get<uint32>(), f[5].Get<uint32>() };
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded health for {} world bosses", uint32(g_worldHealth.size()));
    }

    void ApplyWorldHealth(Creature* me)
    {
        auto it = g_worldHealth.find(me->GetEntry());
        if (it == g_worldHealth.end())
            return;
        WorldBossHealth const& w = it->second;

        uint32 health = w.health;
        if (w.perPlayer)
        {
            uint32 players = 0;
            me->GetMap()->DoForAllPlayers([&](Player* p)
            {
                if (!p->IsGameMaster() && me->IsWithinDistInMap(p, w.radius))
                    ++players;
            });
            health = w.perPlayer * std::clamp(players, w.minPlayers, w.maxPlayers);
        }
        if (!health)
            return;

        float const pct = me->GetMaxHealth() ? me->GetHealthPct() : 100.0f;
        me->SetCreateHealth(health);
        me->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
        me->UpdateMaxHealth();
        me->SetHealth(std::max<uint32>(1, uint32(me->GetMaxHealth() * pct / 100.0f)));
    }

    class coa_world_boss_loader : public WorldScript
    {
    public:
        coa_world_boss_loader() : WorldScript("coa_world_boss_loader") { }
        void OnAfterConfigLoad(bool /*reload*/) override { LoadWorldHealth(); }
    };

    // ---------------------------------------------------------------- helpers
    std::vector<Player*> PlayersNear(Creature* me, float range, std::function<bool(Player*)> const& accept = nullptr)
    {
        std::vector<Player*> out;
        me->GetMap()->DoForAllPlayers([&](Player* p)
        {
            if (p->IsAlive() && !p->IsGameMaster() && me->IsWithinDistInMap(p, range) && (!accept || accept(p)))
                out.push_back(p);
        });
        return out;
    }

    constexpr float CONE_ARC = float(M_PI) / 2;

    // A shared base: world bosses fight on a clock and keep a separate one for
    // pulses and delayed hits, so a cast bar never holds those up.
    struct world_boss_coa : public ScriptedAI
    {
        explicit world_boss_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            events.Reset();
            _clock.Reset();
            ApplyWorldHealth(me);
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            ApplyWorldHealth(me);
            Schedule();
        }

        virtual void Schedule() = 0;
        virtual void Execute(uint32 eventId) = 0;
        virtual void Tick(uint32 /*eventId*/) { }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            events.Update(diff);
            _clock.Update(diff);
            while (uint32 tick = _clock.ExecuteEvent())
                Tick(tick);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                Execute(eventId);
                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }
            DoMeleeAttackIfReady();
        }

        Unit* RandomNonTank()
        {
            if (Unit* u = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true, false))
                return u;
            return me->GetVictim();
        }

    protected:
        EventMap events;
        EventMap _clock;
    };

    // --------------------------------------------------------------- Azuregos
    enum AzuregosSpells
    {
        SPELL_DRACONIC_STRIKE       = 2119101,
        SPELL_FIERCE_DRACONIC_STRIKE= 2119102,
        SPELL_DRACONIC_CLEAVE       = 2119103,
        SPELL_FREEZING_BREATH_CAST  = 2119107,
        SPELL_FREEZING_BREATH_HIT   = 2119109,
        SPELL_FREEZING_BREATH_SLOW  = 2119110,
        SPELL_FROZEN_SOLID          = 2119111,
        SPELL_BLIZZARD_CAST         = 2119112,
        SPELL_BLIZZARD              = 2119114,
        SPELL_PRISON_OF_FROST       = 2119116,
        SPELL_MARK_OF_FROST         = 2119117,
        SPELL_ICE_SPIKES_WARNING    = 2119120,
        SPELL_ICE_SPIKES            = 2119121,
        SPELL_CHILL                 = 21098,
        SPELL_REFLECTION            = 22067,
    };

    enum AzuregosEvents
    {
        EV_STRIKE = 1, EV_CLEAVE, EV_FIERCE, EV_BREATH, EV_CHILL, EV_BLIZZARD, EV_REFLECTION, EV_ICE_SPIKES,
        TK_BREATH_PULSE, TK_BLIZZARD, TK_ICE_SPIKES,
    };

    struct boss_azuregos_coa : public world_boss_coa
    {
        explicit boss_azuregos_coa(Creature* creature) : world_boss_coa(creature) { }

        void Schedule() override
        {
            events.ScheduleEvent(EV_STRIKE, 600ms);
            events.ScheduleEvent(EV_CLEAVE, 8s);
            events.ScheduleEvent(EV_CHILL, 10s);
            events.ScheduleEvent(EV_FIERCE, 11600ms);
            events.ScheduleEvent(EV_BREATH, 15s);
            events.ScheduleEvent(EV_REFLECTION, 20s);
            events.ScheduleEvent(EV_BLIZZARD, 25s);
            events.ScheduleEvent(EV_ICE_SPIKES, 64s);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case EV_STRIKE:     DoCastVictim(SPELL_DRACONIC_STRIKE);        events.Repeat(13200ms); break;
                case EV_FIERCE:     DoCastVictim(SPELL_FIERCE_DRACONIC_STRIKE); events.Repeat(24800ms); break;
                case EV_CHILL:      DoCastAOE(SPELL_CHILL);                     events.Repeat(31s);     break;
                case EV_REFLECTION: DoCastSelf(SPELL_REFLECTION);               events.Repeat(62s);     break;
                case EV_BREATH:     DoCastVictim(SPELL_FREEZING_BREATH_CAST);   events.Repeat(20s);     break;
                case EV_CLEAVE:
                    for (Player* p : PlayersNear(me, 20.0f, [&](Player* x) { return me->isInFront(x, CONE_ARC); }))
                        me->CastSpell(p, SPELL_DRACONIC_CLEAVE, true);
                    events.Repeat(16900ms);
                    break;
                case EV_BLIZZARD:
                    if (Unit* target = RandomNonTank())
                    {
                        _blizzardSpot = target->GetPosition();
                        DoCast(target, SPELL_BLIZZARD_CAST);
                    }
                    events.Repeat(25s);
                    break;
                case EV_ICE_SPIKES:
                {
                    std::vector<Player*> pool = PlayersNear(me, 100.0f);
                    Acore::Containers::RandomResize(pool, 6);
                    _spikes.clear();
                    for (Player* p : pool)
                    {
                        _spikes.push_back(p->GetPosition());
                        me->CastSpell(p->GetPositionX(), p->GetPositionY(), p->GetPositionZ(), SPELL_ICE_SPIKES_WARNING, true);
                    }
                    _clock.ScheduleEvent(TK_ICE_SPIKES, 4s);
                    events.Repeat(60s);
                    break;
                }
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id == SPELL_FREEZING_BREATH_CAST)
            {
                _pulses = 6;
                _clock.ScheduleEvent(TK_BREATH_PULSE, 0ms);
            }
            else if (spell->Id == SPELL_BLIZZARD_CAST)
            {
                _blizzardSeconds = 10;
                _clock.ScheduleEvent(TK_BLIZZARD, 0ms);
            }
        }

        void Tick(uint32 tick) override
        {
            switch (tick)
            {
                case TK_BREATH_PULSE:
                {
                    uint32 const slow = sSpellMgr->GetSpellIdForDifficulty(SPELL_FREEZING_BREATH_SLOW, me);
                    for (Player* p : PlayersNear(me, 30.0f, [&](Player* x) { return me->isInFront(x, CONE_ARC); }))
                    {
                        me->CastSpell(p, SPELL_FREEZING_BREATH_HIT, true);
                        Aura* a = p->GetAura(slow);
                        uint8 const stacks = a ? a->GetStackAmount() + 1 : 1;
                        if (stacks >= 6)
                        {
                            p->RemoveAurasDueToSpell(slow);
                            me->CastSpell(p, SPELL_FROZEN_SOLID, true);
                        }
                        else if (a)
                        {
                            a->SetStackAmount(stacks);
                            a->RefreshDuration();
                        }
                        else
                            me->CastSpell(p, slow, true);
                    }
                    if (--_pulses)
                        _clock.ScheduleEvent(TK_BREATH_PULSE, 500ms);
                    break;
                }
                case TK_BLIZZARD:
                    me->CastSpell(_blizzardSpot.GetPositionX(), _blizzardSpot.GetPositionY(), _blizzardSpot.GetPositionZ(), SPELL_BLIZZARD, true);
                    if (--_blizzardSeconds)
                        _clock.ScheduleEvent(TK_BLIZZARD, 1s);
                    break;
                case TK_ICE_SPIKES:
                    for (Position const& pos : _spikes)
                        me->CastSpell(pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), SPELL_ICE_SPIKES, true);
                    break;
            }
        }

        // Mark of Frost: whoever dies is marked; hit again while marked, frozen.
        void KilledUnit(Unit* victim) override
        {
            if (victim->IsPlayer())
                victim->AddAura(SPELL_MARK_OF_FROST, victim);
        }

        void DamageDealt(Unit* victim, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            world_boss_coa::DamageDealt(victim, damage, type, school);
            if (damage && victim && victim->HasAura(SPELL_MARK_OF_FROST) && !victim->HasAura(SPELL_PRISON_OF_FROST))
                me->CastSpell(victim, SPELL_PRISON_OF_FROST, true);
        }

    private:
        uint8 _pulses = 0;
        uint8 _blizzardSeconds = 0;
        Position _blizzardSpot;
        std::vector<Position> _spikes;
    };

    // ----------------------------------------------------------------- Kazzak
    enum KazzakSpells
    {
        SPELL_MASSIVE_CLEAVE        = 2119201,
        SPELL_THUNDERCLAP           = 2119202,
        SPELL_MARK_OF_KAZZAK        = 2119203,
        SPELL_DOOM                  = 2119204,
        SPELL_DOOM_EXPLOSION        = 2119207,
        SPELL_TWISTED_REFLECTION    = 2119208,
        SPELL_TWISTED_HEAL          = 2119209,
        SPELL_CAPTURE_SOUL          = 2119210,
        SPELL_VOID_BOLT             = 21066,
        SPELL_SHADOW_BOLT_VOLLEY    = 21341,
        SPELL_FIERCE_BLOW           = 975011,
    };

    enum KazzakEvents
    {
        EK_THUNDERCLAP = 1, EK_CLEAVE, EK_MARK, EK_VOID_BOLT, EK_VOLLEY, EK_REFLECTION, EK_DOOM, EK_FIERCE,
        TK_SECOND, TK_DOOM,
    };

    constexpr int32 MARK_MANA_PER_SECOND = 250;
    constexpr int32 TWISTED_HEAL_CAP     = 50000;
    constexpr int32 CAPTURE_SOUL_CAP     = 75000;

    struct boss_kazzak_coa : public world_boss_coa
    {
        explicit boss_kazzak_coa(Creature* creature) : world_boss_coa(creature) { }

        void Schedule() override
        {
            events.ScheduleEvent(EK_THUNDERCLAP, 6s);
            events.ScheduleEvent(EK_CLEAVE, 7800ms);
            events.ScheduleEvent(EK_MARK, 8900ms);
            events.ScheduleEvent(EK_VOID_BOLT, 9900ms);
            events.ScheduleEvent(EK_DOOM, 10s);
            events.ScheduleEvent(EK_VOLLEY, 11500ms);
            events.ScheduleEvent(EK_REFLECTION, 12s);
            events.ScheduleEvent(EK_FIERCE, 13s);
            _clock.ScheduleEvent(TK_SECOND, 1s);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case EK_THUNDERCLAP: DoCastSelf(SPELL_THUNDERCLAP);           events.Repeat(9900ms);  break;
                case EK_CLEAVE:      DoCastVictim(SPELL_MASSIVE_CLEAVE);      events.Repeat(8200ms);  break;
                case EK_VOID_BOLT:   DoCastVictim(SPELL_VOID_BOLT);           events.Repeat(10600ms); break;
                case EK_VOLLEY:      DoCastAOE(SPELL_SHADOW_BOLT_VOLLEY);     events.Repeat(5100ms);  break;
                case EK_FIERCE:      DoCastVictim(SPELL_FIERCE_BLOW);         events.Repeat(8700ms);  break;
                case EK_MARK:
                    if (Unit* t = RandomNonTank())
                    {
                        me->CastSpell(t, SPELL_MARK_OF_KAZZAK, true);
                        _marked.insert(t->GetGUID());
                    }
                    events.Repeat(10100ms);
                    break;
                case EK_REFLECTION:
                    if (Unit* t = RandomNonTank())
                        me->CastSpell(t, SPELL_TWISTED_REFLECTION, true);
                    events.Repeat(15100ms);
                    break;
                case EK_DOOM:
                    if (Unit* t = RandomNonTank())
                    {
                        me->CastSpell(t, SPELL_DOOM, true);
                        _doom = t->GetGUID();
                        _clock.ScheduleEvent(TK_DOOM, 4s);
                    }
                    events.Repeat(46s);
                    break;
            }
        }

        void Tick(uint32 tick) override
        {
            if (tick == TK_DOOM)
            {
                if (Unit* t = ObjectAccessor::GetUnit(*me, _doom))
                    me->CastSpell(t, SPELL_DOOM_EXPLOSION, true);
                _doom.Clear();
                return;
            }

            if (tick != TK_SECOND)
                return;

            // Mark of Kazzak: 250 mana a second; with none left, a shadow bomb.
            for (auto it = _marked.begin(); it != _marked.end();)
            {
                Player* p = ObjectAccessor::GetPlayer(*me, *it);
                if (!p || !p->IsAlive() || !p->HasAura(SPELL_MARK_OF_KAZZAK))
                {
                    it = _marked.erase(it);
                    continue;
                }
                if (p->getPowerType() == POWER_MANA && p->GetPower(POWER_MANA) >= uint32(MARK_MANA_PER_SECOND))
                {
                    p->ModifyPower(POWER_MANA, -MARK_MANA_PER_SECOND);
                    ++it;
                    continue;
                }
                p->RemoveAurasDueToSpell(SPELL_MARK_OF_KAZZAK);
                me->CastSpell(p, SPELL_DOOM_EXPLOSION, true);
                it = _marked.erase(it);
            }
            _clock.ScheduleEvent(TK_SECOND, 1s);
        }

        // Twisted Reflection: his hits on the marked player heal him.
        void DamageDealt(Unit* victim, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            world_boss_coa::DamageDealt(victim, damage, type, school);
            if (damage && victim && victim->HasAura(SPELL_TWISTED_REFLECTION))
            {
                int32 heal = std::min<int32>(int32(damage), TWISTED_HEAL_CAP);
                me->CastCustomSpell(me, SPELL_TWISTED_HEAL, &heal, nullptr, nullptr, true);
            }
        }

        // Capture Soul: every player he kills heals him.
        void KilledUnit(Unit* victim) override
        {
            if (!victim->IsPlayer())
                return;
            int32 heal = std::min<int32>(int32(victim->GetMaxHealth()), CAPTURE_SOUL_CAP);
            me->CastCustomSpell(me, SPELL_CAPTURE_SOUL, &heal, nullptr, nullptr, true);
        }

    private:
        std::set<ObjectGuid> _marked;
        ObjectGuid _doom;
    };

    class boss_azuregos_coa_script : public CreatureScript
    {
    public:
        boss_azuregos_coa_script() : CreatureScript("boss_azuregos_coa") { }
        CreatureAI* GetAI(Creature* creature) const override { return new boss_azuregos_coa(creature); }
    };

    class boss_kazzak_coa_script : public CreatureScript
    {
    public:
        boss_kazzak_coa_script() : CreatureScript("boss_kazzak_coa") { }
        CreatureAI* GetAI(Creature* creature) const override { return new boss_kazzak_coa(creature); }
    };
}

// The emerald dragons share the world boss health table.
void CoaApplyWorldHealth(Creature* creature)
{
    ApplyWorldHealth(creature);
}

void AddCoaWorldBossScripts()
{
    new coa_world_boss_loader();
    new boss_azuregos_coa_script();
    new boss_kazzak_coa_script();
}
