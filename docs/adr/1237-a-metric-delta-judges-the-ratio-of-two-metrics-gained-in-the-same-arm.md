# 1237. A metric delta judges the ratio of two metrics gained in the same arm

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-260 (Sun Cleric 27, Vow of the Valkyr 807749 "Auto attacks generate 1 Solar Power")

## Context

A per-event claim ("1 Solar Power per auto attack") needs the number of events of the same arm as its denominator.
That number is the outcome of the engine swing timer, which neither the tooltip nor the DBC gives, so an absolute
expected stack count rests on a reading of another entry. `expected_ratio` relates one metric's after reading to its
own before reading; nothing related two metrics read in the same arm and window.

## Options

- An expected count taken from the swings entry of the same pair: a self-measured expectation.
- A cross-entry comparison in `compare`: changes the shared judge and couples two scenarios.
- A `metric_delta` option that reads a second metric right after each of the entry's readings and judges the ratio
  of the two gains between the before and the after reading.

## Decision

The `metric_delta` option `same_arm_ratio` (`{metric, fields, ratio, tolerance, least, source}`, optional
`main_below`) adds one read of the second metric, on the entry's `measure_actor`, right after the before and the
after reading. The verdict is gain(reading) / gain(second metric) against `ratio` within `tolerance`; a second-metric
gain below `least`, an after reading at or above `main_below`, or a missing read makes it `unmeasured`. It refuses
the entry's own metric as the second one and `expected_ratio`. Python only, opt-in, default off; the evidence metric
stays the entry's own metric.

## Consequences

- Test: `SameArmRatioTests` (metric_delta_options/test_same_arm_ratio.py), with the seeded mutants (two per event,
  one event more or less) that alert.
- Only entries that set the option change; finished-class scenario digests are unchanged.
- Documented in `apps/coa-gameplay-test/conformance/docs/metric_delta_options/same_arm_ratio.md`.
- The window between the two readings must hold only the after arm: the entry stops its events before each reading.
