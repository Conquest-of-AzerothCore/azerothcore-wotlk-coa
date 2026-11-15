# 0652. A minion aura listing read

- Status: accepted
- Date: 2026-11-14

## Context

In the cycle 14 counted pair (run 20261114-021607), the control entry `503740 behaviour_metric_delta snare_control`
read the Ghoul 50073's run speed rate 0.57143 (a -50% slow) before the learn, where every other stored run of the
same scenario reads 1.14286. No metric could name the aura behind such a reading on an owned creature: `aura`
needs a scenario unit, and `owned_creature_aura_max_duration_ms` needs the spell in advance.

## Decision

- The harness metric `owned_creature_applied_aura_count` reads the number of aura applications on the caster's
  present owned creature of `entry`, any caster, and the step record lists them as `auras` (`spell`, `caster` GUID,
  `caster_entry`, `stacks`, `duration_ms`). It is a read only (G-39): it changes no state.
- It is a diagnostic read; no conformance expectation consumes it, so it has no `METRIC_EVIDENCE` class.

## Consequences

- A leaked or unexpected aura on a minion is named by spell and caster in the result of the run that shows it.
