/*
 * Chromaggus as Ascension redesigned him.
 *
 * No combat logs exist for Blackwing Lair, so the fight is designed - but the
 * DBC block 2111000-2111165 describes a fight the original never had, and the
 * pieces fit together:
 *
 * Chromatic Metabolism. Every 30 seconds he adapts to one school of magic: he
 * takes 125% more from it and 20% less from every other. Each school brings
 * its own breath and its own big spell, and he uses the ones of his current
 * school:
 *
 *   fire     Flame Breath    Incinerate          eruptions spread out from him
 *   nature   Acid Breath     Corrosive Acid      acid pools across the room
 *   frost    Frost Breath    Frost Burn          freezing fog
 *   shadow   Shadow Breath   Engulfing Shadows   5% of current health a second;
 *                                                below 10% the target is consumed
 *   arcane   Arcane Breath   Time Lapse          frozen, then time speeds up or
 *                                                slows down
 *
 * Brood Afflictions. Every 15 seconds each player catches one colour he does
 * not have yet. Each one adds a stack of Unstable Mutation, +10% damage; five
 * turn the player into a Chromatic Drakonid. Losing an affliction loses a
 * stack. At the pull every player is blessed by one dragonflight, which stops
 * that colour from being removed. Hourglass Sand cures bronze.
 *
 * Decided with the raid designer, not found in the data:
 *   - the 30-second rhythm, a breath every 10 seconds, the big spell once per
 *     phase 10 seconds in, no school twice in a row;
 *   - afflictions every 15 seconds (the original: 7), blessings once at the pull;
 *   - numbers for the hits the DBC leaves to a script: 2744 on Normal, taken
 *     from his own "Breath Damage Info" aura, then 20:27:34:40 upwards;
 *   - on Mythic and above, a consumed player heals him (Shadow Mend);
 *   - a hard berserk at 10 minutes instead of the original enrage at 20%.
 *
 * From stock: he is immune until the lever is pulled and walks his path in.
 */

#include "CreatureScript.h"
#include "InstanceScript.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "../../../src/server/scripts/EasternKingdoms/BlackrockMountain/BlackwingLair/blackwing_lair.h"

#include <algorithm>
#include <array>
#include <functional>
#include <map>
#include <vector>

namespace
{
    enum School : uint8 { FIRE, NATURE, FROST, SHADOW, ARCANE, SCHOOL_COUNT };

    constexpr std::array<uint32, SCHOOL_COUNT> ADAPTATION   = { 2111002, 2111003, 2111004, 2111005, 2111006 };
    constexpr std::array<uint32, SCHOOL_COUNT> BREATH_CAST  = { 2111029, 2111030, 2111031, 2111032, 2111033 };
    constexpr std::array<uint32, SCHOOL_COUNT> BREATH_HIT   = { 2111035, 2111036, 2111037, 2111038, 2111039 };
    constexpr std::array<uint32, SCHOOL_COUNT> BREATH_VULN  = { 2111040, 2111041, 2111042, 2111043, 2111044 };
    constexpr std::array<uint32, SCHOOL_COUNT> BIG_CAST     = { 2111045, 2111052, 2111059, 2111066, 2111075 };
    constexpr std::array<uint32, SCHOOL_COUNT> BIG_HIT      = { 2111046, 2111053, 2111060, 2111067, 2111076 };

    enum Colour : uint8 { RED, GREEN, BLUE, BLACK, BRONZE, COLOUR_COUNT };

    constexpr std::array<uint32, COLOUR_COUNT> AFFLICTION = { 2111012, 2111013, 2111014, 2111015, 2111016 };
    constexpr std::array<uint32, COLOUR_COUNT> BLESSING   = { 2111007, 2111008, 2111009, 2111010, 2111011 };

    enum Spells
    {
        SPELL_UNSTABLE_MUTATION     = 2111017,
        SPELL_MUTATING              = 2111018,
        SPELL_CHROMATIC_MUTATION    = 2111019,
        SPELL_CHROMATIC_ADDON       = 2111020,
        SPELL_RED_BURN              = 2111021,
        SPELL_TIME_STOP             = 2111022,
        SPELL_HOURGLASS_SAND        = 2111023,
        SPELL_MUTATION_BURN         = 2111024,

