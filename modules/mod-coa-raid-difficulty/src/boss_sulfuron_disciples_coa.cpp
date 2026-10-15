/*
 * Sulfuron Harbinger's three named disciples with Ascension's spells (92031-92033).
 *
 * The 55-pull Mythic/Ascended log corpus for Sulfuron always shows the same four
 * adds next to him, never more, never fewer: one Corvus the Nimble (11662, the
 * stock Flamewaker Priest, already renamed on CoA - rev_20260930_84) plus Cull the
 * Destroyer (92031), Proxima the Opressor (92032) and Ebon the Cruel (92033), one
 * of each. The base game spawns four Flamewaker Priests around Sulfuron (creature
 * rows near map 409, x594-613/y-1177..-1179); the corpus never shows a second
 * Corvus alongside the three named ones, so on Mythic/Ascended three of those four
 * spots are the disciples instead - not four Corvus plus three more adds on top.
 * `coa_boss_summon` (rev_20260930_96) drives the replacement generically from
 * Sulfuron's own entry: each disciple's row despawns the nearest live Flamewaker
 * Priest/Corvus within range and summons at its exact spot (CoaBossAI.cpp). No
 * Normal/Heroic Sulfuron pull exists in the corpus at all, so Corvus's own four
 * spawns there are left exactly as they are - this file and its SQL touch nothing
 * below Mythic.
 *
 * Each disciple's `sub_name` names the MC boss it apes (exiles-kit export):
 * Cull the Destroyer -> "Disciple to Gehennas", Proxima the Opressor -> "Disciple
 * to Shazzrah", Ebon the Cruel -> "Disciple to Lucifron". Each has its own curse
 * and self-heal pair, read from the client's own Spell.dbc effects this session
 * (apps/coa-dbc/coa-dbc-viewer), not assumed from the name:
 *
 *   Cull the Destroyer (Gehennas):
 *     Shadow Bolt - Cull     2105960 dummy -> 2105961 SCHOOL_DAMAGE (placeholder
 *                            base points 1: no "- Damage Info" aura family exists
 *                            for this pair anywhere in Spell.dbc, so - like the
 *                            still-unmapped Harbinger Priest ids 2105950-53
 *                            flagged in docs/coa/molten-core.md SS8 - this hit
 *                            deals its DBC placeholder amount until one is found;
 *                            not invented here).
 *     Cauterize - Cull       2105966, direct SPELL_EFFECT_HEAL (self, real value
 *                            in the DBC, no dummy needed) - the "self-heal" half.
 *     Curse of Gehennas      2105973 dummy -> 2105974 SPELL_AURA_MOD_HEALING_PCT
 *                            -51% (real value) - the "curse" half.
 *
 *   Proxima the Opressor (Shazzrah):
 *     Shadow Bolt - Proxima  2105956 dummy -> 2105957 (same placeholder caveat).
 *     Dampen Magic - Proxima 2105963 dummy -> 2105964 SPELL_AURA_MOD_DAMAGE_
 *                            PERCENT_TAKEN -51%, self - mitigation, not a curse
 *                            on the raid; cadence copied from Shazzrah's own
 *                            measured Dampen Magic (2105607/608, coa_boss_schedule)
 *                            since it is the same named family on the same floor.
 *     Arcane Instability     2105969 dummy -> 2105970 SPELL_AURA_MOD_DAMAGE_
 *                            PERCENT_TAKEN +99%, on a raider - the counter-
 *                            mitigation "curse" half; cadence copied from
 *                            Shazzrah's own measured Arcane Instability
 *                            (2105605/606) for the same reason.
 *
 *   Ebon the Cruel (Lucifron):
 *     Shadow Bolt - Ebon     2105958 dummy -> 2105959 (same placeholder caveat).
 *     Dark Mending - Ebon    2105965, direct SPELL_EFFECT_HEAL (self, real value,
 *                            no dummy) - the "self-heal" half.
 *     Curse of Lucifron      2105971 dummy -> 2105972 SPELL_AURA_MOD_POWER_COST_
 *                            SCHOOL_PCT +99%, on a raider - the "curse" half;
 *                            cadence copied from Lucifron's own measured Curse of
 *                            Lucifron (2105206/207).
 *
 * Rapid Regeneration (804315, shared by all three per the export) is SPELL_EFFECT_
 * HEAL_PCT + SPELL_EFFECT_ENERGIZE_PCT in the DBC, not a periodic aura, and it
 * never appears cast in any of the 5 logged disciple pulls - scheduling a trigger
 * for it (health threshold? passive tick? on-hit proc?) would be invented, so it
 * stays unwired; flagged, not built.
 *
 * No timer evidence exists for any of the six scheduled casts above (every log
 * entry reads "casts: 0" - only the auras they land are counted), so every
 * interval here is designed, anchored on the closest measured sibling: Cull's and
 * Ebon's own cadences copy the stock npc_flamewaker_priest kit they are reskins
 * of (this file's own Dark Strike/Dark Mending/Shadow Word Pain/Immolate
 * cadences, boss_sulfuron_harbinger.cpp), Proxima's copy Shazzrah's measured rows
 * verbatim (real cadences, same spell family). None of this is a new mechanic
 * needing its own SpellDifficulty grouping: the corpus logs the same numeric ids
 * on both Mythic and Ascended pulls for all three disciples, and per the task's
 * own difficulty rule that makes this ordinary damage scaling, not a tier split.
 */

