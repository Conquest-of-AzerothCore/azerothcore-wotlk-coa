# 0013. Beast Blood is cast by each grouped member on itself

- Status: accepted
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Beast Blood 705870: "15% of the direct Physical damage taken by party and raid members within $a1 yds"
(EffectRadiusIndex 23, 40 yd) is dealt over time. The server turns effect 0 into a raid area dummy aura and the aura
script then called `Cast(player, target, BeastShield)` for each member. 547573 has TargetA 1 TARGET_UNIT_CASTER on
both effects, so the shield landed on the doctor again and a grouped ally 35 yd away read 0 in both final06 runs
(lead L-S-1).

## Decision

- Each member casts 547573 on itself, triggered, with the Witch Doctor as original caster, so the shield, its absorb
  and its stagger ticks belong to the doctor's aura script as on the doctor.

## Consequences

- Regression: catalog `witch-doctor-beast-blood-shields-allies`: 1500 ms after the instant cast the doctor and a
  grouped ally 10 yd away carry 705870 and the doctor's 547573; a grouped ally 45 yd away carries neither. It passed in
  20261121-050156.
