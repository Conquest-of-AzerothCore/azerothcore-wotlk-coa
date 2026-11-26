# Outgoing avoidance elimination (`behaviour_metric_delta`, `kind: "outgoing_avoidance_elimination"`, ADR 1312)

ADR 1312 has a provisional number and is renumbered at merge (guide 14.4).

Proves that a learned passive eliminates all three outgoing melee avoidance outcomes (miss, dodge, and parry) against a
facing target, contrasted against an unlearned control arm where all three outcomes actually occur.

## Harness additions (opt-in)

- Creature fixture field `face_caster: true` (`CoAGameplayTest.cpp` `CreateTargets`, `run.py`): orients the spawned
  fixture creature toward its `owner` player (`SetOrientation`, `SetFacingToObject`, and home orientation) so front-arc
  parry is enabled (`Unit.cpp:3411`). Default `false` leaves existing scenarios untouched.
- Read-only player metrics `melee_misses_dealt`, `melee_dodges_dealt`, and `melee_parries_dealt` (`CoAGameplayTest.cpp`
  `ObservePacket`/`Measure`, `run.py`): count outgoing `SMSG_ATTACKERSTATEUPDATE` swings by `hand` (`0` or `1`,
  omitted = both) matching `(hitInfo & HITINFO_MISS) && victimState != VICTIMSTATE_EVADES`, `VICTIMSTATE_DODGE`, and
  `VICTIMSTATE_PARRY`.

## Scenario, sizing and judgement

- **Arms:** Control (before `gate_spell` is learned) and treatment (after a real `learn` of `gate_spell`) run
  sequentially against the same stationary facing dummy (`face_caster: true`, health restored via `set_health` between
  arms) under identical `haste_auras` and identical `window_ms` swing windows.
- **Pinned-state verification (start and end of both arms):** Checks `knows_spell(gate_spell)` (`0` in control, `1` in
  treatment), dummy `alive == 1`, `distance_2d <= 5.0 yd`, dummy `position_o` facing `caster` within `0.15 rad`, every
  `haste_aura == 1`, and zero extra swings after `stop_attack` (`post_stop`). Any violation voids as `unmeasured`.
- **Sizing:** `required_min_swings(min_control_rate, residual)` enforces enough swings per arm per run that across a
  2-run pair both the control union-bound false-fail probability `6 * (1 - p)^N` and the treatment union-bound
  false-pass probability `3 * (1 - p)^(2N)` are at most `residual` (default `0.001`: at `p = 0.05`, `N >= 170`).
- **Judgement:** `insufficient_trials` if either arm delivers fewer than `min_swings`; `alert` if control misses any of
  the three avoidance outcomes (`misses < 1`, `dodges < 1`, or `parries < 1`) or if treatment sees any miss, dodge,
  parry, or non-damaging swing (`damaging_hits != swings`); `ok` otherwise.
- **Scope boundaries:** Directly exercises white melee auto-attacks on the configured `hand` (`0` main-hand on `805607`)
  against a facing creature (`face_caster: true` is a test-setup condition enabling control parry, not a tooltip
  restriction; `805607`'s DBC auras `333`/`240` also cover melee special abilities, off-hand swings, and spell hit). The
  `damaging_hits == swings` check assumes no full block reduces a landed hit to `0` damage (verified for War Staff
  `2535` vs entry `36`: `0` full blocks across `1744` swings).
- **Evidence class:** Declares `METRIC_EVIDENCE` (`event`) inside the kind module for all three outgoing avoidance
  metrics (zero edits to `coverage.py`).

Cultist: Shadow Training `805607` row 408 (`min_swings: 200`, `window_ms: 180000`, `haste_auras: [62531, 2116852]`).
