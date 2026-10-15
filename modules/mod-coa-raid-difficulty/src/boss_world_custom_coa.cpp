/*
 * Ascension's own world bosses: Setis, Korrim Snowgrave and The Will of
 * Soggoth, each in the boss map Ascension built for it (Map.dbc 880, 889, 883).
 *
 * All three are in one log (24.08.2026), each killed twice. The second kill of
 * each hit harder and had more health with the same raid, so the log holds two
 * levels rather than flex: the lower one runs on the 10/25 normal difficulties,
 * the higher one on the heroic ones. Health and a damage factor per level come
 * from coa_world_boss_level; the damage factor is the log's hits over the base
 * values of the spells Ascension cast (the same ids on both kills).
 *
 * Setis (the log shows a kit between his old spells and his new block; the new
 * block's Seeking Shadow Bolts, Prismatic Barrier, split Meteor and Massive
 * Thunder Stomp never fired and are left out)
 *   Plague              every 5.1s    a random player
 *   Fierce Blow         every 8.8s    tank
 *   Shadow Storm        every 13.6s   shadow bolts at everyone 25-45 yards out
 *   War Stomp           every 32s     around him, knocked back
 *   Meteor              every 32s     4s cast at a player, fire on the ground
 *   Call Lightning      every 35.1s   4s cast, then a strike under every player
 *                                     that electrifies the ground for 20s
 *   Frenzy              at 30%
 *   Armageddon          at 3%         15s cast, +150% damage taken while he
 *                                     casts; if it finishes, the raid dies
 *
 * Korrim Snowgrave (a 62.1-second rotation, every step measured)
 *   Frozen Club         passive       hits stack Frostbite
 *   Massive Stomp       0s            2s cast: the tank, then everyone, less
 *                                     further out; icicles fall 5s later
 *   Hail                10s, 30s, 55s 1s cast at a player: a cone of ice shards
 *   Winter's Grasp      20s           a ring of ice spikes grows out from him
 *   Steal Warmth        40s           isolated players gain Chilled to the
 *                                     Bones each second, huddled ones lose it;
 *                                     at 10 stacks, Frozen Solid
 *   Shock Frost         52s           doubles the stacks, then frost damage
 *                                     that grows with them
 *   Fierce Blow         every 9s      tank
 *
 * The Will of Soggoth
 *   Void Beam           every 2s      a random player
 *   Waking Tear         every 22.1s   3s cast: a tear at a player for 20s
 *   Waking Nightmare    every 33.1s   six Psychophages rise around a player
 *   Visions of Ny'alotha every 45s    4s cast: everyone, then after 6s a void
 *                                     explosion under each of them
 *   Fierce Blow         every 7.8s    tank
 *
 * Atal'zul, the Soulreaver, with Zul'rogg (map 890; two kills in the log of
 * 25.08.2026, same spell damage on both, see the level table for health)
 *   Spectral Bolt       every 1.5s    his tank, stacking shadow damage taken
 *   Spectral Volley     every 12s     3s cast, everyone
 *   Land of the Dead    every 61.4s   six seconds: a Damned Wight a second at
 *                                     the raid, a choking cloud every other
 *   Spectral Veil       at 80/60/40/20%  a channel of up to 100s: shadow damage
 *                                     to everyone each second, growing, and a
 *                                     Restless Spirit that bombs where it lands.
 *                                     One Soul Vessel wakes; its death breaks
 *                                     the veil and gives the raid Soul Release.
 *   Zul'rogg            Fierce Blow every 7.6s, Titanic Crush every 10.8s,
 *                       Consume Life every 8s; cannot die while Atal'zul lives
 *
 * Trut-K'hahn has no log and no map. His kit is his spell block; every timer
 * is designed: Fierce Blow 8s, Turkey Rush 20s, Feather Storm 30s, Flap Flap
 * Flap and Dive Bomb 40s, Call the Flock 60s.
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
#include "TemporarySummon.h"
#include "zg_coa_common.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <map>
#include <unordered_map>
#include <vector>

using namespace coa_zg;

namespace
{
    // ------------------------------------------------------------- the levels
    struct Level
    {
        uint32 health;
        float damage;
    };

    // entry -> difficulty -> level
    std::unordered_map<uint32, std::map<uint8, Level>> g_levels;

    void LoadLevels()
    {
        g_levels.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT entry, difficulty, health, damage_pct FROM coa_world_boss_level"))
        {
            do
            {
                Field* f = result->Fetch();
                g_levels[f[0].Get<uint32>()][f[1].Get<uint8>()] = { f[2].Get<uint32>(), f[3].Get<float>() / 100.0f };
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded levels for {} custom world boss creatures", uint32(g_levels.size()));
    }

    // The level for this creature's difficulty, or the highest one below it.
    Level const* LevelOf(Creature const* me)
    {
        auto it = g_levels.find(me->GetEntry());
        if (it == g_levels.end() || it->second.empty())
            return nullptr;
        uint8 const diff = uint8(me->GetMap()->GetDifficulty());
        auto lv = it->second.upper_bound(diff);
        if (lv == it->second.begin())
            return &lv->second;
        return &std::prev(lv)->second;
    }

    void ApplyLevelHealth(Creature* me)
    {
        Level const* lv = LevelOf(me);
        if (!lv || !lv->health)
            return;
        me->SetCreateHealth(lv->health);
        me->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(lv->health));
        me->UpdateMaxHealth();
        me->SetFullHealth();
    }

    class coa_world_boss_level_loader : public WorldScript
    {
    public:
        coa_world_boss_level_loader() : WorldScript("coa_world_boss_level_loader") { }
        void OnAfterConfigLoad(bool /*reload*/) override { LoadLevels(); }
    };

    constexpr uint32 SPELL_FIERCE_BLOW = 975011;

    // A clock for the rotation and one for pulses, as for Azuregos and Kazzak,
    // plus the level: health on reset, damage on every hit.
    struct custom_world_boss_coa : public ScriptedAI
    {
        explicit custom_world_boss_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            events.Reset();
            _clock.Reset();
            ApplyLevelHealth(me);
            _damage = LevelOf(me) ? LevelOf(me)->damage : 1.0f;
        }

        void JustEngagedWith(Unit* /*who*/) override { Schedule(); }

        virtual void Schedule() = 0;
        virtual void Execute(uint32 eventId) = 0;
        virtual void Tick(uint32 /*tick*/) { }

        void DamageDealt(Unit* victim, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            ScriptedAI::DamageDealt(victim, damage, type, school);
            damage = uint32(damage * _damage);
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            _clock.Update(diff);
            while (uint32 tick = _clock.ExecuteEvent())
                Tick(tick);

            events.Update(diff);
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

        Unit* RandomPlayer(bool notTank = true)
        {
            if (Unit* u = SelectTarget(SelectTargetMethod::Random, notTank ? 1 : 0, 100.0f, true))
                return u;
            return me->GetVictim();
        }

        void CastAt(Position const& pos, uint32 spell)
        {
            me->CastSpell(pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), spell, true);
        }

    protected:
        EventMap events;
        EventMap _clock;
        float _damage = 1.0f;
    };

    // ------------------------------------------------------------------ Setis
    enum SetisSpells
    {
        SPELL_PLAGUE            = 1002115,
        SPELL_SHADOW_STORM      = 1002116,
        SPELL_WAR_STOMP         = 1002213,
        SPELL_FIRE_REFLECT      = 1002118,
        SPELL_FRENZY            = 1002120,
        SPELL_METEOR            = 83360,
        SPELL_CALL_LIGHTNING    = 2119052,
        SPELL_LIGHTNING_STRIKE  = 2119054,
        SPELL_ARMAGEDDON        = 2119050,
        SPELL_ARMAGEDDON_BLAST  = 2119051,
    };

    enum SetisEvents { ES_PLAGUE = 1, ES_FIERCE, ES_STORM, ES_STOMP, ES_METEOR, ES_LIGHTNING };

    struct boss_setis_coa : public custom_world_boss_coa
    {
        explicit boss_setis_coa(Creature* creature) : custom_world_boss_coa(creature) { }

        void Reset() override
        {
            custom_world_boss_coa::Reset();
            _frenzy = _armageddon = false;
            // Reflected Firebolts in the log: fire (and arcane) comes back.
            DoCastSelf(SPELL_FIRE_REFLECT, true);
        }

        void Schedule() override
        {
            events.ScheduleEvent(ES_PLAGUE, 3800ms);
            events.ScheduleEvent(ES_FIERCE, 6200ms);
            events.ScheduleEvent(ES_STORM, 12s);
            events.ScheduleEvent(ES_STOMP, 16300ms);
            events.ScheduleEvent(ES_METEOR, 26400ms);
            events.ScheduleEvent(ES_LIGHTNING, 30500ms);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case ES_PLAGUE:
                    if (Unit* t = RandomPlayer())
                        me->CastSpell(t, SPELL_PLAGUE, true);
                    events.Repeat(5100ms);
                    break;
                case ES_FIERCE:    DoCastVictim(SPELL_FIERCE_BLOW);  events.Repeat(8800ms);  break;
                case ES_STORM:     DoCastSelf(SPELL_SHADOW_STORM);   events.Repeat(13600ms); break;
                case ES_STOMP:     DoCastSelf(SPELL_WAR_STOMP);      events.Repeat(32s);     break;
                case ES_METEOR:
                    if (Unit* t = RandomPlayer())
                        DoCast(t, SPELL_METEOR);
                    events.Repeat(32s);
                    break;
                case ES_LIGHTNING:
                    if (Unit* t = RandomPlayer())
                        DoCast(t, SPELL_CALL_LIGHTNING);
                    events.Repeat(35100ms);
                    break;
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id == SPELL_CALL_LIGHTNING)
            {
                for (Player* p : PlayersWithin(me, 100.0f))
                    CastAt(p->GetPosition(), SPELL_LIGHTNING_STRIKE);
            }
            else if (spell->Id == SPELL_ARMAGEDDON)
                DoCastAOE(SPELL_ARMAGEDDON_BLAST, true);
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            custom_world_boss_coa::DamageTaken(attacker, damage, type, school);
            if (!_frenzy && me->HealthBelowPctDamaged(30, damage))
            {
                _frenzy = true;
                DoCastSelf(SPELL_FRENZY, true);
            }
            if (!_armageddon && me->HealthBelowPctDamaged(3, damage))
            {
                _armageddon = true;
                me->InterruptNonMeleeSpells(false);
                events.Reset();
                DoCastSelf(SPELL_ARMAGEDDON);
            }
        }

    private:
        bool _frenzy = false;
        bool _armageddon = false;
    };

    // -------------------------------------------------------- Korrim Snowgrave
    enum SnowgraveSpells
    {
        SPELL_FROZEN_CLUB       = 2119751,
        SPELL_MASSIVE_STOMP     = 2119757,
        SPELL_STOMP_HIT         = 2119758,
        SPELL_STOMP_DAMAGE_INFO = 2119759,
        SPELL_STOMP_DAMAGE      = 2119763,
        SPELL_STOMP_KNOCKBACK   = 2119764,
        SPELL_WATER_SPIKE       = 2119765,
        SPELL_HAIL              = 2119769,
        SPELL_HAIL_SHARD        = 2119773,
        SPELL_STEAL_WARMTH      = 2119777,
        SPELL_CHILLED           = 2119778,
        SPELL_SHOCK_FROST       = 2119779,
        SPELL_SHOCK_FROST_HIT   = 2119780,
        SPELL_FROZEN_SOLID      = 2119784,
        SPELL_WINTERS_GRASP     = 2119787,
        SPELL_ICE_SPIKE_WARNING = 2119789,
        SPELL_ICE_SPIKE         = 2119790,
        SPELL_CAVE_IN_WARNING   = 2119794,
    };

    enum SnowgraveEvents
    {
        EW_STOMP = 1, EW_HAIL, EW_GRASP, EW_WARMTH, EW_SHOCK, EW_FIERCE,
        TW_ICICLE_WARN, TW_ICICLE, TW_HAIL, TW_RING, TW_RING_HIT, TW_WARMTH,
    };

    constexpr uint8 CHILL_FROZEN      = 10;
    constexpr float HUDDLE_RANGE      = 2.0f;   // Body Heat's radius
    constexpr uint8 HAIL_VOLLEYS      = 4;
    constexpr uint8 GRASP_RINGS       = 8;

    struct boss_snowgrave_coa : public custom_world_boss_coa
    {
        explicit boss_snowgrave_coa(Creature* creature) : custom_world_boss_coa(creature) { }

        void Reset() override
        {
            custom_world_boss_coa::Reset();
            DoCastSelf(SPELL_FROZEN_CLUB, true);
            _stomps = 0;
        }

        void Schedule() override
        {
            events.ScheduleEvent(EW_STOMP, 4200ms);
            events.ScheduleEvent(EW_HAIL, 14300ms);
            events.ScheduleEvent(EW_FIERCE, 20300ms);
            events.ScheduleEvent(EW_GRASP, 24300ms);
            events.ScheduleEvent(EW_WARMTH, 44300ms);
            events.ScheduleEvent(EW_SHOCK, 56300ms);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case EW_STOMP:  DoCastVictim(SPELL_MASSIVE_STOMP);  events.Repeat(62100ms); break;
                case EW_GRASP:  DoCastSelf(SPELL_WINTERS_GRASP);    events.Repeat(62100ms); break;
                case EW_WARMTH: DoCastSelf(SPELL_STEAL_WARMTH);     events.Repeat(62100ms); break;
                case EW_SHOCK:  DoCastSelf(SPELL_SHOCK_FROST);      events.Repeat(62100ms); break;
                case EW_FIERCE: DoCastVictim(SPELL_FIERCE_BLOW);    events.Repeat(9s);      break;
                case EW_HAIL:
                    if (Unit* t = RandomPlayer())
                    {
                        _hailTarget = t->GetGUID();
                        DoCast(t, SPELL_HAIL);
                    }
                    // Three hails a rotation: 20.1s, 24.6s and 17.4s apart.
                    events.Repeat(std::array<Milliseconds, 3>{ 20100ms, 24600ms, 17400ms }[_hails++ % 3]);
                    break;
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            switch (spell->Id)
            {
                case SPELL_MASSIVE_STOMP:
                {
                    if (Unit* tank = me->GetVictim())
                        me->CastSpell(tank, SPELL_STOMP_HIT, true);
                    int32 const base = Info(me, SPELL_STOMP_DAMAGE_INFO);
                    for (Player* p : PlayersWithin(me, 100.0f))
                    {
                        // Less further out: full next to him, a fifth at 40 yards and beyond.
                        float const falloff = std::clamp(1.0f - me->GetDistance(p) / 50.0f, 0.2f, 1.0f);
                        Hit(me, p, SPELL_STOMP_DAMAGE, int32(base * falloff) - 1);
                        me->CastSpell(p, SPELL_STOMP_KNOCKBACK, true);
                    }
                    ++_stomps;
                    _clock.ScheduleEvent(TW_ICICLE_WARN, 1s);
                    break;
                }
                case SPELL_HAIL:
                    _hailVolleys = HAIL_VOLLEYS;
                    _clock.ScheduleEvent(TW_HAIL, 500ms);
                    break;
                case SPELL_WINTERS_GRASP:
                    _ring = _ringHit = 0;
                    _clock.ScheduleEvent(TW_RING, 600ms);
                    break;
                case SPELL_STEAL_WARMTH:
                    _warmthSeconds = 15;
                    _clock.ScheduleEvent(TW_WARMTH, 0ms);
                    break;
                case SPELL_SHOCK_FROST:
                {
                    int32 const base = Info(me, SPELL_SHOCK_FROST_HIT);
                    for (Player* p : PlayersWithin(me, 100.0f))
                    {
                        uint8 stacks = 0;
                        if (Aura* a = p->GetAura(SPELL_CHILLED))
                        {
                            stacks = uint8(std::min<uint32>(a->GetStackAmount() * 2u, CHILL_FROZEN));
                            if (stacks >= CHILL_FROZEN)
                            {
                                p->RemoveAurasDueToSpell(SPELL_CHILLED);
                                me->CastSpell(p, SPELL_FROZEN_SOLID, true);
                            }
                            else
                                a->SetStackAmount(stacks);
                        }
                        Hit(me, p, SPELL_SHOCK_FROST_HIT, int32(base * (1.0f + 0.1f * stacks)) - 1);
                    }
                    break;
                }
            }
        }

        void Tick(uint32 tick) override
        {
            switch (tick)
            {
                case TW_ICICLE_WARN:
                {
                    // Three icicles after the first stomp, three more after each one after.
                    std::vector<Player*> pool = PlayersWithin(me, 100.0f);
                    Acore::Containers::RandomResize(pool, std::min<uint32>(3u * _stomps, 15u));
                    _icicles.clear();
                    for (Player* p : pool)
                    {
                        _icicles.push_back(p->GetPosition());
                        CastAt(p->GetPosition(), SPELL_CAVE_IN_WARNING);
                    }
                    _clock.ScheduleEvent(TW_ICICLE, 4s);
                    break;
                }
                case TW_ICICLE:
                    for (Position const& pos : _icicles)
                        CastAt(pos, SPELL_WATER_SPIKE);
                    break;
                case TW_HAIL:
                    if (Unit* t = ObjectAccessor::GetUnit(*me, _hailTarget))
                    {
                        float const toward = me->GetAngle(t);
                        for (Player* p : PlayersWithin(me, 40.0f))
                        {
                            float const off = Position::NormalizeOrientation(me->GetAngle(p) - toward);
                            if (off < float(M_PI) / 8 || off > 2 * float(M_PI) - float(M_PI) / 8)
                                me->CastSpell(p, SPELL_HAIL_SHARD, true);
                        }
                    }
                    if (--_hailVolleys)
                        _clock.ScheduleEvent(TW_HAIL, 750ms);
                    break;
                case TW_RING:
                {
                    // A ring every 1.5s, six yards further out, a spike every seven yards on it.
                    float const radius = 6.0f * (_ring + 1);
                    uint32 const spikes = std::max<uint32>(6, uint32(2 * float(M_PI) * radius / 7.0f));
                    std::vector<Position>& ring = _ringSpikes[_ring % 2];
                    ring.clear();
                    for (uint32 i = 0; i < spikes; ++i)
                    {
                        float const a = 2 * float(M_PI) * i / spikes;
                        Position pos = me->GetPosition();
                        pos.m_positionX += radius * std::cos(a);
                        pos.m_positionY += radius * std::sin(a);
                        pos.m_positionZ = me->GetMap()->GetHeight(me->GetPhaseMask(), pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ() + 5.0f);
                        ring.push_back(pos);
                        CastAt(pos, SPELL_ICE_SPIKE_WARNING);
                    }
                    _clock.ScheduleEvent(TW_RING_HIT, 2500ms);
                    if (++_ring < GRASP_RINGS)
                        _clock.ScheduleEvent(TW_RING, 1500ms);
                    break;
                }
                case TW_RING_HIT:
                    for (Position const& pos : _ringSpikes[_ringHit++ % 2])
                        CastAt(pos, SPELL_ICE_SPIKE);
                    break;
                case TW_WARMTH:
                    // Isolated players gain a stack each second, huddled ones lose one.
                    for (Player* p : PlayersWithin(me, 100.0f))
                    {
                        bool const huddled = !Players(me, [&](Player* x) { return x != p && p->IsWithinDistInMap(x, HUDDLE_RANGE); }).empty();
                        Aura* a = p->GetAura(SPELL_CHILLED);
                        if (huddled)
                        {
                            if (a)
                                a->ModStackAmount(-1);
                            continue;
                        }
                        AddStack(me, p, SPELL_CHILLED, CHILL_FROZEN);
                        a = p->GetAura(SPELL_CHILLED);
                        if (a && a->GetStackAmount() >= CHILL_FROZEN)
                        {
                            p->RemoveAurasDueToSpell(SPELL_CHILLED);
                            me->CastSpell(p, SPELL_FROZEN_SOLID, true);
                        }
                    }
                    if (--_warmthSeconds)
                        _clock.ScheduleEvent(TW_WARMTH, 1s);
                    break;
            }
        }

    private:
        uint32 _stomps = 0;
        uint32 _hails = 0;
        uint8 _hailVolleys = 0;
        uint8 _ring = 0;
        uint8 _ringHit = 0;
        uint8 _warmthSeconds = 0;
        ObjectGuid _hailTarget;
        std::vector<Position> _icicles;
        std::vector<Position> _ringSpikes[2];
    };

    // -------------------------------------------------------- Will of Soggoth
    enum SoggothSpells
    {
        SPELL_VOID_BEAM         = 254479,
        SPELL_VISIONS           = 2119310,
        SPELL_VISIONS_MARK      = 2119312,
        SPELL_VISIONS_HIT       = 2119313,
        SPELL_VOID_REND         = 2119314,
        SPELL_WAKING_TEAR       = 2119315,
        SPELL_TEAR_ZONE         = 2119317,
        SPELL_TEAR_HIT          = 2119319,
        SPELL_WAKING_NIGHTMARE  = 2119320,
        NPC_PSYCHOPHAGE         = 454004,
    };

    enum SoggothEvents
    {
        EG_BEAM = 1, EG_TEAR, EG_FIERCE, EG_NIGHTMARE, EG_VISIONS,
        TG_TEAR_SECOND, TG_NIGHTMARE, TG_REND,
    };

    constexpr float TEAR_RADIUS = 5.0f;
    constexpr uint32 TEAR_SECONDS = 20;

    struct boss_soggoth_coa : public custom_world_boss_coa
    {
        explicit boss_soggoth_coa(Creature* creature) : custom_world_boss_coa(creature), _summons(creature) { }

        void Reset() override
        {
            custom_world_boss_coa::Reset();
            _summons.DespawnAll();
            _tears.clear();
        }

        void JustDied(Unit* /*killer*/) override { _summons.DespawnAll(); }
        void JustSummoned(Creature* summon) override
        {
            _summons.Summon(summon);
            if (Unit* t = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                summon->AI()->AttackStart(t);
        }

        void Schedule() override
        {
            events.ScheduleEvent(EG_BEAM, 5s);
            events.ScheduleEvent(EG_TEAR, 6s);
            events.ScheduleEvent(EG_FIERCE, 10500ms);
            events.ScheduleEvent(EG_NIGHTMARE, 13200ms);
            events.ScheduleEvent(EG_VISIONS, 22100ms);
            _clock.ScheduleEvent(TG_TEAR_SECOND, 1s);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case EG_BEAM:
                    if (Unit* t = RandomPlayer(false))
                        me->CastSpell(t, SPELL_VOID_BEAM, true);
                    events.Repeat(2s);
                    break;
                case EG_FIERCE:  DoCastVictim(SPELL_FIERCE_BLOW); events.Repeat(7800ms); break;
                case EG_VISIONS: DoCastAOE(SPELL_VISIONS);        events.Repeat(45s);    break;
                case EG_TEAR:
                    if (Unit* t = RandomPlayer())
                    {
                        _tearSpot = t->GetPosition();
                        DoCast(t, SPELL_WAKING_TEAR);
                    }
                    events.Repeat(22100ms);
                    break;
                case EG_NIGHTMARE:
                    if (Unit* t = RandomPlayer())
                    {
                        me->CastSpell(t, SPELL_WAKING_NIGHTMARE, true);
                        _nightmare = t->GetPosition();
                        _phages = 6;
                        _clock.ScheduleEvent(TG_NIGHTMARE, 500ms);
                    }
                    events.Repeat(33100ms);
                    break;
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id == SPELL_WAKING_TEAR)
            {
                CastAt(_tearSpot, SPELL_TEAR_ZONE);
                _tears.push_back({ _tearSpot, TEAR_SECONDS });
            }
            else if (spell->Id == SPELL_VISIONS)
            {
                for (Player* p : PlayersWithin(me, 200.0f))
                {
                    me->CastSpell(p, SPELL_VISIONS_HIT, true);
                    me->CastSpell(p, SPELL_VISIONS_MARK, true);
                }
                _clock.ScheduleEvent(TG_REND, 6s);
            }
        }

        void Tick(uint32 tick) override
        {
            switch (tick)
            {
                case TG_TEAR_SECOND:
                    for (auto it = _tears.begin(); it != _tears.end();)
                    {
                        for (Player* p : Players(me, [&](Player* x) { return x->IsWithinDist3d(&it->first, TEAR_RADIUS); }))
                            me->CastSpell(p, SPELL_TEAR_HIT, true);
                        it = --it->second ? std::next(it) : _tears.erase(it);
                    }
                    _clock.ScheduleEvent(TG_TEAR_SECOND, 1s);
                    break;
                case TG_NIGHTMARE:
                {
                    Position pos = _nightmare;
                    pos.m_positionX += frand(-6.0f, 6.0f);
                    pos.m_positionY += frand(-6.0f, 6.0f);
                    pos.m_positionZ = me->GetMap()->GetHeight(me->GetPhaseMask(), pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ() + 5.0f);
                    me->SummonCreature(NPC_PSYCHOPHAGE, pos, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 10000);
                    if (--_phages)
                        _clock.ScheduleEvent(TG_NIGHTMARE, 500ms);
                    break;
                }
                case TG_REND:
                    for (Player* p : PlayersWithin(me, 200.0f))
                        if (p->HasAura(SPELL_VISIONS_MARK))
                            me->CastSpell(p, SPELL_VOID_REND, true);
                    break;
            }
        }

    private:
        SummonList _summons;
        Position _tearSpot;
        Position _nightmare;
        uint8 _phages = 0;
        std::vector<std::pair<Position, uint32>> _tears;
    };

    // Psychophages: melee and Fierce Blow, and the level's health and damage.
    struct npc_psychophage_coa : public ScriptedAI
    {
        explicit npc_psychophage_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            ApplyLevelHealth(me);
            _damage = LevelOf(me) ? LevelOf(me)->damage : 1.0f;
            _fierce = 8s;
        }

        void DamageDealt(Unit* victim, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            ScriptedAI::DamageDealt(victim, damage, type, school);
            damage = uint32(damage * _damage);
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;
            _fierce -= Milliseconds(diff);
            if (_fierce <= 0ms)
            {
                DoCastVictim(SPELL_FIERCE_BLOW);
                _fierce = 8s;
            }
            DoMeleeAttackIfReady();
        }

    private:
        float _damage = 1.0f;
        Milliseconds _fierce = 8s;
    };

    // --------------------------------------------------------------- Atal'Zul
    enum AtalzulSpells
    {
        SPELL_SPECTRAL_BOLT     = 2119801,
        SPELL_SPECTRAL_BOLT_HIT = 2119802,
        SPELL_LAND_OF_THE_DEAD  = 2119806,
        SPELL_RAISE_DEAD        = 2119807,
        SPELL_CHOKING_CLOUD     = 2119810,
        SPELL_SPECTRAL_VEIL     = 2119816,
        SPELL_VEIL_TRIGGER      = 2119817,
        SPELL_SPECTRAL_BOMB     = 2119819,
        SPELL_SPECTRAL_BOMB_HIT = 2119820,
        SPELL_HAND_OF_SOULREAVER= 2119825,
        SPELL_TITANIC_CRUSH     = 2119826,
        SPELL_TITANIC_CRUSH_HIT = 2119828,
        SPELL_TRAUMA            = 2119830,
        SPELL_ENDLESS_HUNGER    = 2119831,
        SPELL_CONSUME_LIFE      = 2119832,
        SPELL_CONSUME_LIFE_HEAL = 2119836,
        SPELL_CONSUME_LIFE_AP   = 2119837,
        SPELL_SOUL_RELEASE      = 2119839,
        SPELL_SOUL_RELEASE_HIT  = 2119840,
        SPELL_SOUL_VESSEL       = 2119844,
        SPELL_SOUL_BIND         = 2119845,
        SPELL_SOUL_LINK         = 2119847,
        SPELL_SPECTRAL_VOLLEY   = 2119848,
        SPELL_VEIL_PULSE        = 2119853,
        SPELL_VEIL_POWER        = 2119857,

        NPC_ATALZUL             = 67532,
        NPC_ZULROGG             = 67533,
        NPC_DAMNED_WIGHT        = 67534,
        NPC_RESTLESS_SPIRIT     = 67535,
        NPC_SOUL_VESSEL         = 67536,
    };

    enum AtalzulEvents { EA_BOLT = 1, EA_VOLLEY, EA_LAND };

    // Casts the Spectral Bomb where it appears and is gone 2s later; killing it
    // first stops the bomb.
    struct npc_restless_spirit_coa : public ScriptedAI
    {
        explicit npc_restless_spirit_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            ApplyLevelHealth(me);
            me->SetReactState(REACT_PASSIVE);
        }

        void IsSummonedBy(WorldObject* /*summoner*/) override { DoCastSelf(SPELL_SPECTRAL_BOMB); }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_SPECTRAL_BOMB)
                return;
            Unit* caster = me;
            if (TempSummon* s = me->ToTempSummon())
                if (Unit* atal = s->GetSummonerUnit())
                    caster = atal;
            caster->CastSpell(me->GetPositionX(), me->GetPositionY(), me->GetPositionZ(), SPELL_SPECTRAL_BOMB_HIT, true);
            me->DespawnOrUnsummon(100ms);
        }

        void UpdateAI(uint32 /*diff*/) override { }
    };

    // The phylacteries: asleep until Spectral Veil binds one; its death breaks
    // the veil and releases the soul onto the raid.
    struct npc_soul_vessel_coa : public ScriptedAI
    {
        explicit npc_soul_vessel_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            ApplyLevelHealth(me);
            me->SetReactState(REACT_PASSIVE);
            me->SetControlled(true, UNIT_STATE_ROOT);
            DoCastSelf(SPELL_SOUL_VESSEL, true);
            Sleep(true);
        }

        void Sleep(bool asleep)
        {
            if (asleep)
                me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
            else
                me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
        }

        void JustDied(Unit* /*killer*/) override
        {
            for (Player* p : Players(me, [&](Player* x) { return me->IsWithinDistInMap(x, 100.0f); }))
            {
                me->CastSpell(p, SPELL_SOUL_RELEASE_HIT, true);
                AddStack(me, p, SPELL_SOUL_RELEASE);
            }
            if (Creature* atal = me->FindNearestCreature(NPC_ATALZUL, 200.0f))
                atal->AI()->DoAction(1);
        }

        void UpdateAI(uint32 /*diff*/) override { }
    };

    struct boss_atalzul_coa : public custom_world_boss_coa
    {
        explicit boss_atalzul_coa(Creature* creature) : custom_world_boss_coa(creature), _summons(creature) { }

        void Reset() override
        {
            custom_world_boss_coa::Reset();
            _summons.DespawnAll();
            _nextVeil = 80;
            me->RemoveAurasDueToSpell(SPELL_VEIL_POWER);
            std::list<Creature*> vessels;
            me->GetCreatureListWithEntryInGrid(vessels, NPC_SOUL_VESSEL, 100.0f);
            for (Creature* v : vessels)
            {
                if (!v->IsAlive())
                    v->Respawn(true);
                else if (auto* ai = dynamic_cast<npc_soul_vessel_coa*>(v->AI()))
                {
                    v->SetFullHealth();
                    ai->Sleep(true);
                }
            }
        }

        void JustEngagedWith(Unit* who) override
        {
            custom_world_boss_coa::JustEngagedWith(who);
            if (Creature* rogg = me->FindNearestCreature(NPC_ZULROGG, 100.0f))
                if (!rogg->IsInCombat())
                    rogg->AI()->AttackStart(who);
        }

        void JustSummoned(Creature* summon) override
        {
            _summons.Summon(summon);
            if (summon->GetEntry() == NPC_DAMNED_WIGHT)
                if (Unit* t = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                    summon->AI()->AttackStart(t);
        }

        void JustDied(Unit* /*killer*/) override
        {
            _summons.DespawnAll();
            if (Creature* rogg = me->FindNearestCreature(NPC_ZULROGG, 200.0f))
                rogg->DespawnOrUnsummon(10s);
        }

        void Schedule() override
        {
            events.ScheduleEvent(EA_BOLT, 700ms);
            events.ScheduleEvent(EA_VOLLEY, 8400ms);
            events.ScheduleEvent(EA_LAND, 11400ms);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case EA_BOLT:   DoCastVictim(SPELL_SPECTRAL_BOLT);  events.Repeat(1500ms);  break;
                case EA_VOLLEY: DoCastVictim(SPELL_SPECTRAL_VOLLEY); events.Repeat(12s);    break;
                case EA_LAND:   DoCastSelf(SPELL_LAND_OF_THE_DEAD); events.Repeat(61400ms); break;
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id == SPELL_SPECTRAL_BOLT)
            {
                if (Unit* v = me->GetVictim())
                    me->CastSpell(v, SPELL_SPECTRAL_BOLT_HIT, true);
            }
            else if (spell->Id == SPELL_SPECTRAL_VEIL)
                BindVessel();
        }

        // Land of the Dead and Spectral Veil tick through their trigger spells.
        void SpellHit(Unit* /*caster*/, SpellInfo const* spell) override
        {
            if (spell->Id == SPELL_RAISE_DEAD)
            {
                Unit* t = RandomPlayer(false);
                if (!t)
                    return;
                // A wight every second; a choking cloud every other.
                me->SummonCreature(NPC_DAMNED_WIGHT, t->GetPositionX() + frand(-4.0f, 4.0f), t->GetPositionY() + frand(-4.0f, 4.0f),
                    t->GetPositionZ(), 0, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 10000);
                if (_raise++ % 2 == 0)
                    CastAt(t->GetPosition(), SPELL_CHOKING_CLOUD);
            }
            else if (spell->Id == SPELL_VEIL_TRIGGER)
            {
                DoCastAOE(SPELL_VEIL_PULSE, true);
                AddStack(me, me, SPELL_VEIL_POWER);
                if (Unit* t = RandomPlayer(false))
                    me->SummonCreature(NPC_RESTLESS_SPIRIT, t->GetPositionX() + frand(-2.0f, 2.0f), t->GetPositionY() + frand(-2.0f, 2.0f),
                        t->GetPositionZ(), 0, TEMPSUMMON_TIMED_DESPAWN, 5000);
            }
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            custom_world_boss_coa::DamageTaken(attacker, damage, type, school);
            if (_nextVeil && !me->HasAura(SPELL_SPECTRAL_VEIL) && me->HealthBelowPctDamaged(_nextVeil, damage))
            {
                _nextVeil = _nextVeil > 20 ? _nextVeil - 20 : 0;
                me->InterruptNonMeleeSpells(false);
                DoCastSelf(SPELL_SPECTRAL_VEIL);
            }
        }

        void BindVessel()
        {
            std::list<Creature*> vessels;
            me->GetCreatureListWithEntryInGrid(vessels, NPC_SOUL_VESSEL, 100.0f);
            vessels.remove_if([](Creature* v) { return !v->IsAlive() || !v->HasUnitFlag(UNIT_FLAG_NOT_SELECTABLE); });
            if (vessels.empty())
                return;
            Creature* v = Acore::Containers::SelectRandomContainerElement(vessels);
            if (auto* ai = dynamic_cast<npc_soul_vessel_coa*>(v->AI()))
                ai->Sleep(false);
            v->CastSpell(me, SPELL_SOUL_BIND, true);
            v->CastSpell(me, SPELL_SOUL_LINK, true);
        }

        // A vessel died: the veil breaks.
        void DoAction(int32 action) override
        {
            if (action != 1 || !me->HasAura(SPELL_SPECTRAL_VEIL))
                return;
            me->InterruptNonMeleeSpells(false);
            me->RemoveAurasDueToSpell(SPELL_SPECTRAL_VEIL);
            me->RemoveAurasDueToSpell(SPELL_SOUL_LINK);
            me->RemoveAurasDueToSpell(SPELL_VEIL_POWER);
        }

    private:
        SummonList _summons;
        uint8 _nextVeil = 80;
        uint32 _raise = 0;
    };

    enum ZulroggEvents { EZ_CRUSH = 1, EZ_FIERCE };

    struct boss_zulrogg_coa : public custom_world_boss_coa
    {
        explicit boss_zulrogg_coa(Creature* creature) : custom_world_boss_coa(creature) { }

        void Reset() override
        {
            custom_world_boss_coa::Reset();
            DoCastSelf(SPELL_HAND_OF_SOULREAVER, true);
            DoCastSelf(SPELL_ENDLESS_HUNGER, true);
        }

        void JustEngagedWith(Unit* who) override
        {
            custom_world_boss_coa::JustEngagedWith(who);
            if (Creature* atal = me->FindNearestCreature(NPC_ATALZUL, 100.0f))
                if (!atal->IsInCombat())
                    atal->AI()->AttackStart(who);
        }

        void Schedule() override
        {
            events.ScheduleEvent(EZ_FIERCE, 5400ms);
            events.ScheduleEvent(EZ_CRUSH, 7200ms);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case EZ_FIERCE: DoCastVictim(SPELL_FIERCE_BLOW);   events.Repeat(7600ms);  break;
                case EZ_CRUSH:  DoCastVictim(SPELL_TITANIC_CRUSH); events.Repeat(10800ms); break;
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_TITANIC_CRUSH)
                return;
            Unit* target = me->GetVictim();
            if (!target)
                return;
            for (Player* p : Players(me, [&](Player* x) { return target->IsWithinDistInMap(x, 5.0f); }))
                me->CastSpell(p, SPELL_TITANIC_CRUSH_HIT, true);
            me->CastSpell(target, SPELL_TRAUMA, true);
        }

        // Endless Hunger: every Consume Life that lands heals him, or at full
        // health raises his attack power.
        void SpellHitTarget(Unit* target, SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_CONSUME_LIFE || !target->IsPlayer())
                return;
            if (me->IsFullHealth())
                DoCastSelf(SPELL_CONSUME_LIFE_AP, true);
            else
                Hit(me, me, SPELL_CONSUME_LIFE_HEAL, Info(me, SPELL_CONSUME_LIFE) - 1);
        }

        // Hand of the Soulreaver: he cannot die while Atal'zul is bound.
        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            custom_world_boss_coa::DamageTaken(attacker, damage, type, school);
            if (damage >= me->GetHealth())
                if (Creature* atal = me->FindNearestCreature(NPC_ATALZUL, 200.0f))
                    if (atal->IsAlive())
                        damage = me->GetHealth() > 1 ? me->GetHealth() - 1 : 0;
        }
    };

    // ------------------------------------------------------------ Trut-K'hahn
    enum TrutSpells
    {
        SPELL_FLAP              = 2119901,
        SPELL_DIVE_BOMB_INFO    = 2119902,
        SPELL_DIVE_BOMB         = 2119903,
        SPELL_DIVE_KNOCKBACK    = 2119904,
        SPELL_DIVE_STUN         = 2119905,
        SPELL_FEATHER_STORM     = 2119907,
        SPELL_CALL_THE_FLOCK    = 2119908,
        SPELL_TURKEY_RUSH       = 2119909,
        SPELL_TURKEY_RUSH_PRE   = 2119910,
        SPELL_TURKEY_RUSH_HIT   = 2119911,

        NPC_TRUT_FLOCK          = 9780030,
        NPC_FEATHER_STORM       = 9780031,
    };

    enum TrutEvents { ET_FIERCE = 1, ET_RUSH, ET_FLAP, ET_STORM, ET_FLOCK, TT_DIVE };

    constexpr uint8 FLOCK_SIZE = 5;

    struct boss_trut_khahn_coa : public custom_world_boss_coa
    {
        explicit boss_trut_khahn_coa(Creature* creature) : custom_world_boss_coa(creature), _summons(creature) { }

        void Reset() override
        {
            custom_world_boss_coa::Reset();
            _summons.DespawnAll();
        }

        void JustDied(Unit* /*killer*/) override { _summons.DespawnAll(); }

        void JustSummoned(Creature* summon) override
        {
            _summons.Summon(summon);
            if (summon->GetEntry() == NPC_TRUT_FLOCK)
                if (Unit* t = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                    summon->AI()->AttackStart(t);
        }

        void Schedule() override
        {
            events.ScheduleEvent(ET_FIERCE, 6s);
            events.ScheduleEvent(ET_RUSH, 15s);
            events.ScheduleEvent(ET_STORM, 25s);
            events.ScheduleEvent(ET_FLAP, 40s);
            events.ScheduleEvent(ET_FLOCK, 60s);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case ET_FIERCE: DoCastVictim(SPELL_FIERCE_BLOW); events.Repeat(8s); break;
                case ET_RUSH:
                    if (Unit* t = RandomPlayer())
                    {
                        _rushTo = t->GetPosition();
                        CastAt(_rushTo, SPELL_TURKEY_RUSH_PRE);
                        DoCast(t, SPELL_TURKEY_RUSH);
                    }
                    events.Repeat(20s);
                    break;
                case ET_FLAP:
                    if (Unit* t = RandomPlayer(false))
                    {
                        _diveAt = t->GetPosition();
                        DoCastSelf(SPELL_FLAP);
                    }
                    events.Repeat(40s);
                    break;
                case ET_STORM:
                    if (Unit* t = RandomPlayer(false))
                        me->SummonCreature(NPC_FEATHER_STORM, t->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, 15000);
                    events.Repeat(30s);
                    break;
                case ET_FLOCK: DoCastSelf(SPELL_CALL_THE_FLOCK); events.Repeat(60s); break;
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            switch (spell->Id)
            {
                case SPELL_TURKEY_RUSH:
                {
                    // Everyone within 4 yards of his path is run over.
                    Position const from = me->GetPosition();
                    float const dx = _rushTo.GetPositionX() - from.GetPositionX();
                    float const dy = _rushTo.GetPositionY() - from.GetPositionY();
                    float const len2 = std::max(1.0f, dx * dx + dy * dy);
                    for (Player* p : PlayersWithin(me, 100.0f))
                    {
                        float const u = std::clamp(((p->GetPositionX() - from.GetPositionX()) * dx + (p->GetPositionY() - from.GetPositionY()) * dy) / len2, 0.0f, 1.0f);
                        float const ex = from.GetPositionX() + u * dx - p->GetPositionX();
                        float const ey = from.GetPositionY() + u * dy - p->GetPositionY();
                        if (ex * ex + ey * ey <= 16.0f)
                            me->CastSpell(p, SPELL_TURKEY_RUSH_HIT, true);
                    }
                    me->GetMotionMaster()->MoveCharge(_rushTo.GetPositionX(), _rushTo.GetPositionY(), _rushTo.GetPositionZ(), 42.0f);
                    break;
                }
                case SPELL_FLAP:
                    me->SetDisableGravity(true);
                    me->GetMotionMaster()->MovePoint(0, _diveAt.GetPositionX(), _diveAt.GetPositionY(), _diveAt.GetPositionZ() + 15.0f, FORCED_MOVEMENT_NONE, 0.f, 0.f, false);
                    _clock.ScheduleEvent(TT_DIVE, 3s);
                    break;
                case SPELL_CALL_THE_FLOCK:
                    for (uint8 i = 0; i < FLOCK_SIZE; ++i)
                    {
                        Position pos = me->GetPosition();
                        me->MovePosition(pos, 12.0f, 2 * float(M_PI) * i / FLOCK_SIZE);
                        me->SummonCreature(NPC_TRUT_FLOCK, pos, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 10000);
                    }
                    break;
            }
        }

        void Tick(uint32 tick) override
        {
            if (tick != TT_DIVE)
                return;
            me->SetDisableGravity(false);
            me->NearTeleportTo(_diveAt.GetPositionX(), _diveAt.GetPositionY(), _diveAt.GetPositionZ(), me->GetOrientation());
            int32 const base = Info(me, SPELL_DIVE_BOMB_INFO);
            for (Player* p : PlayersWithin(me, 100.0f))
            {
                float const d = p->GetExactDist2d(&_diveAt);
                // Hit directly: stunned. Further out: less damage, thrown back.
                Hit(me, p, SPELL_DIVE_BOMB, int32(base * std::clamp(1.0f - d / 40.0f, 0.1f, 1.0f)) - 1);
                me->CastSpell(p, d <= 5.0f ? SPELL_DIVE_STUN : SPELL_DIVE_KNOCKBACK, true);
            }
        }

    private:
        SummonList _summons;
        Position _rushTo;
        Position _diveAt;
    };

    // A feather storm that drifts from player to player for 15 seconds.
    struct npc_feather_storm_coa : public ScriptedAI
    {
        explicit npc_feather_storm_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            me->SetReactState(REACT_PASSIVE);
            _pulse = 1s;
            _move = 0ms;
        }

        void UpdateAI(uint32 diff) override
        {
            _pulse -= Milliseconds(diff);
            _move -= Milliseconds(diff);
            if (_pulse <= 0ms)
            {
                Unit* caster = me;
                if (TempSummon* s = me->ToTempSummon())
                    if (Unit* trut = s->GetSummonerUnit())
                        caster = trut;
                for (Player* p : Players(me, [&](Player* x) { return me->IsWithinDistInMap(x, 8.0f); }))
                    caster->CastSpell(p, SPELL_FEATHER_STORM, true);
                _pulse = 1s;
            }
            if (_move <= 0ms)
            {
                std::vector<Player*> pool = Players(me, [&](Player* x) { return me->IsWithinDistInMap(x, 60.0f); });
                if (!pool.empty())
                {
                    Player* p = Acore::Containers::SelectRandomContainerElement(pool);
                    me->GetMotionMaster()->MovePoint(0, p->GetPosition());
                }
                _move = 5s;
            }
        }

    private:
        Milliseconds _pulse = 1s;
        Milliseconds _move = 0ms;
    };

    // Adds of the Atal'Zul and Trut-K'hahn fights: melee, Fierce Blow, the level.
    struct npc_custom_add_coa : public npc_psychophage_coa
    {
        using npc_psychophage_coa::npc_psychophage_coa;
    };

    template <class AI>
    class custom_script : public CreatureScript
    {
    public:
        explicit custom_script(char const* name) : CreatureScript(name) { }
        CreatureAI* GetAI(Creature* creature) const override { return new AI(creature); }
    };
}

void AddCoaCustomWorldBossScripts()
{
    new coa_world_boss_level_loader();
    new custom_script<boss_setis_coa>("boss_setis_coa");
    new custom_script<boss_snowgrave_coa>("boss_snowgrave_coa");
    new custom_script<boss_soggoth_coa>("boss_soggoth_coa");
    new custom_script<npc_psychophage_coa>("npc_psychophage_coa");
    new custom_script<boss_atalzul_coa>("boss_atalzul_coa");
    new custom_script<boss_zulrogg_coa>("boss_zulrogg_coa");
    new custom_script<npc_soul_vessel_coa>("npc_soul_vessel_coa");
    new custom_script<npc_restless_spirit_coa>("npc_restless_spirit_coa");
    new custom_script<npc_custom_add_coa>("npc_custom_add_coa");
    new custom_script<boss_trut_khahn_coa>("boss_trut_khahn_coa");
    new custom_script<npc_feather_storm_coa>("npc_feather_storm_coa");
}
