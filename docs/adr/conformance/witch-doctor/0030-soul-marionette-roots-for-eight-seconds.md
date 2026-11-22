# 0030. Soul Marionette roots for 8 sec

- Status: accepted (contributor decision 2026-11-22)
- Date: 2026-11-22

## Context

Soul Marionette 704497: "Root yourself for 8 sec". The load contract turns Effect[0] into SPELL_AURA_MOD_ROOT, and the
aura keeps DurationIndex 793, 8500 ms. Both final08 runs (20261122-003941, 20261122-012101) found the caster still
rooted 8200 ms after the cast (`704497 behaviour_metric_delta root`, an alert). No live log holds the spell. The
contributor chose the tooltip's 8 sec.

## Decision

- The load contract sets DurationIndex 31, 8000 ms.
- The clones keep their four stacks: the clone tick at 8000 ms casts the stack when the root is gone, because it
  already accepts an age of 8000 ms (`AscensionWitchDoctorSummons.cpp`, the Marionette tick).

## Consequences

- Regression: `704497 behaviour_metric_delta root` (rooted inside 7600 to 8000 ms, gone at 8200 ms); the clone and
  explosion entries of 704497 check the stacks and the transform.
