# 1318. Opt-in `base_mana_power_cost` judges `ManaCostPercentage` mana and health costs

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist class-end pair 2 diagnosis (`power_cost` `ManaCostPercentage` `unreadable` checks), amended for `POWER_HEALTH` (`base_health`)

## Context

`values.power_cost_expectation` previously marked every spell with `ManaCostPercentage > 0` as
`unreadable: ManaCostPercentage <N> needs the base power of the caster`, even though `value_scenario` already
measures `spell_power_cost` and class files already record `"base_mana": {"power": 0, "value": <N>}` (ADR 0688).

In Cultist (class 25), `cultist.json` records `base_mana = {"power": 0, "value": 1512}` and
`player_class_stats` gives level-60 `BaseHP = 1418` (`rev_20260903_01_live_class_baseline.sql` level-1
`BaseHP = 65` + `player_class_stats.sql` `fallback_class = 2` level-60 `BaseHP = 1381` - level-1 `BaseHP = 28` via
`rev_20260912_00_custom_class_stat_progression.sql`, `CoA.ClassLevelSixtyStats.Enable = 0`), yet 106 `power_cost`
verdicts were `unreadable`: 105 with `PowerType == 0` (`POWER_MANA`) and 1 spell (`681104` Voidborne) with
`PowerType == 4294967294` (`POWER_HEALTH`, `-2`), whose cost in `SpellInfo::CalcPowerCost` (`SpellInfo.cpp:3212-3214`)
is `int32(CalculatePct(caster->GetCreateHealth(), ManaCostPercentage))` = `floor(1418 * 10 / 100) = 141`.

Finished classes 13 (Witch Doctor, 214 spells), 15 (Witch Hunter, 69 spells), and 27 (Sun Cleric, 111 spells)
already carry `"base_mana"` in their class files. Changing `power_cost_expectation` unconditionally would alter
their generated `manifest.json` files.

## Options

- Compute `ManaCostPercentage` expectations unconditionally whenever `class_file` contains `base_mana`: rejected,
  because it changes generated `manifest.json` for finished classes 13, 15, and 27.
- Apply `base_mana` to all `ManaCostPercentage` spells regardless of `PowerType`: rejected, because
  `SpellInfo::CalcPowerCost` (`SpellInfo.cpp:3209-3217`) uses `GetCreateMana()` only for `POWER_MANA (0)` and
  `GetCreateHealth()` for `POWER_HEALTH (-2)`.
- Gate `ManaCostPercentage` judgement on an explicit opt-in boolean `"base_mana_power_cost": true` in the class file,
  using `base_mana.value` when `facts.power_type == MANA (0)` and optional sourced `base_health.value` when
  `facts.power_type == HEALTH_POWER (4294967294)` (and `not facts.mana_cost_per_level`). Chosen.

## Decision

Extend `values.py` and `compare.py` ([value-scenarios.md](../../apps/coa-gameplay-test/conformance/docs/value-scenarios.md),
[generate-and-compare.md](../../apps/coa-gameplay-test/conformance/docs/generate-and-compare.md)):

- Add top-level optional class-file boolean `base_mana_power_cost` (`BASE_MANA_POWER_COST_KEY = 'base_mana_power_cost'`,
  default `False`, rejecting non-boolean values or `True` without a valid `base_mana` `{power: 0, value: >0}`) and
  optional `base_health` (`BASE_HEALTH_KEY = 'base_health'`, `{value: >0, source: ...}`, validated only when
  `base_mana_power_cost` is `True` and `base_health` is present).
- In `values.power_cost_expectation`, when `facts.mana_cost_percentage > 0` and `not facts.mana_cost_per_level`:
  - if `base_mana` is provided and `facts.power_type == MANA (0)`:
    - compute `expected = facts.mana_cost + (base_mana * facts.mana_cost_percentage) // 100`,
    - emit `displayed = str(expected // divisor)` and
      `rule = f'ManaCost {facts.mana_cost} + {facts.mana_cost_percentage}% of base_mana {base_mana} divisor {divisor}'`.
  - elif `base_health` is provided and `facts.power_type == HEALTH_POWER (4294967294)`:
    - compute `expected = facts.mana_cost + (base_health * facts.mana_cost_percentage) // 100`,
    - emit `displayed = str(expected // divisor)` and
      `rule = f'ManaCost {facts.mana_cost} + {facts.mana_cost_percentage}% of base_health {base_health} divisor {divisor}'`.
- Other percentage power types (or `POWER_HEALTH` when `base_health` is omitted) remain `unreadable`.
- In `compare.py`, match `BASE_MANA_COST_DIVISOR` (`base_(?:mana|health)`) alongside `COST_DIVISOR` for `power_cost`
  checks and compare `measured / divisor` against `float(expectation.displayed)` using the existing `deterministic`
  band (`max(1, 0.5% of expected)`).
- When `base_mana_power_cost` is omitted or `false`, generated manifests and scenarios are byte-identical.

## Consequences

- Purely opt-in via `"base_mana_power_cost": true` (and optional `"base_health"`) in `cultist.json`; zero diff on
  finished classes 13, 14, 15, 19, 23, and 27.
- Makes all 106 Cultist percentage `power_cost` checks (105 mana + 1 `POWER_HEALTH` `681104` Voidborne) readable and
  judged against `spell_power_cost`.
- Unit tests in `test_values.py` and `test_compare.py` verify mana-percentage and health-percentage expectations,
  missing-`base_health` preservation, default identity, `ok`/`alert` comparison, and input validation.
