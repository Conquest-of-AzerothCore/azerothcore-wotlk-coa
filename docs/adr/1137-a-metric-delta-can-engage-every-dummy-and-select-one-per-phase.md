# 1137. A metric-delta can engage every dummy and select one per phase

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0995 (area_dummies)

## Context

Serpent Ward 500960 "attempting to focus on your primary target": the ward takes the owner's selected unit, else the
first nearby enemy in combat with the owner (AscensionWitchDoctorSummons.cpp:420-431). A proof needs two enemies in
combat with the owner and the selection changed between them (tool note T-b13-2).

## Decision

The option `engage_and_select` selects one unit per phase after the trigger cast, then casts a stated spell at every
area dummy and the dummy, so only the selection differs between the phases.

## Consequences

Opt-in only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical. Class 13 gains
500960 `focus_primary` and `focus_control`.
