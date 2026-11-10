# 0075. `behaviour_metric_delta` reads a configurable actor and an optional explicit tolerance

- Status: accepted
- Date: 2026-11-10

## Context

Patience (712678) claims two effects on Interdict (560116): "Increases the duration of Interdict by
`$/1000;s1` sec" and "and its cooldown by `$/1000;s2` sec". Both are dummied in the DBC at load
(`AscensionTemplarContracts.cpp`) and implemented as scripted hooks in `AscensionTemplarAbilities.cpp`
(`OnCalcMaxDuration` for the duration, a post-cast `ModifySpellCooldown` call for the cooldown), so the generic
spell-modifier probe cannot see either and both were flagged `unmodelled_effects`. The existing
`behaviour_metric_delta` scenario (learn a passive, cast a trigger spell, read one metric before/after) is
otherwise the right shape, but two gaps blocked reusing it unchanged:

- Interdict's own silence effect (`EffectImplicitTargetA` `TARGET_UNIT_TARGET_ENEMY`) lands on the cast's enemy
  target, not the caster, so `aura_duration_ms` has to be read on the dummy fixture; `metric_delta_scenario`
  always measured on `CASTER`.
- `aura_duration_ms` is read live off `Aura::GetDuration()`, which decrements every world tick, unlike
  `cooldown_ms` (computed from a stored absolute end time): two independent exploratory runs of the same
  scenario read the same `before` value but a 3 ms different `after` value (7941 ms vs. 7938 ms). The existing
  `METRIC_DELTA_FLOAT_TOLERANCE` (1e-5) is sized for float32 round-trip noise on a deterministic read, not for
  this jitter, and cannot absorb it without masking a real defect of similar size elsewhere.

## Considered options

1. Write a new, Patience-specific scenario/judge pair outside `behaviour_metric_delta`. Rejected: duplicates a
   mechanism that otherwise fits exactly, for a difference that is only "which unit" and "how exact".
2. Hard-code the dummy as the measured actor whenever `target == 'dummy'`. Rejected: several existing entries
   (e.g. Scourge-Defense Training, Sacred Resistance) already cast at the dummy while deliberately measuring on
   the caster (a buff landing on self from a dummy-targeted cast); conflating "who is cast at" with "who is
   measured" would silently change their scenario.
3. Add two independent, backward-compatible fields: `measure_actor` (default `CASTER`, as today) and an
   optional `tolerance` (default `METRIC_DELTA_FLOAT_TOLERANCE`, as today), both read from the class-file entry
   and threaded through `MetricDeltaSpec`/`behaviour_metric_delta_verdict`. Chosen.

## Decision

- `MetricDeltaSpec` gains `measure_actor: str = CASTER` and `tolerance: float | None = None`.
  `metric_delta_scenario` measures `before_label`/`after_label` on `spec.measure_actor` instead of a hardcoded
  `CASTER`, and adds the creature fixture whenever `target == TARGET` or `measure_actor == TARGET` (today only
  `target` triggered it). `metric_delta_spec` reads both from the entry (`measure_actor`, `tolerance`), keeping
  prior entries byte-for-byte unchanged since both default to today's behaviour.
- `behaviour_metric_delta_verdict` reads `model.get('tolerance', METRIC_DELTA_FLOAT_TOLERANCE)` instead of the
  module constant directly, and reports `low`/`high` as `expected ± tolerance` instead of a point value.
- `templar.json`'s two new Patience entries set `measure_actor: "dummy"` for the duration clause (and keep the
  default `CASTER` for the cooldown clause, read on the caster where the real cooldown lives) and `tolerance: 10`
  for the duration clause only (10 ms, two orders of magnitude below the 2000 ms the clause exists to prove, and
  wide enough to absorb the observed 3 ms jitter with margin). The two `unmodelled_effects` entries for 712678
  keep their existing round4 explanation (why the static probe cannot see either effect) with one added sentence
  pointing at the new live entries, rather than being deleted: the static-probe gap they describe is still true.
- The real server defect this uncovered (`ModifySpellCooldown(info->Id, 5000)` added 5000 ms to the stored
  cooldown end time instead of subtracting it, lengthening Interdict's cooldown by Patience instead of shortening
  it) is fixed in the same commit by flipping the literal to `-5000`.

## Consequences

- Any future metric_delta clause whose effect lands on something other than the caster (another silence/debuff
  tooltip) can set `measure_actor` with no new tool code; any clause whose underlying runtime quantity carries
  its own non-float-rounding jitter (another live-ticked duration/amount read) can set an explicit `tolerance`
  without weakening every other entry's default exact match.
- Every pre-existing `behaviour_metric_delta` entry is unaffected: neither field is present in their JSON, so
  both defaults reproduce the prior scenario and judge exactly.
