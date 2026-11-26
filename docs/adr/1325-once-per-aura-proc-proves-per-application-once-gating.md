# 1325. `once_per_aura_proc` proves per-application once-only proc gating and recast reset

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-26
- Rulings: Bloodmage (class 20) Bucket 2 tool plan (`681190` Endure the Curse `row#264`)

## Context

Bloodmage's `681190` (*Endure the Curse*) states: "While active, taking damage that would reduce your health below 10%
will instantly heal you for `$681189s1%` of your maximum health. Can only occur once." `aura_ascension_endure_the_curse`
(`AscensionBloodmageVitality.cpp:318-349`) enforces this via a per-aura-instance boolean `_healed` that triggers
`681189` once on the first qualifying hit, suppresses every subsequent qualifying hit while the same `10 s` aura
application persists, and resets only when a fresh `681190` aura is applied.

Existing interval kinds (`proc_gate_interval`, `avoided_icd`) measure timed internal cooldowns across multiple procs,
and `block_charge_strikes` tests aura removal after consuming charges rather than an aura that stays active while
suppressing repeat triggers until reapplied.

## Options

- Approximate once-per-aura with a single-hit `metric_delta`: rejected, because a single hit cannot distinguish a
  once-per-application gate from an uncapped proc that fires on every hit, nor from a permanent lockout that never
  resets on recast.
- Add a dedicated reusable kind `kinds/once_per_aura_proc.py` (`ORDER = 63`) that runs a four-strike sequence
  (pre-aura control, hit 1 and hit 2 inside application 1, then `cancel_aura` + recast + hit 3 inside application 2)
  with strict landed-strike and aura-persistence checks. Chosen.

## Decision

Add `apps/coa-gameplay-test/conformance/kinds/once_per_aura_proc.py` (`ORDER = 63`,
[doc](../../apps/coa-gameplay-test/conformance/docs/kinds/once_per_aura_proc.md)):

- Accept `spell`, `name`, `quote`, `proc_spell`, `strike_spell`, `strike_health`, `strike_max_health`, and optional
  `cast_power`, `label_suffix`, `proc_metric` (default `'spell_heal_count'`, restricted to event metrics),
  `striker_entry`, `wait_ms` (`>= 100`), and `caster_auras` precondition fixtures. Automatically apply `CasterAuraSpell`
  via `required_aura_steps` and validate that both intra-application strikes fit inside `spell`'s duration.
- Run four passive-striker hits at `strike_health / strike_max_health` with regeneration off and avoidance set to `0`:
  1. Control strike before `spell` is cast (`aura == 0`, proc delta `0`).
  2. Cast `spell` (`cast_failure == 0`, `aura == 1`) and land hit 1 (`aura == 1`, proc delta `+1`).
  3. Reset health to `strike_health` while `spell` stays active and land hit 2 (`aura == 1`, proc delta `+0`).
  4. `cancel_aura(spell)` (`aura == 0`), reset cooldown, re-cast `spell` (`cast_failure == 0`, `aura == 1`), reset
     health, and land hit 3 (`aura == 1`, proc delta `+1`).
- Guard every strike with `spell_log_count` delta `== 1` (missed or avoided strikes return `unmeasured`, never a false
  pass on hit 2); alert on control firing, aura dropping on hit 1/2, missing hit 1 proc, hit 2 firing a second time, or
  hit 3 failing to reset after reapplication.

## Consequences

- Pure Python kind; zero C++ harness changes and zero diff on finished-class snapshots (`templar (19)` and
  `necromancer (23)`).
- Reusable for any defensive or reactive aura whose proc is gated once per aura application.
- Unit tests in `kinds/test_once_per_aura_proc.py` validate schema, step order, pass case, all five mutant failure
  modes, `unmeasured` precondition guards, and invalid-spec refusals.
