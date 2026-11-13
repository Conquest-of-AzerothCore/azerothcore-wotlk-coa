# 0594. An owned creature's distance to a unit times minion movement

- Status: accepted
- Date: 2026-11-13

## Context

`distance_2d` reads between actors only; minions are not actors (gap T5: 101.1 "moves at a slow speed", 278.1, and the
pilot check of 376.1 that a Ghoul stays at the dummy).

## Options

1. A pure-read metric `owned_creature_distance_2d` (G-39 pure read, like `owned_creature_victim`).
2. Registering minions as actors (harness lifecycle change).

## Decision

Option 1: `owned_creature_distance_2d` (entry, target) returns the exact 2D distance from the caster's living owned
creature of that entry to the unit. Two kinds use it:

- `minion_range_arms`: a minion sent onto the dummy, the caster stepping to a near and a far distance; heals inside the
  radius, none beyond it plus a 3 yd object size margin (376.1).
- `minion_travel_ratio`: a slowed and an unslowed minion sent at a far dummy; least-squares speeds while closing, the
  stalled tail at melee reach left out, ratio in the G-19 band (101.1).

## Consequences

- Pilot 20261113-150027: 376.1 ok (13.1 yd: 10 heals; 29.1 yd: 0). Pilot 20261113-150434: 101.1 read 3.99 against
  7.97 yd/s (ratio 0.501) once the stalled tail was cut; the first judge, which kept it, read 0.433.
- 278.1 (Rotling) needs a forced proc first (gap T1) and stays open.
