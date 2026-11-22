# 1061. A cost gate priming read can expect a different state per arm

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-253 (Sun Cleric 27, The Coming Dawn 560861 dawnfall_gate and concord_gate)

## Context

ADR 1036 gives a cost gate `priming_reads`, one expected aura state for every arm. The two 560861 entries hold an
`unset` arm that skips the Dawn setup, so Dawn 807440 must be absent there and present in the other arms. `only_arm`
refuses `unset_arm`, so the arm could not be split out either.

## Options

- Split the unset arm into its own scenario: refused by `only_arm`, and a second scenario per entry.
- Drop the Dawn read from these two entries: leaves the precondition unread.
- A per-arm override of the expected state.

## Decision

A priming read may carry `arm_expected: {<arm name>: 0|1}`. The expectation of that arm's priming label uses the
override; every other arm keeps `expected`. The existing priming judge applies: a mismatch is not `ok`. Python only,
opt-in, default off.

## Consequences

- Tests: `PrimingArmExpectedTests` (test_d8_tool_fields.py), with the mutant that has Dawn up in the unset arm.
- Finished-class scenario digests are byte-identical before and after.
