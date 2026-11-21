# 0195. Pool hit-ratio parts and judge rates in points

- Status: accepted
- Date: 2026-11-12

## Context

Light's Chosen 301310, after its sign fix (ADR 0156), grants the spell penetration its tooltip states; the bonus that
penetration gives a Holy hit against the 60-resistance dummy is +7.5%. One `hit_ratio` scenario holds 166 trials per
arm in the ten-minute cap, and the band (+-2 points, ADR 0125) needs about 1,100 to 1,800. The mentor asked for a
pooled proof that also takes rates (crit chance, proc chance) as well as damage ratios, for claim 83 (+50% crit
chance), and set a rule for any chance or rate claim too costly for one scenario: about 300 casts per arm first,
recorded as "effect present, interval stated" and not final, then the pooled proof to the ruled band; status 5 if the
pooled proof costs more than 90 minutes for one claim or is not done by the cap.

## Considered options

1. The accelerated one-hour cap. Rejected for this kind: a hit-ratio trial takes about eight steps, so the 10,000-step
   limit of a scenario stops it near 600 trials per arm.
2. Identical scenarios ("parts") whose trials the judge pools. Chosen.

## Decision

- `hit_ratio` takes `parts`: `generate` writes that many copies (`-part-<n>`, the name suffixed) with one label; the
  judge concatenates every part's per-trial series, requires every part to have run, and reports the parts pooled.
- `hit_ratio` takes `rate` with `expected_points`: `critical` counts critical hits over all hits of the observed spell,
  `proc` counts `rate_spell` hits over them; each arm's rate is in percent and the difference is judged in points
  inside the larger of 5% of the stated points and 2 points (`bonus.bonus_band`).
- Light's Chosen's spell penetration entry takes 12 parts of 160 trials.

## Consequences

- Light's Chosen, claim 47. Step one (2 parts, 320 casts per arm, diagnostic 20261111-235419): +6.86%, 99% interval
  +4.95% to +8.77%, "effect present, interval stated", not judged (needs 1,172). Pooled proof (12 parts, 1,920 per
  arm): +7.47% (interval +6.69% to +8.26%) and +6.93% (+6.15% to +7.71%), inside +-2 points in both runs of one
  counted pair: behaviour proven. Cost about 2 minutes of runs.
- The single 301310 hit-ratio scenario becomes 12 parts with the same steps; every other scenario is unchanged.
- A crit or proc chance claim takes `rate`; claim 83 can use it.
- Tests: `test_behaviours.PooledRateHitRatioTests`.
