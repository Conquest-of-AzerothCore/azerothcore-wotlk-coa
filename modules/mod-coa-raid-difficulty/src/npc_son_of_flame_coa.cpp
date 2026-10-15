/*
 * Son of Flame merge chain (Ragnaros, Molten Core).
 *
 * `.agents/plans/mc-restoration/logs/mc-dataset.json` (54 CoA/Ascension logs) confirms a
 * 4-tier chain: Lesser Son of Flame (12143, live) -> Son of Flame (92026) -> Greater Son of
 * Flame (92027) -> Unstable Son of Flame (92028, 1 pull only). In every logged transition, two
 * same-tier adds "die" within 0-0.3s of each other and the next tier's first appearance in the
 * log lands within that same 0-0.3s window - a near-instant merge once triggered. The dataset
 * carries no coordinates, so the actual distance between the pair at merge time is NOT measured
 * evidence; only the near-instant timing is. MERGE_RANGE_YARDS/MERGE_TRIGGER_MS below are a
 * [designed] proximity trigger shaped by that timing, not a measured value - see
 * refs/mc-refs.md A.2 and hp/hp-pools.md for the rest of the reconstruction.
 *
 * Per-tier kit (db.exil.es export + Spell.dbc, refs/mc-refs.md A.2): Fire Strike / Fierce Fire
 * Strike (2108704/2108705) are the only spells the log corpus ever shows as a direct, counted
 * cast, at every tier. Magma Strike (2108657, Son tier on) and Cone of Fire (2108735, Greater
 * tier on) are logged only as "Auras applied", never as a counted cast - refs.md flags this as
 * "likely on-summon or proc", not resolved by this pass - so both are applied once on
 * engagement here instead of guessed onto a repeating cast timer. Unstable Son of Flame's kit
 * also lists the closing "Unstable Flames" (2108749, refs.md), but the corpus's single Unstable
 * pull never shows it casting anything beyond the shared Fire Strike/Magma Strike/Cone of Fire
 * kit - it is deliberately NOT wired here; do not add a finisher trigger without more data.
 */

#include "CreatureScript.h"
#include "ObjectAccessor.h"
#include "ScriptedCreature.h"
#include "../../../src/server/scripts/EasternKingdoms/BlackrockMountain/MoltenCore/molten_core.h"

namespace
{
    enum SonOfFlameCreatures
    {
        NPC_LESSER_SON_OF_FLAME  = 12143,
        NPC_SON_OF_FLAME         = 92026,
        NPC_GREATER_SON_OF_FLAME = 92027,
        NPC_UNSTABLE_SON_OF_FLAME = 92028,
    };

    enum SonOfFlameSpells
    {
        SPELL_FIRE_STRIKE        = 2108704,
        SPELL_FIERCE_FIRE_STRIKE = 2108705,
        SPELL_MAGMA_STRIKE       = 2108657,
        SPELL_CONE_OF_FIRE       = 2108735,
    };

    enum SonOfFlameEvents
    {
        EVENT_FIRE_STRIKE = 1,
        EVENT_MERGE_SCAN,
    };

    // [designed] the log corpus has no coordinates; only the near-instant merge timing (see
    // file header) is measured. These values are a reasonable, tagged guess, not a fitted one.
    constexpr float MERGE_RANGE_YARDS = 5.0f;
    constexpr uint32 MERGE_SCAN_INTERVAL_MS = 500;
    constexpr uint32 MERGE_TRIGGER_MS = 1500;

    struct SonOfFlameTier
    {
        uint32 nextTierEntry;
        bool hasMagmaStrike;
        bool hasConeOfFire;
    };

    SonOfFlameTier GetSonOfFlameTier(uint32 entry)
    {
        switch (entry)
        {
            case NPC_LESSER_SON_OF_FLAME:
                return { NPC_SON_OF_FLAME, false, false };
            case NPC_SON_OF_FLAME:
                return { NPC_GREATER_SON_OF_FLAME, true, false };
            case NPC_GREATER_SON_OF_FLAME:
                return { NPC_UNSTABLE_SON_OF_FLAME, true, true };
            case NPC_UNSTABLE_SON_OF_FLAME:
            default:
                return { 0, true, true };
        }
    }

