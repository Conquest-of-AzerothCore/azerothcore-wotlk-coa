# 0870. Phase power can apply in an uncast before phase

- Status: accepted
- Date: 2026-11-16

## Context

Heartseeking Bolt 807284 "Generates Rage based on the damage dealt." (claim 383.0) is read as the caster's Rage power
before (no bolt) and after one bolt. The `metric_delta` `phase_power` field sets the power right before each phase's
cast, inside the cast block of `cast_steps` (`behaviours.py`). With `cast_in_before` false the before phase returns
before that block, so its read gave the fixture's starting Rage (1000 raw in the f-s2 run, Witch Hunter archive
`authors/f-s2`) instead of 0, and the entry had no valid control.

## Options

- Move the `phase_power` step ahead of the `include_cast` return for every entry: it changes the scenarios of every
  existing `phase_power` entry with an uncast before phase and moves finished-class digests.
- An opt-in `metric_delta` option that sets the before value at the start of an uncast before phase.

## Decision

The option `phase_power_in_uncast_before: true` (standing approval D-293) requires `phase_power` and a before phase that
does not cast the trigger (`cast_in_before` false or `trigger_only_after`). Its phase step sets `power` to the
`phase_power` before value at the start of the before phase; the after phase keeps the existing step before its cast.
Entries without the option generate unchanged scenarios.

## Consequences

- Test: `PhasePowerInUncastBeforeTests` (`metric_delta_options/test_phase_power_in_uncast_before.py`), with a before
  read left at the fixture's Rage that alerts.
- Only entries that set the option change; the Templar and Necromancer digests are unchanged. First user: Witch Hunter
  807284 `rage`.
- Number provisional (guide 14.4).