        SPELL_INCINERATE_DOT        = 2111047,
        SPELL_INCINERATE_ERUPTION   = 2111151,
        SPELL_CORROSIVE_ACID_DOT    = 2111054,
        SPELL_ACIDIC_PUS            = 2111156,
        SPELL_ACIDIC_OOZE           = 2111160,
        SPELL_FROST_BURN_DOT        = 2111061,
        SPELL_FREEZING_FOG          = 2111165,
        SPELL_ENGULFING_SHADOWS     = 2111068,
        SPELL_ENGULFING_TICK        = 2111072,
        SPELL_CONSUMING_SHADOWS     = 2111073,
        SPELL_SHADOW_MEND           = 2111074,
        SPELL_TIME_LAPSE_FREEZE     = 2111077,
        SPELL_ACCELERATE_TIME       = 2111078,
        SPELL_DECELERATE_TIME       = 2111080,

        SPELL_BERSERK               = 2100213,
    };

    // The stock lever passes the player who pulled it with this id.
    constexpr int32 GUID_LEVER_USER = 0;

    enum Events
    {
        EVENT_PHASE = 1,
        EVENT_BREATH,
        EVENT_BIG,
        EVENT_AFFLICTION,
        EVENT_BERSERK,

        // on the clock
        EVENT_SECOND,
        EVENT_BREATH_PULSE,
        EVENT_ERUPTION_RING,
        EVENT_ACID_POOL,
        EVENT_FOG,
        EVENT_TIME_FLOW,
    };

    constexpr uint32 BREATH_BASE        = 2744;     // his "Breath Damage Info" aura
    constexpr std::array<float, 4> TIER = { 1.0f, 1.35f, 1.7f, 2.0f };   // 20:27:34:40
    constexpr float  CONE_ARC           = float(M_PI) / 2;
    constexpr float  BREATH_RANGE       = 25.0f;
    constexpr float  NEARBY             = 60.0f;
    constexpr uint8  BREATH_PULSES      = 6;
    constexpr uint8  ERUPTION_RINGS     = 7;
    constexpr uint8  ACID_POOLS         = 8;
    constexpr uint8  FOG_SPOTS          = 4;
    constexpr uint8  FOG_SECONDS        = 20;
    constexpr uint8  TIME_FLOW_SECONDS  = 10;
    constexpr uint8  MUTATION_AT        = 5;
    constexpr float  CONSUMED_BELOW     = 10.0f;

    void SetStacks(Unit* caster, Unit* target, uint32 spellId, int32 stacks, int32 max)
    {
        uint32 const id = sSpellMgr->GetSpellIdForDifficulty(spellId, caster);
        stacks = std::clamp<int32>(stacks, 0, max);
        Aura* aura = target->GetAura(id);
        if (!stacks)
        {
            if (aura)
                target->RemoveAurasDueToSpell(id);
            return;
        }
        if (!aura)
        {
            caster->CastSpell(target, id, true);
            aura = target->GetAura(id);
        }
        if (aura)
        {
            aura->SetStackAmount(uint8(stacks));
            aura->RefreshDuration();
        }
    }

    int32 Stacks(Unit* target, uint32 spellId)
    {
        Aura* aura = target->GetAura(spellId);
        return aura ? aura->GetStackAmount() : 0;
    }

    struct boss_chromaggus_coa : public BossAI
    {
        boss_chromaggus_coa(Creature* creature) : BossAI(creature, DATA_CHROMAGGUS)
        {
            // Stock: immune until the lever is pulled, so he cannot be pulled
            // through the floor.
            creature->SetImmuneToAll(true);
        }

        void Reset() override
        {
            _Reset();
            CleanUpPlayers();
            _clock.Reset();
            _school = SCHOOL_COUNT;
            _had.clear();
            _mutating.clear();
            _fogSpots.clear();
        }

        void JustDied(Unit* /*killer*/) override
        {
            _JustDied();
            CleanUpPlayers();
        }

        void SetGUID(ObjectGuid const& guid, int32 id) override
        {
            if (id == GUID_LEVER_USER)
            {
                _leverUser = guid;
                me->SetImmuneToAll(false);
            }
        }

        void PathEndReached(uint32 /*pathId*/) override
        {
            if (Unit* player = ObjectAccessor::GetUnit(*me, _leverUser))
                me->SetInCombatWith(player);
        }

        bool CanAIAttack(Unit const* victim) const override
        {
            return !victim->HasAura(SPELL_TIME_LAPSE_FREEZE);
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);

            // One blessing per player, for the whole fight.
            for (Player* p : Players([](Player*) { return true; }))
                me->CastSpell(p, BLESSING[urand(0, COLOUR_COUNT - 1)], true);