    struct npc_son_of_flame_coa : public ScriptedAI
    {
        npc_son_of_flame_coa(Creature* creature) :
            ScriptedAI(creature), _tier(GetSonOfFlameTier(creature->GetEntry())), _mergeProximityMs(0)
        {
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            events.ScheduleEvent(EVENT_FIRE_STRIKE, 1s);

            if (_tier.nextTierEntry)
                events.ScheduleEvent(EVENT_MERGE_SCAN, Milliseconds(MERGE_SCAN_INTERVAL_MS));

            // [uncertain timing] see file header: both are logged only as "Auras applied",
            // never a counted cast, so they land once on engagement rather than on a guessed
            // repeating timer.
            if (_tier.hasMagmaStrike)
                DoCastVictim(SPELL_MAGMA_STRIKE, true);
            if (_tier.hasConeOfFire)
                DoCastAOE(SPELL_CONE_OF_FIRE, true);
        }

        void JustSummoned(Creature* summon) override
        {
            DoZoneInCombat(summon);
        }

        void ExecuteEvent(uint32 eventId)
        {
            switch (eventId)
            {
                case EVENT_FIRE_STRIKE:
                    // [designed] approximates the logs' interval medians (0.3-2s across tiers);
                    // the corpus never distinguishes what triggers Fire Strike from Fierce Fire
                    // Strike, only their relative cast counts (roughly 3:1 in favor of Fire
                    // Strike).
                    DoCastVictim(urand(0, 3) ? SPELL_FIRE_STRIKE : SPELL_FIERCE_FIRE_STRIKE);
                    events.Repeat(1s);
                    break;
                case EVENT_MERGE_SCAN:
                    TryMerge();
                    events.Repeat(Milliseconds(MERGE_SCAN_INTERVAL_MS));
                    break;
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
            {
                events.Update(diff);
                return;
            }

            events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 const eventId = events.ExecuteEvent())
                ExecuteEvent(eventId);

            DoMeleeAttackIfReady();
        }

    private:
        SonOfFlameTier _tier;
        uint32 _mergeProximityMs;
        ObjectGuid _mergePartnerGUID;

        // Proximity merge: while two same-tier adds stay within MERGE_RANGE_YARDS of each
        // other for MERGE_TRIGGER_MS, both despawn and the next tier is summoned at their
        // midpoint. Only the lower-GUID add of a pair drives the check, so the pair is not
        // merged (and despawned) twice from both sides in the same scan.
        void TryMerge()
        {
            if (!_tier.nextTierEntry || !me->IsAlive())
                return;

            Creature* partner = _mergePartnerGUID ? ObjectAccessor::GetCreature(*me, _mergePartnerGUID) : nullptr;

            if (!partner || !partner->IsAlive() || me->GetDistance(partner) > MERGE_RANGE_YARDS)
            {
                std::list<Creature*> nearby;
                GetCreatureListWithEntryInGrid(nearby, me, me->GetEntry(), MERGE_RANGE_YARDS);
                nearby.remove(me);

                partner = nearby.empty() ? nullptr : nearby.front();
                _mergePartnerGUID = partner ? partner->GetGUID() : ObjectGuid::Empty;
                _mergeProximityMs = 0;
            }

            if (!partner || partner->GetGUID() < me->GetGUID())
                return;

            _mergeProximityMs += MERGE_SCAN_INTERVAL_MS;

            if (_mergeProximityMs < MERGE_TRIGGER_MS)
                return;

            Position midpoint;
            midpoint.Relocate((me->GetPositionX() + partner->GetPositionX()) / 2.0f,
                (me->GetPositionY() + partner->GetPositionY()) / 2.0f,
                (me->GetPositionZ() + partner->GetPositionZ()) / 2.0f,
                me->GetOrientation());

            if (Creature* next = me->SummonCreature(_tier.nextTierEntry, midpoint, TEMPSUMMON_CORPSE_DESPAWN))
                DoZoneInCombat(next);

            partner->DespawnOrUnsummon();
            me->DespawnOrUnsummon();
        }
    };
}

void AddCoaSonOfFlameScripts()
{
    RegisterMoltenCoreCreatureAI(npc_son_of_flame_coa);
}
