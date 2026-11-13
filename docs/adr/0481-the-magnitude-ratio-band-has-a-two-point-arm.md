# 0481. The magnitude ratio band has a two-point arm

- Status: accepted
- Date: 2026-11-13

## Context

`trigger_magnitude_ratio` judged "X% of the damage" claims within max(0.01, 5% of the expected ratio). The mentor's
G-19 band is the larger of 5% of the stated value and 2 points (a "10%" claim passes from 8% to 12%), so a small
stated fraction was judged tighter than every other check of the method.

## Decision

- The margin is max(0.01, 0.02, 5% of the expected ratio): `MAGNITUDE_RATIO_POINTS` 0.02 is the 2-point arm in
  ratio units. The explanation names the three terms.

## Consequences

- A 10% fraction is judged from 0.08 to 0.12; 30% and above keep 5% of their value only when that is wider than 2
  points (an 80% fraction: 0.76 to 0.84). The generated scenarios do not change (Templar and Necromancer `generate`
  byte-identical); only verdicts of small fractions widen.
- Tests: `MagnitudeTwoPointBandTest` (test_triggers.py): 0.117 against 0.10 is ok (alerts without the arm), 0.123
  alerts, 0.835 against 0.80 is ok.
- Tomb King 262.1 stays status 5 (owner question Q-a1-5), not rejudged.
