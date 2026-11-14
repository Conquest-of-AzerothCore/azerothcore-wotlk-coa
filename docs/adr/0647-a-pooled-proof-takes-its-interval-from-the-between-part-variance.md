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
(t or bootstrap over parts) and that 77.0 counts if that interval is inside 13-17. A later ruling the same day limits
the t interval to 10 parts or more: with fewer, the t quantile is too wide (4.60 at 4 df against z 2.576) and Wilson
stays the judge, the flip rule across merged pairs remaining the guard against overdispersion.

## Options

1. A t interval over the parts: the trial-weighted rate, its variance from the spread of the per-part counts around
   it (the ratio estimator), Student t at 99% with parts - 1 degrees of freedom.
2. A bootstrap over the parts: resamples, a seed and a resample count to fix; no closed form to test against.

## Decision

Option 1, from 10 parts (`MINIMUM_BETWEEN_PARTS`). For a `band` proc rate with at least 10 counted parts
(`judge_proc`), the rate is sum(procs) / sum(trials)
and the half-width is t(0.995, k - 1) x sqrt(k / (k - 1) x sum((procs_i - rate x trials_i)^2)) / sum(trials), clipped
to [0, 1]; the minimum-trial and count checks stay on the pooled count, and the band judge of ADR 0646 follows. A pooled
`rate` hit ratio with at least 10 parts sums each part's casts into one total and one count per arm, so its interval is
the existing ratio or difference interval over the parts. Binomial parts give about the Wilson width; overdispersed
parts widen it. Below 10 parts a `band` proc rate is judged on the Wilson interval of the pooled count (its explanation
states the t interval it would have), and a pooled `rate` hit ratio keeps the per-cast sample. A pooled proc rate
without `band` keeps the Wilson verdict and states the between-part interval in its explanation only.

## Consequences

- Few parts give a wide t quantile: three 5-part `band` proc labels of cycle 11 run 2 (560730 x2, 705750) would move
  from `ok` to `measured`; under the 10-part minimum they keep their Wilson verdicts. Pooled entries under 10 parts
  are resized to at least 10 when next touched.
- A pooled rate hit ratio's `trials` and sizing figures count parts, not casts.
- Templar: seven pooled `rate` hit ratios (705253, 707852, 520032, 524767, 560650, 561346, 520608) are judged by this
  interval on their next comparison; generated scenarios do not change.
- Seeded tests: test_compare.py `BetweenPartIntervalTests` (binomial parts about the Wilson width, overdispersed parts
  wider, 9 parts judged by Wilson, 10 parts by t, one part without an interval) and `BetweenPartHitRatioTests`
  (overdispersed parts widen a pooled rate at 10 parts; 9 parts keep the per-cast interval).
