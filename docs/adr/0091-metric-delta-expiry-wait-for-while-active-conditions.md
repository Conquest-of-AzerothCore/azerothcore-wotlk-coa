# 0091. `expiry_wait_ms`/`after_expiry_expected` on `metric_delta` to prove a "while active" condition

- Status: accepted
- Date: 2026-11-10

## Context

Argent Knight/Righteous Tempest's clause "now reduces all damage taken by $s2% while active" (300512) needs
a scenario that distinguishes the effect being scoped to Righteous Tempest 805409's own aura (correct) from
the effect leaking into a longer-lived state that outlives it (the exact defect shape the clause's wording
rules out). The round 10 final review (`round10/final-review.md`, finding I1) found the existing `gate_timing:
"start"`/`trigger_only_after` entry only ever casts 805409 once and never lets it expire before the final
measurement, so it can prove the effect is present while 805409 is up but cannot catch it staying present
after 805409 is gone.

805409's own `DurationIndex` (160) is 27 (coa-dbc-viewer Spell record); `SpellDuration.dbc` id 27's
`Duration`/`MaxDuration` is 3000 ms (coa-dbc-viewer SpellDuration record), so a wait past that duration, with
no further cast of 805409, lets the aura actually expire while 300512 stays known throughout.

## Considered options

1. A new behaviour kind dedicated to "cast once, measure while active, wait past expiry, measure again".
   Rejected: duplicates `metric_delta`'s scenario-building, `before_label`/`after_label` machinery and
   `behaviour_metric_delta_verdict`'s before/after comparison for no behavioural difference beyond one more
   wait-then-measure pair.
2. A third, always-present phase on every `gate_timing: "start"` entry. Rejected: every other `start` entry
   in `classes/templar.json` (none at the time of this change) would gain an unused measurement and an
   unconditional validation requirement (`expiry_wait_ms`/`after_expiry_expected` set together), widening the
   blast radius of a fix scoped to one clause.
3. Two optional `MetricDeltaSpec` fields, `expiry_wait_ms: int | None` and `after_expiry_expected: float |
   None`, defaulting to `None` (no third phase, every existing entry's generated scenario and model are
   unchanged), required together, and only valid with `gate_timing == "start"` (the shape this clause needs:
   a single cast, not a before/after gate toggle). Chosen.

## Decision

- `behaviours.py`'s `MetricDeltaSpec` gains `expiry_wait_ms: int | None = None` and `after_expiry_expected:
  float | None = None`. `metric_delta_scenario` raises `ValueError` if exactly one of the two is set, or if
  either is set with `gate_timing != "start"`.
- When both are set, the `"start"` branch appends one more step pair after the existing after-phase
  measurement: `wait` for `expiry_wait_ms`, then a `measurement` at label `metric_delta_label(spec, 'expired')`
  with the same `metric`/`fields`. The model gains `expired_label` and `after_expiry_expected`.
- `compare.py`'s `behaviour_metric_delta_verdict` reads `model.get('expired_label')`; when present, it fetches
  that run value (a missing measurement is still reported through the existing `missing_measurement` path),
  compares it against `after_expiry_expected` with the entry's own tolerance, and factors the result into the
  overall `ok`/`alert` status and explanation alongside the existing before/after check.
- `classes/templar.json`'s 300512 `while_active` entry sets `expiry_wait_ms: 4000` (500 ms post-cast wait
  already elapsed plus 4000 ms, 4500 ms total since the single 805409 cast, past its own 3000 ms duration)
  and `after_expiry_expected: 0`, with an `observe_source` note recording the DBC lookup above.
- A seeded-wrong-value unit test (`test_while_active_shape_catches_the_effect_outliving_its_own_aura`)
  asserts `alert` when the expired reading still shows the effect (-20) and `ok` when it has actually reset
  to 0, so this check kind can fail. `test_expiry_wait_requires_gate_timing_start` and
  `test_expiry_wait_and_after_expiry_expected_are_required_together` cover the two validation guards.

## Consequences

- Any future "while active"/"only while X is up" clause can reuse `metric_delta` with `expiry_wait_ms`/
  `after_expiry_expected` instead of a new kind, as long as the condition's own aura duration is read from
  the DBC (not assumed) and the scenario's existing wait budget is extended to clear it.
- Existing `metric_delta` entries (including `gate_timing: "start"` ones with neither field set) are
  unaffected: their generated scenarios, labels and models are byte-for-byte unchanged.
- The ledger label for 300512's "while active" clause (`300512 behaviour_metric_delta while_active`) is
  unchanged, so no `templar_clauses.json` edit was needed; the label now denotes a scenario that actually
  measures the condition it is cited for.
