# 1321. `cast_condition` supports `out_of_combat` for non-resurrect `SPELL_ATTR0_NOT_IN_COMBAT_ONLY_PEACEFUL` spells

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-26
- Rulings: Bloodmage Bucket 2 tool plan (`bm-tb1`, Moon Gaze `562723` and Blood Feast `706605`)

## Context

Bloodmage has non-resurrect spells carrying `SPELL_ATTR0_NOT_IN_COMBAT_ONLY_PEACEFUL` (`0x10000000`) whose tooltips
state `"Cannot be used in combat."` — specifically *Moon Gaze* (`562723`) and *Blood Feast* (`706605`).

`CastConditionSpec` in `apps/coa-gameplay-test/conformance/behaviours.py` previously modelled only `outdoors`,
`mounted`, and `avoided`, while `peaceful_resurrect` (ADR 1022) requires a `SPELL_EFFECT_RESURRECT` effect.

## Options

- Duplicate `peaceful_resurrect` into a separate kind for non-resurrect spells: rejected, because `cast_condition`
  already owns caster castability restrictions and `compare.behaviour_cast_gate_verdict` already supports `priming_void`
  precondition checks.
- Add `CAST_CONDITION_OUT_OF_COMBAT = 'out_of_combat'` to `CAST_CONDITIONS` in `behaviours.py`, with optional `target`
  and optional `corpse` fixture support. Chosen.

## Decision

Extend `apps/coa-gameplay-test/conformance/behaviours.py` ([doc](../../apps/coa-gameplay-test/conformance/docs/behaviour-scenarios.md)):

- Add `SPELL_FAILED_AFFECTING_COMBAT = 1`, `NOT_IN_COMBAT_ONLY_PEACEFUL = 0x10000000`, and
  `CAST_CONDITION_OUT_OF_COMBAT = 'out_of_combat'` to `CAST_CONDITIONS`.
- Add optional `target: str = CASTER` (`'caster'` or `'dummy'`) and optional
  `corpse: tuple[int, int, float, int] | None = None` (`{entry, health, distance, kill_spell}`) on `CastConditionSpec`,
  restricted to `out_of_combat`.
- Require `Attributes & SPELL_ATTR0_NOT_IN_COMBAT_ONLY_PEACEFUL` and `blocked_result == 1` for `out_of_combat`.
- Run the out-of-combat arm first (`combat_allowed == 0`, `cast_failure == 0`), cancel `spec.spell`'s aura and wait
  `GCD_WAIT_MS` (or `duration_ms + CAST_MARGIN_MS` for channeled spells such as Blood Feast so the channel ends
  cleanly before engaging), then attack `TARGET`, wait `CAST_COMBAT_SETTLE_MS`, read `combat_blocked == 1`, attempt
  `spec.spell` expecting `cast_failure == 1`, and `stop_attack`.
- Attach `priming_void: {combat_allowed: 0}` to the `allowed` expectation and `priming_void: {combat_blocked: 1}` to
  the `blocked` expectation so `compare.behaviour_cast_gate_verdict` returns `unmeasured` if combat state was not
  reached.
- For `metric_delta` with `attack_swings` and `gate_cast: true`, when `gate_spell` carries
  `SPELL_ATTR0_NOT_IN_COMBAT_ONLY_PEACEFUL`, run the cast-and-attack treatment arm first while peaceful (`after`),
  cancel `gate_spell`'s aura, and then run the control swing arm (`before`) using a symmetric `swing_interval + 500 ms`
  window so the peaceful cast is not blocked by permanent combat from an earlier attack phase.
- Existing `outdoors`, `mounted`, `avoided`, and non-peaceful `attack_swings` scenarios remain byte-identical.

## Consequences

- Opt-in by `condition: "out_of_combat"`; zero C++ changes, zero `compare.py` changes, and zero diff on finished classes.
- Proves `"Cannot be used in combat."` on Bloodmage Moon Gaze `562723` and Blood Feast `706605`.
- Unit tests in `test_behaviours.py` verify arm order, `cancel_aura` cleanup, optional `corpse` setup, `priming_void`
  unmeasured handling, mutant alerts, and validation refusals.
