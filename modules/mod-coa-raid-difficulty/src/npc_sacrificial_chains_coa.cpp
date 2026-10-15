/*
 * Sacrificial Chains (92030), Majordomo Executus's periodic hostage add.
 *
 * Correction (this session, raw WoWCombatLog re-query - mc-dataset.json's own aggregation drops
 * aura target names, so this reads the four logs directly:
 * local/logs/ascension/logs-rar/2026-08-25-14.41.47, -19.31.05, -23.06.25, -27-18.49.53 in the
 * coa-combatlog-parser checkout). The previous implementation had 92030 self-cast Sacrifice and
 * loop a heal-to-full/re-sacrifice on itself. That is not what happens:
 *
 *   - 2108020 Sacrifice's own Spell.dbc row targets TARGET_UNIT_TARGET_ENEMY, not the caster.
 *     Every logged SPELL_AURA_APPLIED for 2108020 has "Sacrificial Chains" as the *source* and a
 *     player as the *dest* (e.g. "..., 0xF13001677E00317C, Sacrificial Chains, ..., 0x...C569,
 *     Paredinha, ..., 2108020, Sacrifice, ..., DEBUFF"). The chain casts Sacrifice on players, not
 *     itself - this is the "chains a player" mechanic the restoration was missing.
 *   - Each spawn casts 2108023 Sacrifice rank 2 (a SPELL_EFFECT_HEAL_MAX_HEALTH, "restores the
 *     target health to full, then sacrifices it") on the same target a few hundred ms *before*
 *     2108020, once, at spawn - not a repeating loop. No repeat cast of 2108023 or 2108020 was
 *     ever observed for the same chain instance in any of the four logs.
 *   - One spawn (one creature GUID) chains more than one player at once: every apply for a given
 *     GUID lands within ~0.5s of the others, e.g. GUID …E003357 (Ascended, 12p,
 *     2026-08-25-14.41.47) applies to both "Scorchwalker" and "Geonox" 0.5s apart. Counting
 *     distinct targets per GUID across all four logs, re-verified at the coordinator's request
 *     (exact per-spawn group sizes, not just a max): Heroic (13p, 1 pull, 6 spawns) is 2 targets
 *     every single time (6/6) - never 3, contrary to the "3 on Normal/Heroic" fallback the task
 *     otherwise allows. Ascended (12p x2 pulls + 15p x1 pull, 35 spawns total) is 1 target 14/35
 *     of the time and 2 targets the other 21/35 - never 3 or 4. Mythic (17p, 1 pull, 8 spawns) is
 *     2 targets 6/8 of the time and 3 targets the other 2/8 - the only difficulty that ever reaches
 *     3. No Normal Majordomo pull exists in the corpus.
 *
 *     Rule set by the user from CoA play: chained players follow the flex raid size, not
 *     difficulty - same on every mode. The flex-scaled player count (coa_flex::CountPlayers,
 *     non-GM players in the instance, clamped 10..25) maps to a cap of 1 at 10-14 players, 2 at
 *     15-19, 3 at 20-25 (so also 1 below 10, the clamp's floor); a random distinct selection of
 *     nearby raid members is chained, clamped to however many are actually available.
 *   - Killing the chain frees its chained player(s): in every clean (non-wipe) sample, e.g. GUID
 *     …E00317C, the chain's own UNIT_DIED/PARTY_KILL and the SPELL_AURA_REMOVED of 2108020 on its
 *     target(s) share the exact same log timestamp (17:43:57.250 for all three lines). 2108020's
 *     own SpellDuration (index 5) is 300000ms - far longer than the 10-24s the chain actually
 *     lived - so this is not the debuff's own timer expiring; the removal is tied to the chain's
 *     death. JustDied here explicitly clears Sacrifice from every player it chained.
 *   - Berserk (2100213) is real but rare (1/56 Sacrifice applications, one Ascended pull) and, in
 *     that one case, cast at spawn alongside the Sacrifice applies (not after some elapsed
 *     "loops"; there is no loop to count). Kept as a small chance at spawn, matching the measured
 *     rarity, self-only (TARGET_UNIT_CASTER on all three effects per Spell.dbc) and with no other
 *     behavioural effect on this passive, non-melee add.
 *   - Not implemented: a "roast" that kills an unfreed chain's captives. 2108020 has no
 *     EffectTriggerSpell and no SPELL_PERIODIC_DAMAGE tied to spell id 2108020 appears anywhere
 *     in the four logs. The one Berserk sample's two chained players (Scorchwalker, Froez) did
 *     both die ~38-48s after being chained without the chain itself dying first - but nothing in
 *     Spell.dbc or the log attributes that death to 2108020 specifically (2108020's own
 *     SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN effect is -101, i.e. ~immune to ordinary damage from
 *     "outside sources"), so a timed kill on unfreed captives would be invented, not evidenced.
 *     Flagged, not built.
 *
 * Timing (same re-query, by pull id): each instance's own lifetime before dying to raid damage
 * clusters at 10-24s (median ~15s) across every difficulty and player count sampled; the boss
 * summons a new one on a median ~47-50s cycle starting a median 29s after the pull (both
 * measured, see boss_majordomo_executus.cpp - unchanged by this correction).
 *
 * Corrected (diag-G3.md "Ascension evidence" #2): two independently-checked chained players show
 * a hard stop on every cast/ability for essentially the exact Sacrifice debuff duration (22.7s
 * and 18.3s gaps bounding ~20.3s/~17.1s chain lifetimes) - not just "fewer casts". Neither
 * 2108020 nor 2108023 carries any mechanic/aura in Spell.dbc that would do this, so the evidence
 * chain cannot see the real mechanism from a combat log alone. Per the user's own decision,
 * spell_sacrificial_chains_sacrifice_coa (below) reproduces the effect server-side: on apply, the
 * chained player is moved next to the chain and loses movement/casting/melee until the debuff is
 * removed; on remove, all three are restored. Also corrected: the chain itself now spawns at a
 * fixed point (Majordomo's own battle position, boss_majordomo_executus.cpp) instead of under a
 * random player, so "next to the chain" is a stable spot, not wherever a random target stood.
 *
 * Type 10 in the export ("non-combat/object-like") is real DBC data, unlike this row's
 * placeholder level/health/faction (hp-pools.md) - implemented passive, no melee: the raid
 * burns it down, it does not fight back.
 */

