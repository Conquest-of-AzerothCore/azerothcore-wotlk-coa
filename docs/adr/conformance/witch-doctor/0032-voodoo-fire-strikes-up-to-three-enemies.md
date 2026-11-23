# 0032. Voodoo Fire strikes up to three enemies

- Status: accepted
- Date: 2026-11-22

## Context

Voodoo Fire 802262 and 803846: the ward's shot can deal Fire damage "to up to $500473x1 nearby enemies" (3,
EffectChainTarget[0] of 500473). The ward casts 500473 at each of up to 3 enemies near its target
(`AscensionWitchDoctorSummons.cpp`, the Voodoo Fire roll), and the load contract retargets 500473 to
TARGET_UNIT_TARGET_ENEMY but kept EffectChainTarget 3, so every cast also chained to 2 more enemies: one proc could
strike 9 times. The cycle 12 sweep 20261122-053609 read 27 hits over three forced procs on four dummies 3 yd apart
against at most 9 (`802262 voodoo_targets`, `803846 voodoo_targets`). The live combat logs (2026-05 to 2026-08,
aggregates) hold 1705 Voodoo Fire bursts, 98.8% of them on at most 3 distinct targets.

## Decision

- The load contract sets EffectChainTarget 0 on 500473: the ward's own pick of up to 3 enemies is the target cap.

## Consequences

- Regression: `802262 voodoo_targets` and `803846 voodoo_targets` (6 to 9 hits over three procs).
