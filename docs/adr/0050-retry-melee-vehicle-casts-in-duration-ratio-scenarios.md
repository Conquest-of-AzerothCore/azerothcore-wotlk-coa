# 0050. Retry a melee-class vehicle cast in `behaviour_duration_ratio` scenarios

- Status: accepted
- Date: 2026-11-09

## Context

712466 (Templar "Courage (Rank 2)") carried an open `behaviour_duration_ratio` item with an unusual symptom:
round 8's two runs disagreed on its *status*, not just its measured value — run 1 read `unmeasured` (`before`
measured 0 ms, "a duration ratio needs a positive baseline"), run 2 read `alert` (`measured` 0.0 against expected
0.8). Round 8's own `coverage.md` recorded the same event from a different angle: "passives with a behaviour
check" dropped from 133 to 132 of 145 between round 7 and round 8 — 712466 lost its judged status entirely in at
least one of the two runs.

`mechanic_duration_scenario`'s striker fixture sets `spell_hit_bonus: 100` on the creature and its contract text
called this "forced to hit", but Hamstring 1715 (the vehicle for both Courage ranks) has `DmgClass`
`SPELL_DAMAGE_CLASS_MELEE` (confirmed via `coa-dbc-viewer`) and `AttributesEx3`
`SPELL_ATTR3_REQUIRES_MAIN_HAND_WEAPON`: a melee-class ability resolves through the melee combat table
(`Unit::RollMeleeOutcomeAgainst`), not the plain spell hit/resist roll `m_modSpellHitChance`
(`spell_hit_bonus`) feeds. `spell_hit_bonus` removes the miss leg of that roll but not the separate dodge/parry
legs, which depend on the defender's own dodge/parry chance and are not forced to zero by anything this
scenario sets. A single cast can therefore land on no one.

Round 9 reproduced both failure directions with the unmodified, single-cast scenario at the current base
(`07fb6f4ff1`, gameplay stamp `20261109-203047`): a run where the cast landed matched the tooltip's claim
cleanly (before 14494 ms, after 11494 ms, ratio 0.793 against expected 0.8, well inside the band). Round 8's
own `server-findings`/`templar.json` prose (the 301340 entry) had already independently observed, while
investigating an unrelated clause, that "an actual Hamstring cast... never lands" in some configurations and
"lands normally" in others for this same vehicle — consistent with an intermittent combat-table outcome rather
than a deterministic server defect in either Courage rank's own duration-reduction aura
(`SPELL_AURA_MECHANIC_DURATION_MOD`, a stock, no-CoA-code aura type).

## Considered options

1. Leave the flaky status open as a server finding. Rejected: the one successful measurement this round (and
   round 8's own successful runs in other items using the same vehicle) shows the duration-reduction mechanism
   itself works exactly as the tooltip claims; the flakiness is in whether the vehicle cast lands at all, not in
   what happens once it does.
2. Zero the test caster's dodge/parry chance for the scenario (a new, more invasive harness lever — a rating or
   stat override action, or an aura/flag that suppresses the melee combat table's dodge/parry legs specifically).
   Deferred: correct in principle, but a new `CoAGameplayTest.cpp` action/flag needs its own test coverage and
   correctness check against the engine's actual dodge/parry formulas, a larger change than this item's proven
   gap calls for.
3. Retry the vehicle cast a bounded number of times, spaced apart, before the single settle-and-measure read
   already in place. Chosen, because Hamstring (like other mechanic-duration vehicles sharing its non-stacking,
   refresh-on-reapply aura behaviour) overwrites its own aura to full duration on every landed cast: whichever
   attempt lands *last* is the only one that determines the state at measurement time, so adding attempts before
   the existing fixed-delay read changes nothing about what is measured when an attempt lands, and only lowers
   the probability that every attempt in a phase misses.

## Decision

- `mechanic_duration_scenario`'s `phase()` helper now casts `vehicle_spell` up to `MECHANIC_LAND_ATTEMPTS` (3)
  times per phase, `MECHANIC_RETRY_WAIT_MS` (500 ms) apart, before the existing `CAST_MARGIN_MS` settle wait and
  `aura_duration_ms` read. The read's own timing (a fixed delay after the *last* attempt) is unchanged, so a
  phase where the first attempt(s) miss and a later one lands measures identically to today's single-attempt
  design; a phase where the last attempt misses but an earlier one landed is left as residual, acceptable noise
  shared symmetrically by the `before` and `after` phase (same vehicle, same attempt count, same spacing), not a
  one-sided bias.
- The contract text and `docs/behaviour-scenarios.md` are corrected: `spell_hit_bonus` is described as removing
  only the miss leg of a melee-class vehicle's combat roll, not dodge/parry, and the retry's safety argument
  (non-stacking, refresh-on-reapply) is spelled out so a future reader does not reintroduce the single-cast
  design for a new vehicle without checking whether it shares that property.
- No change to `judge_hit`/`behaviour_duration_ratio_verdict`'s judging logic, the DR gap sizing, or any other
  `behaviour_duration_ratio` entry's expected ratio or tolerance.

## Consequences

- 712466's `behaviour_duration_ratio` stops flipping `unmeasured`/`alert` between runs for a reason unrelated to
  the passive it checks; round 9's two gameplay runs after this change (stamps `20261109-203047` pre-fix single
  landed-run and the regression run recorded in `round9/mechanics-report.md`) are its evidence.
- Any future `mechanic_duration_scenario` entry whose `vehicle_spell` is also melee-class inherits the same
  retry protection automatically, with no per-entry configuration; a non-melee vehicle (the common case today)
  is unaffected in practice, since its single cast already lands reliably and the extra attempts are simply
  never needed (cost is bounded scenario time, not correctness).
- A future vehicle whose mechanic-duration aura does *not* refresh to full duration on reapplication (stacks,
  or extends instead of resetting) would need a different, explicit model before reusing this retry pattern —
  flagged, not yet a problem, since every vehicle used by this file today is a simple non-stacking snare/disarm.
