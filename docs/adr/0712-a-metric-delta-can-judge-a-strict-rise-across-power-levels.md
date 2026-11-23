# 0712. A metric delta can judge a strict rise across power levels

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Damnation 520217 (Witch Hunter) converts "each point of Rage into additional damage"; the text states no amount and
mentor ruling D-165 accepts a direction check. The three entries `rage_r500`, `rage_r750` and `rage_r1000` only floor
the treatment read at 1 with an opened tolerance, so no verdict proves the direction (c11-bk). Mentor decision D-160
(c12 tool batch item 2).

## Options

- A `metric_delta` option module `monotone` that repeats the treatment phase at further power levels and judges a
  strict rise from the control.
- A hit_ratio direction judge per pair: three entries, each a pair, with no single verdict over the series.

## Decision

The option module `metric_delta_options/monotone.py`: `levels` (power values above the `phase_power` treatment) and
`cumulative` (judge each phase by its increase of a cumulative metric). The verdict replaces the plain bands and is
`ok` only when every reading rises strictly from the control.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry states the option).
- Seeded tests: a flat or falling phase, a constant per-phase increase of a cumulative total and a missing level
  alert.
- Witch Hunter: `520217 behaviour_metric_delta rage_monotone` (25, 50, 75 and 100 Rage).
