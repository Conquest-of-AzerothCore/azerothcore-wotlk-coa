# 0600. A pushback reduction promises the casting state

- Status: accepted
- Date: 2026-11-13
- Amends: ADR 0570 (a pushback reduction stamps its contrast)

## Context

Pair final6 (20261113-155556 / -161917) judged 802988 `behaviour_metric_delta pushback_game_time` ok in both runs (99%
intervals 48.42-48.67% and 48.42-48.58% against 50%, band 47.5-52.5), yet audited 240.0, Lich Essence "and reduces
your spell pushback suffered from taking damage by $s1%", as data. The kind reported the shared `casting` state
metric; coverage counts a state read as behaviour only where the clause carries that metric's promise words
(`\bcast\w*|haste|all actions`), and this clause names the pushback, not casting. The pushback is the delay of the
cast the kind reads, so the clause does promise the casting state.

## Options

- Add `pushback` to the shared `casting` promise in `coverage.STATE_PROMISES`: a central-list edit that widens every
  `casting` read of every class.
- A ratio judge or a pushback arm in `hit_ratio` (the c6 tool-group note): new judge code for a reading the kind
  already makes.
- The kind names its own state metric and declares its evidence row and promise words in the module (ADR 0581).

## Decision

The `pushback_reduction` model reports `pushback_casting`; the module declares `METRIC_EVIDENCE`
`{'pushback_casting': 'state'}` and `STATE_PROMISES` `{'pushback_casting': r'\bcast\w*|haste|all actions|pushback'}`.
The scenario, its reads and the judge are unchanged.

## Consequences

- 240.0 (802988, learned contrast) audits as behaviour; 360.3 (807813, own cast, "while casting") stays behaviour.
- The shared `casting` row is unchanged. Templar has no pushback entry: `generate --class 19` and `--stack` are
  byte-identical to 019887b267.
- Test: `test_a_spell_pushback_clause_promises_the_kinds_casting_state` (kinds/test_pushback_reduction.py).
