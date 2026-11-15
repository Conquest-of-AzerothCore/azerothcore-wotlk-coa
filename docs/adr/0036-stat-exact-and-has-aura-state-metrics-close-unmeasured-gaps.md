# 0036. `stat_exact` and `has_aura_state` metrics, and an `exact_truncated_verdict` judging path

- Status: accepted
- Date: 2026-11-09

## Context

Round 4's `unmeasured` investigation (`unmeasured-spec.md`) found two of the five open gaps needed a new
read-only harness metric, not only a scenario-fixture change:

- 801204 effect 2 (Bells of Light) is a `stat` aura (327, Intellect) whose expected delta is `+0.96`, below the
  1-point resolution of `UNIT_FIELD_STAT0+stat`. `Player::UpdateStats` (`StatSystem.cpp`) computes the true
  fractional value first and only writes the truncated `int32(value)` to that field; the existing `"stat"`
  metric reads the truncated field, so `compare.py`'s `TRUNCATED_METRICS = {'stat'}` guard correctly, but
  permanently, bails out to `unmeasured` for any sub-point claim.
- 520034 effect 0 (Pious Sweep) is a `SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE` (303) aura gated on
  `AURA_STATE_HEALTH_ABOVE_75_PERCENT`. `passive_verdict` had an unconditional early return for any aura 303
  effect, before ever looking at the measured delta, because the harness had no way to confirm the target's
  aura state was actually established on the dummy — so a genuinely missing bonus and an untestable scenario
  were both reported as the same `unmeasured`, and the check could never fail.

Both gaps are measurement-precision/measurement-coverage gaps, not judging-logic gaps: the expected value in
each case was already computed correctly by the existing relation tables; only the measured side needed a new
read.

## Considered options

For 801204:

1. Round the expected value to the field's integer resolution instead of adding a metric. Rejected: this would
   turn a genuine sub-point claim into a false `ok` at delta 0, the exact "check that cannot fail" the hard
   rule forbids.
2. Redefine the existing `"stat"` metric to return the fractional value. Rejected: changes a shared metric's
   established meaning for every other probe already reading it (the harness rule requires a new name for a
   behaviour change, never silently redefining one).
3. Add a new, additive `stat_exact` metric returning the pre-truncation float (`Player::GetTotalStatValue`,
   the same call `UpdateStats` makes before truncating), consulted by `passive_verdict` only when a `stat_exact`
   reading is present alongside the usual `stat` one. Chosen.

For 520034:

1. Leave the blanket `unmeasured` bailout in place and only improve the message. Rejected: still reports a
   genuinely missing bonus as `unmeasured`, not `alert` — the check still could never fail.
2. Assume a full-health dummy always satisfies the aura-state gate and judge the delta unconditionally.
   Rejected: would silently give a false `ok` (or false `alert`) if a future scenario's dummy is not at full
   health when the state is read, with no way to tell the two cases apart.
3. Add a new, additive `has_aura_state` metric (`target->HasAuraState(...)`) measured once per `VERSUS_AURA_STATE`
   probe; `passive_verdict` falls through to the normal delta judging only when the reading confirms the state
   is established, and keeps `unmeasured` with a sharper reason when it is not. Chosen.

## Decision

- `CoAGameplayTest.cpp`'s metric dispatch gains two new, read-only metric names: `stat_exact` (player-only,
  returns `GetTotalStatValue`'s pre-truncation float for a given stat index) and `has_aura_state` (returns 0/1
  for `target->HasAuraState(AuraStateType(state))`). Neither redefines an existing metric's meaning;
  `TRUNCATED_METRICS` still only contains `{'stat'}`.
- `compare.py` gains `exact_truncated_verdict`: when a `stat` probe's measured delta would otherwise hit the
  `TRUNCATED_METRICS` bailout, and a parallel `stat_exact` reading is present, the delta is judged against the
  pre-truncation expected value with a tolerance of `max(FRACTIONAL_FLOOR, 0.005 * exact_before)` instead of
  returning `unmeasured`. An older manifest without the `stat_exact` field keeps today's `unmeasured` path
  unchanged.
- `passive_verdict`'s `VERSUS_AURA_STATE` branch now only returns `unmeasured` when the new `has_aura_state`
  reading is absent or reads 0 (using the sharper reason "aura state {state} is not set on the dummy" in the
  latter case); when it reads 1, the effect falls through to the normal `scale`/`ratio` relation judging that
  already handles every other spell-modifier-gated aura.
- `passives.py` adds the matching probes/measurements for both metrics, scoped to the two aura kinds (327
  `stat`, 303 `VERSUS_AURA_STATE`); no class spell ids appear in `values.py`/`passives.py`/`compare.py`/
  `CoAGameplayTest.cpp` — the Templar spell ids stay in `classes/templar.json`-adjacent fixtures only.

## Consequences

- 801204 e2 and 520034 e0 both move from a permanent `unmeasured` to a real `ok`/`alert` verdict, and both
  checks are now demonstrably able to fail: a suppressed sub-point bonus reads `alert` under
  `exact_truncated_verdict` (`test_exact_stat_reading_judges_a_sub_point_delta`), and a damage bonus measured
  without the aura state established still reads `alert` once the state *is* established
  (`test_damage_versus_an_established_aura_state_is_judged`), while the negative control
  (`test_damage_versus_an_unestablished_aura_state_is_unmeasured_with_a_sharper_reason`) proves the
  state-absent path still reports `unmeasured`, not a false `ok`.
- Any future `stat` or `VERSUS_AURA_STATE` effect in another class gets the same precision/coverage for free,
  with no class-specific code: `stat_exact` and `has_aura_state` are generic, additive metrics available to any
  probe that chooses to use them.
- A future effect pairing a `stat`'s truncated-int reading and its pre-truncation float reading on opposite
  sides of the `delta < 1` boundary (not reachable by any of this round's items, where both readings agree)
  would need `exact_truncated_verdict`'s entry gate revisited; flagged, not yet a problem.
