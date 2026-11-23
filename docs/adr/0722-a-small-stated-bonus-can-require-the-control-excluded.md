# 0722. A small stated bonus can require the control excluded

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

G-19 gives a percent bonus the larger of 5% of its value and 2 points, so a stated +2% passes from 0 to +4: the band
alone accepts a server without the effect. The hit ratio judge only withholds a verdict while its 99% interval holds 0
(`bonus.bonus_status`), so a zero-effect server is never alerted, and the verdict states neither the trials needed to
exclude 0 nor a failure probability. The Witch Hunter review c11 I-1 rejected 9.0 (300571 Dusk, Stake and Dawn Blade
+2%) and 250.0 (705484 Dawn, Dusk Blade +2%) on that ground. Mentor decision D-178 (approved D-179): such a value
counts only if the measured interval excludes the control (lower bound above 0 for a stated increase), the trials and
the residual failure probability are stated, and the estimate lies inside the band.

## Options

- Widen nothing and keep "not judged" for an interval holding 0: a zero-effect server is never an alert.
- Narrow the band for small values: G-19 forbids changing the band.
- An opt-in judge option on the hit ratio: a one-sided bound at a stated residual must exclude 0, the trials must be
  large enough that a server at the stated bonus clears that bound with the same residual, and the band still holds
  the estimate.

## Decision

`control_excluded: {"residual": p}` on a `hit_ratio` entry (`control_excluded.py`, 0 < p <= 0.005), for a plain percent
bonus whose band holds 0 (refused otherwise, and with a flat token, a rate or a stated part). With the standard error
`se` of the ratio and its Welch degrees of freedom, `t` is the one-sided `1 - p` Student quantile:

- `se > |stated| / (2 t)`: insufficient trials, with the trials needed (a server at the stated bonus would miss the
  bound with probability above `p`);
- the bound `estimate - t se` (`+` for a stated decrease) does not exclude 0: alert (a server without the effect
  passes with probability at most `p`);
- the estimate outside the band: alert; otherwise ok.

The 99% interval outside the band still alerts first. The contract states `p` and the rule; the verdict states the
bound, `t`, `se`, the trials per arm and the probability that a rerun at the estimate misses the bound.

## Consequences

- Entries without the field generate and judge unchanged; Templar 19 and Necromancer 23 digests are identical.
- Seeded tests (`test_control_excluded.py`): a sized +2% passes, a zero-effect mutant alerts where the plain judge
  withholds, a +0.3% effect alerts, a +1.04% shortfall that excludes 0 counts, +4.5% alerts, too few trials are not
  judged, a stated decrease is mirrored, and a band without 0 or a bad residual is refused.
- Witch Hunter: 300571 stake and dawn_blade, 705484 dusk_blade.
