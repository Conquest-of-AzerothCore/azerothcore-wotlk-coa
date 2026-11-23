# 1233. A metric delta reads a unit aura before the trigger cast

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-273 (Sun Cleric 27, Rapture 807372 redesign), tool approved within delegation D-213

## Context

The Rapture "piercing all immunities" proof stands a Divine Shield 642 on the dummy with `set_aura` (a named precondition
fixture). A control that reads 0 damage proves nothing when the shield was never there. `after_start_reads` (ADR 1208) and
`after_setup_reads` (ADR 1227) read an aura on the caster only; `before_aura_absent` reads an owned creature's aura as
absent.

## Options

- Read the shield on the dummy in a separate entry: not the same trial as the judged cast.
- Extend `after_start_reads` or `after_setup_reads` with a unit: the branch feat/coa-sun-cleric-rc3 (commit 3a9e5082cf,
  ADR 1228) already adds an optional per-read `actor` to `after_start_reads`; a second edit of the same module would
  conflict.
- A sibling `metric_delta` option.

## Decision

The `metric_delta` option `before_trigger_reads` (`[{spell, expected, actor}]`, expected 0 or 1, actor `caster` or
`dummy`) reads `aura_stacks` of each spell on the named unit right after the entry's fixture auras are set and before the
trigger cast, in every phase that makes the cast (the after phase; the before phase too when it casts). A mismatch or a
missing read makes the run `unmeasured`; it never produces `ok` or `alert` and adds no counted label. Python only,
opt-in, default off; it uses the existing `phase_steps` option point.

The field names `spell`, `expected` and `actor` are those of the rc3 `after_start_reads`, so the two options can be
unified at merge (`actor` is required here, optional there with the caster as default). This branch does not merge rc3.

## Consequences

- Test: `BeforeTriggerReadsTests` (metric_delta_options/test_before_trigger_reads.py), including the seeded mutant: a
  missing shield reads 0 or nothing and the verdict is `unmeasured`.
- Only entries that set the option change; finished-class scenario digests (15, 19, 19 `--stack`, 23) are unchanged.
- Documented in `apps/coa-gameplay-test/conformance/docs/metric_delta_options/before_trigger_reads.md`.
- Sun Cleric: Rapture 807372 `immune_all`, `immune_all_control`, `immune_all_control_open` read the shield 642 on the dummy.
