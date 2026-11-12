# 0223. fixed_count: a dummy behind the caster

- Status: accepted
- Date: 2026-11-12

## Context

Sacred Swing 572769, claim 205: "Swing at enemies in front of you". Its three effects target
TARGET_UNIT_CONE_ENEMY_54 in 6 yd (SpellRadius 29), and the cone check keeps only units in front of the caster
(Spell.cpp:1277-1304, 9472-9492). A `fixed_count` scenario places every dummy on the caster's spawn axis in front of
it (CoAGameplayTest.cpp `CreateTargets`), so a cone that ignored the facing would read the same. The scenario
validator accepts creature distances from 0 to 100 yd and `relocate` offsets up to 20 yd (run.py).

## Considered options

1. A negative creature distance. Refused by the validator; changing it is a harness change.
2. Spawn every dummy further out and step the caster forward past one of them before the casts. Chosen.

## Decision

`behind_yd` (optional, inside the radius): every dummy spawns `2 x behind_yd` further out, one more dummy spawns
`behind_yd` from the caster, and a `relocate` of `2 x behind_yd` along the caster's facing comes before the first
cast, so that dummy stands `behind_yd` behind the caster. Its hit count is read with the others; a hit makes the
verdict an `alert`, as the far dummy's does. Entries without `behind_yd` regenerate byte-identical.

## Consequences

- Sacred Swing on build 2414539ce1bb: the four dummies 1.2 to 4.8 yd in front hit, the one 11 yd away and the one
  3 yd behind never.
- Seeded tests: the spawn distances and the relocation; a behind dummy outside the radius is refused; a hit behind the
  caster alerts.
