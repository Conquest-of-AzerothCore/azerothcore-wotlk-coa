# 0026. The ally-cast relocate fixture requires a charge effect

- Status: accepted
- Date: 2026-11-08

## Context

ADR 0023 generalized the Temple Guardian ally-casting fixture into the shared `targets_ally` gate: every rank
whose own effects target a friendly unit gets an `ally` player, a `CHARGE_OFFSET_YD = 10` yd `relocate` fixture
before every scheduled cast/attempt, and `target: 'ally'`. The relocate step was built for Temple Guardian
803792, whose own effect (`SPELL_EFFECT_CHARGE`) teleports the caster onto the ally as part of the cast, so
moving 10 yd away before the next cast re-creates the "not yet charged" precondition the next charge closes
again.

Round 3 found two reported ally-targeted ranks with no such effect: Benediction 801448 (max rank 578276, a plain
heal, `Effect[1] = 10` target 21, no charge) and Testament of Faith 801478 (Binding Scripture 801457's trigger
cast, heal + speed-buff aura + dummy, no charge). Neither moves the caster, so the unconditional relocate drifts
the caster 10 yd further from the stationary ally on every cast with nothing ever closing the gap back. At their
20 yd `SpellRange`, this clears the range after about two casts and keeps growing, eventually losing line of
sight to the ally as the drift grows unboundedly. Measured: Benediction's `hit_mean` came back
`insufficient_trials` (2 usable hits of 157 needed, 31 `SPELL_FAILED_OUT_OF_RANGE`, 203
`SPELL_FAILED_LINE_OF_SIGHT`); Binding Scripture's `trigger_count` came back `unmeasured` for the same reason,
worse because its baseline phase alone schedules 20 attempts before the passive is even learned.

## Considered options

1. Retune `CHARGE_OFFSET_YD` or add a return-trip relocate so a non-charging ally cast still drifts but within
   range. Rejected: still open-ended for a longer scenario (more scheduled casts/attempts), and does not reflect
   what is actually true of these ranks - they never move the caster at all.
2. Branch on the two reported spell ids. Rejected: violates "tool code stays class-agnostic"; the next
   non-charging `targets_ally` rank, in this class or another, would hit the same bug.
3. Gate the existing relocate fixture on a new, read-only, class-agnostic predicate over the rank's own effects:
   does this rank's own `Effect` list contain a charge/leap effect (`SPELL_EFFECT_CHARGE` = 96,
   `SPELL_EFFECT_CHARGE_DEST` = 149, `SharedDefines.h`)? Chosen.

## Decision

- `values.py` gains `CHARGE_EFFECTS = frozenset({96, 149})` and `closes_distance(facts: RankFacts) -> bool`,
  mirroring `is_hostile`/`targets_ally`'s shape over the same `RankFacts.effects` field.
- `hits.py::hit_parts`'s `cast_fixtures` only includes the relocate step when `ally and closes_distance(hit.facts)`
  (was `ally` alone).
- `triggers.py::attempt_fixtures` takes the trigger rank's `RankFacts` (already computed by its one caller,
  `attempt_steps`, right before the call) and only includes the relocate step when
  `entry['trigger'].get('target') == ALLY and closes_distance(facts)` (was the `target == ALLY` check alone).
- Nothing about what `targets_ally`, `hit_mean`, `trigger_count` or any other existing metric means changes; the
  `ally` player fixture, `target: 'ally'` on the cast, and the heal metric's dropped `target` filter (ADR 0023)
  all stay for every `targets_ally` rank regardless of `closes_distance` - only the relocate step is now
  conditional.

## Consequences

- Benediction 578276 and Testament of Faith 801478 (as cast by Binding Scripture's trigger) stop relocating the
  caster: both move from a trial-starved verdict to a judged `ok` (measured against the exploratory run this
  round: Benediction 231 usable hits of 157 needed, mean 266.83 against an expected 266.39; Binding Scripture 273
  trigger events in 273 trials against an expected 273, both inside their tolerance).
- Temple Guardian 803792 (`hits.py`'s hit scenario) and Determined's trigger entry (also Temple Guardian, a
  charge) are unaffected: `closes_distance` is `True` for a charge effect, so the existing relocate fixture still
  applies, locked by the existing regression tests for both.
- Any other `targets_ally` rank without a charge effect (the round's dispatch noted other ally-targeted spells
  passing only "by small-sample luck") stops drifting too, with no further per-spell change.
