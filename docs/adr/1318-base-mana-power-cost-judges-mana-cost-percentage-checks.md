# 1318. Opt-in `base_mana_power_cost` judges `ManaCostPercentage` mana costs

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist class-end pair 2 diagnosis (`power_cost` `ManaCostPercentage` `unreadable` checks)

## Context

`values.power_cost_expectation` previously marked every spell with `ManaCostPercentage > 0` as
`unreadable: ManaCostPercentage <N> needs the base power of the caster`, even though `value_scenario` already
measures `spell_power_cost` and class files already record `"base_mana": {"power": 0, "value": <N>}` (ADR 0688).

In Cultist (class 25), `cultist.json` records `base_mana = {"power": 0, "value": 1512}`, yet 106 `power_cost`
verdicts were `unreadable` (105 with `PowerType == 0` Mana, plus 1 spell `681104` Voidborne with
`PowerType == 4294967294` `POWER_HEALTH` whose cost is 10% of `GetCreateHealth()` rather than base mana).

Finished classes 13 (Witch Doctor, 214 spells), 15 (Witch Hunter, 69 spells), and 27 (Sun Cleric, 111 spells)
already carry `"base_mana"` in their class files. Changing `power_cost_expectation` unconditionally would alter
their generated `manifest.json` files.

## Options

- Compute `ManaCostPercentage` expectations unconditionally whenever `class_file` contains `base_mana`: rejected,
  because it changes generated `manifest.json` for finished classes 13, 15, and 27.
- Apply `base_mana` to all `ManaCostPercentage` spells regardless of `PowerType`: rejected, because
  `SpellInfo::CalcPowerCost` (`SpellInfo.cpp:3209-3217`) uses `GetCreateMana()` only for `POWER_MANA (0)` and
  `GetCreateHealth()` for `POWER_HEALTH (-2)`.
- Gate `ManaCostPercentage` mana-cost judgement on an explicit opt-in boolean `"base_mana_power_cost": true` in
  the class file, applying only when `facts.power_type == MANA (0)` and `not facts.mana_cost_per_level`. Chosen.

## Decision

Extend `values.py` and `compare.py` ([value-scenarios.md](../../apps/coa-gameplay-test/conformance/docs/value-scenarios.md),
[generate-and-compare.md](../../apps/coa-gameplay-test/conformance/docs/generate-and-compare.md)):

- Add top-level optional class-file boolean `base_mana_power_cost` (`BASE_MANA_POWER_COST_KEY = 'base_mana_power_cost'`,
  default `False`, rejecting non-boolean values or `True` without a valid `base_mana` `{power: 0, value: >0}`).
- In `values.power_cost_expectation`, when `base_mana` is provided, `facts.mana_cost_percentage > 0`,
  `not facts.mana_cost_per_level`, and `facts.power_type == MANA (0)`:
  - compute `expected = facts.mana_cost + (base_mana * facts.mana_cost_percentage) // 100`,
  - emit `displayed = str(expected // divisor)` and
    `rule = f'ManaCost {facts.mana_cost} + {facts.mana_cost_percentage}% of base_mana {base_mana} divisor {divisor}'`.
- Non-mana percentage costs (such as `POWER_HEALTH` `681104` Voidborne) remain `unreadable`.
- In `compare.py`, match `BASE_MANA_COST_DIVISOR` alongside `COST_DIVISOR` for `power_cost` checks and compare
  `measured / divisor` against `float(expectation.displayed)` using the existing `deterministic` band
  (`max(1, 0.5% of expected)`).
- When `base_mana_power_cost` is omitted or `false`, generated manifests and scenarios are byte-identical.

## Consequences

- Purely opt-in via `"base_mana_power_cost": true` in `cultist.json`; zero diff on finished classes 13, 14, 15, 19,
  23, and 27.
- Makes all 105 mana-percentage Cultist `power_cost` checks readable and judged against `spell_power_cost`; leaves
  the 1 health-percentage check (`681104` Voidborne) honestly `unreadable` rather than comparing against base mana.
- Unit tests in `test_values.py` and `test_compare.py` verify mana-percentage expectations, non-mana preservation,
  default identity, `ok`/`alert` comparison, and input validation.
