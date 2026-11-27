# 1331. Conformance percentage power costs for Energy, zero-mana classes, and rolled per-tick foreign totals

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-27
- Rulings: Felsworn (class 14) extra-spell catch-up (`523495` *Greater Man'ari Intuition*, `804220` *Betray*, `532229` *Twisted Sight*, `954534` *Enslave Elemental*, `802075` *Blood of Mannoroth*, `705121` *Sunder* / `556503`)

## Context

Catching up Felsworn's server-granted `extra_spells` (class 14, per ADR 1327) surfaced three shared conformance gaps in
`values.py`, `hits.py`, and `compare.py`:

1. **Zero-mana classes with `POWER_MANA` percentage costs**: Felsworn has `GetCreateMana() == 0` (`player_class_stats`
   `BaseMana = 0`), yet carries spells with `PowerType = 0` (`POWER_MANA`) and `ManaCostPercentage > 0` (`532229`
   *Twisted Sight* 4%, `954534` *Enslave Elemental* 27%), whose `SpellInfo::CalcPowerCost` resolves to `0`. Previously
   `base_mana_for_power_cost` rejected `base_mana.value <= 0`, blocking both zero-mana percentage costs and opt-in
   `base_health` (`802075` *Blood of Mannoroth*, 20% of `BaseHP = 1563`) on non-mana classes.
2. **Percentage costs on `POWER_ENERGY`**: `523495` (*Greater Man'ari Intuition*, 24% Energy) and `804220` (*Betray*,
   15% Energy) use `PowerType = 3` (`POWER_ENERGY`) with `ManaCost = 0` and `ManaCostPercentage > 0`. The server computes
   `CalculatePct(GetCreatePowers(POWER_ENERGY), ManaCostPercentage)` (`SpellInfo.cpp:3224`, `100` base Energy), giving
   `24` and `15` Energy. Previously `values.py` marked these `unreadable` and `cast_steps` / `ally_grant_proofs` only
   seeded Energy when flat `ManaCost > 0`.
3. **Rolled `per_tick_foreign_totals`**: `705121` (*Sunder*) displays `${($556503d*1000/$556503T1)*($556503m1*$<scalingbp>+$AP*0.12)}`
   where `556503` (*Sunder* DoT) has `EffectBasePoints[0] = 94, EffectDieSides[0] = 2` (4 ticks over 12 s) and is
   scheduled in C++ (`AscensionFelswornAbilities.cpp:455-482`) rather than as a DBC periodic effect on `705121`.
   Previously `per_tick_ticks` refused rolled `EffectDieSides` and `judge_token` skipped `judge_roll` whenever `ticks`
   was set, leaving `705121 effect_value 556503e0 #1` `unmodelled`.

## Options

- Special-case Felsworn spell IDs or leave percentage Energy/zero-mana costs unreadable: rejected; non-mana classes
  share the same `SpellInfo::CalcPowerCost` semantics and `per_tick_foreign_totals` already models per-tick totals.
- Extend the opt-in `base_mana_power_cost` contract to accept `base_mana.value >= 0` and optional `base_energy`, seed
  resolved Energy percentage costs before casts, and allow `per_tick_foreign_totals` to sample and judge rolled
  effects via `judge_roll`. Chosen.

## Decision

1. **Zero-mana `base_mana` and opt-in `base_energy` in `apps/coa-gameplay-test/conformance/values.py` & `hits.py`**:
   - Allow `base_mana.value >= 0` (rejecting `< 0` and non-`int`) when `base_mana_power_cost: true`. In
     `hits.base_mana_steps`, return `[]` when `base['value'] <= 0` and `cost <= base['value']`.
   - Add `ENERGY = 3`, `BASE_ENERGY_KEY = 'base_energy'`, and `base_energy_for_power_cost(class_file)` requiring
     `base_mana_power_cost: true` and `{"power": 3, "value": int > 0}`.
   - Extend `power_cost_expectation` to resolve `POWER_ENERGY` percentage costs as
     `ManaCost <flat> + <pct>% of base_energy <base> divisor <divisor>`, and update `compare.py`
     `BASE_MANA_COST_DIVISOR` to match `base_(?:mana|health|energy)`.
   - Add `cast_power_cost(facts, base_energy)` so `cast_steps` and `ally_grant_proofs` seed Energy with the resolved
     percentage cost when `facts.power_type == ENERGY` and `base_energy` is configured. Preserve
     `PERCENT_POWER_COST_CONTRACT` verbatim for mana/health spells and use `PERCENT_ENERGY_COST_CONTRACT` for Energy
     percentage spells so existing class snapshots remain byte-identical.
2. **Rolled `per_tick_foreign_totals` in `values.py` & `compare.py`**:
   - Allow `per_tick_ticks` on rolled `EffectDieSides` and invoke `sample_rolled` for listed `per_tick_foreign_totals`
     entries in `value_scenario`.
   - In `compare.py`, allow `judge_token` to dispatch rolled `PER_TICK_TICKS` expectations to `judge_roll`, which
     divides each rolled tooltip evaluation by `ticks` before computing the per-tick mean, sigma, and truncation check.
   - Leave `tooltip.py:amplitude_ms` (`AttributesEx5 0x2000`) untouched so existing classes are unaffected.

## Consequences

- Zero diff on all seven existing finished/in-flight class snapshots (`13, 14, 15, 19, 20, 25, 27`).
- Non-mana classes opting into `base_mana_power_cost: true` can prove `POWER_MANA` (`0`), `POWER_HEALTH`, and
  `POWER_ENERGY` percentage costs in `value_scenario`.
- Rolled foreign periodic totals listed in `per_tick_foreign_totals` (such as `705121` -> `556503e0`) are sampled and
  judged per tick without breaking fixed-roll entries (such as `802678`).
- Unit tests in `test_values.py` and `test_compare.py` cover zero-mana, `base_energy`, Energy seeding, invalid configs,
  and rolled `per_tick_foreign_totals` judging.
