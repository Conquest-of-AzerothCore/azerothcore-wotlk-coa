/*
 * The four dragons of Nightmare as Ascension rebuilt them.
 *
 * Kit: Ascension's blocks 2119400 (Ysondre), 2119500 (Taerar), 2119600
 * (Lethon), 2119700 (Emeriss). No combat logs exist for them. The shared kit
 * is the same family as Azuregos' (Draconic Strike, Fierce Draconic Strike,
 * Draconic Cleave), so it runs on Azuregos' measured timers; everything else
 * is designed.
 *
 * All four
 *   Draconic Strike        every 13.2s   tank          (Azuregos' timer)
 *   Draconic Cleave        every 16.9s   20-yard cone  (Azuregos' timer)
 *   Fierce Draconic Strike every 24.8s   tank          (Azuregos' timer)
 *   Tail Sweep             every 4s, if anyone stands behind: weapon damage and
 *                          thrown away
 *   Noxious Breath         first 10s, every 15s: 2s cast, six pulses in a
 *                          30-yard cone, each leaving Lingering Corruption (a
 *                          DoT, +1s on every cooldown)
 *   Dream Fog              first 20s, every 30s: 2s cast, a drifting cloud at a
 *                          player for 30s; whoever it touches falls asleep until
 *                          damaged, then is immune for 4s (Insomnia)
 *   Mark of Nightmares     whoever dies is marked; a marked player the dragon
 *                          hits falls into a Dreamless Sleep nothing wakes
 *
 * At 75, 50 and 25% each dragon calls its own nightmare:
 *   Ysondre  Awaken the Sleepers (5s cast): demented druid spirits join, casting
 *            Dreamfire and Silence. Lightning Wave every 12s: a chain, +20% per
 *            leap.
 *   Taerar   Split the Nightmare (5s cast): three shades fight while he is
 *            banished (up to 60s, until they die); the shades breathe acid and
 *            throw toxic clouds. Arcane Shock every 10s, Bellowing Roar every 30s.
 *   Lethon   Dream Eater (5s cast): a shade rises from every player and walks to
 *            him; each that arrives heals him. Seeking Shadow Bolts every 20s:
 *            five volleys at everyone on his left or on his right side.
 *   Emeriss  Corruption of the Earth (5s cast): 20% of maximum health as Shadow
 *            damage every 2s for 10s on everyone within 100 yards. Volatile
 *            Infection every 30s on a player and those near. Whoever dies grows a
 *            Putrid Mushroom: a burst and a spore cloud for 3 minutes.
 *
 * Health: 21.8 million each, fixed. The stock dragons have 0.563 of stock
 * Azuregos' health; the same share of Azuregos' measured Ascension pool.
 *
 * Decided here, not in the data: every timer except the three strikes, six
 * breath pulses, fog lasting 30s, how far the dragons' tails reach, the
 * druids' two spells, and the health. Curse of Thorns (a chance-on-hit dummy)
 * is left out.
 */

#include "Containers.h"
#include "CreatureScript.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "zg_coa_common.h"

#include <map>
#include <set>

using namespace coa_zg;

void CoaApplyWorldHealth(Creature* creature);

namespace
{
    // Offsets into each dragon's block.
    enum Offsets
    {
        OFF_STRIKE          = 1,
        OFF_FIERCE          = 2,
        OFF_CLEAVE          = 3,
        OFF_TAIL_HIT        = 5,
        OFF_BREATH          = 7,
        OFF_BREATH_HIT      = 9,
        OFF_CORRUPTION      = 10,
        OFF_MARK            = 12,
        OFF_DREAMLESS       = 13,
        OFF_FOG             = 14,
        OFF_SLEEP           = 19,
        OFF_INSOMNIA        = 20,
    };

