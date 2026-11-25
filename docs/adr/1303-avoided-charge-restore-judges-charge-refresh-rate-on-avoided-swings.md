# 1303. Avoided charge restore judges charge refresh rate on avoided swings

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-39

## Context

Cultist (class 25) talent Bulwark of Horror 300278 (row 25) states:

> "Avoiding an attack now has a $h% chance to refresh a charge of Blade of the Empire."

`Spell.dbc` 300278 carries `ProcChance = 40` (`$h = 40%`). `AscensionCultistEvents.cpp:52,62,155-156` checks
`avoided && Chance(player, 300278)` (where `avoided` covers `PROC_HIT_DODGE | PROC_HIT_PARRY | PROC_HIT_MISS` and
`Chance` rolls `roll_chance_f`, which cannot be forced) and calls `RestoreBlade(player) -> RestoreSpellCharge(502122)`
(Blade of the Empire: 3 charges, 6 s recharge).

Existing kinds cannot prove this claim:
- `procs.counts_charges` (`procs.py:468-473`) refuses `trigger.action != 'cast'` and `proc_spell != trigger.spell`.
- `avoided_proc_instances`, `avoided_swing_reads` and `parried_restore` do not read `spell_charges`.
- `flat_chance_rate` lacks an avoided-swing trigger and `spell_charges` event metric.

(Sibling Felsworn claim 805245 in `felsworn_clauses.json` row 303 is a separate avoided-trigger gap caused by landed
swings under `attempt_auras` and does not restore spell charges; Felsworn files are untouched.)

## Options

- Extend `procs.py` `counts_charges` to support avoided triggers: touches the shared `procs` pipeline used by all
  finished classes and risks altering existing proc generation.
- Add a standalone opt-in pooled behaviour kind `kinds/avoided_charge_restore.py` (reviewer condition `cu-rt3` Ext #8)
  reusing `proc_avoided` helpers and `restore_charges` / `spell_charges`, with zero C++ changes.

## Decision

Add `kinds/avoided_charge_restore.py`
([doc](../../apps/coa-gameplay-test/conformance/docs/kinds/avoided_charge_restore.md)):

- Declares `METRIC_EVIDENCE = {'avoided_charge_restore_rate': 'event'}` (no edits to `coverage.py` or `procs.py`).
- Each cycle pauses the strikers with Stun (`56`) while resetting `charge_spell` (`restore_charges`), spending
  `spend_charges` charges with `ignore_gcd` at `dummy` (`stop_attack` immediately after), and reading `spell_charges`
  and cumulative avoided swings (`dodged`, `parried`, optional `missed` + attack-balance `total`), unpausing strikers
  only during the `window_ms` sampling window so no swing can fall between reads or resets.
- Enforces a zero-capping invariant: any window with `avoided_swings > max_charges - charges_before` voids the run as
  `unmeasured`, preventing charge-cap bias. Any cycle restoring more charges than avoided swings alerts.
- Runs an unlearned control arm (requiring `0` restores over `>= minimum_control_trials`) and a learned treatment arm
  pooled over `parts`, sized by exact binomial calculation so conformant pair false-fail and cross-arm/0%-mutant pair
  false-pass probabilities are at most `residual` (`0.1%` default) inside the G-20 band (`+-2` pts at 40%: `>= 22,014`
  pooled avoided swings).

## Consequences

- Purely opt-in new kind auto-discovered by `kinds/__init__.py`; zero finished-class impact.
- Closes Cultist Bulwark of Horror 300278 row 25 (`expected_pct: 40`, 3 strikers with `[42716, 62531, 2116852]`,
  `window_ms: 400`, `count_misses: true`, `miss_exclusion: {"min_share": 0.04}`, 16 parts).
- Seeded tests cover generation, event evidence registration, pooled `ok`, mutant wrong rate (`50%`), zero-proc alert,
  control-proc alert, extra-restore alert, miss-exclusion, capping-risk void, guard failure, cast failure, attack
  imbalance, missing read, insufficient trials and spec refusals.
