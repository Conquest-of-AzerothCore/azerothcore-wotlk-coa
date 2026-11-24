# 1199. An ally arm can state a precondition that voids the trial

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22
- Builds on: [ADR 1186](1186-a-metric-delta-may-read-grouped-allies-in-stated-arms.md),
  [ADR 1196](1196-a-metric-delta-can-place-grouped-allies-away-from-the-caster.md)

## Context

Sun Cleric 92136 Sunlight heals "allies within $704911a1 yds" (704911 EffectRadiusIndex 23, SpellRadius 23 = 40 yd).
Fulfill selects the allies through `AnyUnitInObjectRangeCheck`, whose `IsWithinDistInMap` adds the object size of
both units (`Object.h:550` defaults, `_IsWithinDist` in `Object.cpp:1257-1264`); the object size of a unit is its
`UNIT_FIELD_COMBATREACH` (`Object.cpp:2898-2901`). The entry's edge arms at 42.5 and 43.5 yd rest on a computed edge
of 40 + 1.5 + 1.5 = 43.0 yd, but the two 1.5 yd terms were cited, not read: `ally_arm` refuses `combat_reach`, which
has no `METRIC_EVIDENCE` row, although the harness reads it (`CoAGameplayTest.cpp` `metric == "combat_reach"`).

Mentor D-169 set the conditions: the reach reads of the caster, the ally and ally2 are preconditions only, never
behaviour; a read off 1.5 voids the trial and is not judged; the radius is proven by the edge arms, whose edge is
computed from the DBC radius and the cited rule, never from a measured distance, and which exclude a radius 10%
smaller or larger.

## Options

1. A `METRIC_EVIDENCE` row for `combat_reach` and plain arms: an off reach would alert, a judgement on a premise.
2. The row plus an opt-in `precondition: true` arm key: an off or unread precondition makes the verdict unmeasured,
   as the precondition reads of `deflect_arcs` and `pet_armor_arms` do.
3. A stock area spell control that measures the effective edge: more scenario work, and the edge would come from a
   measured distance.

## Decision

Option 2, inside `metric_delta_options/ally_arm.py` so the registration stays in one option module:

- `METRIC_EVIDENCE = {'combat_reach': 'state'}` (an option row, merged by `coverage.metric_evidence()`).
- An arm may carry `precondition: true`; any other value is refused. A precondition arm needs a state metric, and
  `combat_reach` is accepted only on a precondition arm. A ratio may not name a precondition arm: not as numerator,
  denominator, denominator list entry or `floor_count` (ADR 1198), and a precondition arm is never ratio-only.
- The verdict judges the precondition arms first: one off or unread returns `unmeasured` with "a precondition
  failed: the trial is void, not judged", whatever the main verdict says. Held, they leave the status unchanged and
  add their reads to the explanation.
- The model and the contract carry the key only when it is set.

## Consequences

- Opt-in: no finished-class file states it, and `conformance.py generate` for classes 15, 19 (and `--stack`) and 23
  is byte-identical before and after (4215, 2301, 40 and 3734 scenarios, `diff -r` empty).
- Seeded tests in `test_ally_arm.py`: the read, the model key and the contract line; a judged `combat_reach` arm,
  `precondition: false` or a string, a precondition on an event metric and a ratio over a precondition arm are
  refused; held preconditions keep `ok` and `alert`; the mutants (a reach off after, off before, off while the main
  verdict alerts) and an unread reach give `unmeasured`.
- A void trial is not a pass: a claim whose every run is void stays unproven.
- Sun Cleric 92136 `radius_edge` states three precondition arms (caster, ally, ally2, 1.5 within 0.01).
