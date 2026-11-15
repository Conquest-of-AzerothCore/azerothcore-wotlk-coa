# 0651. A minion swing arms entry pools its parts' windows

- Status: accepted
- Date: 2026-11-14
- Amends: ADR 0630 (minion swing arms)

## Context

A `minion_swing_arms` entry ran one scenario of `windows` control and treatment windows. Fetid Mark 706948 (claim
198.0) read a 99% half-width of 4.69 points at 24 windows per arm in cycle 13 run 1, where one control window read 780
per swing against about 1185 in the others, and 0.66 in run 2: `insufficient_trials` in one run of the pair. Its
verdict sized the entry at 528 windows per arm. ADR 0647 asks pooled entries for at least 10 parts, and one scenario of
528 windows per arm exceeds a part's budget.

## Options

1. A `parts` field: the scenario runs that many times and the windows of every part form one per-window sample per
   arm, judged as one scenario's windows are.
2. More `windows` in one scenario.

## Decision

Option 1, through the generic behaviour `parts` and a kind `POOLED_JUDGE`. A part with a missing read or an unheld
aura makes the label unmeasured and is named in the explanation. A single-scenario entry is judged as before.

## Consequences

- Fetid Mark 706948 runs 22 parts of 24 windows per arm; Rotting Flesh 574138 is unchanged.
- Seeded test: kinds/test_minion_swing_arms.py
  `test_pooled_parts_judge_every_window_of_every_part_and_name_a_failing_part`.
