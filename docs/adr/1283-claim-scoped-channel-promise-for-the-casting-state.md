# 1283. A claim-scoped channel promise for the casting state

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-24
- Builds on: ADR 0707 (`promise_of`, a claim borrows the promised words of an earlier clause)

## Context

Carve 800206 says "you can channel while moving". Its labels read the STATE metric `casting` (Carve still channelling
after two relocations, and the Whirlwind 13736 moved/still controls), ok in both runs of fw-fa1, but the audit classes
the claim data: the promise words of `casting` (`\bcast\w*|haste|all actions|interrupt\w*`, `coverage.py`) have no
`channel`, and no earlier clause of 800206 says "cast", so `promise_of` cannot lend the word (triage row 206.2, review
fw-rfa1 M6). Adding `channel\w*` to the global `casting` promise would move the audit of every class with a casting
state read on a channel clause. Mentor ruling Felsworn D-109 (1) refused the global word and approved a claim-scoped
key under four limits: only the STATE metric `casting`; the word must be in that claim's own words; the word list is
closed in code; finished-class audits stay byte-identical.

## Options

- Add `channel\w*` to `STATE_PROMISES['casting']`. Refused (D-109): global, it changes finished-class audits.
- `promise_of` to an earlier clause. Not possible: no earlier 800206 clause carries a casting word.
- A ledger key naming free words. Refused (D-109): an entry could promise anything it states.
- A claim-scoped key naming a metric from a closed map. Chosen.

## Decision

A declared claim (an item of a clause's `claims`) may carry `"state_promise": "casting"`. `CLAIM_STATE_PROMISES` in
`coverage.py` is the closed map, `{'casting': r'channel\w*'}`. For that claim only, the promise words of the metric
named are extended by the mapped words in both state-promise matches (`verdict_evidence` with a required contrast and
`promised_state`); every other metric, claim and clause keeps the global words. `clause_coverage` refuses (an
`EvidenceError`) a metric outside the map, a claim whose own words do not match the mapped words, and the key on a
clause instead of a declared claim. No judge, tolerance, evidence class or closing key changes; the contrast rules
still apply.

## Consequences

- A ledger without the key audits byte-identically; no generated scenario changes.
- Seeded tests in `test_coverage.py`: the key turns the casting claim to behaviour and leaves its sibling data; it
  does not reach another metric; refusals for a claim without `channel`, a metric outside the map and a clause-level
  key (mutants: dropping the word check or the closed map fails them).
- Felsworn: claim "you can channel while moving" of 800206 carries the key.
- Observation: each of the three labels of that claim (Carve's own `moving_channel_state` and the two Whirlwind
  controls) alone makes the claim behaviour under the existing evidence rules; the key does not change that rule.
