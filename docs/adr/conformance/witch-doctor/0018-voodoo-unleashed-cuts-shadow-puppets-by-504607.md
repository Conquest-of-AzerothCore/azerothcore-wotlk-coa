# 0018. Voodoo Unleashed cuts Shadow Puppets by 504607's 3 sec

- Status: accepted
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Voodoo Unleashed 705901: "casting Bad Juju now reduces the cooldown of Shadow Puppets by $/1000;504607S1 sec." 504607
effect 0 is SPELL_EFFECT_ASCENSION_COOLDOWN 165 on misc 500015 with BasePoints -3001 and DieSides 1, so -3000 ms, 3
sec. The class code cut Shadow Puppets by a hard-coded 5000 ms on every Juju cast with 705901 known (cycle 9 sweep
20261121-051237: the cost_gate attempt 3500 ms before the uncut end at 14500 ms went through).

## Decision

- The cast hook reads the cut from 504607 (`Reduce(player, Puppets, abs(Amount(UnleashedCooldown)))`) instead of the
  literal 5000.

## Consequences

- Regression: catalog `witch-doctor-voodoo-unleashed-cuts-puppets-3-sec`: 5000 ms after the Puppets cast the control
  player's cooldown reads 13000 ms and the doctor's 10000 ms, which excludes both the 5000 ms cut and no cut. It
  passed in 20261121-062124.
