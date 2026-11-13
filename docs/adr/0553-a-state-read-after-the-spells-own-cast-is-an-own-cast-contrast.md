# 0553. A state read after the spell's own cast is an own-cast contrast

- Status: accepted
- Date: 2026-11-13
- Amends: ADR 0120 (when a state read counts as behaviour) for `metric_delta`

## Context

The Necromancer merged pair 20261113-105514 / -111950 classed three claims that their authors had reported done as
data or unproven:

- 360.3, Icebound Champion 807813, "and reduces the pushback suffered from damaging attacks while casting by
  $807812s1%". The claim's reads are of the caster's `casting` state. Each phase without the Champion is compared with
  a phase after a real summon of the claim's own spell (`setup_only_after`, setup cast 807813). Coverage counts a state
  read as behaviour only in a `learned` contrast (`coverage.promised_state`), and `metric_delta` stamped every
  `setup_only_after` entry `condition`, the same as a contrast made by a foreign setup.
- 254.0, Foul Invocation 804371, "increasing your maximum Stamina by $s2%". The `stat_gain` entry had no stat
  attribution (`attribute_stat`, ADR 0385), so ADR 0258's judge never stamped `learned`. Once attribution was on, a
  second aura appeared that the entry did not list: Lich Form 504747, which the Foul Invocation aura script casts
  (AscensionNecromancerAuras.cpp:122-123; mechanic immunities only, no stat).
- 401.0, Frozen Bodies 707562: its `consumed` label expected the stack to be consumed by "your next Glacial Impact"
  and alerted. The owner's ruling Q-ma-1 (a) and text item 6 (cycle 2, the word "next" removed) settle it, and the
  cycle 2 entry expects the stack kept.

## Decision

- `metric_delta` stamps `own_cast` instead of `condition` when the entry is `setup_only_after`, every setup cast is
  the entry's own spell, and the metric is a state read. An own cast attributes the contrast to the claimed spell, as
  ADR 0258's "own cast" case does for `stat_gain`. Event metrics keep `condition`; for them coverage already counts the
  read as behaviour, and keeping the stamp leaves Templar's generation byte-identical.
- `coverage.promised_state` accepts `learned` and `own_cast`. A promise word is still required, and `condition` stays
  data, so readbacks are never reclassified.
- 804371 `stamina`: `attribute_stat: true`, and `clear_auras` lists Lich Form 504747 next to 804371.

## Consequences

- 807813's `casting` reads (unhit / pushback / control held and done) are behaviour for 360.3 on this branch. The
  integration branch replaced them with T's `pushback_reduction` kind, whose verdict carries no contrast. It needs the
  same stamp: `own_cast` when the reducer is a real cast of the entry's own spell, `learned` with `reducer_learn`
  (integration note).
- 804371: attribution now holds in both arms (pair c3-2: applied [804371, 504747], stat back after the clear). On this
  branch the Stamina arm still misses (gain 27, expected 52), because F1's total-Stamina fix (ADR 0524) is on F1's
  branch; with it merged, the entry stamps `learned`.
- Tests: `MetricDeltaOwnCastContrastTests` (test_behaviours.py) and
  `test_a_state_read_after_the_spells_own_cast_counts_where_the_clause_promises_it` (test_coverage.py), whose
  condition contrast and claim without the promise word are the mutants. Templar `generate --class 19` and `--stack`
  byte-identical.
