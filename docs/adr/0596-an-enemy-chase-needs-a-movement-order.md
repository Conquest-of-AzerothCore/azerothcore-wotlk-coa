# 0596. An enemy chase needs a movement order

- Status: superseded by [0604](0604-a-fixture-creature-moves-on-a-harness-point-order.md)
- Date: 2026-11-13

## Context

Command: Hook 504316 "slowing their movement speed to a halt" (claim 81.1): the slow is read as a state (run speed
rate); the behaviour is that a hooked enemy stops moving. Design: two movable dummies chase a minion, one is
hooked; the hooked one must cover 2% of the other's yards.

## Decision

- Kind `chase_halt` (dummies `stationary: false`, `attack_owned_creature` towards a Bone Construct beside a far dummy,
  Hook on one of them, stamped distances). A chaser under 3 yd is unmeasured.
- Pilot 20261113-150434: the chaser covered 0.00 yd in 1012 ms after `attack_owned_creature` (the order is accepted,
  target 503200, but fixture creatures stay passive), so the chase does not happen. Gap T6 (an enemy movement order) is
  confirmed; it needs harness C++ beyond a read and waits for a G-39 approval. Two designs are written in the
  Necromancer ADR 0044.

## Consequences

- 81.1 stays a named gap; the kind is ready for the order once it exists.
