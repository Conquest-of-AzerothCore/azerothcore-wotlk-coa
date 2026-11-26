# Summon retarget out of range (`behaviour_metric_delta`, `kind: "summon_retarget_out_of_range"`, ADR 1313, provisional)

ADR 1313 has a provisional number and is renumbered at merge (guide 14.4).

Proves that a summoned creature seeks and afflicts a second engaged enemy when its initial target runs beyond its target
range while remaining alive and in line of sight, contrasted against an in-range control arm where the initial target
stays within range and the second enemy is left unafflicted. Zero harness C++ changes: reuses `dx`/`dy` creature
placement, `creature_attack`, `set_aura`, `move_point`, `owned_creature_count`, `owned_creature_distance_2d`, `alive`,
`aura`, `combat`, and the `line_of_sight` diagnostic field emitted by player `cast` steps (`CoAGameplayTest.cpp:9210`).

## Scenario and judgement

- **Fixtures:** Movable primary `dummy` at `(primary_dx, primary_dy)` (`stationary: false`) and stationary secondary
  `area1` at `(secondary_dx, secondary_dy)` (`stationary: true`, inside `secondary_max_range_yd` of `dummy` and outside
  melee reach of `caster`), engaged in combat with `caster` via `creature_attack`. Optional `speed_aura` (e.g. Sprint
  `11305`) is applied identically to `dummy` in every arm so movement speed is never confounded.
- **Control arm (in-range):** Casts `trigger_spell` on `dummy`, confirms the summon (`entry`) spawns, `dummy` is alive,
  and `effect_aura` is applied to `dummy` and not `area1`. Optional `(control_move_dx, control_move_dy)` moves `dummy`
  just inside `max_range_yd` so the control brackets the range threshold and exercises `move_point` symmetrically. Holds
  across `pre_pulse_wait_ms + post_pulse_wait_ms`, verifies `dummy` stays `<= max_range_yd`, `alive == 1`, and
  `line_of_sight == 'true'` (via unlearned `los_probe_spell`, default `133`, requiring `spell_active == 'false'`), and
  alerts if `area1` receives `effect_aura`.
- **Between-arm cleanup:** Returns `dummy` to its start coordinates if moved, waits `expire_wait_ms`, and verifies
  `owned_creature_count == 0`, `dummy` `alive == 1`, and `effect_aura == 0` on both `dummy` and `area1`.
- **Treatment arms (out-of-range):** Supports an optional near treatment arm `(near_move_dx, near_move_dy)` just beyond
  `max_range_yd` (with a full cleanup/return between arms) followed by the far treatment arm `(move_dx, move_dy)`. Each
  treatment arm repeats the identical cast and initial check, orders `move_point`, verifies at `pre_pulse_wait_ms`
  (`mid`) that `summon_count == 1`, `dummy` `alive == 1`, `primary_dist > max_range_yd`, and `line_of_sight == 'true'`,
  then verifies at `post_pulse_wait_ms` (`end`) that `summon_count == 1`, `dummy` remains `> max_range_yd`,
  `alive == 1`, and `line_of_sight == 'true'`, `area1` stays in combat and within `secondary_max_range_yd`, and `area1`
  carries `effect_aura == 1` (alerts on `0`). Loss of line of sight or primary death voids as `unmeasured`, never `ok`.
- **Evidence class:** Uses `metric: "aura"` (`event` in `coverage.METRIC_EVIDENCE`, counted as `behaviour`).

Cultist: Tentacle of N'Zoth `572103` row 206 (`entry: 501464`, `effect_aura: 806596`, `max_range_yd: 15`,
`secondary_max_range_yd: 15` from `Spell.dbc` `572103` & `806596` `RangeIndex 11 = 15.0 yd`, bracketing moves along
clear-LOS south `-y`: control `-9`, near `-22`, far `-50`, `speed_aura: 11305`).