#include "CreatureScript.h"
#include "EventMap.h"
#include "ObjectAccessor.h"
#include "ScriptedCreature.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "../../../src/server/scripts/EasternKingdoms/BlackrockMountain/MoltenCore/molten_core.h"

#include <unordered_map>

namespace
{
    enum DiscipleSpells
    {
        SPELL_CULL_SHADOW_BOLT_DUMMY    = 2105960,
        SPELL_CULL_SHADOW_BOLT_HIT      = 2105961,
        SPELL_CULL_CAUTERIZE            = 2105966,
        SPELL_CULL_CURSE_DUMMY          = 2105973,
        SPELL_CULL_CURSE_EFFECT         = 2105974,

        SPELL_PROXIMA_SHADOW_BOLT_DUMMY = 2105956,
        SPELL_PROXIMA_SHADOW_BOLT_HIT   = 2105957,
        SPELL_PROXIMA_DAMPEN_DUMMY      = 2105963,
        SPELL_PROXIMA_DAMPEN_EFFECT     = 2105964,
        SPELL_PROXIMA_INSTABILITY_DUMMY = 2105969,
        SPELL_PROXIMA_INSTABILITY_EFFECT = 2105970,

        SPELL_EBON_SHADOW_BOLT_DUMMY    = 2105958,
        SPELL_EBON_SHADOW_BOLT_HIT      = 2105959,
        SPELL_EBON_DARK_MENDING         = 2105965,
        SPELL_EBON_CURSE_DUMMY          = 2105971,
        SPELL_EBON_CURSE_EFFECT         = 2105972,

        // Shared, exported on all three; not cast - see the file header.
        SPELL_RAPID_REGENERATION        = 804315,
    };

    // Shared dummy-then-effect chain: the boss casts a dummy, and when it
    // completes this AI casts the spell it stood for at the same target -
    // the same idiom CoaBossAI.cpp and boss_garr_coa.cpp use for the rest of
    // this instance's Ascension casts.
    struct DiscipleAI : public ScriptedAI
    {
        DiscipleAI(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            _events.Reset();
            _pending.clear();
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            ScheduleAbilities();
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            auto it = _pending.find(spell->Id);
            if (it == _pending.end())
                return;

            Pending const pending = it->second;
            _pending.erase(it);

            Unit* target = pending.target.IsEmpty() ? nullptr : ObjectAccessor::GetUnit(*me, pending.target);
            if (!target || !target->IsAlive())
                target = me->GetVictim();
            if (target)
                me->CastSpell(target, pending.effect, true);
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            _events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 const eventId = _events.ExecuteEvent())
            {
                ExecuteAbility(eventId);
                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    protected:
        virtual void ScheduleAbilities() = 0;
        virtual void ExecuteAbility(uint32 eventId) = 0;

        Unit* RandomTarget()
        {
            return SelectTarget(SelectTargetMethod::Random, 0, 0.0f, true, false);
        }

        void CastDummyThenEffect(Unit* target, uint32 dummy, uint32 effect)
        {
            if (!target)
                return;

            uint32 const resolved = sSpellMgr->GetSpellIdForDifficulty(dummy, me);
            _pending[resolved] = { effect, target->GetGUID() };

            if (me->CastSpell(target, dummy, false) != SPELL_CAST_OK)
                _pending.erase(resolved);
        }

        EventMap _events;

    private:
        struct Pending
        {
            uint32 effect;
            ObjectGuid target;
        };

        std::unordered_map<uint32, Pending> _pending;
    };

    struct npc_cull_the_destroyer_coa : public DiscipleAI
    {
        npc_cull_the_destroyer_coa(Creature* creature) : DiscipleAI(creature) { }

