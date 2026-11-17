# 0661. run_speed_rate takes the hundredth-point floor in rate units

- Status: accepted
- Date: 2026-11-14
- Amends: ADR 0135 (the floor of a deterministic stat reading) for `run_speed_rate`

## Context

`run_speed_rate` is a deterministic stat reading (`compare.DETERMINISTIC_STAT_METRICS`, ADR 0135), but it is not in
`FRACTIONAL_METRICS`, so `delta_floor` gave it the 1-point floor of the integer metrics. The metric reads rates
(1.0, 8/7, 1.2), so that floor is wider than the whole scale: a passive verdict judged Courage's +20% inside
[-0.8, 1.2], which contains no change at all, and `floor_only_reason` marked both Courage passives (712466 +20% and
707754 +10%) `data_only`.

The reading is `Unit::m_speed_rate`, a float32, recorded as a double with 17 significant digits. One float32 ULP is
1.19e-7 in [1, 2). The largest error of an archived `run_speed_rate` reading against its expected value is 2.3e-6
(Tranquil Circle 801205 and Sacred Swing 572769 on the dummy, whose template speed is stored as the decimal 1.14286,
not 8/7). A speed aura applies integer percent points (`AuraEffect::m_amount` is `int32`, `Unit::UpdateSpeed` uses
`AddPct`), so the smallest statable step is 0.01 of the rate it multiplies; half of it is 0.005 at the base rate.

## Options

1. Keep the 1-point floor. Rejected: it cannot tell a stated speed bonus from no change.
2. Put `run_speed_rate` in `FRACTIONAL_METRICS` (floor 0.01). Rejected: 0.01 is one whole statable step at the base
   rate, so a +19% reading (0.19000005722) passes as +20% (owner answer Q1 of ADR 0012 forbids a floor that accepts
   the neighbouring statable value), and it would free 712466 (band 0.01) but keep 707754 (band 0.005) `data_only`
   although both readings have the same resolution.
3. The existing 0.01 percent-point floor (`FRACTIONAL_FLOOR`) converted to rate units: a rate is a percentage
   divided by 100, so the floor is 0.01 / 100 = 1e-4. Chosen (mentor ruling of 2026-11-14).

## Decision

- `compare.RATE_METRICS` holds `run_speed_rate`; `delta_floor` returns `FRACTIONAL_FLOOR / PERCENT_POINTS_PER_RATE`
  (100) for it. No new value enters: it is the percent-point floor read in the metric's unit.
- Basis: 1e-4 is about 43 times the largest archived error (2.3e-6) and 50 times below half the smallest statable
  step (0.005), so it holds the reading to its rounding (ADR 0135) and rejects the neighbouring statable values
  (ADR 0012 Q1). It treats 712466 (+0.2, band 0.01) and 707754 (+0.1, band 0.005) the same way.
- `behaviour_metric_delta` keeps its own `METRIC_DELTA_FLOAT_TOLERANCE` (1e-5); `owned_creature_run_speed_rate` is
  not covered by this ruling.

## Consequences

- Offline replay of the shared-pass raw results (Necromancer 20261114-125549 / -132456, Templar 20261114-135017 /
  -141026): the only changed verdicts are `712466 e0 run_speed_rate` and `707754 e0 run_speed_rate` (ok in both
  runs, interval [-0.8, 1.2] and [-0.9, 1.1] narrowed to 0.2 ± 1e-4 and 0.1 ± 1e-4, `data_only` dropped). Templar
  claim 272 (712466, "Increases your movement speed") moves from data to behaviour; claim 263 (707754) was already
  behaviour through `707754 behaviour_metric_delta speed`. No Necromancer verdict or class changes.
- Tests: `test_compare.PassiveDeltaTest.test_a_run_speed_rate_delta_takes_the_hundredth_point_floor_in_rate_units`
  (+19% read for +20% is an alert), `test_run_speed_rate_readings_of_ten_and_twenty_percent_are_judged_alike` and
  `QuestionDetailTest.test_percent_point_metrics_take_the_hundredth_floor`.
