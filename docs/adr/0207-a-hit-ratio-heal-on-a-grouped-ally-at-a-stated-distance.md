# 0207. A hit-ratio heal on a grouped ally at a stated distance

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0125 (hit ratio), ADR 0153 (applied events, ruling 4)

## Context

Fortified Body 300515, claims 25 and 26: "Allies within $a1 yds receive $s1% more healing. Does not stack with similar
effects." The ledger held the healing-taken calculation (a readback) and a group-cap read of it. A raid area aura
reaches only grouped units, and `hit_ratio` had an ally but never grouped or placed it.

## Considered options

1. Heal the caster only. It does not show the ally or the radius.
2. Let `hit_ratio` group the ally and move it to a stated distance. Chosen.

## Decision

`hit_ratio` takes `ally_distance`: the ally is grouped with the caster and relocated that far before the trials; the
ally must be the caster or the target. The contract states it.

## Consequences

- 25: the ally's self heal grows 6% at 30 yd and not at 45 yd. 26 (caster self heals): 300515 with Tree of Life 34123
  reads as 300515 alone, 34123 alone gives 6%.
- Entries without the field regenerate byte-identical (1693 of 1693 for ADRs 0204-0208 together, 11 new scenarios).
- Tests: `test_behaviours.HitRatioAllyDistanceTests`.
