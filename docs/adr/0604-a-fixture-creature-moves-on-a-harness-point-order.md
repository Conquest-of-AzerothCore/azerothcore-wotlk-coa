# 0604. A fixture creature moves on a harness point order

- Status: accepted
- Date: 2026-11-13
- Supersedes: [0596](0596-an-enemy-chase-needs-a-movement-order.md)

## Context

Claim 81.1, Command: Hook 504316 "slowing their movement speed to a halt": the hook jumps the target to the
Abomination and casts 800043 (aura 33, BasePoints -99 + DieSides 1 = -98, 2000 ms). The behaviour is that a hooked
enemy stops moving. ADR 0596 left it as gap T6: fixture dummies do not chase after `attack_owned_creature` (the pilot
read 0.00 yd), `relocate` teleports a player, and harness players have no client that runs. The hook's `MoveJump`
replaces any earlier movement order, so an order given before the hook is lost. The mentor approved a test-only
harness order under G-39 (c6-g39-notes.md, section 81.1).

## Options

- Find why the fixture does not chase and change its AI or reaction: a gameplay path, and the cause is not
  established.
- A harness action that gives a fixture creature a running point move, issued after the jump has landed.

## Decision

- Harness action `move_point` (CoAGameplayTest.cpp, beside `set_health`): a fixture creature only, not
  `stationary`, alive; destination = its position + (`dx`, `dy`), ground height from the map;
  `MotionMaster::MovePoint` with `FORCED_MOVEMENT_RUN`. A speed change relaunches a running point spline
  (`PointMovementGenerator`, the speed-change relaunch), so the slow applies to the move as it runs. No gameplay
  path, no script and no AI change. `run.py` validates it (a creature actor, `dx`/`dy` within 100 yd).
- Kind `chase_halt` takes `order: "move_point"` and `move_yd`: no chased creature; 500 ms after the hook both
  movers get the same point move towards the far dummy; the unhooked mover is the control arm. The `attack` order
  stays the default, so existing entries generate unchanged.

## Consequences

- Pilot 20261113-173235 (build with the action): the hooked dummy covered 0.160 yd and the control 8.022 yd in
  1012 ms, ratio 0.0199 against 0.02 (G-19 band 0 to 0.04).
- The control's 8.0 yd confirms the Harvest Golem fixture runs at 1.14286 x 7 yd/s once ordered; why it does not
  chase on `attack_owned_creature` is still not established.
- Necromancer ADR 0044 (the hook halt waits for an order) is answered by this decision.
