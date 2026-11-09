# 0051. A `tolerated` verdict status for a measured value within 5% of the tooltip

- Status: accepted
- Date: 2026-11-09

## Context

Round 9's two-run verification repeatedly produced small, non-reproducible deviations on otherwise-correct
numeric clauses (rounding, float accumulation across several scaled terms, minor combat-table noise) that sit
just outside `compare.py`'s existing band (`max(1.0, 0.5% of expected)`) but are self-evidently not a tooltip
mismatch: the measured value is within 5% of the DBC/tooltip expectation. Before this change every such case
reported `alert`, indistinguishable from a real defect, forcing a human to re-read the explanation of every
alert to tell "the server is wrong" apart from "the measurement has normal noise a hair past a tight band".

The owner ruling (round 10, 2026-11-09) is binding: a measured value outside the current band but within 5% of
the tooltip value is a new status, `tolerated`. It counts as conformant (proves its clause) but stays listed
with its deviation so a human can still see it; beyond 5% it is still `alert`.

## Considered options

1. Widen the existing band itself to 5%. Rejected: this would also accept a real defect that happens to land
   inside 5%, and loses the tight-band signal that most numeric clauses should still meet exactly.
2. Keep two bands and a new status in between (`ok` / `tolerated` / `alert`), listed in `alerts.tsv` with the
   `tolerated` ones kept visible for audit. Chosen — matches the owner ruling exactly, and `alerts.tsv` already
   has a `deviation` column.

## Decision

- `compare.py` gains `TOLERATED_RELATIVE = 0.05` and a `banded_status(value, low, high, expected)` helper:
  inside `[low, high]` is `ok`; outside but within 5% of `expected` is `tolerated`; otherwise `alert`.
- `STATUSES` gains `tolerated` (between `ok` and `alert`); `NOT_ALERTS` is unchanged (`tolerated` still appears in
  `alerts.tsv`, per the ruling that it "stays listed with its deviation"). `CONFORMANT = {ok, tolerated,
  closed}` names the set of statuses that prove a clause (used by the clause ledger, ADR 0052).
- `banded_status` is wired into `deterministic` (the general effect-value/aura-amount numeric check),
  `judge_roll` (DBC roll-range checks) and the hit-mean judge in `judge_hit`. Other numeric judges
  (`judge_trigger_cooldown`, `judge_trigger_duration`, the statistical `proc_rate` z-test, `judge_stack`'s
  delta checks) are **not yet covered** — their status falls out of more complex control flow this item did not
  touch, and the proc-rate check in particular is gated on statistical significance (a z-score), not a plain
  deviation from `expected`, so a blind 5%-of-expected band does not obviously apply the same way. Flagged as
  remaining work, not claimed here.
- `coverage.py`'s `JUDGED` set gains `tolerated` (a tolerated spell counts as judged, matching "counts as
  conformant").

## Consequences

- A clause whose only applicable verdict is `tolerated` is proven (ADR 0052's clause ledger treats it as such),
  so round 10's residue of near-band numeric clauses can close without a server fix, while remaining visible in
  `alerts.tsv` for a human to spot a drifting trend.
- `test_compare.py::BandedStatusTest` and the updated `test_tolerance_is_half_a_percent_of_a_large_value` seed a
  4% deviation (`tolerated`) and a 6% deviation (`alert`) against the same expected value, so a future change
  that silently widens or removes the tolerated band fails a test immediately.
- The three judges this item did not touch keep today's binary `ok`/`alert` behaviour unchanged; widening them
  to `tolerated` is a follow-up, not a regression introduced here.
