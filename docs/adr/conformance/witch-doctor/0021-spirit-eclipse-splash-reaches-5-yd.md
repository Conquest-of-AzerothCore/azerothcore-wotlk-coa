# 0021. Spirit Eclipse splash reaches 5 yd

- Status: accepted
- Date: 2026-11-21

## Context

Spirit Eclipse 811117 splashes enemies within `$802712a1` of the target, SpellRadius 8 = 5 yd. The aura script
searched a literal 10 yd (`AscensionWitchDoctorAuras.cpp`, the Eclipse tick). The cycle 10 sweep 20261121-203210
read one splash on a dummy 8.05 yd from the target, past 5 yd plus both combat reaches (triage row 17).

## Decision

- The splash search reads `Radius(EclipseSplash)`, the radius the tooltip shows.

## Consequences

- Regression: the class entry `811117 splash_beyond` (no splash past 5 yd), with `splash_inside` and `splash_damage`.
- Fix note: cycle 10 triage.md FIX-T1 (the four G-37 checks hold).
