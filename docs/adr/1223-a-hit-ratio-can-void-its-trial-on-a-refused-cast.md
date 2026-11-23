# 1223. A hit ratio can void its trial on a refused cast

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Empowered Holy Form 800602 (`hit_ratio` holy_form_doubled) had Daybreak 503624 refused with NOT_READY (67)
five times per run, at the same cast indices in every run, and its verdict stayed ok: the `hit_ratio` judge never reads
the run's `cast_failures`, so the missing heals only lowered the hit count. The cause was Daybreak's charges
(SpellCharges.dbc 503624 -> SpellChargesCategory 548: 2 charges, 10000 ms recharge), which the harness
`reset_cooldown` does not restore, at 6700 ms per trial. Mentor ruling D-222 approved an opt-in spacing or void option
on `hit_ratio` only. The `metric_delta` option of ADR 1207 cannot be reused: `hit_ratio` has no option registry.

## Options

- A spacing option: the existing `cast_wait_ms` already spaces the trials, so no new option is needed for spacing.
- An opt-in void flag that reads the result's existing `cast_failures`: Python only, no step change.
- A `restore_charges` step before every observed cast: an existing harness action, but a fixture on the measured
  spell, and not the approved design.

## Decision

An opt-in `void_on_cast_failure: true` on `hit_ratio` entries (module `hit_ratio_void.py`): the model carries the
flag, the contract says it, and the judge returns `unmeasured` when any run of the trial lists a refused cast. The
800602 entry gets `cast_wait_ms` 6900 (10100 ms per trial, one recharge per cast) and the flag; the two Purgation
806024 entries get the flag.

## Consequences

- Absent by default: no step changes, so the finished classes regenerate byte-identical; a run without a refusal is
  judged exactly as without the flag.
- Seeded tests (`test_hit_ratio_void.py`): refused casts give `unmeasured`, a clean run is judged, a refusal without
  the flag is judged, and the 14%-on-20% mutant still alerts with the flag.
- An entry whose design refuses a cast on purpose must not set the flag.
