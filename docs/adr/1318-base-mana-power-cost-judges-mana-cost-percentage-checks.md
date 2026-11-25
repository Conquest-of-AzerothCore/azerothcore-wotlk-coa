# 1318. Opt-in `base_mana_power_cost` checks `ManaCostPercentage` application against server create mana/health

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist class-end pair 2 diagnosis (`power_cost` `ManaCostPercentage` `unreadable` checks), amended for `POWER_HEALTH` (`base_health`) and scope clarification after independent review `cu-rev7`

## Context

`values.power_cost_expectation` previously marked every spell with `ManaCostPercentage > 0` as
`unreadable: ManaCostPercentage <N> needs the base power of the caster`, even though `value_scenario` already
measures `spell_power_cost` (`CoAGameplayTest.cpp:6006-6011`, calling `SpellInfo::CalcPowerCost` before any cast)
and class files already record `"base_mana": {"power": 0, "value": <N>}` (ADR 0688).

WoW 3.3.5a client DBC has no per-level base mana or base health table. In Cultist (class 25), `cultist.json`
records the **server's** level-60 create mana and create health from `player_class_stats` (`CoA.ClassLevelSixtyStats.Enable = 0`,
`src/server/coa/conf/coa.conf.dist:156`, loaded by `ObjectMgr::LoadPlayerInfo` at `ObjectMgr.cpp:4964-4971`):
- `base_mana = {"power": 0, "value": 1512}` (`player_class_stats` compatibility curve via Paladin `fallback_class = 2`,
  `rev_20260912_00_custom_class_stat_progression.sql:3,9-10`, whereas `ascension_class_stats` in
  `rev_20261105_95_coa_class_level_sixty_stats.sql:62` has `1814`), covering 105 `POWER_MANA` (`0`) spells;
- `base_health = {"value": 1418}` (`rev_20260903_01_live_class_baseline.sql:933` L1 `BaseHP = 65` + Paladin L60 `1381`
  - L1 `28` via `rev_20260912_00_custom_class_stat_progression.sql:7-8`, whereas `ascension_class_stats` has `3502`),
  covering 1 `POWER_HEALTH` (`-2` / `4294967294`) spell (`681104` Voidborne, `10%` -> `141`).

### Explicit scope and limitation

Because the expected cost multiplies client/DBC `ManaCostPercentage` by the **server's** create mana (`GetCreateMana()`)
or create health (`GetCreateHealth()`) taken from the same server `player_class_stats` table that
`SpellInfo::CalcPowerCost` (`SpellInfo.cpp:3205-3217`) reads:

1. **What the check proves:** that the server applies the tooltip/DBC `ManaCostPercentage` (plus flat `ManaCost`) to
   `GetCreateMana()` / `GetCreateHealth()` inside `SpellInfo::CalcPowerCost` — detecting a wrong percentage, a wrong
   contract override, `UsesMaxManaForCost` misuse, or unintended cost modifiers in `CalcPowerCost`.
2. **What the check does NOT prove:**
   - It does **NOT** prove that the server's base mana (`1512` vs `1814`) or base health (`1418` vs `3502`) table
     value itself is right (a wrong server base value passes because both expected and observed multiply by the same
     table row).
   - The observed metric `spell_power_cost` is the server's **computed** cost from `SpellInfo::CalcPowerCost`, **not**
     mana or health actually deducted during a live cast.

Finished classes 13 (Witch Doctor), 15 (Witch Hunter), and 27 (Sun Cleric) already carry `"base_mana"` in their class
files. Changing `power_cost_expectation` unconditionally would alter their generated `manifest.json` files.

## Options

- Compute `ManaCostPercentage` expectations unconditionally whenever `class_file` contains `base_mana`: rejected,
  because it changes generated `manifest.json` for finished classes 13, 15, and 27.
- Apply `base_mana` to all `ManaCostPercentage` spells regardless of `PowerType`: rejected, because
  `SpellInfo::CalcPowerCost` (`SpellInfo.cpp:3209-3217`) uses `GetCreateMana()` only for `POWER_MANA (0)` and
  `GetCreateHealth()` for `POWER_HEALTH (-2)`.
- Gate `ManaCostPercentage` judgement on an explicit opt-in boolean `"base_mana_power_cost": true` in the class file,
  using the server's `base_mana.value` when `facts.power_type == MANA (0)` and optional `base_health.value` when
  `facts.power_type == HEALTH_POWER (4294967294)` (and `not facts.mana_cost_per_level`), and state the server-table
  / `CalcPowerCost` scope explicitly in the ADR, tool docs, class-file sources, and generated scenario contract. Chosen.

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
- Append `PERCENT_POWER_COST_CONTRACT` to the generated value scenario's `contract` whenever a percentage `power_cost`
  expectation is judged under `base_mana_power_cost`, stating explicitly that it checks `ManaCostPercentage` against
  server create mana/health in `SpellInfo::CalcPowerCost`, not that the base table value is right or that power was
  spent in a cast.
- Other percentage power types (or `POWER_HEALTH` when `base_health` is omitted) remain `unreadable`.
- In `compare.py`, match `BASE_MANA_COST_DIVISOR` (`base_(?:mana|health)`) alongside `COST_DIVISOR` for `power_cost`
  checks and compare `measured / divisor` against `float(expectation.displayed)` using the existing `deterministic`
  band (`max(1, 0.5% of expected)`).
- When `base_mana_power_cost` is omitted or `false`, generated manifests and scenarios are byte-identical.

## Consequences

- Purely opt-in via `"base_mana_power_cost": true` (and optional `"base_health"`) in `cultist.json`; zero diff on
  finished classes 13, 14, 15, 19, 23, and 27.
- Makes all 106 Cultist percentage `power_cost` checks (105 mana + 1 `POWER_HEALTH` `681104` Voidborne) readable and
  judged against `spell_power_cost` (`CalcPowerCost`), with the server-table limitation documented openly everywhere
  the check is described.
- Unit tests in `test_values.py` and `test_compare.py` verify mana-percentage and health-percentage expectations,
  contract text honesty, missing-`base_health` preservation, default identity, `ok`/`alert` comparison, and input
  validation.
