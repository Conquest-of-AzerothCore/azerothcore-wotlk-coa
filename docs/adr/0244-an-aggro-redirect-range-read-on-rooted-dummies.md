# 0244. An aggro-redirect range read on rooted dummies

- Status: accepted
- Date: 2026-11-12

## Context

Absolution 800424, claim 279: "Taunt all enemies within 8 yds". The `aggro_redirect` entry placed dummies at 3, 6 and
20 yd. Its dummies are REACT_DEFENSIVE and chase the ally that engages them, so a placed distance is not the distance
at the cast: a diagnostic (20261112-033554) read dummies placed at 7.5-13 yd at 10.6-13.5 yd from the caster.

## Decision

`aggro_redirect` gains `rooted` and `label_suffix`. With `rooted`, every dummy gets Self Root Forever 42716 before the
engagement, and its `distance_2d` to the caster is read right before the cast. Each target's verdict alerts unless that
read lies within 0.25 yd of the placed distance, beside the victim reading. Labels gain the suffix:
`<spell> aggro_redirect <suffix> <dummy> after`. Entries without them regenerate byte-identical.

## Consequences

- Absolution `range`: a dummy read at 7.5 yd and one at 8.5 yd, the stated edge between them. The engine taunts both,
  see FN-r2b-3: stock Spell::SelectImplicitAreaTargets adds the caster's leeway radius (2.66 yd) and the area check the
  target's combat reach (1.275 yd), an edge near 11.9 yd (diagnostics 20261112-033832 to -034042: taunted at 10.5 and
  11.5 yd, not at 12.5).
- Seeded tests: the roots and reads precede the cast; a dummy read 2 yd off its place alerts even when its victim
  matches; an unrooted entry keeps its labels.
