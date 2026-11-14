# 0647. A pooled proof takes its interval from the between-part variance

- Status: accepted
- Date: 2026-11-14
- Amends: ADR 0346 (proc chances are proven to the band)

## Context

A G-20 pooled proof runs one label over many parts (scenarios) and judged the pooled count: the Wilson interval of
all procs over all trials for a `band` proc rate, and for a pooled `rate` hit ratio (critical or proc share) a
per-cast sample over every cast of every part. Both assume that every trial is independent. The four reads of
Necromancer 77.0 (503740) in cycles 11 and 12, 0.1443, 0.1699, 0.1512, 0.1421, are overdispersed against one binomial
(chi-square 15.5, 3 df, p about 0.002). The mentor ruled on 2026-11-14 that pooled proofs use a between-part interval
(t or bootstrap over parts) and that 77.0 counts if that interval is inside 13-17.

## Options

1. A t interval over the parts: the trial-weighted rate, its variance from the spread of the per-part counts around
   it (the ratio estimator), Student t at 99% with parts - 1 degrees of freedom.
2. A bootstrap over the parts: resamples, a seed and a resample count to fix; no closed form to test against.

## Decision

Option 1. For a `band` proc rate with more than one counted part (`judge_proc`), the rate is sum(procs) / sum(trials)
and the half-width is t(0.995, k - 1) x sqrt(k / (k - 1) x sum((procs_i - rate x trials_i)^2)) / sum(trials), clipped
to [0, 1]; the minimum-trial and count checks stay on the pooled count, and the band judge of ADR 0646 follows. A pooled
`rate` hit ratio sums each part's casts into one total and one count per arm, so its interval is the existing ratio or
difference interval over the parts. Binomial parts give about the Wilson width; overdispersed parts widen it. A pooled
proc rate without `band` keeps the Wilson verdict and states the between-part interval in its explanation only.

## Consequences

- Few parts give a wide t quantile: three 5-part `band` proc labels of cycle 11 run 2 (560730 x2, 705750) move from
  `ok` to `measured`; they need more parts.
- A pooled rate hit ratio's `trials` and sizing figures count parts, not casts.
- Templar: seven pooled `rate` hit ratios (705253, 707852, 520032, 524767, 560650, 561346, 520608) are judged by this
  interval on their next comparison; generated scenarios do not change.
- Seeded tests: test_compare.py `BetweenPartIntervalTests` (binomial parts about the Wilson width, overdispersed parts
  wider, one part without an interval) and `BetweenPartHitRatioTests` (overdispersed parts widen a pooled rate).