#include "Containers.h"
#include "CreatureScript.h"
#include "DBCEnums.h"
#include "FlexHealth.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "zg_coa_common.h"
#include "../../../src/server/scripts/EasternKingdoms/BlackrockMountain/MoltenCore/molten_core.h"

#include <algorithm>
#include <cmath>

namespace
{
    enum SacrificialChainsSpells
    {
        SPELL_SACRIFICE       = 2108020,
        SPELL_SACRIFICE_RENEW = 2108023,
        SPELL_BERSERK         = 2100213,
    };

    // 1/56 Sacrifice applications carried Berserk in the corpus (one Ascended pull).
    constexpr float BERSERK_CHANCE_PCT = 1.8f;

    // User request: chained players stand apart from the chain, not adjacent to it.
    constexpr float CHAIN_RING_RADIUS = 10.0f;
    constexpr float CHAIN_RING_MIN_RADIUS = 4.0f;
    constexpr float CHAIN_RING_STEP = 2.0f;

    constexpr uint32 POSITION_CHECK_INTERVAL_MS = 500;
    constexpr float POSITION_DRIFT_TOLERANCE_YD = 0.5f;

    // User rule from CoA play: chained players follow the flex raid size, the same
    // non-GM player count coa_flex::CountPlayers uses for boss health (clamped 10..25
    // there), not the difficulty. 10-14 -> 1, 15-19 -> 2, 20-25 -> 3; same on every mode.
    uint8 ChainTargetCap(Map* map)
    {
        uint32 const players = coa_flex::CountPlayers(map);
        if (players >= 20)
            return 3;
        if (players >= 15)
            return 2;
        return 1;
    }

    struct npc_sacrificial_chains_coa : public ScriptedAI
    {
        npc_sacrificial_chains_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            me->SetReactState(REACT_PASSIVE);
            me->SetControlled(true, UNIT_STATE_ROOT);
            _chained.clear();
            _positionCheckTimer = POSITION_CHECK_INTERVAL_MS;

            uint8 const cap = ChainTargetCap(me->GetMap());
            _targetCap = cap;

            // Exclude players a concurrent chain already has Sacrifice on, so two chains spawning
            // close together never both pick the same player.
            std::vector<Player*> targets = coa_zg::PlayersWithin(me, 40.0f);
            targets.erase(std::remove_if(targets.begin(), targets.end(), [](Player* player)
            {
                return player->HasAura(SPELL_SACRIFICE);
            }), targets.end());
            Acore::Containers::RandomResize(targets, cap);

            for (Player* target : targets)
            {
                DoCast(target, SPELL_SACRIFICE_RENEW, true);
                DoCast(target, SPELL_SACRIFICE, true);
            }

