# 0409. Damnation doubles its increase below 35% health

- Status: accepted
- Date: 2026-11-13

## Context

Damnation 806149 (rank 1, $s1 = 5) and 807925 (rank 2, $s1 = 10) state "Increases your Shadow damage by $s1%,
doubled against enemies below 35% health." Effect[1] aura 79 gives the increase; Factor() multiplied a Shadow hit on
a target below 35% by a further 1.05 or 1.1 (AscensionNecromancerContracts.cpp), so rank 2 read 456 -> 551 below 35%
(x1.21, pair 20261113-023713 / -023822, build 894d1062b5d9) where the doubled increase gives 456 x 1.20 = 547. The
class-file expectation had been taken from the code (review B4 side a, I-a). Both ranks share the one Factor() line.

## Decision

- Mentor ruling of 2026-11-13 (G-1, G-6): "doubled" doubles the increase, +2 x $s1%. Below 35% Factor() multiplies a
  Shadow hit by (1 + 2 x s) / (1 + s), s = the rank's Effect[1] value / 100, so that with the aura's 1 + s the hit
  reads 1 + 2 x s. Necromancer code only.

## Consequences

- Rank 2 below 35%: int(456 x 1.10) = 501, then int(501 x 1.20 / 1.10) = 546 (ratio 1.1974 for the stated 1.20; the
  point below 547 is the truncation of the two integer steps). Rank 1: 478, then 500 (1.0965 for 1.10).
- Entries `806149/807925 behaviour_hit_ratio below_35` expect the tooltip's x1.10 / x1.20; `807925 behaviour_hit_ratio
  edge_34` (x1.20) and `edge_36` (x1.10) are the edge arms; every hit_ratio arm pair has the no-talent control.
