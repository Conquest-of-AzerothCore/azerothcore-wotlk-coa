# Summon retarget out of range (`behaviour_metric_delta`, `kind: "summon_retarget_out_of_range"`, ADR 1313, provisional)

ADR 1313 has a provisional number and is renumbered at merge (guide 14.4).

Proves that a summoned creature seeks and afflicts a second engaged enemy when its initial target runs beyond its target
range, contrasted against an in-range control arm where the initial target stays put and the second enemy is left
unafflicted. Zero harness C++ changes: reuses `dx`/`dy` creature placement, `creature_attack`, `set_aura`, `move_point`,
`owned_creature_count`, `owned_creature_distance_2d`, `aura`, and `combat`.

## Scenario and judgement

- **Fixtures:** Movable primary `dummy` at `(primary_dx, primary_dy)` (`stationary: false`) and stationary secondary
  `area1` at `(secondary_dx, secondary_dy)` (`stationary: true`, inside `secondary_max_range_yd` of `dummy` and outside
  melee reach of `caster`), engaged in combat with `caster` via `creature_attack`. Optional `speed_aura` (e.g. Sprint
  `11305`) is applied identically to `dummy` in both arms so movement speed is never confounded.
- **Control arm (in-range):** Casts `trigger_spell` on `dummy`, confirms the summon (`entry`) spawns, applies
  `effect_aura` to `dummy` and not `area1`, and holds `dummy` in range across `pre_pulse_wait_ms + post_pulse_wait_ms`.
  Alerts if `area1` receives `effect_aura` while `dummy` stayed within `max_range_yd`.
- **Between-arm cleanup:** Waits `expire_wait_ms` and verifies `owned_creature_count == 0` and `effect_aura == 0` on
  both `dummy` and `area1`.
- **Treatment arm (out-of-range):** Casts `trigger_spell` on `dummy`, confirms the same initial state, issues
  `move_point` `(move_dx, move_dy)` on `dummy`, verifies at `pre_pulse_wait_ms` that `dummy` cleared `max_range_yd`
  while the summon lives, then verifies at `post_pulse_wait_ms` that the summon still lives, `dummy` stays beyond
  `max_range_yd`, `area1` remains in combat and within `secondary_max_range_yd`, and `area1` now carries `effect_aura == 1`.
- **Evidence class:** Uses `metric: "aura"` (`event` in `coverage.METRIC_EVIDENCE`, counted as `behaviour`).

Cultist: Tentacle of N'Zoth `572103` row 206 (`entry: 501464`, `effect_aura: 806596`, `move_dx: 50`, `max_range_yd: 40`,
`secondary_max_range_yd: 30`, `speed_aura: 11305`).
