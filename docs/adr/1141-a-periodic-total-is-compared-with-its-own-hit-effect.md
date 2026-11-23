# 1141. A periodic total is compared with the model of its own hit effect

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-22
- Builds on: ADR 0920 (rank_hit_effects)

## Context

A class file's `rank_hit_effects` splits a rank's direct hit (`hit_mean`) from its periodic ticks (`periodic_total`).
The generator builds each scenario from the effect of its own check (`hits.hit_parts` passes the check to
`rank_hit`), but the comparison rebuilt every model with the default `hit_mean` role
(`hits.measured_hit_model`), so a periodic total was judged against the direct-hit tokens and alerted ("hit tokens
with the measured stats '${$m2+$sps*0.08+$RAP*.1}' differ from the generated '$o1'"). Hex of Malice 504608, label
`504608 effect_value #1`, final08 runs 1 and 2.

## Decision

`measured_hit_model` passes the expectation's check to `rank_hit` when it is one of `HIT_ROLES`, and `hit_mean`
otherwise, as before.

## Consequences

- With the final08 readings the 504608 ticks judge against the `$o1` model (mean 140.6 after the dummy's partial
  resists, sigma 12.7): 140.21 and 141.27 over 786 ticks, inside the 99% interval in both runs.
- A comparison change only: no scenario changes for any class. Ranks without `rank_hit_effects` model the same effects
  as before.
