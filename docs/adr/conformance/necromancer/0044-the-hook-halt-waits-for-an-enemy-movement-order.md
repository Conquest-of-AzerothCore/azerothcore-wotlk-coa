# 0044. The Hook's halt waits for an enemy movement order

- Status: accepted
- Date: 2026-11-13

## Context

Claim 81.1 (Command: Hook 504316 "slowing their movement speed to a halt", 800043 aura 33 -98 for 2000 ms). Only the
state read exists (`504316 halt`, run speed rate 0.0228572).

## Options

1. Design 1 (kind `chase_halt`, built): movable dummies ordered with `attack_owned_creature` to chase a Bone Construct,
   one hooked; the hooked one must cover 0.02 of the chaser's yards. Pilot 20261113-150434: the chaser did not move
   (0.00 yd in 1012 ms), so the design cannot run on the current harness.
2. Design 2 (not built): a harness action that orders a fixture creature to move to a point or chase a unit
   (`MotionMaster::MovePoint`/`MoveChase`), then the same kind with the order instead of `attack_owned_creature`. Needs
   harness C++ beyond a read (G-39 approval first).

## Decision

- Keep the `504316 chase_halt` entry (unmeasured, the T6 signal). 81.1 is a named gap until design 2 is approved.
