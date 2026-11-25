# 1313. Summon retarget out of range proves secondary-target acquisition without harness C++

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-39 (revisited under G-25)

## Context

Cultist (class 25) Tentacle of N'Zoth `572103` (`Spell.dbc`, row 206) states:

> "If your target runs out of range, the tentacle will seek a new target."

`AscensionCultistAbilities.cpp:508` summons `501464` for `8000 ms` with `dummy` as target. `AscensionCultistSummons.cpp:
72-75,255-260` records `command = dummy->GetGUID()`, immediately applies Thoughtseize `806596` to `dummy`, and schedules
`Pulse` at `6000 ms`. At `6000 ms`, `Target(player)` (`:220-239`) checks `me->IsWithinDistInMap(unit, 40)` on `command`:
if `dummy` remains within `40 yd`, it keeps `dummy` and leaves nearby enemies untouched; if `dummy` has moved beyond
`40 yd`, it falls through to `Nearby(me, 30)` for an enemy with `player->IsInCombatWith(enemy)` and applies `806596` to
it.

Earlier triage (`cu-rt3/review.md:182-189,206`, D-39) deferred this claim assuming a new C++ creature `relocate` action
was needed. However, `CoAGameplayTest.cpp:8059-8072` and `run.py:948-952` already provide `move_point` on non-stationary
fixture creatures up to `±100 yd` with speed auras applied, `CoAGameplayTest.cpp:8094-8115` already provides
`creature_attack` to engage a second enemy in combat, and ADR 1307 already added explicit 2D `(dx, dy)` creature
placement. Zero C++ changes are required.

## Options

- Add a new creature `relocate` C++ harness action. Rejected: unnecessary once `move_point` (`±100 yd`) with symmetric
  speed aura and existing 2D `(dx, dy)` placement cover the full out-of-range run natively.
- Add a pure-Python opt-in kind `summon_retarget_out_of_range` (`ORDER = 62`) using existing harness primitives. Chosen.

## Decision

Add `kinds/summon_retarget_out_of_range.py` (`ORDER = 62`):

- Spawns movable `dummy` at `(primary_dx, primary_dy)` (`stationary: false`) and stationary `area1` at `(secondary_dx,
  secondary_dy)` (`stationary: true`, inside `secondary_max_range_yd` of `dummy` and outside melee reach of `caster`).
- Applies optional `speed_aura` (`11305` Sprint `+70%` on `572103`) identically to `dummy` in both arms so movement
  speed is never confounded, and engages `area1` with `caster` via `creature_attack` in both arms.
- **Control arm:** casts `trigger_spell` on `dummy`, confirms initial `summon_count == 1`, `dummy` `effect_aura == 1`,
  `area1` `effect_aura == 0`, `area1` `combat == 1`, and holds `dummy` stationary across `pre_pulse_wait_ms +
  post_pulse_wait_ms`; alerts if `area1` receives `effect_aura` while `dummy` stays within `max_range_yd`.
- **Cleanup check:** waits `expire_wait_ms` and voids as `unmeasured` if `summon_count != 0` or either target retains
  `effect_aura`.
- **Treatment arm:** repeats the identical cast and initial check, orders `move_point` `(move_dx, move_dy)` on `dummy`,
  checks at `pre_pulse_wait_ms` that `dummy` cleared `max_range_yd` while the summon lives, then checks at
  `post_pulse_wait_ms` that the summon still lives, `dummy` remains beyond `max_range_yd`, `area1` stays in range and
  in combat, and `area1` now carries `effect_aura == 1` (alerts on `0`).
- Uses `metric = 'aura'` (`event` in `coverage.METRIC_EVIDENCE`, zero edits to `coverage.py` or `behaviours.py`).

## Consequences

- Purely opt-in Python kind with zero C++ or shared-core changes; finished classes regenerate byte-identical.
- Closes Cultist Tentacle of N'Zoth `572103` row 206 with combat-event `behaviour` evidence.
- Seeded tests in `test_summon_retarget_out_of_range.py` cover generation, evidence classification, `ok`, mutants (no
  retarget in treatment, spurious retarget in control), `unmeasured` (primary fails to clear range by mid or end, early
  despawn, incomplete cleanup, lost combat, refused cast, missing read), and spec refusals.
