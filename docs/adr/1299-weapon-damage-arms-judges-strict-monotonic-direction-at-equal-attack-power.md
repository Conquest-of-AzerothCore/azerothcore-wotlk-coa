# 1299. Weapon damage arms judges strict monotonic direction over three main-hand weapons at equal attack power

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-38, D-39
- Follows [ADR 1295](1295-stat-arms-judges-strict-monotonic-direction-with-unrelated-control.md)

## Context

Cultist (class 25) passive Void Power 574147 (row 211) states:

> "Your healing power is increased based on your main-hand weapon damage."

`AscensionCultist.cpp:291-292` and `AscensionCultistAuras.cpp:135-136` set effect 0 of 574147
(`SPELL_AURA_MOD_HEALING_DONE`, all schools) to `int32((UNIT_FIELD_MINDAMAGE + UNIT_FIELD_MAXDAMAGE) / 2)`, refreshed
every 500 ms. In `StatSystem.cpp:693-728` (`Player::CalculateMinMaxDamage`), unnormalized `UNIT_FIELD_MINDAMAGE` and
`UNIT_FIELD_MAXDAMAGE` include `(BaseAttackTime / 1000) * AP / 14`, so arms whose unhasted base weapon delay
(`ItemTemplate::Delay` / `speed_ms`) or weapon `subclass` rises alongside weapon damage leave weapon damage confounded
with weapon speed and weapon type.

An earlier entry used `attack_power_arms` (`+980` AP), which confounded attack power with main-hand weapon damage: a
mutant scaling healing power directly off attack power with zero weapon dependence passed (review `cu-rt2` I1).
A first `weapon_damage_arms` entry used `[2534, 2535, 2531]` whose unhasted base delay (`1600 < 3300 < 3600 ms`) and
weapon subclass (`15 / 10 / 1`) rose together with weapon damage (review `cu-rtb2` I1).
`stat_arms` (ADR 1295) varies a stat through auras rather than swapping equipped main-hand items, and does not assert
constant attack power across arms.

## Options

- Extend `stat_arms` to accept both aura-driven stats and item swaps: widens an already-used option's schema and mixes
  aura stacking with item equipping and cross-arm attack-power constancy checks.
- Add a dedicated sibling opt-in option `weapon_damage_arms` (`metric_delta_options/weapon_damage_arms.py`) modeled on
  `stat_arms` (D-38, `FORBIDS_EXPECTED = True`), swapping three or more main-hand weapons declared in the class file at
  equal attack power.

## Decision

Add `metric_delta_options/weapon_damage_arms.py`
([doc](../../apps/coa-gameplay-test/conformance/docs/metric_delta_options/weapon_damage_arms.md)) with
`FORBIDS_EXPECTED = True`:

- Accepts only `{weapons, unrelated, wait_ms}` and refuses any expected figure, gain, ratio, bound or `phase_power`
  (D-38).
- Requires at least 3 distinct main-hand items declared in the class file (`weapon`, `alternate_weapons` or
  `weapon_sets[*].main_hand`), granting missing items and setting missing skill lines before the first swap.
- Refuses to generate unless every declared weapon arm carries valid `subclass` and `speed_ms` metadata and all arms
  share one identical `subclass` and one identical unhasted base `speed_ms`, eliminating weapon-speed and weapon-type
  confounding.
- In both the unlearned control phase and the learned phase, equips each weapon in slot 15, waits `wait_ms`, and reads
  `equipped_item` (slot 15), `weapon_damage_min`, `attack_power` and the judged output metric. Then re-equips
  `weapons[0]` and runs an unrelated-stat control (`unrelated` aura applied, unrelated stat read before/after along with
  `equipped_item`, `weapon_damage_min`, `attack_power` and the judged output).
- Voids as `unmeasured` if any weapon fails to equip, `weapon_damage_min` fails to rise strictly or differs across
  phases, `attack_power` differs across any read (`> 0.5`), or the unrelated stat fails to rise or perturbs
  `weapon_damage_min` / `attack_power`.
- Judges `ok` iff learned gains `learned[i] - control[i]` strictly rise across all `>= 3` weapons (`gain[0] >= -tol`,
  `gain[i+1] > gain[i] + tol`) and the unrelated-stat gain matches `weapons[0]` within `tol`. No figure or slope is
  asserted.

## Evidence class

Uses the entry's own `STATE` metric (`healing_power`, already in `coverage.METRIC_EVIDENCE` with
`STATE_PROMISES['healing_power'] = r'healing power|healing done'`) under `LEARNED_CONTRAST` over three measured
main-hand weapons at verified equal attack power plus an unrelated-stat control — genuine `behaviour` evidence without
altering `coverage.py`.

## Consequences

- Purely opt-in sibling option auto-discovered by `metric_delta_options/__init__.py`; zero edits to shared core files
  and zero change to finished-class scenarios.
- Closes Cultist Void Power 574147 row 211 using three white zero-stat Daggers (shared `subclass` 15, shared unhasted
  base `speed_ms` 1600 ms, `InventoryType` 13, `skill_line` 173): Worn Dagger 2092 (`1.1607-3.4821`), Kris 2209
  (`15.36-25.6`) in `alternate_weapons`, and Rondel 2534 (`28.46-45.46`) in `weapon_sets.Dreadnought.main_hand`, all at
  equal attack power `376.0`, with Haste Rating 10033 as the unrelated-stat control.
- Seeded tests cover `ok`, mutants/alerts (flat, plateau, falling, unrelated movement), `unmeasured` (missing read, AP
  confound, non-rising weapon damage, wrong equipped item, broken unrelated fixture, cast failure) and refusals
  (including differing `subclass`, differing `speed_ms`, and missing weapon metadata).
