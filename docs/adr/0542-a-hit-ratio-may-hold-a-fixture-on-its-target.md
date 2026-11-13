# 0542. A hit ratio may hold a fixture aura on its cast target

- Status: accepted
- Date: 2026-11-13

## Context

Chilling Presence 300958 states "increases the critical strike chance of Ice Barrage by $s2% against Frozen targets"
($s2 = 20). The night left it at status 5 under G-20 (cost): no crit-rate route set an aura on the target, and the
band needs about ten thousand hits per arm. The owner ruled the pooled proof in scope (Q-b3b-5, G-20 step 2). The
hit ratio's `rate: "critical"` mode already casts a spell whose triggered hits it counts (`cast_spell`) and pools
`parts`; it could hold fixtures on the caster (`auras`) and on the casting unit (`cast_unit_auras`), not on the unit
it hits.

## Decision

- `hit_ratio` takes `target_auras` (`[[spell, stacks], ...]`): set on the cast target by the caster before every
  observed cast in both arms, as a precondition fixture. Swing entries and a caster target refuse them.
- The Chilling Presence entry casts Ice Barrage 501997 at a dummy held frozen by Ice Lock 22856 (the stable frozen
  fixture of the Soulfreeze entries) and counts the critical share of its 803779 hits without the talent and with it
  learned. The expected difference is $s1 + $s2 = 23 points: the talent's Effect[0] +3 area crit aura holds the
  caster too, and both values are the tooltip's. The run is a G-20 pilot first; the parts are then sized.
- Entries without `target_auras` generate the same scenarios (Templar `generate --class 19` and `--stack`
  byte-identical).

## Consequences

- The +3 of Effect[0] on the caster is not separated from the +20 by this entry; the party entry (party_stat_ratio)
  proves the +3 on an ally.
- The pilot read +21.18 points at 296 casts per arm; the pooled runs then read +23.7 / +22.6 at 7548 and +22.94 at
  9620 casts per arm, each with a half-width just above the 1-point power limit, so the entry runs 170 parts.
- Creeping Crypt 300960 ("by $s1% against enemies below 35% maximum health") uses the same pooled critical rate with
  the dummy at 30% health, and a scope control at 50% (0 points).
- Tests: `HitRatioTargetAuraTests` (test_behaviours.py).
