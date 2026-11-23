# 1208. A metric delta reads a caster aura at the start of the after phase

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-22

## Context

Casting Dawn 807440 while it is up removes it (#5741, #6809). The Sun Cleric conversions (commit bc7f739e73) remove
Dawn at the start of the after phase with a `set_aura` of 0 stacks, but nothing read the state afterwards (round A
review I-9, mentor D-202).

## Options

- Trust the removal: the state is forced, not read.
- Reuse `before_aura_absent`: it reads an owned creature, not the caster, and before the before reading.
- A `metric_delta` option that reads the caster aura after the removal and voids the run on a mismatch.

## Decision

The `metric_delta` option `after_start_reads` (`[{spell, expected}]`, expected 0 or 1) reads `aura_stacks` of each
spell on the caster right after the after phase's aura steps. A mismatch or a missing read makes the run
`unmeasured`; it never produces `ok` or `alert` and adds no counted label. Python only, opt-in, default off.

## Consequences

- Test: `AfterStartReadsTests` (metric_delta_options/test_after_start_reads.py).
- Only entries that set the option change; finished-class scenario digests are unchanged.
