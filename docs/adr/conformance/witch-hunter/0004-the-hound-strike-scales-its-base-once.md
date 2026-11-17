# 0004. The hound strike scales its base with level once

- Status: accepted
- Date: 2026-11-15

## Context

Owner ruling O-14 keeps the live-fitted Houndmaster's Call formula: the base (225 + 90, the changelog's "before level
scaling") scales with level through `$<scalingbp>` (spell description variable 182, the `ScalingBase` polynomial), the
ranged attack power term does not. The mentor's reading: O-14 means keep the live formula, not keep today's measured
value.

The landing code in `AscensionWitchHunterSummons.cpp` reads 706332 Effect[1] through `CalcValue(owner)`, which the
`{706332, 2}` row of `AscensionScalingBaseData.h` scales once, adds 0.55 x ranged attack power, the 705450 level term
and the 0.3 lesser factor, then passes the value as base points of two 706332 casts. Each cast's `CalcValue(hound)`
went through the same scaling hook again, so the whole value, attack power and level terms included, was scaled a
second time: final07 read 165 per strike against 168 at ranged attack power 237 and 328 against 333 at 1237 (level 60,
scale 0.98743), and the factor departs further from 1 at other levels (0.198 at 20, 1.605 at 80).

The 705450 client text (rev_20261115_15) stated no scaling at all.

## Options

- Divide the base points by the strike's own scaling factor, read from the same hook, so the cast cancels it.
- Drop the scaling table row: removes the live base scaling too.
- Use the unscaled base and let the cast scale once: scales the attack power and level terms.
- Export `ScalingBase()` and divide by it: the same result through a shared CoA file.

## Decision

The first option: `sScriptMgr->ModifySpellEffectBaseValue(_me, strike, EFFECT_1, strikeScale)` on 1.0 gives the
factor, and both casts take `ceil(value / strikeScale)`. A new pending world update replaces the 705450 text row with
the scaling polynomial inlined (705450 has no description variable id, so `$<scalingbp>` is not available):
`${0.3*($706332m2*315/225*(0.0267291844060354+0.0048541098014737*$pl+0.0001859597762293*$pl*$pl)+$RAP*0.55+$pl*2)}`.

## Consequences

- Counted pair 20261115-163258 / 20261115-163350 (worldserver 7cbb6fe9bc40): `705450 script_hit 706332 one_leap` ok
  168 / 168 against 168 (two strikes), `... rap` ok 333 / 333 against 333, the resisted hit entry ok 147.7 / 147.0
  against 148.4; `witch-hunter-houndmasters-call-scaling` and `witch-hunter-lesser-shadowhound-call` pass in both runs.
- Gameplay change: every hound strike (Shadowhound and Lesser Shadowhound) loses the second scaling: +1.3% at level
  60, and the attack power and level terms keep their full value at every level.
- The client text now states the server formula with its base scaling. Client lab, slot 1 at d308fbb89e (preflight
  PASS), level 60 Witch Hunter at ranged attack power 237: `probe spell 705450` renders "deals two strikes for 168
  Shadow damage each." (the old row rendered 170).
