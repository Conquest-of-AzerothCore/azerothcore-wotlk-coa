# Ally interact (`metric_delta` `ally_interact`, ADR 1220, provisional)

`ally_interact` makes the grouped `ally` (from `ally_arm`) interact with a creature the trigger leaves behind, through
the harness `gossip_hello` with `entry`, 1500 ms after each trigger cast. The entry measures the ally
(`measure_actor: "ally"`), casts the trigger at the caster and has no setup casts or swings. Place the ally inside
the interaction distance of the creature with `ally_offsets`, so the step does not walk it (calibration read rb7,
2026-11-22: 3 yd, no walk). Two forms:

- `{"entry": N, "bearing"?: degrees, "bearing_tolerance"?: degrees}` (blink): `cast_in_before: false` and the ally's
  `position_x` without fields. The after phase interacts once; the judged readings become the ally's 2D displacement
  from right before the interaction (right before the reading in the uncast before phase) to the reading, the
  evidence metric `displacement_2d` of the `displacement` option. A `bearing` also judges the direction from the
  ally's facing at its start, as `displacement` does.
- `{"entry": N, "lockout_aura": A, "return_yd": d}` (lockout): `cast_in_before: true`, a `cast_power`, and the ally's
  `aura_apply_count` of `A`. The before phase first casts the trigger and interacts; the caster and the ally are then
  moved back `d` yd along x (relocate steps of at most 20 yd), so each new creature stands where the ally is. The
  before phase's trigger and try come 0.9 x the DBC duration of `A` after the first try (refused), the after phase's
  1.1 x after it (accepted). The builder sets the first wait and refuses an `expire_ms` that misplaces the accepted
  try, naming the one that fits.

The scenario timeout is recomputed with the added waits. Absent, the scenario is unchanged.

Sun Cleric: Sun Gate 802161 `ally_blink` (ledger row 327, claim 2: the ally blinks 25 yd forward) and
`ally_lockout` (row 328: "Allies can only use Sun Gate every $802148d", refused at 81 s, accepted at 99 s).
