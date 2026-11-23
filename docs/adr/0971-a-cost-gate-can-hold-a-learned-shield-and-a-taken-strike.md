# 0971. A cost gate can hold a learned shield and a taken strike

- Status: accepted
- Date: 2026-11-16

## Context

Two Witch Hunter cooldown claims are readbacks of `cooldown_ms` and count as data: Alertness 681152 (cuts Witching
Shroud's cooldown when the caster takes an Arcane or Shadow critical strike) and Dead and Gone 705524 (Pavise's reduced
cooldown). A `cost_gate` proves such a cut by a refused or accepted cast at timed arms (precedent 705497), but it had
no way to equip the shield Pavise requires (`EquippedItemClass 4`, mask 64) nor to make the caster take a critical
strike. Controller decision t5, 2026-11-16: category A of D-293, reusing the `metric_delta` fields.

## Options

- Keep the `cooldown_ms` reads only: the parts stay data.
- A new kind for each: more code for two arms of the same judgement.
- Opt-in `cost_gate` fields that reuse the `metric_delta` helpers (decision).

## Decision

`cost_gate` takes `learn` (spells learned at the start), `shield_after_learn` (the `metric_delta_options` module's
`parse` and `phase_steps`, equipped once after the learns, in every arm), `strike` (the `MetricDeltaStrike` fields of
`metric_delta`; `strike_cast_steps` is now shared) with `strike_victim_auras` (`[[spell, stacks]]` set on the caster
before the strike). The strike is cast `after_wait_ms` after the priming cast in every arm; the attempt waits are
shortened by it. A strike on a power gate, a reset, `in_before`, `owned_entry` or `after_trigger_ms` is refused.

## Consequences

- Only entries that set a field change; Templar and Necromancer digests are unchanged.
- Tests: `CostGateShieldTests`, `CostGateStrikeTests` and `CostGateMutantTests` in `test_behaviours.py` (steps, absence without the option, misuse, mutants that alert in the with,
  without and beyond arms).
- Witch Hunter entries `pavise_gate` (705524) and `shroud_gate` (681152).
