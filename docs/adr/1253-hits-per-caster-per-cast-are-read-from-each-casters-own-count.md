# 1253. Hits per caster per cast are read from each caster's own count

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-23

## Context

Fel Torpedo 500610 hits each enemy once per caster per cast (Felsworn owner ruling O-25,
[Felsworn ADR 0013](conformance/felsworn/0013-fel-torpedo-hits-each-enemy-once-per-caster-per-cast.md)). `script_hit`
judges the amount per hit and counts at least `minimum_hits`; `fixed_count` counts how many dummies are struck, not how
often one dummy is. No kind casts from two players of the class or reads hits per cast on one dummy.

## Decision

- Behaviour kind `caster_hits` (module `kinds/caster_hits.py`, ADR 0581 hooks; doc `docs/kinds/caster_hits.md`). One or
  two players of the class (`caster`, `caster2`). `trial_position` is the scenario's `location`, so the dummy spawns
  `dummy_distance` yd ahead of it; every caster is restored there before every trial with a position assertion, and
  the dummy's position is read. `cast_spell` is cast at the dummy or, with `cast_target` "self", at the caster itself
  (Fel Torpedo is a self cast). Every caster's own `spell_damage_count` of `hit_spell` on the dummy is read before and
  after each trial's casts, the second caster casting `gap_ms` after the first.
- Each caster and trial is one expectation `<spell> behaviour_metric_delta <suffix> <actor> #<trial>`, judged by the
  existing `metric_delta` judge: before = (trial - 1) x `hits_per_cast`, after = trial x `hits_per_cast`. The read
  before the first cast is the no-cast control (0).

## Consequences

- A cast that hits twice, or a second caster blocked by the first, alerts in the trial where it happens.
- Additive module: no shared core file changes. Tests: `CasterHitsTests` (kinds/test_caster_hits.py), with two hits
  per cast and a blocked second caster that must alert.