    protected:
        void ScheduleAbilities() override
        {
            _events.ScheduleEvent(EVENT_SHADOW_BOLT, 3500ms, 6s);
            _events.ScheduleEvent(EVENT_CAUTERIZE, 15s, 30s);
            _events.ScheduleEvent(EVENT_CURSE, 11s, 14s);
        }

        void ExecuteAbility(uint32 eventId) override
        {
            switch (eventId)
            {
                case EVENT_SHADOW_BOLT:
                    CastDummyThenEffect(RandomTarget(), SPELL_CULL_SHADOW_BOLT_DUMMY, SPELL_CULL_SHADOW_BOLT_HIT);
                    _events.Repeat(5s, 7s);
                    break;
                case EVENT_CAUTERIZE:
                    DoCastSelf(SPELL_CULL_CAUTERIZE);
                    _events.Repeat(15s, 20s);
                    break;
                case EVENT_CURSE:
                    CastDummyThenEffect(RandomTarget(), SPELL_CULL_CURSE_DUMMY, SPELL_CULL_CURSE_EFFECT);
                    _events.Repeat(35s, 45s);
                    break;
            }
        }

    private:
        enum { EVENT_SHADOW_BOLT = 1, EVENT_CAUTERIZE, EVENT_CURSE };
    };

    struct npc_proxima_the_opressor_coa : public DiscipleAI
    {
        npc_proxima_the_opressor_coa(Creature* creature) : DiscipleAI(creature) { }

    protected:
        void ScheduleAbilities() override
        {
            _events.ScheduleEvent(EVENT_SHADOW_BOLT, 3500ms, 6s);
            _events.ScheduleEvent(EVENT_DAMPEN_MAGIC, 14100ms);
            _events.ScheduleEvent(EVENT_ARCANE_INSTABILITY, 18400ms);
        }

        void ExecuteAbility(uint32 eventId) override
        {
            switch (eventId)
            {
                case EVENT_SHADOW_BOLT:
                    CastDummyThenEffect(RandomTarget(), SPELL_PROXIMA_SHADOW_BOLT_DUMMY, SPELL_PROXIMA_SHADOW_BOLT_HIT);
                    _events.Repeat(5s, 7s);
                    break;
                case EVENT_DAMPEN_MAGIC:
                    CastDummyThenEffect(me, SPELL_PROXIMA_DAMPEN_DUMMY, SPELL_PROXIMA_DAMPEN_EFFECT);
                    _events.Repeat(30200ms);
                    break;
                case EVENT_ARCANE_INSTABILITY:
                    CastDummyThenEffect(RandomTarget(), SPELL_PROXIMA_INSTABILITY_DUMMY, SPELL_PROXIMA_INSTABILITY_EFFECT);
                    _events.Repeat(65200ms);
                    break;
            }
        }

    private:
        enum { EVENT_SHADOW_BOLT = 1, EVENT_DAMPEN_MAGIC, EVENT_ARCANE_INSTABILITY };
    };

    struct npc_ebon_the_cruel_coa : public DiscipleAI
    {
        npc_ebon_the_cruel_coa(Creature* creature) : DiscipleAI(creature) { }

    protected:
        void ScheduleAbilities() override
        {
            _events.ScheduleEvent(EVENT_SHADOW_BOLT, 3500ms, 6s);
            _events.ScheduleEvent(EVENT_DARK_MENDING, 15s, 30s);
            _events.ScheduleEvent(EVENT_CURSE, 18800ms);
        }

        void ExecuteAbility(uint32 eventId) override
        {
            switch (eventId)
            {
                case EVENT_SHADOW_BOLT:
                    CastDummyThenEffect(RandomTarget(), SPELL_EBON_SHADOW_BOLT_DUMMY, SPELL_EBON_SHADOW_BOLT_HIT);
                    _events.Repeat(5s, 7s);
                    break;
                case EVENT_DARK_MENDING:
                    DoCastSelf(SPELL_EBON_DARK_MENDING);
                    _events.Repeat(15s, 20s);
                    break;
                case EVENT_CURSE:
                    CastDummyThenEffect(RandomTarget(), SPELL_EBON_CURSE_DUMMY, SPELL_EBON_CURSE_EFFECT);
                    _events.Repeat(79900ms);
                    break;
            }
        }

    private:
        enum { EVENT_SHADOW_BOLT = 1, EVENT_DARK_MENDING, EVENT_CURSE };
    };
}

void AddCoaSulfuronDisciplesScripts()
{
    RegisterMoltenCoreCreatureAI(npc_cull_the_destroyer_coa);
    RegisterMoltenCoreCreatureAI(npc_proxima_the_opressor_coa);
    RegisterMoltenCoreCreatureAI(npc_ebon_the_cruel_coa);
}
