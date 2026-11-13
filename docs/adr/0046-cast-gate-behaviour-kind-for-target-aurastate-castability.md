# 0046. `cast_gate` behaviour kind for target-`TargetAuraState` castability clauses

- Status: accepted
- Date: 2026-11-10

## Context

Round 10's clause audit (`claims-merged.json`) found two Templar tooltip clauses with `coverage: missing`
on the same mechanism: Titanstrike 806521's "Only usable on enemies below 35% health." and Testament of
Strength 300514's "are usable regardless of your target's health percentage,". `values.py`'s
`required_target_health_steps` already fixtures the target to 30% health for 806521's own `effect_value`
scenario (its `TargetAuraState`, 13, is `AURA_STATE_HEALTHLESS_35_PERCENT`), but that scenario only ever
casts at the lowered target: nothing in the existing manifest ever attempted the cast at a target *above*
the threshold to confirm the engine actually refuses it, and nothing exercised 300514's own bypass claim.

Reading `SpellInfo::CheckTarget` (`SpellInfo.cpp`) and `Unit::HasAuraState` (`Unit.cpp`) confirms both
clauses are the stock engine path, no CoA-specific code: `CheckTarget` returns
`SPELL_FAILED_TARGET_AURASTATE` when `!unitTarget->HasAuraState(TargetAuraState, ...)`, and `HasAuraState`
itself first checks the *caster's* own `SPELL_AURA_ABILITY_IGNORE_AURASTATE` effects and returns `true`
unconditionally for a matching one, before ever looking at the target's actual state. 300514's own effect 2
is exactly that aura, scoped to Titanstrike by its `EffectSpellClassMask`.

## Considered options

1. Extend the existing `effect_value` value-scenario machinery to also assert `cast_failure` above the
   threshold. Rejected: `value_scenario`'s cast step is one cast per rank with one fixed setup; it has no
   room for a second, differently-fixtured attempt of the same spell, and `cast_failure` there is already a
   bare diagnostic, never an `Expectation`, by design (`values.py` docstring: "Two diagnostic measurements
   ride along without an `Expectation`").
2. Add a `metric_delta`-shaped entry reading `cast_failure` before/after learning a bypass spell. Rejected:
   `metric_delta_scenario`'s own contract is "learn the trigger spell once, measure the same metric and
   fields before and after `spell` is learned" — it has no notion of a *target*-health fixture between
   phases, and `cast_failure`'s meaning ("the reason the last submitted cast was refused, or zero") is not a
   metric that benefits from a before/after-learn diff shape: the three states this clause pair needs
   (blocked, bypassed, allowed) are three different fixtures, not two measurements around one learn.
3. Add a new `cast_gate` behaviour kind: three independent cast attempts of the same gated spell (full
   target health with neither buff, full target health with the bypass spell active, lowered target health
   with neither), each `reset_cooldown`/re-funded, each read through the existing `cast_failure` metric and
   judged by exact match against the expected `SpellCastResult` reason. Chosen: no new harness metric (the
   client-visible `cast_failure` read already exists), reuses `required_target_health_steps` for the lowered
   fixture, and the one-way `set_health_pct` ordering (full, full-with-bypass, lowered) lets a single `dummy`
   fixture serve all three without ever needing to raise health back up.

## Decision

- `behaviours.py` gains `BEHAVIOUR_CAST_GATE`, `CastGateSpec`, `cast_gate_scenario` and `cast_gate_spec`, and
  the `cast_gate` kind in `KINDS`/`behaviour_scenario`'s dispatch. A `cast_gate` entry names the gated
  `spell`/`name`/`quote` and a `bypass_spell`/`bypass_name`/`bypass_quote`; the builder raises `NotModelled`
  if the gated spell has no `TargetAuraState` to gate on, since the kind has nothing to prove without one.
- `compare.py` gains `behaviour_cast_gate_verdict`, read exactly off `run.values[expectation.label]` and
  judged with the existing `exact()` helper against `float(expectation.displayed)` (the expected
  `SpellCastResult` reason as an int-valued string, `0` for a successful attempt).
- A `cast_gate` entry produces three `Expectation`s from one scenario: the gated spell's own clause gets two
  (blocked above the threshold, allowed below it), and the bypass spell's own clause gets the third (spell_id
  set to `bypass_spell`, rank_id to the gated spell, since the attempt that proves it casts the gated spell).
- This closes Titanstrike 806521's "Only usable on enemies below 35% health." and Testament of Strength
  300514's "are usable regardless of your target's health percentage," clauses; no server-side defect was
  found (both are the unmodified stock engine path).

## Consequences

- A future `TargetAuraState` castability clause on any class reuses this kind directly; a clause with no
  bypass spell simply omits `bypass_spell` from its own equivalent entry once that is wired (this round's
  entry always has one, since the two clauses this round closes come as a gate/bypass pair).
- The three-attempt, monotonically-decreasing-health ordering (never raise a fixture's health back up) is now
  the established pattern for any future `cast_gate` entry that also needs a bypass attempt.