    enum Spells
    {
        // Ysondre
        SPELL_LIGHTNING_WAVE     = 2119425,
        SPELL_LIGHTNING_WAVE_HIT = 2119426,
        SPELL_AWAKEN_SLEEPERS    = 2119427,
        SPELL_DREAMFIRE          = 2119430,
        SPELL_SILENCE            = 2119431,
        SPELL_SUMMON_DRUIDS      = 24795,
        // Taerar
        SPELL_ARCANE_SHOCK       = 2119521,
        SPELL_ARCANE_SHOCK_HIT   = 2119522,
        SPELL_BELLOWING_ROAR     = 2119523,
        SPELL_BELLOWING_FEAR     = 2119524,
        SPELL_SPLIT              = 2119525,
        SPELL_BANISHED           = 2119526,
        SPELL_ACID_BREATH        = 2119551,
        SPELL_ACID_BREATH_HIT    = 2119553,
        SPELL_ACID_BREATH_DOT    = 2119554,
        SPELL_TOXIC_BOMBARDEMENT = 2119556,
        SPELL_TOXIC_CLOUD        = 2119557,
        SPELL_SUMMON_SHADE_1     = 24841,
        SPELL_SUMMON_SHADE_2     = 24842,
        SPELL_SUMMON_SHADE_3     = 24843,
        // Lethon
        SPELL_SEEKING_BOLTS      = 2119621,
        SPELL_SEEKING_BOLT_HIT   = 2119623,
        SPELL_DREAM_EATER        = 2119624,
        // Emeriss
        SPELL_VOLATILE_INFECTION = 2119721,
        SPELL_VOLATILE_AURA      = 2119722,
        SPELL_CORRUPTION_EARTH   = 2119724,
        SPELL_CORRUPTION_AURA    = 2119725,
        SPELL_CORRUPTION_HIT     = 2119726,
        SPELL_SPORE_CLOUD        = 2119729,
        SPELL_SPORE_BURST        = 2119730,
    };

    enum Npcs
    {
        NPC_YSONDRE        = 14887,
        NPC_LETHON         = 14888,
        NPC_EMERISS        = 14889,
        NPC_TAERAR         = 14890,
        NPC_DEMENTED_DRUID = 15260,
        NPC_SPIRIT_SHADE   = 15261,
        NPC_SHADE_OF_TAERAR = 15302,
        NPC_WORLD_TRIGGER  = 12999,
    };

    enum Events
    {
        EV_STRIKE = 1, EV_CLEAVE, EV_FIERCE, EV_TAIL, EV_BREATH, EV_FOG, EV_SECOND,
        EV_OWN_1, EV_OWN_2, EV_OWN_3,
        TK_BREATH, TK_BOLTS, TK_CORRUPTION,
    };

    constexpr float BREATH_RANGE = 30.0f;
    constexpr float CONE_ARC     = float(M_PI) / 2;
    constexpr float TAIL_RANGE   = 20.0f;
    constexpr float FOG_RADIUS   = 5.0f;
    constexpr uint8 BREATH_PULSES = 6;

    struct emerald_dragon_coa : public ScriptedAI
    {
        emerald_dragon_coa(Creature* creature, uint32 block) : ScriptedAI(creature), _block(block) { }

        uint32 S(uint32 offset) const { return _block + offset; }

        void Reset() override
        {
            _events.Reset();
            _clock.Reset();
            _stage = 1;
            _fogs.clear();
            _sleepers.clear();
            CoaApplyWorldHealth(me);
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            CoaApplyWorldHealth(me);
            _events.ScheduleEvent(EV_STRIKE, 1s);
            _events.ScheduleEvent(EV_CLEAVE, 8s);
            _events.ScheduleEvent(EV_FIERCE, 12s);
            _events.ScheduleEvent(EV_TAIL, 4s);
            _events.ScheduleEvent(EV_BREATH, 10s);
            _events.ScheduleEvent(EV_FOG, 20s);
            _events.ScheduleEvent(EV_SECOND, 1s);
            ScheduleOwn();
        }