            if (roll_chance_f(BERSERK_CHANCE_PCT))
                DoCastSelf(SPELL_BERSERK, true);
        }

        // Called by spell_sacrificial_chains_sacrifice_coa::HandleApply once Sacrifice has actually
        // landed on the target. A failed/blocked cast (e.g. the target got chained by another
        // instance a moment earlier) never reaches here, so it never leaves a phantom teleport with
        // no chain - the defect this fix addresses.
        //
        // Placed on a ring around the chain rather than adjacent to it (user request): evenly
        // spread by angle across the actual number of chained targets, radius shrunk in steps if
        // the ground or line of sight does not hold at the full 10 yd (lava-room edges, pillars).
        void OnSacrificeApplied(Player* target)
        {
            uint8 const slots = std::max<uint8>(_targetCap, 1);
            float const angle = float(M_PI * 2.0) / float(slots) * float(_chained.size() % slots);

            Position chainedSpot = me->GetNearPosition(CHAIN_RING_RADIUS, angle);
            for (float radius = CHAIN_RING_RADIUS - CHAIN_RING_STEP; radius >= CHAIN_RING_MIN_RADIUS &&
                 (std::fabs(chainedSpot.GetPositionZ() - me->GetPositionZ()) > 6.0f || !me->IsWithinLOS(chainedSpot.GetPositionX(), chainedSpot.GetPositionY(), chainedSpot.GetPositionZ()));
                 radius -= CHAIN_RING_STEP)
            {
                chainedSpot = me->GetNearPosition(radius, angle);
            }

            target->NearTeleportTo(chainedSpot);
            _chained.push_back(target->GetGUID());
        }

        void JustDied(Unit* /*killer*/) override
        {
            for (ObjectGuid const& guid : _chained)
                if (Unit* target = ObjectAccessor::GetUnit(*me, guid))
                    target->RemoveAurasDueToSpell(SPELL_SACRIFICE);

            _chained.clear();
        }

        void UpdateAI(uint32 diff) override
        {
            if (_positionCheckTimer > diff)
            {
                _positionCheckTimer -= diff;
                return;
            }

            _positionCheckTimer = POSITION_CHECK_INTERVAL_MS;
            Position home = me->GetHomePosition();
            if (me->GetExactDist(home) > POSITION_DRIFT_TOLERANCE_YD)
                me->NearTeleportTo(home);
        }

    private:
        GuidVector _chained;
        uint8 _targetCap = 1;
        uint32 _positionCheckTimer = POSITION_CHECK_INTERVAL_MS;
    };

    // Root + silence + pacify for the duration of Sacrifice (2108020): neither effect exists in
    // Spell.dbc for this spell (see the file header), so this is applied/reverted server-side.
    class spell_sacrificial_chains_sacrifice_coa : public AuraScript
    {
        PrepareAuraScript(spell_sacrificial_chains_sacrifice_coa);

        void HandleApply(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            Unit* target = GetTarget();
            if (!target)
                return;

            target->SetControlled(true, UNIT_STATE_ROOT);
            target->SetUnitFlag(UNIT_FLAG_SILENCED);
            target->SetUnitFlag(UNIT_FLAG_PACIFIED);

            // The teleport-next-to-the-chain step lives here, not in the chain's own Reset(), so it
            // only ever runs once Sacrifice has actually landed on this target.
            if (Player* player = target->ToPlayer())
                if (Unit* caster = GetCaster())
                    if (Creature* chain = caster->ToCreature())
                        if (npc_sacrificial_chains_coa* chainAI = dynamic_cast<npc_sacrificial_chains_coa*>(chain->AI()))
                            chainAI->OnSacrificeApplied(player);
        }

        void HandleRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            if (Unit* target = GetTarget())
            {
                target->SetControlled(false, UNIT_STATE_ROOT);
                target->RemoveUnitFlag(UNIT_FLAG_SILENCED);
                target->RemoveUnitFlag(UNIT_FLAG_PACIFIED);
            }
        }

        void Register() override
        {
            AfterEffectApply += AuraEffectApplyFn(spell_sacrificial_chains_sacrifice_coa::HandleApply, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
            AfterEffectRemove += AuraEffectRemoveFn(spell_sacrificial_chains_sacrifice_coa::HandleRemove, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        }
    };
}

void AddCoaSacrificialChainsScripts()
{
    RegisterMoltenCoreCreatureAI(npc_sacrificial_chains_coa);
    RegisterSpellScript(spell_sacrificial_chains_sacrifice_coa);
}