            events.ScheduleEvent(EVENT_PHASE, 1s);
            events.ScheduleEvent(EVENT_AFFLICTION, 15s);
            events.ScheduleEvent(EVENT_BERSERK, 10min);
            _clock.ScheduleEvent(EVENT_SECOND, 1s);
        }

        void CleanUpPlayers()
        {
            me->GetMap()->DoForAllPlayers([&](Player* p)
            {
                for (uint8 c = 0; c < COLOUR_COUNT; ++c)
                {
                    p->RemoveAurasDueToSpell(AFFLICTION[c]);
                    p->RemoveAurasDueToSpell(BLESSING[c]);
                }
                for (uint32 id : { uint32(SPELL_UNSTABLE_MUTATION), uint32(SPELL_MUTATING), uint32(SPELL_CHROMATIC_MUTATION),
                                   uint32(SPELL_CHROMATIC_ADDON), uint32(SPELL_ENGULFING_SHADOWS) })
                    p->RemoveAurasDueToSpell(id);
            });
        }

        std::vector<Player*> Players(std::function<bool(Player*)> const& accept)
        {
            std::vector<Player*> out;
            me->GetMap()->DoForAllPlayers([&](Player* player)
            {
                if (player->IsAlive() && !player->IsGameMaster() && accept(player))
                    out.push_back(player);
            });
            return out;
        }

        int32 Scaled(uint32 base) const
        {
            uint8 const mode = uint8(me->GetMap()->GetSpawnMode());
            return int32(base * TIER[std::min<uint8>(mode, 3)]);
        }

        void HitWith(Unit* target, uint32 spell, int32 amount)
        {
            if (amount > 0)
                me->CastCustomSpell(target, spell, &amount, nullptr, nullptr, true);
        }

        Position Around(float minDist, float maxDist) const
        {
            float const angle = frand(0.0f, 2 * float(M_PI));
            float const dist = frand(minDist, maxDist);
            float x = me->GetPositionX() + std::cos(angle) * dist;
            float y = me->GetPositionY() + std::sin(angle) * dist;
            float z = me->GetPositionZ();
            me->UpdateGroundPositionZ(x, y, z);
            return Position(x, y, z);
        }

        // ----------------------------------------------------------- phases
        void NewPhase()
        {
            if (_school < SCHOOL_COUNT)
                me->RemoveAurasDueToSpell(ADAPTATION[_school]);

            uint8 next;
            do
                next = uint8(urand(0, SCHOOL_COUNT - 1));
            while (next == _school);
            _school = next;

            DoCastSelf(ADAPTATION[_school], true);
            events.ScheduleEvent(EVENT_BREATH, 5s);
            events.ScheduleEvent(EVENT_BIG, 10s);
            events.ScheduleEvent(EVENT_BREATH, 15s);
            events.ScheduleEvent(EVENT_BREATH, 25s);
            events.ScheduleEvent(EVENT_PHASE, 30s);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);
            if (_school >= SCHOOL_COUNT)
                return;