        virtual void ScheduleOwn() = 0;
        virtual void Own(uint32 eventId) = 0;
        virtual void Nightmare() = 0;
        virtual void OwnTick(uint32 /*tick*/) { }

        // Whoever dies carries the Mark of Nightmares.
        void KilledUnit(Unit* victim) override
        {
            if (victim->IsPlayer())
                me->AddAura(S(OFF_MARK), victim);
        }

        void DamageDealt(Unit* victim, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            ScriptedAI::DamageDealt(victim, damage, type, school);
            if (damage && victim && victim->IsAlive() && victim->HasAura(S(OFF_MARK)))
            {
                victim->RemoveAurasDueToSpell(S(OFF_MARK));
                me->AddAura(S(OFF_DREAMLESS), victim);
            }
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            ScriptedAI::DamageTaken(attacker, damage, type, school);
            if (_stage <= 3 && me->HealthBelowPctDamaged(100 - 25 * _stage, damage))
            {
                ++_stage;
                me->InterruptNonMeleeSpells(false);
                Nightmare();
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id == S(OFF_BREATH))
            {
                _pulses = BREATH_PULSES;
                _clock.ScheduleEvent(TK_BREATH, 0ms);
            }
            else if (spell->Id == S(OFF_FOG))
                SpawnFog();
        }

        void SpawnFog()
        {
            Unit* target = ObjectAccessor::GetUnit(*me, _fogTarget);
            if (!target)
                return;
            if (Creature* fog = me->SummonCreature(NPC_WORLD_TRIGGER, target->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, 30000))
            {
                fog->SetFaction(me->GetFaction());
                fog->CastSpell(fog, S(OFF_FOG) + 3, true);   // the visible cloud
                fog->GetMotionMaster()->MoveRandom(10.0f);
                _fogs.push_back(fog->GetGUID());
            }
        }

        // Every second: the fog puts people to sleep; sleepers who woke up get Insomnia.
        void Second()
        {
            for (ObjectGuid const& guid : _fogs)
                if (Creature* fog = ObjectAccessor::GetCreature(*me, guid))
                    for (Player* p : Players(me, [&](Player* x) { return fog->IsWithinDist(x, FOG_RADIUS); }))
                        if (!p->HasAura(S(OFF_INSOMNIA)) && !p->HasAura(S(OFF_SLEEP)))
                        {
                            me->AddAura(S(OFF_SLEEP), p);
                            _sleepers.insert(p->GetGUID());
                        }
            for (auto it = _sleepers.begin(); it != _sleepers.end();)
            {
                Player* p = ObjectAccessor::GetPlayer(*me, *it);
                if (p && p->HasAura(S(OFF_SLEEP)))
                {
                    ++it;
                    continue;
                }
                if (p)
                    me->AddAura(S(OFF_INSOMNIA), p);
                it = _sleepers.erase(it);
            }
            _fogs.erase(std::remove_if(_fogs.begin(), _fogs.end(), [this](ObjectGuid const& g) { return !ObjectAccessor::GetCreature(*me, g); }), _fogs.end());
        }

