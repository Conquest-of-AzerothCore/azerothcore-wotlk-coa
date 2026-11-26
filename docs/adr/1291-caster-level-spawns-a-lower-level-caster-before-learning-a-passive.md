# 1291. `caster_level` spawns a lower-level caster before learning a passive

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25

## Context

Cultist Voidwarding 560002 (row 171) states: "In addition, increases all of your resistances by ${$floor($m2)}, scaling
with level." At level 60, `res_holy..res_arcane` already prove `+19` across all 6 magic schools (`floor(5 + 0.5 *
(60 - 31))`). Proving "scaling with level" requires a second lower-level passive arm (e.g., level 50: `floor(5 + 0.5 *
(50 - 31)) = +14`).

The existing `phase_caster_level` option (ADR 1136) requires two distinct levels with `cast_in_before: true` and runs
`set_level` inside `cast_steps`. `Player::GiveLevel` does not recalculate already-applied passive aura amounts, so
changing level mid-scenario cannot test passive level scaling cleanly.

In the harness (`CoAGameplayTest.cpp:3046-3054`), `Normalize` applies `players[0]['level']` when the actor logs in,
before any scenario step executes — including `learn` of the passive gate spell. Orchestrator decision D-39 approved
an opt-in `caster_level` option on `metric_delta` that enforces ruling G-32 by requiring the word "level" in the
claim's quote.

## Decision

- Add opt-in `metric_delta` option module `caster_level`
  ([doc](../../apps/coa-gameplay-test/conformance/docs/metric_delta_options/caster_level.md)), accepting an integer
  level `1..60` strictly below `class_file['level']`.
- Refuse any entry whose `quote` lacks the word `level` (case-insensitive word boundary, G-32), any level outside
  `1..60` or `>= class_file['level']`, and combinations with `phase_caster_level` or `shifted_control`.
- In `fixtures`, set `scenario['players'][0]['level'] = caster_level` so the caster is normalized at that level before
  any `learn` step runs, and insert `level` reads right before the `before` and `after` measurements.
- In `verdict`, void the trial (`unmeasured`) if either `level` read is missing or differs from `caster_level`;
  otherwise keep the main verdict and append the observed levels.

## Consequences

- Opt-in: absent, no scenario changes and finished classes regenerate byte-identical.
- Zero C++ harness changes: uses existing `players[0]['level']` normalization and the existing `level` metric.
- Seeded tests in `test_caster_level.py` cover scenario generation, `ok`, mutant (`alert` on level-60 expectation `+19`
  against level-50 read `+14`), `unmeasured` (missing or wrong level read), and all refusals.