            if (spell->Id == BREATH_CAST[_school])
            {
                _pulses = BREATH_PULSES;
                _clock.ScheduleEvent(EVENT_BREATH_PULSE, 0ms);
            }
            else if (spell->Id == BIG_CAST[_school])
                BigSpell();
        }

        void BreathPulse()
        {
            for (Player* p : Players([&](Player* x) { return me->IsWithinDistInMap(x, BREATH_RANGE) && me->isInFront(x, CONE_ARC); }))
            {
                HitWith(p, BREATH_HIT[_school], Scaled(BREATH_BASE));
                SetStacks(me, p, BREATH_VULN[_school], Stacks(p, BREATH_VULN[_school]) + 1, 100);
            }
            if (--_pulses)
                _clock.ScheduleEvent(EVENT_BREATH_PULSE, 500ms);
        }

        void BigSpell()
        {
            std::vector<Player*> const inRange = Players([&](Player* x) { return me->IsWithinDistInMap(x, NEARBY); });
            for (Player* p : inRange)
                HitWith(p, BIG_HIT[_school], Scaled(BREATH_BASE));

            switch (_school)
            {
                case FIRE:
                    for (Player* p : inRange)
                        me->CastSpell(p, SPELL_INCINERATE_DOT, true);
                    _ring = 0;
                    _clock.ScheduleEvent(EVENT_ERUPTION_RING, 1s);
                    break;
                case NATURE:
                    for (Player* p : inRange)
                        me->CastSpell(p, SPELL_CORROSIVE_ACID_DOT, true);
                    _pools = ACID_POOLS;
                    _clock.ScheduleEvent(EVENT_ACID_POOL, 500ms);
                    break;
                case FROST:
                    for (Player* p : inRange)
                        me->CastSpell(p, SPELL_FROST_BURN_DOT, true);
                    _fogSpots.clear();
                    for (uint8 i = 0; i < FOG_SPOTS; ++i)
                        _fogSpots.push_back(Around(8.0f, 30.0f));
                    _fogLeft = FOG_SECONDS;
                    _clock.ScheduleEvent(EVENT_FOG, 1s);
                    break;
                case SHADOW:
                    for (Player* p : inRange)
                        me->CastSpell(p, SPELL_ENGULFING_SHADOWS, true);
                    break;
                case ARCANE:
                    for (Player* p : inRange)
                        me->CastSpell(p, SPELL_TIME_LAPSE_FREEZE, true);
                    // Once the freeze ends, time runs one way or the other.
                    _timeFlow = urand(0, 1) ? SPELL_ACCELERATE_TIME : SPELL_DECELERATE_TIME;
                    _flowSecond = 0;
                    _clock.ScheduleEvent(EVENT_TIME_FLOW, 4s);
                    break;
                default:
                    break;
            }
        }

        // "A chain of flaming eruptions expands slowly from his position."
        void EruptionRing()
        {
            float const radius = 5.0f * (_ring + 1);
            uint8 const points = uint8(4 + _ring * 2);
            for (uint8 i = 0; i < points; ++i)
            {
                float const angle = 2 * float(M_PI) * i / points;
                float x = me->GetPositionX() + std::cos(angle) * radius;
                float y = me->GetPositionY() + std::sin(angle) * radius;
                float z = me->GetPositionZ();
                me->UpdateGroundPositionZ(x, y, z);
                me->CastSpell(x, y, z, SPELL_INCINERATE_ERUPTION, true);
            }
            if (++_ring < ERUPTION_RINGS)
                _clock.ScheduleEvent(EVENT_ERUPTION_RING, 1s);
        }

        void AcidPool()
        {
            Position const pos = Around(5.0f, 35.0f);
            me->CastSpell(pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), SPELL_ACIDIC_PUS, true);
            me->CastSpell(pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), SPELL_ACIDIC_OOZE, true);
            if (--_pools)
                _clock.ScheduleEvent(EVENT_ACID_POOL, 500ms);
        }

        void Fog()
        {
            for (Position const& pos : _fogSpots)
                me->CastSpell(pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), SPELL_FREEZING_FOG, true);
            if (--_fogLeft)
                _clock.ScheduleEvent(EVENT_FOG, 1s);
        }

        void TimeFlow()
        {
            ++_flowSecond;
            for (Player* p : Players([&](Player* x) { return me->IsWithinDistInMap(x, NEARBY); }))
                SetStacks(me, p, _timeFlow, _flowSecond, TIME_FLOW_SECONDS);
            if (_flowSecond < TIME_FLOW_SECONDS)
                _clock.ScheduleEvent(EVENT_TIME_FLOW, 1s);
        }

        // ------------------------------------------------------ afflictions
        void GiveAfflictions()
        {
            for (Player* p : Players([](Player*) { return true; }))
            {
                std::vector<uint8> free;
                for (uint8 c = 0; c < COLOUR_COUNT; ++c)
                    if (!p->HasAura(AFFLICTION[c]))
                        free.push_back(c);
                if (free.empty())
                    continue;
                uint8 const c = free[urand(0, free.size() - 1)];
                me->CastSpell(p, AFFLICTION[c], true);
                _had[p->GetGUID()] |= 1u << c;
            }
        }

        // Once a second, everything that ticks on its own.
        void EverySecond()
        {
            ++_second;
            for (Player* p : Players([](Player*) { return true; }))
            {
                uint8& had = _had[p->GetGUID()];
                uint8 count = 0;
                for (uint8 c = 0; c < COLOUR_COUNT; ++c)
                {
                    bool const has = p->HasAura(AFFLICTION[c]);
                    // A blessed colour cannot be removed: it comes straight back.
                    if (!has && (had & (1u << c)) && p->HasAura(BLESSING[c]))
                    {
                        me->CastSpell(p, AFFLICTION[c], true);
                        ++count;
                        continue;
                    }
                    if (!has)
                    {
                        had &= uint8(~(1u << c));
                        continue;
                    }
                    ++count;
                }

                if (p->HasAura(AFFLICTION[RED]))
                    HitWith(p, SPELL_RED_BURN, int32(p->GetMaxHealth() * 3 / 100));
                if (p->HasAura(AFFLICTION[BRONZE]) && _second % 2 == 0)
                    me->CastSpell(p, SPELL_TIME_STOP, true);

                bool const mutated = p->HasAura(SPELL_CHROMATIC_MUTATION);
                if (mutated)
                    HitWith(p, SPELL_MUTATION_BURN, int32(p->GetHealth() / 100));
                else if (!_mutating.count(p->GetGUID()))
                {
                    SetStacks(me, p, SPELL_UNSTABLE_MUTATION, count, MUTATION_AT);
                    if (count >= MUTATION_AT)
                    {
                        me->CastSpell(p, SPELL_MUTATING, true);
                        _mutating[p->GetGUID()] = _second + 5;
                    }
                }

                auto m = _mutating.find(p->GetGUID());
                if (m != _mutating.end() && _second >= m->second)
                {
                    p->RemoveAurasDueToSpell(SPELL_UNSTABLE_MUTATION);
                    me->CastSpell(p, SPELL_CHROMATIC_MUTATION, true);
                    me->CastSpell(p, SPELL_CHROMATIC_ADDON, true);
                    _mutating.erase(m);
                }

                // Engulfing Shadows: 5% of current health, consumed below 10%.
                if (p->HasAura(SPELL_ENGULFING_SHADOWS))
                {
                    if (p->GetHealthPct() < CONSUMED_BELOW)
                    {
                        int32 const left = int32(p->GetHealth());
                        HitWith(p, SPELL_CONSUMING_SHADOWS, int32(p->GetMaxHealth()));
                        p->RemoveAurasDueToSpell(SPELL_ENGULFING_SHADOWS);
                        if (me->GetMap()->GetSpawnMode() >= 2)
                            HitWith(me, SPELL_SHADOW_MEND, left);
                    }
                    else
                        HitWith(p, SPELL_ENGULFING_TICK, int32(p->GetHealth() * 5 / 100));
                }
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            events.Update(diff);
            _clock.Update(diff);

            while (uint32 tick = _clock.ExecuteEvent())
            {
                switch (tick)
                {
                    case EVENT_SECOND:
                        EverySecond();
                        _clock.ScheduleEvent(EVENT_SECOND, 1s);
                        break;
                    case EVENT_BREATH_PULSE:    BreathPulse();  break;
                    case EVENT_ERUPTION_RING:   EruptionRing(); break;
                    case EVENT_ACID_POOL:       AcidPool();     break;
                    case EVENT_FOG:             Fog();          break;
                    case EVENT_TIME_FLOW:       TimeFlow();     break;
                }
            }

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_PHASE:
                        NewPhase();
                        break;
                    case EVENT_BREATH:
                        DoCastVictim(BREATH_CAST[_school]);
                        break;
                    case EVENT_BIG:
                        DoCastVictim(BIG_CAST[_school]);
                        break;
                    case EVENT_AFFLICTION:
                        GiveAfflictions();
                        events.ScheduleEvent(EVENT_AFFLICTION, 15s);
                        break;
                    case EVENT_BERSERK:
                        DoCastSelf(SPELL_BERSERK, true);
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    private:
        EventMap _clock;
        ObjectGuid _leverUser;
        uint8 _school = SCHOOL_COUNT;
        uint8 _pulses = 0;
        uint8 _ring = 0;
        uint8 _pools = 0;
        uint8 _fogLeft = 0;
        uint8 _flowSecond = 0;
        uint32 _timeFlow = 0;
        uint32 _second = 0;
        std::vector<Position> _fogSpots;
        std::map<ObjectGuid, uint8> _had;           // colours a player carried
        std::map<ObjectGuid, uint32> _mutating;     // second the mutation lands
    };

    // Hourglass Sand: cures bronze - unless the bronze dragonflight blessed it.
    class spell_chromaggus_coa_hourglass_sand : public SpellScript
    {
        PrepareSpellScript(spell_chromaggus_coa_hourglass_sand);

        void HandleHit(SpellEffIndex /*effIndex*/)
        {
            Unit* target = GetHitUnit();
            if (!target || target->HasAura(BLESSING[BRONZE]))
                return;
            target->RemoveAurasDueToSpell(AFFLICTION[BRONZE]);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_chromaggus_coa_hourglass_sand::HandleHit, EFFECT_0, SPELL_EFFECT_APPLY_AURA);
        }
    };
}

void AddCoaChromaggusScripts()
{
    RegisterBlackwingLairCreatureAI(boss_chromaggus_coa);
    RegisterSpellScript(spell_chromaggus_coa_hourglass_sand);
}
