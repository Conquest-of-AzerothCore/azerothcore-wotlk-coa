# 0724. A fixed count can judge an outcome below and at its gate

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 31.0 ("Striking at least 5 enemies with Darkflock ... causes you to unleash a flock of crows around
each enemy struck", Feast of Talons 500056) states a gate on the number of enemies struck by one cast. The class script
(`AscensionWitchHunterAbilities.cpp:322-331`) lists the enemies each Darkflock tick 520271 damages and, from the fifth,
casts the crows 500564 around each of them. `fixed_count` counted the struck dummies against a cap; it had no arm that
places fewer dummies than the gate, nor a read of the outcome on each dummy, so the cycle 11 author stopped. Mentor
decision D-185 (c13 tool batch item 3, design G4 in the c12 gap designs).

## Options

- An optional `gate {arm, metric, spell}` on `fixed_count`: arm `below` places `expected - 1` dummies, arm `at` exactly
  `expected`, both uncapped with the primary counted; the outcome is read on each dummy after the casts.
- Two dummies counts inside one scenario: the second cast would meet the crows of the first, and the gate is per cast.
- A `metric_delta`: it has one dummy, so it cannot reach five struck enemies.

## Decision

The first option, as two entries (one per arm). The judge keeps the struck count (every dummy struck, the far dummy
unhit) and alerts unless the outcome reads 0 on every dummy below the gate and above 0 on every dummy at it. A gate
without an uncapped count of every dummy, an arm other than `below` or `at`, or a gate under 2 is refused.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: the arms place 4 and 5 dummies and read the outcome after the cast; crows below the gate, none at
  it, or an unstruck dummy alert; malformed gates are refused.
- Witch Hunter: `500056 darkflock_below behaviour_fixed_count` and `500056 darkflock_at behaviour_fixed_count`.
