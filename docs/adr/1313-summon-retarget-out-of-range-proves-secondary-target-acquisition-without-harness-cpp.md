# 1313. Summon retarget out of range proves secondary-target acquisition without harness C++

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-39 (revisited under G-25)

## Context

Cultist (class 25) Tentacle of N'Zoth `572103` (`Spell.dbc`, `/srv/coa/server-data/dbc`, row 206) states:

> "If your target runs out of range, the tentacle will seek a new target."

In `Spell.dbc` (`/srv/coa/server-data/dbc`, sha256 `4e4ed9ba1c2e...`), BOTH `572103` (Tentacle of N'Zoth) and `806596`
(Thoughtseize, the silence + periodic Shadow damage spell referenced by `$806596m2`/`$806596t2`/`$806596d` in `572103`'s
tooltip) carry `RangeIndex = 11` (`SpellRange[11]`: `RangeMin = 0.0`, `RangeMax = 15.0 yd`, `"Fifteen yards"`). `806596`
also carries `AttributesEx = 16388` (`SPELL_ATTR1_IS_CHANNELED | SPELL_ATTR1_TRACK_TARGET_IN_CHANNEL`, matching its twin
`289151`); in AzerothCore's channeled-spell engine (`Spell.cpp:3473-3514`), a channeled `APPLY_AURA` spell breaks and
removes its aura once the target exceeds `GetMaxRange()` (`15.0 yd` + `1.5 yd` channel tolerance).

By contrast, our server implementation (`AscensionCultistAbilities.cpp:508`,
`AscensionCultistSummons.cpp:72-75,187-201,220-239,255-260,335,363`) summons `501464` for `8000 ms`, calls
`player->AddAura(Thoughtseize, target)` instead of having the tentacle channel `806596`, and on the `6000 ms` `Pulse`
uses the generic `Target(player)` helper's hardcoded `me->IsWithinDistInMap(unit, 40)` (`:226`) and `Nearby(me, 30)`
(`:235`). Neither `40 yd` nor `30 yd` appears anywhere in `Spell.dbc` or SQL for Tentacle of N'Zoth; `Target(player)`
also reacts to `me->IsWithinLOSInMap(unit)` (`:226`) and `unit->IsAlive()` (`:224`), and `ApplyThoughtseize`
(`:187-201`) applies `806596` to the new target without removing `806596` from the original target.

Earlier triage (`cu-rt3/review.md:182-189,206`, D-39) deferred this claim assuming a new C++ creature `relocate` action
was needed. However, `CoAGameplayTest.cpp:8092-8105` and `run.py:951` already provide `move_point` on non-stationary
fixture creatures up to `±100 yd` with speed auras applied, `CoAGameplayTest.cpp:8127-8148` already provides
`creature_attack` to engage a second enemy in combat, `CoAGameplayTest.cpp:9210` already records `line_of_sight` on
every player `cast` step, and ADR 1307 already added explicit 2D `(dx, dy)` creature placement. Zero C++ changes are
required.

## Options

- Add a new creature `relocate` C++ harness action. Rejected: unnecessary once `move_point` (`±100 yd`) with symmetric
  speed aura, `cast` `line_of_sight` diagnostics, and 2D `(dx, dy)` placement cover the full out-of-range check
  natively.
- Adapt the `572103` entry's thresholds to the server's hardcoded `40 yd` / `30 yd`. Rejected: `Spell.dbc` fixes
  `RangeIndex = 11` (`15.0 yd`) on both `572103` and the tentacle's channeled spell `806596`; adapting to `40 yd` would
  mask a genuine server/data contradiction.
- Add a pure-Python opt-in kind `summon_retarget_out_of_range` (`ORDER = 62`) that brackets the range threshold, checks
  both `alive` and `line_of_sight` after every move, and tests `572103` against the `15.0 yd` game-data range. Chosen.

## Decision

Add `kinds/summon_retarget_out_of_range.py` (`ORDER = 62`):

- Spawns movable `dummy` at `(primary_dx, primary_dy)` (`stationary: false`) and stationary `area1` at `(secondary_dx,
  secondary_dy)` (`stationary: true`, inside `secondary_max_range_yd` of `dummy` and outside melee reach of `caster`).
- Applies optional `speed_aura` (`11305` Sprint `+70%` on `572103`) identically to `dummy` in every arm so movement
  speed is never confounded, and engages `area1` with `caster` via `creature_attack` in every arm.
- **Line-of-sight and liveness isolation (prevents LOS/death confounds):** Every arm reads `primary_alive` (`alive` on
  `dummy`) at `initial`, `mid`, `end`, and `between` cleanup, and executes a non-`trigger_spell` unlearned `cast` probe
  (`los_probe_spell`, default `133`) from `caster` to `dummy` at `control end` and each treatment arm's `mid` and `end`.
  `summon_retarget_verdict` verifies `spell_active == 'false'` (zero gameplay side effects) and
  `line_of_sight == 'true'` in `run.steps`, voiding as `unmeasured` (never `ok`) if `dummy` loses line of sight or dies.
- **Control arm (in-range bracket):** Casts `trigger_spell` on `dummy`, confirms initial `summon_count == 1`, `dummy`
  `alive == 1`, `dummy` `effect_aura == 1`, `area1` `effect_aura == 0`, `area1` `combat == 1`, optionally moves `dummy`
  by `(control_move_dx, control_move_dy)` just inside `max_range_yd`, holds across `pre_pulse_wait_ms +
  post_pulse_wait_ms`, verifies `dummy` stayed `<= max_range_yd`, `alive == 1`, and `line_of_sight == 'true'`, and
  alerts if `area1` receives `effect_aura`.
- **Cleanup & return:** Returns `dummy` to its starting offset if moved, waits `expire_wait_ms`, and voids as
  `unmeasured` if `summon_count != 0`, `primary_alive != 1`, or either target retains `effect_aura`.
- **Treatment arms (near + far out-of-range bracket):** Supports an optional near move `(near_move_dx, near_move_dy)`
  just beyond `max_range_yd` (with cleanup and return between arms) followed by the far move `(move_dx, move_dy)`. Each
  arm checks at `pre_pulse_wait_ms` (`mid`) only the fields it judges (`summon_count == 1`, `primary_alive == 1`,
  `primary_dist > max_range_yd`, `line_of_sight == 'true'`), then at `post_pulse_wait_ms` (`end`) verifies
  `summon_count == 1`, `primary_alive == 1`, `primary_dist > max_range_yd`, `line_of_sight == 'true'`, `area1` in range
  and combat, and `area1` `effect_aura == 1` (alerts on `0`).
- Uses `metric = 'aura'` (`event` in `coverage.METRIC_EVIDENCE`, zero edits to `coverage.py` or `behaviours.py`).

## Consequences

- Purely opt-in Python kind with zero C++ or shared-core changes; finished classes regenerate byte-identical.
- For Cultist Tentacle of N'Zoth `572103` row 206, the entry uses the clear-LOS south (`-y`) direction (`control -9 yd`,
  `near -22 yd`, `far -50 yd`) against the `Spell.dbc` `15.0 yd` range (`572103` & `806596` `RangeIndex 11`). On our
  current server (`40 yd` / `30 yd` hardcoded at `AscensionCultistSummons.cpp:226,235`), the near arm (`~22 yd > 15 yd`,
  `los=True`, `alive=1`) alerts (`area1 806596 = 0`) while the far arm (`~50 yd`, `los=True`, `alive=1`) retargets
  (`area1 806596 = 1`, leaving `806596` active on `dummy` because `ApplyThoughtseize` calls `AddAura` without clearing
  the previous target). Row 206 therefore stays uncounted until the range contradiction is resolved.
- Seeded tests in `test_summon_retarget_out_of_range.py` cover generation, evidence classification, `ok`, mutants (no
  retarget in near or far treatment, spurious retarget in control, lost line of sight at any check, active probe spell,
  primary death at any check), `unmeasured` (range/cleanup/combat/cast failures, missing reads), and spec refusals.
