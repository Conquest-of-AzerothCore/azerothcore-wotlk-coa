# 1160. An effectiveness delta can read a slow as the run speed rate

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0601, ADR 0671

## Context

Shadow Enchantments 301361 increases "the duration and effectiveness of your Jinxes" by 50% (SPELLMOD_DURATION and
SPELLMOD_ALL_EFFECTS on the Jinx class mask). The duration half had a behaviour route; the effectiveness half only
its data label. The effect a Jinx carries that a unit read shows is the Lethargy Jinx 802065 slow (aura 33, -50%) on
the dummy, read as `run_speed_rate`, a state metric whose promise words (`movement speed|run speed|slow`) the claim
"and effectiveness of your Jinxes" does not contain, so a plain `metric_delta` read of it was data only.
`effectiveness_delta` reads the effect without and with the learned modifier and promises its own state metric to the
word "effectiveness", but read only spell power, a stat, dodge and parry.

## Decision

`effectiveness_delta` also reads `run_speed_rate` (on the unit `measure_actor` names, here the dummy), stamped as
the state metric `effectiveness_run_speed_rate` with the promise word `effectiveness`.

## Consequences

Opt-in only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical. Class 13 gains
301361 `jinx_effect` (a real Lethargy Jinx on the dummy before and after the learn: 0.57143 -> 0.285715).
