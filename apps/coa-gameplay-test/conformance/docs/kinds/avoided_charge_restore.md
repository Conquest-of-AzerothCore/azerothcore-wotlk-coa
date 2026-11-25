# Avoided charge restore (`behaviour_metric_delta`, `kind: "avoided_charge_restore"`, ADR 1303, provisional)

ADR 1303 has a provisional number and is renumbered at merge (guide 14.4).

Measures the rate at which avoiding an incoming melee swing refreshes a charge of a charge-based spell when the proc
chance is rolled by class code (`roll_chance_f`) and cannot be forced.

## Scenario and zero-capping invariant

A stationary aggressive striker group (`proc_avoided`: `strikers` copies of `striker_entry`, optional `striker_auras`,
`dodge + parry == 100`, `count_misses` and optional `miss_exclusion`) swings at the caster across short sampling
windows of length `window_ms` (chosen strictly below the spell's natural charge recharge time).

In each cycle:
1. `restore_charges` resets `charge_spell` to `max_charges` and clears its natural charge recharge timer.
2. `spend_charges` instant `ignore_gcd` casts of `charge_spell` at `dummy` (placed at `dummy_distance` yd so melee-class
   ranged casts do not start caster auto-attacks) open `spend_charges` empty charge slots and start a fresh recharge
   timer.
3. Strikers are paused with Stun (`56`) during charge resets, spend casts and counter reads, and unpaused only for the
   `window_ms` avoided-swing window, keeping charge restores and avoided-swing counts atomic across every cycle.
4. `spell_charges` is read before and after the `window_ms` window alongside cumulative avoided-swing counters
   (`melee_attacks_taken` dodged/parried, optional `melee_missed_taken`, and total `melee_attacks_taken`).

Any cycle where avoided swings exceed the open charge slots (`w_trials > max_charges - charges_before`) voids the run as
`unmeasured` so charge capping can never silently bias the measured rate downward. Choosing `strikers <= spend_charges`
with `window_ms` below a single striker's swing period guarantees at most `strikers` swings per window.

## Arms, sizing and judgement

- **Control arm** (`control_cycles` per part, before `spell` is learned): must restore `0` charges over at least
  `minimum_control_trials(rate, residual)` pooled avoided swings (at least 50; pair false-pass `<= residual`), proving
  neither natural recharge nor any unrelated effect restores charges during the window.
- **Treatment arm** (`treatment_cycles` per part, after a real `learn` of `spell`): pooled across `parts`, requiring at
  least `minimum_treatment_trials(rate, residual)` avoided swings (exact binomial sizing for the Wilson 99% interval
  inside the G-20 band `max(5% * p, 2 pt)` with pair false-fail and 0%-mutant false-pass both `<= residual`, default
  `0.1%`).
- **Preconditions (`unmeasured` on failure):** zero refused casts, zero landed/blocked/own swings (`proc_avoided`
  guards), attack-balance equality when `count_misses` is true, and `miss_share >= miss_exclusion.min_share` when set.
- **Evidence class:** declares `METRIC_EVIDENCE = {'avoided_charge_restore_rate': 'event'}` (counted as `behaviour`).

Cultist: Bulwark of Horror 300278 (40% chance to refresh a charge of Blade of the Empire 502122, 1 striker with
`[42716, 62531, 2116852]`, `window_ms: 1100`, `count_misses: true`, `miss_exclusion: {"min_share": 0.04}`, 18 parts).
