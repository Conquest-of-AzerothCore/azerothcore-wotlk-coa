# 0221. The gameplay harness admits twelve creatures

- Status: accepted
- Date: 2026-11-12

## Context

Norgannon's Wrath 524739, claim 89: "dealing ... Holy damage to up to $524740i enemies within $524740a1 yds"
(524740 MaxAffectedTargets 10). A cap is shown only by more candidates than the cap in one cast, and the harness took
at most eight creatures: CoAGameplayTest.cpp `MaximumCreatures = 8` and run.py's schema check
`len(creatures) <= 8`. No recorded reason: the limit came with the harness (bb1d48a5f1, #235, 2026-09-15) beside the
8-player limit, and ADR 0002 kept creatures at eight without stating why. The mentor ruled the change a tool extension
(owner rulings, "Claim 89, harness MaximumCreatures").

## Decision

Twelve, no higher, in both places (CoAGameplayTest.cpp:143, run.py:580) and in the README. `fixed_count` gains
`headroom` (candidates beyond the stated count, capped counts only), `far_dummy` (default true; false places no dummy
beyond the radius) and `primary_distance_reads` (each additional dummy's `distance_2d` to the primary, read before the
casts and judged under `radius`), and a `label_suffix`. Entries without them regenerate byte-identical.

## Consequences

- Norgannon's Wrath on build b617a5b10b67: cap arm, twelve dummies 0.42 to 4.58 yd from the primary: each of two casts
  strikes the primary and exactly 9 of the 11 others (10 in all), per dummy from its damage logs; control arm, ten
  dummies within 4.5 yd: each cast strikes all ten.
- Every worktree that runs a scenario of more than eight creatures needs a worldserver built with this change.
