# 0085. `cast_combat` behaviour kind for "usable while in combat" clauses

- Status: accepted
- Date: 2026-11-10

## Context

Round 10's `cast-conditions-cooldowns` workstream carries Spiritual Ascension 500688's "Usable while in
combat." This is the opposite shape of the existing `cast_condition` kind (ADR 0051): `cast_condition`
proves a restriction exists (the spell is blocked when a condition is unmet), while this clause states that
a restriction many sibling spells of the same shape carry does *not* apply here. 500688's only effect is 18
`SPELL_EFFECT_RESURRECT`; the known stock restriction on resurrection spells is `SPELL_ATTR0_NOT_IN_COMBAT_
ONLY_PEACEFUL`, which the engine's own `CheckCasterAuras` path refuses with `SPELL_FAILED_AFFECTING_COMBAT`
whenever `caster->IsInCombat()`. ADR 0051 already flagged this clause as needing "a dead-ally resurrection
target, which [the `cast_condition` shape] does not cover."

Reading `Spell.dbc` (`coa-dbc-viewer record --id 500688`) confirms 500688's own `Attributes` field carries
only `SPELL_ATTR0_NOT_SHAPESHIFTED`, `SPELL_ATTR0_AURA_IS_DEBUFF`, `SPELL_ATTR0_ALLOW_WHILE_SITTING` and
`SPELL_ATTR0_NO_AURA_CANCEL` - no `NOT_IN_COMBAT_ONLY_PEACEFUL`. Redemption 7328, a stock combat-blocked
resurrection spell of the same effect shape, carries exactly that one flag and nothing else (same tool, same
read), confirming the flag is the real mechanism the tooltip clause is denying, not a guess. No Templar
script (`AscensionTemplarAbilities.cpp`, `AscensionTemplarAuras.cpp`) touches 500688 either.

## Considered options

1. Extend `cast_condition` with a third `condition` value (`"in_combat"`). Rejected: every existing
   `cast_condition` attempt is on the caster alone (`target: CASTER`) and needs no fixture beyond a location
   or an aura; a resurrection spell needs a second player actor, a `die` fixture and an actual melee attack
   to produce a real `IsInCombat()` state, none of which `cast_condition_scenario`'s shape has room for
   without branching its whole attempt helper on the gated spell's own effect, which would make the one
   kind responsible for two unrelated fixture shapes.
2. Fold this into the generic rank scenario (`values.py`, which already handles `targets_resurrect()` for a
   plain effect/cost/cooldown read) with an opt-in "attack first" flag. Rejected: that scenario measures a
   single rank's own numeric tokens and is not behaviour-specific; adding a combat precondition to it would
   change what every other resurrection-targeting entry measures, not just this one clause.
3. Add a new `cast_combat` behaviour kind: one spell, a fixed setup (attack a `dummy` fixture for a real
   `IsInCombat()`, kill the `ALLY` fixture, cast at `ALLY`), two measurements (`combat`, `cast_failure`).
   Chosen: reuses the already-proven `die`-for-resurrect shape (`values.py`'s own `targets_resurrect()`
   path), the already-proven `attack`/`stop_attack` actions (used by the `trigger` kind's `ATTACK` action)
   and `cast_gate_power_step`/`required_aura_steps` unchanged, and reuses
   `compare.behaviour_cast_gate_verdict` unchanged for the judge (it only compares a measured value to the
   expectation's displayed float, regardless of the metric). No new harness metric, no new judge function.

Reading the `combat` metric before the cast attempt, as its own `Expectation` rather than scenario-only
sanity output, was chosen over trusting the `attack` action silently: without it, a fixture that failed to
put the caster in real combat would still show `cast_failure == 0` (since nothing blocks the spell either
way), so the check would never fail for the one thing it exists to test — a future regression that added
`NOT_IN_COMBAT_ONLY_PEACEFUL` to 500688 could only be caught if the "really in combat" precondition is
itself asserted and judged, not assumed.

## Decision

- `behaviours.py` gains `BEHAVIOUR_CAST_COMBAT`, `CastCombatSpec`, `cast_combat_scenario` and
  `cast_combat_spec`, and the `cast_combat` kind in `KINDS`/`BEHAVIOUR_CHECKS`/`behaviour_scenario`'s
  dispatch. A `cast_combat` entry names only the gated `spell`/`name`/`quote`: the setup is fixed, since the
  only modelled shape so far is a spell whose own effect targets a dead ally.
- `compare.py` reuses `behaviour_cast_gate_verdict` unchanged for `BEHAVIOUR_CAST_COMBAT`, for both of the
  kind's measurements.
- One `classes/templar.json` entry closes Spiritual Ascension 500688's "Usable while in combat." clause.
- No server fix: 500688's own `Attributes` already omits `NOT_IN_COMBAT_ONLY_PEACEFUL`; the clause is stock
  engine behaviour, unaudited by any existing scenario before this capability.

## Consequences

- A future "usable while/despite X" clause on a spell whose own effect needs no second actor (not a
  resurrection) does not fit this shape and needs its own kind or an extension once that shape exists;
  `cast_combat` is deliberately narrow (one fixed setup) rather than parameterised, since a single example
  does not yet show what varies.
- `cast_combat_scenario`'s two expectations (`combat`, then `cast_failure`) are a reusable pattern for any
  future "state X genuinely occurred, and then Y was unaffected by it" clause: assert the precondition itself
  before asserting the outcome, rather than trusting the fixture silently.
