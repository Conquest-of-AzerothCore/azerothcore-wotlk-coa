/*
 * Moam as Ascension rebuilt him.
 *
 * Kit: Ascension's block 2112600-2112626. No logs or video exist for
 * Ahn'Qiraj; every timer and threshold here is designed.
 *
 * Ancient Living Stone: Moam lives on mana, and the fight is his mana bar.
 *
 *   Mana Flows      20-80% mana   he condenses 1% of his mana from the ruins
 *                                 every 2s
 *   Mana Starved    below 20%     condenses 2% every 2s and drains everyone
 *   Mana Surge      above 80%     the same, greedily
 *                   Drain Mana: every second, 5% of each player's current mana
 *                   within 40 yards, at most 1% of his own maximum each
 *   Mana Meltdown   at full mana  10s cast: Arcane damage to everyone within
 *                                 100 yards, less the further away, and the
 *                                 same amount of mana given to them. His mana
 *                                 is gone.
 *   Lifeless Stone  at 0 mana     20s as stone (99% less damage, no action);
 *                                 three Mana Fiends rise, and whatever mana
 *                                 they still hold merges back into him when
 *                                 he wakes (Mana Merge)
 *
 *   Arcane Barrage     first 6s,  every 6s    random player
 *   Arcane Explosion   first 15s, every 15s   4s cast, 15 yards around him
 *   Mana Leak          first 20s, every 20s   he burns 10% of his current
 *                                            mana: that much Arcane damage split
 *                                            over the raid, and mana for them
 *
 * Mana burn and drain on him work as they always did, and are how a raid keeps
 * him away from a meltdown.
 *
 * Decided here, not in the data: every timer, the 20/80% thresholds, 10% for
 * Mana Leak, a meltdown worth 10% of his maximum mana per player at the centre,
 * 20s of stone, waking on at least 10% mana, and starting the fight at half
 * mana.
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
    enum Texts
    {
        EMOTE_AGGRO       = 0,
        EMOTE_MANA_FULL   = 1,
        EMOTE_STONE_PHASE = 2
    };

    enum Spells
    {
        SPELL_SUMMON_MANA_FIENDS   = 25684,
        SPELL_LARGE_OBSIDIAN_CHUNK = 27630,

        SPELL_LIVING_STONE    = 2112600,
        SPELL_MANA_STARVED    = 2112601,
        SPELL_MANA_FLOWS      = 2112602,
        SPELL_MANA_SURGE      = 2112603,
        SPELL_DRAIN_MANA      = 2112610,
        SPELL_MANA_MELTDOWN   = 2112612,
        SPELL_MELTDOWN_HIT    = 2112613,
        SPELL_MELTDOWN_MANA   = 2112614,
        SPELL_LIFELESS_STONE  = 2112615,
        SPELL_MANA_MERGE      = 2112616,
        SPELL_ARCANE_BARRAGE  = 2112617,
        SPELL_ARCANE_EXPLOSION = 2112621,
        SPELL_MANA_LEAK_HIT   = 2112625,
        SPELL_MANA_LEAK_MANA  = 2112626,
    };

    enum Events
    {
        EVENT_TICK = 1,
        EVENT_DRAIN,
        EVENT_BARRAGE,
        EVENT_EXPLOSION,
        EVENT_LEAK,
        EVENT_WAKE,
    };

    enum Misc
    {
        NPC_MANA_FIEND = 15527
    };

    constexpr uint32 LOW_PCT        = 20;
    constexpr uint32 HIGH_PCT       = 80;
    constexpr uint32 LEAK_PCT       = 10;
    constexpr uint32 MELTDOWN_PCT   = 10;
    constexpr float DRAIN_RANGE     = 40.0f;
    constexpr float MELTDOWN_RANGE  = 100.0f;

    struct boss_moam_coa : public BossAI
    {
        boss_moam_coa(Creature* creature) : BossAI(creature, DATA_MOAM) { }

        void InitializeAI() override
        {
            me->m_CombatDistance = 50.0f;
            BossAI::InitializeAI();
        }

        void Reset() override
        {
            BossAI::Reset();
            me->SetRegeneratingPower(false);
            me->SetPower(POWER_MANA, me->GetMaxPower(POWER_MANA) / 2);
            for (uint32 s : { SPELL_MANA_STARVED, SPELL_MANA_FLOWS, SPELL_MANA_SURGE, SPELL_LIFELESS_STONE })
                me->RemoveAurasDueToSpell(s);
            me->AddAura(SPELL_LIVING_STONE, me);
            _stone = false;
            _melting = false;
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            Talk(EMOTE_AGGRO);
            events.ScheduleEvent(EVENT_TICK, 2s);
            events.ScheduleEvent(EVENT_DRAIN, 1s);
            events.ScheduleEvent(EVENT_BARRAGE, 6s);
            events.ScheduleEvent(EVENT_EXPLOSION, 15s);
            events.ScheduleEvent(EVENT_LEAK, 20s);
        }

        void JustDied(Unit* killer) override
        {
            BossAI::JustDied(killer);
            DoCastAOE(SPELL_LARGE_OBSIDIAN_CHUNK, true);
        }

        uint32 ManaPct() const
        {
            uint32 const max = me->GetMaxPower(POWER_MANA);
            return max ? me->GetPower(POWER_MANA) * 100 / max : 0;
        }

        void SetState()
        {
            uint32 const pct = ManaPct();
            uint32 const state = pct < LOW_PCT ? SPELL_MANA_STARVED : pct > HIGH_PCT ? SPELL_MANA_SURGE : SPELL_MANA_FLOWS;
            for (uint32 s : { SPELL_MANA_STARVED, SPELL_MANA_FLOWS, SPELL_MANA_SURGE })
                if (s != state)
                    me->RemoveAurasDueToSpell(s);
            if (!me->HasAura(state))
                me->AddAura(state, me);
        }

        void GainPct(uint32 pct)
        {
            me->ModifyPower(POWER_MANA, int32(me->GetMaxPower(POWER_MANA) * pct / 100));
        }

        // Every second while starved or surging: a bite of every player's mana.
        void Drain()
        {
            if (!me->HasAura(SPELL_MANA_STARVED) && !me->HasAura(SPELL_MANA_SURGE))
                return;
            int32 const cap = int32(me->GetMaxPower(POWER_MANA) / 100);
            for (Player* p : PlayersWithin(me, DRAIN_RANGE))
            {
                if (p->getPowerType() != POWER_MANA || !p->GetPower(POWER_MANA))
                    continue;
                int32 amount = std::min<int32>(p->GetPower(POWER_MANA) * 5 / 100, cap);
                if (amount > 0)
                    me->CastCustomSpell(p, SPELL_DRAIN_MANA, &amount, nullptr, nullptr, true);
            }
        }

        void Meltdown()
        {
            int32 const full = int32(me->GetMaxPower(POWER_MANA) * MELTDOWN_PCT / 100);
            for (Player* p : PlayersWithin(me, MELTDOWN_RANGE))
            {
                int32 amount = int32(full * (1.0f - me->GetDistance(p) / MELTDOWN_RANGE));
                if (amount <= 0)
                    continue;
                Hit(me, p, SPELL_MELTDOWN_HIT, amount);
                if (p->getPowerType() == POWER_MANA)
                    Hit(me, p, SPELL_MELTDOWN_MANA, amount);
            }
            me->SetPower(POWER_MANA, 0);
            _melting = false;
        }

        void Leak()
        {
            int32 const lost = int32(me->GetPower(POWER_MANA) * LEAK_PCT / 100);
            std::vector<Player*> raid = PlayersWithin(me, MELTDOWN_RANGE);
            if (lost <= 0 || raid.empty())
                return;
            me->ModifyPower(POWER_MANA, -lost);
            int32 const share = lost / int32(raid.size());
            for (Player* p : raid)
            {
                Hit(me, p, SPELL_MANA_LEAK_HIT, share);
                if (p->getPowerType() == POWER_MANA)
                    Hit(me, p, SPELL_MANA_LEAK_MANA, share);
            }
        }

        void TurnToStone()
        {
            _stone = true;
            me->InterruptNonMeleeSpells(false);
            Talk(EMOTE_STONE_PHASE);
            me->AddAura(SPELL_LIFELESS_STONE, me);
            DoCastAOE(SPELL_SUMMON_MANA_FIENDS, true);
            events.ScheduleEvent(EVENT_WAKE, 20s);
        }

        // Mana Merge: what the fiends still hold comes back.
        void Wake()
        {
            std::list<Creature*> fiends;
            me->GetCreatureListWithEntryInGrid(fiends, NPC_MANA_FIEND, 150.0f);
            for (Creature* fiend : fiends)
            {
                if (!fiend->IsAlive())
                    continue;
                int32 mana = int32(fiend->GetPower(POWER_MANA));
                if (mana > 0)
                    fiend->CastCustomSpell(me, SPELL_MANA_MERGE, &mana, nullptr, nullptr, true);
                fiend->DespawnOrUnsummon(500ms);
            }
            // With every fiend dead he still wakes on what the ruins gave him.
            if (ManaPct() < LOW_PCT / 2)
                GainPct(LOW_PCT / 2);
            me->RemoveAurasDueToSpell(SPELL_LIFELESS_STONE);
            _stone = false;
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);
            if (spell->Id == SPELL_MANA_MELTDOWN)
                Meltdown();
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            events.Update(diff);

            if (!_stone && !_melting)
            {
                if (me->GetPower(POWER_MANA) >= me->GetMaxPower(POWER_MANA))
                {
                    _melting = true;
                    Talk(EMOTE_MANA_FULL);
                    me->InterruptNonMeleeSpells(false);
                    DoCastSelf(SPELL_MANA_MELTDOWN);
                    return;
                }
                if (!me->GetPower(POWER_MANA))
                {
                    TurnToStone();
                    return;
                }
            }

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_TICK:
                        if (!_stone)
                        {
                            SetState();
                            GainPct(me->HasAura(SPELL_MANA_FLOWS) ? 1 : 2);
                        }
                        events.ScheduleEvent(EVENT_TICK, 2s);
                        break;
                    case EVENT_DRAIN:
                        if (!_stone)
                            Drain();
                        events.ScheduleEvent(EVENT_DRAIN, 1s);
                        break;
                    case EVENT_BARRAGE:
                        if (!_stone)
                            if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                                me->CastSpell(target, SPELL_ARCANE_BARRAGE, true);
                        events.ScheduleEvent(EVENT_BARRAGE, 6s);
                        break;
                    case EVENT_EXPLOSION:
                        if (!_stone)
                            DoCastSelf(SPELL_ARCANE_EXPLOSION);
                        events.ScheduleEvent(EVENT_EXPLOSION, 15s);
                        break;
                    case EVENT_LEAK:
                        if (!_stone)
                            Leak();
                        events.ScheduleEvent(EVENT_LEAK, 20s);
                        break;
                    case EVENT_WAKE:
                        Wake();
                        break;
                    default:
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            if (!_stone)
                DoMeleeAttackIfReady();
        }

    private:
        bool _stone = false;
        bool _melting = false;
    };
}

void AddCoaMoamScripts()
{
    RegisterRuinsOfAhnQirajCreatureAI(boss_moam_coa);
}
