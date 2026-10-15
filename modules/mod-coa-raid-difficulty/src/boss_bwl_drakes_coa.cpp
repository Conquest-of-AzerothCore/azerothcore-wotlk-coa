/*
 * Firemaw, Ebonroc and Flamegor with Ascension's spells.
 *
 * No combat logs exist for Blackwing Lair, so these fights are designed. The
 * three share one block of the DBC (2110800-2110868), and Ascension tied them
 * together: Stress grows on a drake once one of his brothers has died, so the
 * longer the last ones take, the harder they hit.
 *
 * Shared, every drake:
 *   Draconic Cleave  every 8s    1.5s cast, 150% weapon in a 20-yard cone
 *   Tail Sweep       every 20s   100% weapon behind him, knockback
 *   Fierce Blow      every 8.5s  on the tank
 *   Stress           +1 stack every 5s per dead brother, up to 200
 *
 * Firemaw:
 *   Scorching Breath every 15s   six pulses over 3s in a cone, then Scorched
 *   Flame Buffet     every 10s   everyone he can see; +5% fire damage taken per
 *                                stack for 60s. Hiding behind a pillar still
 *                                works, as in the original -
 *   Coward           every 5s    - but anyone further than 45 yards away is
 *                                marked a coward, one stack each time.
 * Ebonroc:
 *   Dark Breath      every 15s   as Scorching Breath, shadow
 *   Shadow of Ebonroc every 30s  on the tank for 20s; his hits on the marked
 *                                target heal him for the damage done
 * Flamegor:
 *   Combustion       every 25s   on a random player other than the tank: a
 *                                living bomb for 8s. However it ends, it
 *                                explodes on everyone nearby and throws them up.
 *   Reckless Assault every 30s   10s of +200% attack speed and +50% damage taken
 *   Hot Temper       always      immune to taunt
 *
 * All timings were agreed with the raid designer; the effects are what the
 * DBC describes. Damage per difficulty comes from SpellDifficulty.dbc.
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
#include "../../../src/server/scripts/EasternKingdoms/BlackrockMountain/BlackwingLair/blackwing_lair.h"

#include <algorithm>
#include <functional>
#include <set>
#include <vector>

namespace
{
    enum Spells
    {
        SPELL_FIERCE_BLOW           = 975011,
        SPELL_STRESS                = 2110801,
        SPELL_DRACONIC_CLEAVE_CAST  = 2110802,
        SPELL_DRACONIC_CLEAVE       = 2110803,
        SPELL_TAIL_SWEEP_HIT        = 2110805,

        SPELL_SCORCHING_BREATH_CAST = 2110807,
        SPELL_SCORCHING_BREATH      = 2110809,  // first of a tier row
        SPELL_SCORCHED              = 2110813,  // first of a tier row
        SPELL_FLAME_BUFFET_CAST     = 2110818,
        SPELL_FLAME_BUFFET_DEBUFF   = 2110819,  // first of a tier row
        SPELL_FLAME_BUFFET          = 2110823,  // first of a tier row
        SPELL_COWARD                = 2180131,

        SPELL_DARK_BREATH_CAST      = 2110830,
        SPELL_DARK_BREATH           = 2110832,  // first of a tier row
        SPELL_SHADOW_OF_EBONROC     = 2110837,  // first of a tier row
        SPELL_SHADOW_OF_EBONROC_HEAL= 2110841,

        SPELL_HOT_TEMPER            = 2110855,
        SPELL_RECKLESS_ASSAULT      = 2110856,
        SPELL_COMBUSTION_CAST       = 2110857,
        SPELL_COMBUSTION            = 2110858,  // first of a tier row
        SPELL_COMBUSTION_EXPLOSION  = 2110864,  // first of a tier row
        SPELL_COMBUSTION_KNOCK_UP   = 2110868,
    };

    enum Events
    {
        EVENT_FIERCE_BLOW = 1,
        EVENT_CLEAVE,
        EVENT_TAIL_SWEEP,
        EVENT_STRESS,
        EVENT_BREATH,
        EVENT_FLAME_BUFFET,
        EVENT_COWARD,
        EVENT_SHADOW,
        EVENT_COMBUSTION,
        EVENT_RECKLESS,

        EVENT_BREATH_PULSE,
        EVENT_WATCH,
    };

    constexpr float CONE_ARC            = float(M_PI) / 2;
    constexpr float CLEAVE_RANGE        = 20.0f;
    constexpr float BREATH_RANGE        = 20.0f;
    constexpr float TAIL_RANGE          = 30.0f;
    constexpr float FLAME_BUFFET_RANGE  = 200.0f;
    constexpr float COWARD_DISTANCE     = 45.0f;
    constexpr float COMBUSTION_RADIUS   = 8.0f;
    constexpr uint8 BREATH_PULSES       = 6;
    constexpr int32 STRESS_MAX          = 200;
    constexpr int32 COWARD_MAX          = 9;
    constexpr int32 FLAME_BUFFET_MAX    = 100;

    // Sets an aura's stack count and refreshes it; adds the aura when missing,
    // removes it at zero. Many of these spells carry no stack limit in the DBC
    // and would otherwise just refresh.
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
            aura->SetStackAmount(uint8(std::min<int32>(stacks, 255)));
            aura->RefreshDuration();
        }
    }

    int32 Stacks(Unit* caster, Unit* target, uint32 spellId)
    {
        Aura* aura = target->GetAura(sSpellMgr->GetSpellIdForDifficulty(spellId, caster));
        return aura ? aura->GetStackAmount() : 0;
    }

    // What all three share.
    struct bwl_drake_coa : public BossAI
    {
        bwl_drake_coa(Creature* creature, uint32 bossId, uint32 breathCast)
            : BossAI(creature, bossId), _drakeId(bossId), _breathCast(breathCast) { }

        void Reset() override
        {
            BossAI::Reset();
            _clock.Reset();
            _stress = 0;
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            events.ScheduleEvent(EVENT_FIERCE_BLOW, 6s);
            events.ScheduleEvent(EVENT_CLEAVE, 8s);
            events.ScheduleEvent(EVENT_BREATH, 15s);
            events.ScheduleEvent(EVENT_TAIL_SWEEP, 20s);
            // Stress runs on its own clock, so a cast bar cannot hold it up.
            _clock.ScheduleEvent(EVENT_STRESS, 5s);
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

        uint32 DeadBrothers() const
        {
            uint32 dead = 0;
            for (uint32 id : { DATA_FIREMAW, DATA_EBONROC, DATA_FLAMEGOR })
                if (id != _drakeId && instance->GetBossState(id) == DONE)
                    ++dead;
            return dead;
        }

        // Breath pulses: damage, and for the fire breath the burn after it.
        virtual void BreathPulseHit(Player* player) = 0;

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            if (spell->Id == SPELL_DRACONIC_CLEAVE_CAST)
            {
                for (Player* p : Players([&](Player* x) { return me->IsWithinDistInMap(x, CLEAVE_RANGE) && me->isInFront(x, CONE_ARC); }))
                    me->CastSpell(p, SPELL_DRACONIC_CLEAVE, true);
            }
            else if (spell->Id == _breathCast)
            {
                _pulses = BREATH_PULSES;
                _clock.ScheduleEvent(EVENT_BREATH_PULSE, 0ms);
            }
        }

        void TailSweep()
        {
            for (Player* p : Players([&](Player* x) { return me->IsWithinDistInMap(x, TAIL_RANGE) && !me->isInFront(x, float(M_PI) * 1.5f); }))
            {
                me->CastSpell(p, SPELL_TAIL_SWEEP_HIT, true);
                p->KnockbackFrom(me->GetPositionX(), me->GetPositionY(), 15.0f, 7.0f);
            }
        }

        // Per-drake events; return false for events the drake does not own.
        virtual bool ExecuteOwn(uint32 /*eventId*/) { return false; }
        virtual void OnClock(uint32 /*eventId*/) { }

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
                    case EVENT_STRESS:
                        if (uint32 dead = DeadBrothers())
                        {
                            _stress = std::min<int32>(_stress + int32(dead), STRESS_MAX);
                            SetStacks(me, me, SPELL_STRESS, _stress, STRESS_MAX);
                        }
                        _clock.ScheduleEvent(EVENT_STRESS, 5s);
                        break;
                    case EVENT_BREATH_PULSE:
                        for (Player* p : Players([&](Player* x) { return me->IsWithinDistInMap(x, BREATH_RANGE) && me->isInFront(x, CONE_ARC); }))
                            BreathPulseHit(p);
                        if (--_pulses)
                            _clock.ScheduleEvent(EVENT_BREATH_PULSE, 500ms);
                        break;
                    default:
                        OnClock(tick);
                        break;
                }
            }

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_FIERCE_BLOW:
                        DoCastVictim(SPELL_FIERCE_BLOW);
                        events.ScheduleEvent(EVENT_FIERCE_BLOW, 8500ms);
                        break;
                    case EVENT_CLEAVE:
                        DoCastVictim(SPELL_DRACONIC_CLEAVE_CAST);
                        events.ScheduleEvent(EVENT_CLEAVE, 8s);
                        break;
                    case EVENT_TAIL_SWEEP:
                        TailSweep();
                        events.ScheduleEvent(EVENT_TAIL_SWEEP, 20s);
                        break;
                    case EVENT_BREATH:
                        DoCastVictim(_breathCast);
                        events.ScheduleEvent(EVENT_BREATH, 15s);
                        break;
                    default:
                        ExecuteOwn(eventId);
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    protected:
        EventMap _clock;    // stress, breath pulses and per-drake watchers

    private:
        uint32 _drakeId;
        uint32 _breathCast;
        uint8 _pulses = 0;
        int32 _stress = 0;
    };

    struct boss_firemaw_coa : public bwl_drake_coa
    {
        boss_firemaw_coa(Creature* creature) : bwl_drake_coa(creature, DATA_FIREMAW, SPELL_SCORCHING_BREATH_CAST) { }

        void JustEngagedWith(Unit* who) override
        {
            bwl_drake_coa::JustEngagedWith(who);
            events.ScheduleEvent(EVENT_FLAME_BUFFET, 10s);
            _clock.ScheduleEvent(EVENT_COWARD, 5s);
        }


        void BreathPulseHit(Player* player) override
        {
            me->CastSpell(player, SPELL_SCORCHING_BREATH, true);
            me->CastSpell(player, SPELL_SCORCHED, true);
        }

        // Everyone he can see. The pillar still protects.
        void FlameBuffet()
        {
            for (Player* p : Players([&](Player* x) { return me->IsWithinDistInMap(x, FLAME_BUFFET_RANGE) && me->IsWithinLOSInMap(x); }))
            {
                int32 const before = Stacks(me, p, SPELL_FLAME_BUFFET_DEBUFF);
                me->CastSpell(p, SPELL_FLAME_BUFFET, true);
                // Set explicitly: the Normal variant forgets to apply the
                // debuff at all, and the others would only refresh it.
                SetStacks(me, p, SPELL_FLAME_BUFFET_DEBUFF, before + 1, FLAME_BUFFET_MAX);
            }
        }

        bool ExecuteOwn(uint32 eventId) override
        {
            if (eventId != EVENT_FLAME_BUFFET)
                return false;
            FlameBuffet();
            events.ScheduleEvent(EVENT_FLAME_BUFFET, 10s);
            return true;
        }

        void OnClock(uint32 eventId) override
        {
            if (eventId != EVENT_COWARD)
                return;
            for (Player* p : Players([&](Player* x) { return !me->IsWithinDistInMap(x, COWARD_DISTANCE); }))
                SetStacks(me, p, SPELL_COWARD, Stacks(me, p, SPELL_COWARD) + 1, COWARD_MAX);
            _clock.ScheduleEvent(EVENT_COWARD, 5s);
        }
    };

    struct boss_ebonroc_coa : public bwl_drake_coa
    {
        boss_ebonroc_coa(Creature* creature) : bwl_drake_coa(creature, DATA_EBONROC, SPELL_DARK_BREATH_CAST) { }

        // Stock: the patrol wanders about for a while at its last waypoint.
        void MovementInform(uint32 type, uint32 id) override
        {
            if (type != WAYPOINT_MOTION_TYPE || id != 13)
                return;

            me->GetMotionMaster()->MoveRandom(10.f);
            me->m_Events.AddEventAtOffset([this]()
            {
                me->GetMotionMaster()->Initialize();
            }, 15s);
        }

        void JustEngagedWith(Unit* who) override
        {
            bwl_drake_coa::JustEngagedWith(who);
            events.ScheduleEvent(EVENT_SHADOW, 30s);
        }


        void BreathPulseHit(Player* player) override
        {
            me->CastSpell(player, SPELL_DARK_BREATH, true);
        }

        // Hits on the marked target heal him for the damage done.
        void DamageDealt(Unit* victim, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            bwl_drake_coa::DamageDealt(victim, damage, type, school);
            if (!damage || !victim)
                return;
            if (!victim->HasAura(sSpellMgr->GetSpellIdForDifficulty(SPELL_SHADOW_OF_EBONROC, me)))
                return;

            int32 heal = int32(damage);
            me->CastCustomSpell(me, SPELL_SHADOW_OF_EBONROC_HEAL, &heal, nullptr, nullptr, true);
        }

        bool ExecuteOwn(uint32 eventId) override
        {
            if (eventId != EVENT_SHADOW)
                return false;
            DoCastVictim(SPELL_SHADOW_OF_EBONROC);
            events.ScheduleEvent(EVENT_SHADOW, 30s);
            return true;
        }
    };

    struct boss_flamegor_coa : public bwl_drake_coa
    {
        boss_flamegor_coa(Creature* creature) : bwl_drake_coa(creature, DATA_FLAMEGOR, SPELL_SCORCHING_BREATH_CAST) { }

        void Reset() override
        {
            bwl_drake_coa::Reset();
            _bombs.clear();
            _combustionTarget.Clear();
            ApplyHotTemper();
        }

        void ApplyHotTemper()
        {
            DoCastSelf(SPELL_HOT_TEMPER, true);
            me->ApplySpellImmune(0, IMMUNITY_EFFECT, SPELL_EFFECT_ATTACK_ME, true);
            me->ApplySpellImmune(0, IMMUNITY_STATE, SPELL_AURA_MOD_TAUNT, true);
        }

        void JustEngagedWith(Unit* who) override
        {
            bwl_drake_coa::JustEngagedWith(who);
            events.ScheduleEvent(EVENT_COMBUSTION, 25s);
            events.ScheduleEvent(EVENT_RECKLESS, 30s);
            _clock.ScheduleEvent(EVENT_WATCH, 250ms);
        }


        void BreathPulseHit(Player* player) override
        {
            me->CastSpell(player, SPELL_SCORCHING_BREATH, true);
            me->CastSpell(player, SPELL_SCORCHED, true);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            bwl_drake_coa::OnSpellCast(spell);
            if (spell->Id != SPELL_COMBUSTION_CAST)
                return;

            if (Player* target = ObjectAccessor::GetPlayer(*me, _combustionTarget))
            {
                me->CastSpell(target, SPELL_COMBUSTION, true);
                _bombs.insert(target->GetGUID());
            }
            _combustionTarget.Clear();
        }

        // "If this effect is removed by any means, you explode."
        void OnClock(uint32 eventId) override
        {
            if (eventId != EVENT_WATCH)
                return;

            uint32 const bomb = sSpellMgr->GetSpellIdForDifficulty(SPELL_COMBUSTION, me);
            for (auto it = _bombs.begin(); it != _bombs.end();)
            {
                Player* player = ObjectAccessor::GetPlayer(*me, *it);
                if (player && player->HasAura(bomb))
                {
                    ++it;
                    continue;
                }
                if (player)
                    for (Player* p : Players([&](Player* x) { return x == player || x->IsWithinDistInMap(player, COMBUSTION_RADIUS); }))
                    {
                        me->CastSpell(p, SPELL_COMBUSTION_EXPLOSION, true);
                        me->CastSpell(p, SPELL_COMBUSTION_KNOCK_UP, true);
                    }
                it = _bombs.erase(it);
            }
            _clock.ScheduleEvent(EVENT_WATCH, 250ms);
        }

        bool ExecuteOwn(uint32 eventId) override
        {
            switch (eventId)
            {
                case EVENT_COMBUSTION:
                    if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 0.0f, true, false))
                    {
                        _combustionTarget = target->GetGUID();
                        DoCast(target, SPELL_COMBUSTION_CAST);
                    }
                    events.ScheduleEvent(EVENT_COMBUSTION, 25s);
                    return true;
                case EVENT_RECKLESS:
                    DoCastSelf(SPELL_RECKLESS_ASSAULT, true);
                    events.ScheduleEvent(EVENT_RECKLESS, 30s);
                    return true;
                default:
                    return false;
            }
        }

    private:
        std::set<ObjectGuid> _bombs;
        ObjectGuid _combustionTarget;
    };
}

void AddCoaDrakeScripts()
{
    RegisterBlackwingLairCreatureAI(boss_firemaw_coa);
    RegisterBlackwingLairCreatureAI(boss_ebonroc_coa);
    RegisterBlackwingLairCreatureAI(boss_flamegor_coa);
}
