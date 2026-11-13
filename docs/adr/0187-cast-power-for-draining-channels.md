# 0187. Cast power for draining channels

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0183 (hit ratio cast spell) and ADR 0153 (taken hits)

## Context

Testament of Fortitude 500678: "Meditate for $d, restoring $s1% of your maximum health every $T1 sec and reducing damage
taken by $s2%." It costs 15 Energy and drains 15 Energy a second (`ManaPerSecond`). The `hit_ratio`, `taken_hit` and
`metric_delta` kinds set the caster's power to the plain cost before a cast. At exactly 15 Energy the channel ended
at its first drain: in diagnostics the aura was gone 1.5 s after the cast, no heal of 500690 landed, and a strike
under it read the full 1100. The `cost_gate` kind already has a `power` field for the same reason.

## Options

1. Give the caster an energy aura in the arms. No stock aura gives a known, permanent energy pool.
2. Set full power before every cast in these kinds. That changes every existing scenario.
3. An optional `cast_power` on the three kinds, set before each cast in place of the cost.

## Decision

Option 3. Without the field, the cost is set as before, and existing scenarios regenerate byte-identical.

## Consequences

- Testament of Fortitude reads 108 per heal (5% of 2173) and 217 with +100% maximum health (Increase Health 43833),
  a first tick between 950 and 1050 ms, and 550 against 1100 for a Holy strike.
