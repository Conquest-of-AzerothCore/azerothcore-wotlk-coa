# 0446. A no-stack state read needs equal readings

- Status: accepted
- Date: 2026-11-13

## Context

ADR 0424 lets a `behaviour_group_stack_cap` state read prove a clause with the no-stack words. The mentor's ruling
(G-21 point 2) asks for equal consumed values after one and after two or more real applications. The judge accepts a
combined reading capped at the stronger percent, so a stronger partner passes with a higher second reading, and
`coverage.promised_state` checked only the clause words. ADR 0444 (side c) dropped ADR 0440's no-stack words for
`behaviour_metric_delta`; ADR 0424 remains the only no-stack state promise.

## Options

1. Keep the words check alone: a stronger partner would prove "does not stack" from unequal readings.
2. Compare the expected percents: equal tooltip percents do not show what the server consumed.
3. Mark the verdict with the measured comparison of the two readings and require it. Chosen.

## Decision

- `compare.behaviour_group_stack_cap_verdict` sets `detail['stacked_same']` (`compare.STACKED_SAME`): the reading
  after the partner equals the reading after the own spell alone, within the combined margin.
- `coverage.promised_state` promises a no-stack clause from a `behaviour_group_stack_cap` verdict only when that flag
  is true and the clause carries `NO_STACK_WORDS`.

## Consequences

- Chilling Presence 300958 (3.2817, 6.2817, 6.2817) keeps its proof. A verdict without the flag, such as a report
  written before this change, is data for a no-stack clause until it is judged again.
- Scenario generation is unchanged (`generate --class 19`, `--stack`).
- Tests: `JudgeGroupStackCapTests` (test_behaviours.py) and `NoStackStatePromiseTest` (test_coverage.py).
