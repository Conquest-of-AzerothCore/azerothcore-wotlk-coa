# 0019. Diabolical stacks last 20 seconds

- Status: accepted
- Date: 2026-11-13

## Context

Diabolical 704723: "... for $706504d." (706504 DurationIndex 18 = 20000 ms). The stacks the server casts are
Diabolical 707133 (AscensionNecromancerAbilities.cpp:275-276), DurationIndex 9 = 30000 ms. The owner ruled (Q-a2-1,
option (b)) 20 s; the mentor approved fix note FN-own-6. Live ran 30 s (72 natural expiries at 30 s); the ruling
departs from live.

## Decision

- The 707133 contract block sets its DurationEntry to SpellDuration 18 (706504's). 707133 stays the cast spell: the
  damage factor and the consumption read it.

## Consequences

- Regression (class file): `Diabolical (past the stated duration)` (1 stack at 19500 ms, 0 at 20500 ms) and
  `Diabolical (stack duration long)` (0 at 29500 ms); the before phase without a stack is the control. The 1000 ms
  bracket is G-19's 5% of 20 s, so a wait drift beyond it would flip the read.