        void Tail()
        {
            for (Player* p : Players(me, [&](Player* x) { return me->IsWithinDist(x, TAIL_RANGE) && !me->isInFront(x, float(M_PI)); }))
            {
                me->CastSpell(p, S(OFF_TAIL_HIT), true);
                p->KnockbackFrom(me->GetPositionX(), me->GetPositionY(), 15.0f, 8.0f);
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            _events.Update(diff);
            _clock.Update(diff);
            while (uint32 tick = _clock.ExecuteEvent())
            {
                if (tick == TK_BREATH)
                {
                    for (Player* p : PlayersInFront(me, BREATH_RANGE, CONE_ARC))
                    {
                        me->CastSpell(p, S(OFF_BREATH_HIT), true);
                        me->CastSpell(p, S(OFF_CORRUPTION), true);
                    }
                    if (--_pulses)
                        _clock.ScheduleEvent(TK_BREATH, 500ms);
                }
                else
                    OwnTick(tick);
            }

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = _events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EV_STRIKE:
                        DoCastVictim(S(OFF_STRIKE), true);
                        _events.ScheduleEvent(EV_STRIKE, 13200ms);
                        break;
                    case EV_CLEAVE:
                        for (Player* p : PlayersInFront(me, 20.0f, CONE_ARC))
                            me->CastSpell(p, S(OFF_CLEAVE), true);
                        _events.ScheduleEvent(EV_CLEAVE, 16900ms);
                        break;
                    case EV_FIERCE:
                        DoCastVictim(S(OFF_FIERCE), true);
                        _events.ScheduleEvent(EV_FIERCE, 24800ms);
                        break;
                    case EV_TAIL:
                        Tail();
                        _events.ScheduleEvent(EV_TAIL, 4s);
                        break;
                    case EV_BREATH:
                        DoCastVictim(S(OFF_BREATH));
                        _events.ScheduleEvent(EV_BREATH, 15s);
                        break;
                    case EV_FOG:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 80.0f, true))
                        {
                            _fogTarget = target->GetGUID();
                            DoCast(target, S(OFF_FOG));
                        }
                        _events.ScheduleEvent(EV_FOG, 30s);
                        break;
                    case EV_SECOND:
                        Second();
                        _events.ScheduleEvent(EV_SECOND, 1s);
                        break;
                    default:
                        Own(eventId);
                        break;
                }
                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            if (!me->HasAura(SPELL_BANISHED))
                DoMeleeAttackIfReady();
        }

    protected:
        uint32 _block;
        EventMap _events;
        EventMap _clock;
        uint8 _stage = 1;
        uint8 _pulses = 0;
        ObjectGuid _fogTarget;
        ObjectGuid _target;
        GuidVector _fogs;
        std::set<ObjectGuid> _sleepers;
    };

    // ---- Ysondre -------------------------------------------------------------

    struct boss_ysondre_coa : public emerald_dragon_coa
    {
        boss_ysondre_coa(Creature* creature) : emerald_dragon_coa(creature, 2119400) { }

        void ScheduleOwn() override { _events.ScheduleEvent(EV_OWN_1, 12s); }

        void Own(uint32 eventId) override
        {
            if (eventId != EV_OWN_1)
                return;
            if (Unit* target = me->GetVictim())
            {
                _target = target->GetGUID();
                DoCast(target, SPELL_LIGHTNING_WAVE);
            }
            _events.ScheduleEvent(EV_OWN_1, 12s);
        }

        void Nightmare() override { DoCastSelf(SPELL_AWAKEN_SLEEPERS); }

        void OnSpellCast(SpellInfo const* spell) override
        {
            emerald_dragon_coa::OnSpellCast(spell);
            if (spell->Id == SPELL_AWAKEN_SLEEPERS)
            {
                // From stock: one spirit for every two players, at most 15.
                size_t const raid = Players(me, [this](Player* x) { return me->IsWithinDist(x, 100.0f); }).size();
                uint8 const count = uint8(std::clamp<size_t>(raid / 2, 1, 15));
                for (uint8 i = 0; i < count; ++i)
                    DoCastSelf(SPELL_SUMMON_DRUIDS, true);
            }
            else if (spell->Id == SPELL_LIGHTNING_WAVE)
            {
                Player* current = ObjectAccessor::GetPlayer(*me, _target);
                float amount = float(Info(me, SPELL_LIGHTNING_WAVE, 1));
                std::vector<Player*> hit;
                for (uint8 i = 0; current && i < 5; ++i)
                {
                    Hit(me, current, SPELL_LIGHTNING_WAVE_HIT, int32(amount));
                    hit.push_back(current);
                    amount *= 1.2f;
                    current = NextInChain(me, current, 10.0f, hit);
                }
            }
        }
    };

    // Ysondre's demented druid spirits.
    struct npc_ysondre_druid_coa : public ScriptedAI
    {
        npc_ysondre_druid_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override { _events.Reset(); }

        void JustEngagedWith(Unit* /*who*/) override
        {
            _events.ScheduleEvent(1, 2s);
            _events.ScheduleEvent(2, 8s);
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;
            _events.Update(diff);
            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;
            while (uint32 id = _events.ExecuteEvent())
            {
                if (id == 1)
                {
                    if (Unit* t = SelectTarget(SelectTargetMethod::Random, 0, 40.0f, true))
                        DoCast(t, SPELL_DREAMFIRE);
                    _events.ScheduleEvent(1, 6s);
                }
                else if (id == 2)
                {
                    if (Unit* t = SelectTarget(SelectTargetMethod::Random, 0, [](Unit* u) { return u->IsPlayer() && u->getPowerType() == POWER_MANA; }))
                        DoCast(t, SPELL_SILENCE);
                    _events.ScheduleEvent(2, 15s);
                }
                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }
            DoMeleeAttackIfReady();
        }

    private:
        EventMap _events;
    };

    // ---- Taerar --------------------------------------------------------------

    struct boss_taerar_coa : public emerald_dragon_coa
    {
        boss_taerar_coa(Creature* creature) : emerald_dragon_coa(creature, 2119500) { }

        void Reset() override
        {
            emerald_dragon_coa::Reset();
            Unbanish();
            _shades = 0;
        }

        void ScheduleOwn() override
        {
            _events.ScheduleEvent(EV_OWN_1, 10s);
            _events.ScheduleEvent(EV_OWN_2, 30s);
        }

        void Own(uint32 eventId) override
        {
            if (me->HasAura(SPELL_BANISHED))
            {
                _events.ScheduleEvent(eventId, 2s);
                return;
            }
            if (eventId == EV_OWN_1)
            {
                if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 60.0f, true))
                {
                    _target = target->GetGUID();
                    DoCast(target, SPELL_ARCANE_SHOCK);
                }
                _events.ScheduleEvent(EV_OWN_1, 10s);
            }
            else if (eventId == EV_OWN_2)
            {
                DoCastSelf(SPELL_BELLOWING_ROAR);
                _events.ScheduleEvent(EV_OWN_2, 30s);
            }
            else if (eventId == EV_OWN_3)
                Unbanish();
        }

        void Nightmare() override { DoCastSelf(SPELL_SPLIT); }

        void OnSpellCast(SpellInfo const* spell) override
        {
            emerald_dragon_coa::OnSpellCast(spell);
            switch (spell->Id)
            {
                case SPELL_ARCANE_SHOCK:
                    if (Unit* target = ObjectAccessor::GetUnit(*me, _target))
                        me->CastSpell(target, SPELL_ARCANE_SHOCK_HIT, true);
                    break;
                case SPELL_BELLOWING_ROAR:
                    DoCastSelf(SPELL_BELLOWING_FEAR, true);
                    break;
                case SPELL_SPLIT:
                    _shades = 3;
                    for (uint32 summon : { SPELL_SUMMON_SHADE_1, SPELL_SUMMON_SHADE_2, SPELL_SUMMON_SHADE_3 })
                        DoCastSelf(summon, true);
                    me->AddAura(SPELL_BANISHED, me);
                    me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
                    me->AttackStop();
                    me->SetReactState(REACT_PASSIVE);
                    _events.ScheduleEvent(EV_OWN_3, 60s);
                    break;
                default:
                    break;
            }
        }

        void JustSummoned(Creature* summon) override
        {
            if (summon->GetEntry() == NPC_SHADE_OF_TAERAR)
                summon->SetInCombatWithZone();
        }

        void SummonedCreatureDies(Creature* summon, Unit* /*killer*/) override
        {
            if (summon->GetEntry() == NPC_SHADE_OF_TAERAR && _shades && !--_shades)
                Unbanish();
        }

        void Unbanish()
        {
            _events.CancelEvent(EV_OWN_3);
            me->RemoveAurasDueToSpell(SPELL_BANISHED);
            me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
            me->SetReactState(REACT_AGGRESSIVE);
        }

    private:
        uint8 _shades = 0;
    };

    // Taerar's shades: acid and toxic clouds.
    struct npc_taerar_shade_coa : public ScriptedAI
    {
        npc_taerar_shade_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override { _events.Reset(); }

        void JustEngagedWith(Unit* /*who*/) override
        {
            _events.ScheduleEvent(1, 6s);
            _events.ScheduleEvent(2, 10s);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_ACID_BREATH)
                return;
            for (Player* p : PlayersInFront(me, BREATH_RANGE, CONE_ARC))
            {
                me->CastSpell(p, SPELL_ACID_BREATH_HIT, true);
                AddStack(me, p, SPELL_ACID_BREATH_DOT);
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;
            _events.Update(diff);
            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;
            while (uint32 id = _events.ExecuteEvent())
            {
                if (id == 1)
                {
                    DoCastVictim(SPELL_ACID_BREATH);
                    _events.ScheduleEvent(1, 12s);
                }
                else if (id == 2)
                {
                    if (Unit* t = SelectTarget(SelectTargetMethod::Random, 0, 40.0f, true))
                        if (Creature* spot = me->SummonCreature(NPC_WORLD_TRIGGER, t->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, 10000))
                        {
                            spot->SetFaction(me->GetFaction());
                            spot->CastSpell(spot, SPELL_TOXIC_CLOUD, true, nullptr, nullptr, me->GetGUID());
                        }
                    _events.ScheduleEvent(2, 15s);
                }
                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }
            DoMeleeAttackIfReady();
        }

    private:
        EventMap _events;
    };

    // ---- Lethon --------------------------------------------------------------

    struct boss_lethon_coa : public emerald_dragon_coa
    {
        boss_lethon_coa(Creature* creature) : emerald_dragon_coa(creature, 2119600) { }

        void ScheduleOwn() override { _events.ScheduleEvent(EV_OWN_1, 20s); }

        void Own(uint32 eventId) override
        {
            if (eventId != EV_OWN_1)
                return;
            DoCastSelf(SPELL_SEEKING_BOLTS);
            _events.ScheduleEvent(EV_OWN_1, 20s);
        }

        void Nightmare() override { DoCastSelf(SPELL_DREAM_EATER); }

        void OnSpellCast(SpellInfo const* spell) override
        {
            emerald_dragon_coa::OnSpellCast(spell);
            if (spell->Id == SPELL_SEEKING_BOLTS)
            {
                _left = roll_chance_i(50);
                _volleys = 5;
                _clock.ScheduleEvent(TK_BOLTS, 0ms);
            }
            else if (spell->Id == SPELL_DREAM_EATER)
            {
                // A shade from every player walks to him (stock Spirit Shade: it heals him on arrival).
                for (Player* p : Players(me, [this](Player* x) { return me->IsWithinDist(x, 100.0f); }))
                    me->SummonCreature(NPC_SPIRIT_SHADE, p->GetPosition(), TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT, 50000);
            }
        }

        // Five volleys at everyone on one side of him.
        void OwnTick(uint32 tick) override
        {
            if (tick != TK_BOLTS)
                return;
            for (Player* p : Players(me, [this](Player* x) { return me->IsWithinDist(x, 100.0f); }))
            {
                float const rel = Position::NormalizeOrientation(me->GetAngle(p) - me->GetOrientation());
                bool const left = rel > 0.0f && rel < float(M_PI);
                if (left == _left)
                    me->CastSpell(p, SPELL_SEEKING_BOLT_HIT, true);
            }
            if (--_volleys)
                _clock.ScheduleEvent(TK_BOLTS, 1s);
        }

    private:
        bool _left = true;
        uint8 _volleys = 0;
    };

    // ---- Emeriss -------------------------------------------------------------

    struct boss_emeriss_coa : public emerald_dragon_coa
    {
        boss_emeriss_coa(Creature* creature) : emerald_dragon_coa(creature, 2119700) { }

        void ScheduleOwn() override { _events.ScheduleEvent(EV_OWN_1, 12s); }

        void Own(uint32 eventId) override
        {
            if (eventId != EV_OWN_1)
                return;
            if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 60.0f, true))
            {
                _target = target->GetGUID();
                DoCast(target, SPELL_VOLATILE_INFECTION);
            }
            _events.ScheduleEvent(EV_OWN_1, 30s);
        }

        void Nightmare() override { DoCastSelf(SPELL_CORRUPTION_EARTH); }

        void OnSpellCast(SpellInfo const* spell) override
        {
            emerald_dragon_coa::OnSpellCast(spell);
            if (spell->Id == SPELL_VOLATILE_INFECTION)
            {
                if (Unit* target = ObjectAccessor::GetUnit(*me, _target))
                    for (Player* p : Players(me, [&](Player* x) { return target->IsWithinDist(x, 8.0f); }))
                        me->AddAura(SPELL_VOLATILE_AURA, p);
            }
            else if (spell->Id == SPELL_CORRUPTION_EARTH)
            {
                for (Player* p : PlayersWithin(me, 100.0f))
                    me->AddAura(SPELL_CORRUPTION_AURA, p);
                _corruptionTicks = 5;
                _clock.ScheduleEvent(TK_CORRUPTION, 2s);
            }
        }

        // 20% of maximum health every 2 seconds, five times.
        void OwnTick(uint32 tick) override
        {
            if (tick != TK_CORRUPTION)
                return;
            for (Player* p : Players(me, [](Player* x) { return x->HasAura(SPELL_CORRUPTION_AURA); }))
                SpellDamage(me, p, SPELL_CORRUPTION_HIT, p->CountPctFromMaxHealth(20), SPELL_SCHOOL_MASK_SHADOW);
            if (--_corruptionTicks)
                _clock.ScheduleEvent(TK_CORRUPTION, 2s);
        }

        // Whoever dies grows a Putrid Mushroom.
        void KilledUnit(Unit* victim) override
        {
            emerald_dragon_coa::KilledUnit(victim);
            if (!victim->IsPlayer())
                return;
            if (Creature* spot = me->SummonCreature(NPC_WORLD_TRIGGER, victim->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, 180000))
            {
                spot->SetFaction(me->GetFaction());
                spot->CastSpell(spot, SPELL_SPORE_BURST, true, nullptr, nullptr, me->GetGUID());
                spot->CastSpell(spot, SPELL_SPORE_CLOUD, true, nullptr, nullptr, me->GetGUID());
            }
        }

    private:
        uint8 _corruptionTicks = 0;
    };

    template <class AI>
    class dragon_script : public CreatureScript
    {
    public:
        explicit dragon_script(char const* name) : CreatureScript(name) { }
        CreatureAI* GetAI(Creature* creature) const override { return new AI(creature); }
    };
}

void AddCoaEmeraldDragonScripts()
{
    new dragon_script<boss_ysondre_coa>("boss_ysondre_coa");
    new dragon_script<boss_taerar_coa>("boss_taerar_coa");
    new dragon_script<boss_lethon_coa>("boss_lethon_coa");
    new dragon_script<boss_emeriss_coa>("boss_emeriss_coa");
    new dragon_script<npc_ysondre_druid_coa>("npc_ysondre_druid_coa");
    new dragon_script<npc_taerar_shade_coa>("npc_taerar_shade_coa");
}
