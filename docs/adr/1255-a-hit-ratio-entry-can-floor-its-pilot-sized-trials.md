# 1255. A hit_ratio entry can floor its pilot-sized trials

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-23

## Context

The `prove` pilot sizes each `hit_ratio` arm so that the 99% half-width is 0.8 of half the band, never below 20 trials
(ADR 0125). A correct server then fails only as `insufficient_trials`, when the sample variance exceeds 1.5625 times
the true one (chi-square, 2(n-1) degrees of freedom). At 20 trials per arm that is 1.48e-02 per run; four Felsworn
labels were held for a residual above 0.1% per pair. Mentor ruling D-70 asks for a written per-entry number, not a
looser check.

## Decision

`min_trials` (hit_ratio entry, opt-in, at least 20, with the entry's `trials` at least the floor): the pilot's judged
trials are max(20, sized, `min_trials`), still capped at the scenario's trial limit (`capped` in the record). Runs
without a pilot use the entry's `trials`. Judge and band are unchanged.

## Uses

| Entry | min_trials | Trial limit | Tail per run / per pair |
|---|---|---|---|
| 520833 Doomsayer above_76 | 47 | 83 | 4.55e-04 / 9.1e-04 |
| 520833 Doomsayer control_below_74 | 47 | 83 | 4.55e-04 / 9.1e-04 |
| 524947 Mark of Chaos damage | 47 | 83 | 4.55e-04 / 9.1e-04 |
| 525079 Black Magic bane | 47 | 52 | 4.55e-04 / 9.1e-04 |

## Consequences

- Entries without the field are sized as before; generation output does not change for them.
- Tests: `test_a_trial_floor_lifts_the_sized_count_and_stays_under_the_scenario_limit`,
  `test_trial_floors_come_from_hit_ratio_entries_with_trials_at_the_floor` (test_prove.py).
