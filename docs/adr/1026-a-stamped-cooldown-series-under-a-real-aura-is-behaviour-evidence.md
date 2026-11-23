# 1026. A stamped cooldown series under a real aura is behaviour evidence

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Amends: ADR 0342, for this shape only
- Builds on: ADR 0581 (kind modules), ADR 1008 (a module promises its own metric)

## Context

The Shadow Avatar family cuts the Spirit Glaive cooldown by a share every tick ("by $706803s1% every $706489t1 sec").
The cast gates (`cost_gate` on Spirit Glaive with a real Avatar) are presence reads: an integer replay shows that an
accepted attempt passes any cut of about 14 to 16% or more, so they cannot bracket 20% to its G-19 band. A
`cooldown_ms` read gives the remaining cooldown, but ADR 0342 classes every such read as data (READBACK).

## Decision

The owner rules (2026-11-21) that a game-time stamped series of `cooldown_ms` reads taken while a real cast's aura
runs, judged against a control series without it (the cooldown falls by elapsed time only), is behaviour evidence.
The kind module `cooldown_cut_series` (`kinds/cooldown_cut_series.py`, page `docs/kinds/cooldown_cut_series.md`)
declares its own metric `cooldown_cut_series`, event class in its `METRIC_EVIDENCE`; the `cooldown_ms` row of
`coverage.METRIC_EVIDENCE` is not changed. Each tick's cut is the excess of the fall over the elapsed game time
between two reads; its share and the tick period are judged with two labels.

## Consequences

- No existing verdict changes class: the metric name is new. Generated scenarios of classes 19 (also `--stack`) and
  23 are byte-identical (`diff -r`, 2026-11-21).
- Witch Doctor entries: 706543 `lesser_cut`, 706577 `glaive_cut`, 705943 `glaive_cut` (clauses 248, 255 and 431, the
  share and the period of each).
- The judge assumes that the cooldown clock and the game time agree; the control series checks it and reads
  `unmeasured` when they do not.
- Seeded tests in `kinds/test_cooldown_cut_series.py`: the arm layout, a simulated 20% per 1000 ms server (ok), a
  wrong share, a wrong period, no cut, a cut without the talent (alert), a missing read (unmeasured) and the refusals.
