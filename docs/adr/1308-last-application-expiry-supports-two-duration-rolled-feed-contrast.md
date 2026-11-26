# 1308. `last_application_expiry` supports two-duration rolled-feed contrast

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Builds on: ADR 0593 (`last_application_expiry`), ADR 1297 (`feed.stop_target`), ADR 1305 (two-arm contrast)

## Context

Cultist Teachings of Mythrax `561035` states `"Increases the duration of Presence of N'Zoth and Presence of Y'Shaarj by
$s1%."` (`Spell.dbc` Effect[0] aura 108 `SPELLMOD_DURATION`, `BasePoints = 24, DieSides = 1 -> +25%`, `ProcChance =
100`). In `AscensionCultistEvents.cpp:27-33,100-104,249-260`, Presence of N'Zoth (`803037`, active stance, `ProcChance =
20`) procs `500707` on the caster (`8000 -> 10000 ms`), and Presence of Y'Shaarj (`803035`, active stance, `ProcChance =
20`) procs `805180` Despoiled Ground on the target (`12000 -> 15000 ms`, `ModifiedDuration` on `807632`).

Even after ADR 1297 added `feed.stop_target`, `last_application_expiry` refused `561035` for two reasons:
1. `feed_casts` read `ProcChance` from `gate_spell` (`561035`, `ProcChance = 100`), refusing it because the rolled proc
   lives on the separate active Presence stance (`803037` / `803035`, `ProcChance = 20`) which must be learned and cast
   before control.
2. `last_application_reading` hard-alerted on any control application (`0 -> 1` gate model), whereas `561035` extends
   an existing non-zero base duration (`8000 -> 10000 ms` and `12000 -> 15000 ms`).

## Decision

Extend `kinds/last_application_expiry.py` with four opt-in fields (pure Python, zero C++ harness changes):

- `control_expected_ms`: positive baseline duration (ms) expected in the control arm; requires `feed` with `proc_spell`,
  strictly disjoint G-19 bands between `control_expected_ms` and `expected_ms`, and `control_window_ms >
  control_expected_ms + bonus_band(control_expected_ms)`. Refuses `same_stamp_applies`.
- `feed.proc_spell`: spell id (distinct from `gate_spell`, present in `base_learn`) whose DBC `ProcChance` in `(0, 100)`
  sizes both arms' `cast_until_aura` cap at `FEED_RESIDUAL / 2 = 0.00025` per arm so the 2-run pair union bound across
  4 fed arms stays `<= 0.1%` (`38` casts/arm at `20%`: `4 * 0.80^38 = 0.083%`).
- `base_learn`: non-empty list of distinct spell ids learned before control (omitting `gate_spell` and `trigger_spell`).
- `base_casts`: optional non-empty subset of `base_learn` cast on the caster before control (to activate stances).

To stamp both arms without opening a second timeline (`CoAGameplayTest.cpp:8362` permits one `encounter_start` per
scenario), one encounter timeline opens before the control feed and stays open through treatment:
- Control checks `timeline_count == 1`, `remaining > 0`, age `control[1].time - start - timeline_first_ms <= 100 ms`,
  and expiry bracket inside `control_expected_ms +- band`.
- Treatment checks `timeline_count == 2`, `remaining > 0`, age
  `treatment[1].time - start - (control_first + timeline_interval_max_ms) <= 100 ms`, and expiry bracket inside
  `expected_ms +- band`, strictly separated from control.

## Consequences

- Strictly opt-in: omitted `control_expected_ms` leaves existing single-duration `feed` and non-feed entries
  byte-identical across all finished classes; zero C++ changes.
- Unlocks Cultist Teachings of Mythrax `561035` row 196 across both named Presences (`803037` N'Zoth `8000 -> 10000 ms`
  on caster, `803035` Y'Shaarj `12000 -> 15000 ms` on dummy).
- Seeded tests in `test_last_application_expiry.py` (`TwoDurationFeedTests`) cover both caster and target generation,
  `ok`, mutants (no-op talent, pre-extended control, wrong bonus, wrong entry expectations, lingering aura),
  `unmeasured` (cap hit, pre-existing aura, stale age, bad apply counts, `NaN` interval), and 15 refusal cases.
