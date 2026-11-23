# 1130. A metric-delta reading can count only its own phase

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582 (metric_delta option modules), ADR 1030

## Context

Event totals (`spell_damage_total`, `spell_heal_total`) are cumulative over a scenario. A share claim judged as one
total over another (Puppeteer's Threads 92084 "stores 15% of its value", Frenzied Spirits 560748 "heal for $s3% of all
damage dealt for each Spirit consumed", a fixed heal under Hex of Death 706557) needs a control phase that casts too,
so the treatment total also carries the control phase's events.

## Decision

The metric_delta option `phase_since: true` snapshots the judged read and its ratio base right before each phase's
trigger cast and judges the readings relative to them (the harness `relative_to`). It needs both phases cast and no
setup cast of the trigger, and refuses summed or windowed readings.

## Consequences

Opt-in only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical. Class 13 gains
92084 `stored_share`, 560748 `heal_three` and `heal_one`, 706557 `heal_cut`.
