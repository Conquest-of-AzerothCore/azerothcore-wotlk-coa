# 0028. Voodoo Cauldron heals allies within 15 yd

- Status: accepted
- Date: 2026-11-21

## Context

Voodoo Cauldron 804684: "Allies within $a3 yds are healed", 15 yd. The load contract zeroes effect 2 and the summon
script pulses a literal 10 yd: the sweep 20261121-235946 healed the ally at 15 yd 0 times (`804684 cauldron_radius`).

## Decision

- The pulse reads `Radius(VoodooCauldron, EFFECT_2)`, the radius the tooltip shows; zeroing the effect keeps its
  radius entry.

## Consequences

- Regression: `804684 cauldron_radius`.
