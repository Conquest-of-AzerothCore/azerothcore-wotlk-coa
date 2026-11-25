# 1230. A cost gate priming read can expect a different state per arm

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-253 (Sun Cleric 27, The Coming Dawn 560861 dawnfall_gate and concord_gate)

## Context

ADR 1205 gives a cost gate `priming_reads`, one expected aura state for every arm. The two 560861 entries hold an
`unset` arm that skips the Dawn setup, so Dawn 807440 must be absent there and present in the other arms. `only_arm`
refuses `unset_arm`, so the arm could not be split out either.

## Options

- Split the unset arm into its own scenario: refused by `only_arm`, and a second scenario per entry.
- Drop the Dawn read from these two entries: leaves the precondition unread.
- A per-arm override of the expected state.

## Decision

A priming read may carry `arm_expected: {<arm name>: 0|1}`. The expectation of that arm's priming label uses the
override; every other arm keeps `expected`. Python only, opt-in, default off.

## Consequences

- Tests: `PrimingArmExpectedTests` (test_d8_tool_fields.py), with the mutant that has Dawn up in the unset arm.
- Finished-class scenario digests are byte-identical before and after.

## Addendum (mentor D-253, 2026-11-23): a priming mismatch voids the arm

The first version judged a priming label like any cast condition, so the mutant with Dawn up in the unset arm alerted.
A priming read states a premise of the trial, not behaviour. When an entry sets `arm_expected`, every expectation of
an arm (its priming labels, its gate reading, its cooldown and after-cast readings) carries the model key
`priming_void` `{priming label: state}`; `behaviour_cast_gate_verdict` reads those labels first and returns
`unmeasured` when one is off its state (a missing read keeps the missing-measurement verdict). Without `arm_expected`
the key is not written, so the priming judge of every other entry and the finished-class digests are unchanged.
