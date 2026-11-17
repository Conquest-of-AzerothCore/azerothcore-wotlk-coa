# 0670. A metric delta can clear the trigger cooldown after its setup casts

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-14
- Builds on: ADR 0582

## Context

`metric_delta_scenario` clears `trigger_spell`'s cooldown before a phase's setup casts and then casts the trigger. A
clause whose setup is the trigger itself, or a spell that shares its cooldown, cannot be measured: the setup cast
puts the trigger back on cooldown and the trigger cast is refused. Witch Hunter batch 1 met it on Fiery Judgement
803369, "or increases the duration [of Flames of Sin] by 3 sec": a first Fiery Judgement grants Flames of Sin, a
second one extends it, and the five ranks share category 1052 (30 s).

## Options

- A `MetricDeltaSpec` field: edits the owner's dataclass, parser and scenario body (ADR 0582 moved new options out).
- A new kind module wrapping `metric_delta`: duplicates the kind for one reset step.
- A `metric_delta` option module using the existing named point `setup_cast_steps`.

## Decision

The option module `trigger_reset_after_setup` (`true`): after the last setup cast of each phase it adds
`reset_cooldown` of `trigger_spell`. It needs setup casts and a cast trigger. The global cooldown is not cleared;
`setup_wait_ms` covers it.

## Consequences

- Test: `TriggerResetAfterSetupTests` (metric_delta_options/test_trigger_reset_after_setup.py).
- No owner file changes; only entries that set the option change, so the Templar and Necromancer scenarios are
  unchanged.
- Mutant: `803503 effect2 x2` (the 3000 ms extension doubled) must alert the Witch Hunter `flames_extension` entry.
