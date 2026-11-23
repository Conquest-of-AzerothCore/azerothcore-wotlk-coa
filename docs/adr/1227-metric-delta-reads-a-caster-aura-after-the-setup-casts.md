# 1227. A metric delta reads a caster aura after the setup casts

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-22
- Decided by: mentor D-237 (Sun Cleric 27, the Dawn-casting entries)

## Context

Many Sun Cleric `metric_delta` entries cast Dawn 804584 as a setup cast because their claim holds only while Dawn
807440 is up (a Vow is fulfilled by a cast under Dawn, Scorch Marks come from the Dawn activation, Sunrise and
Sunset are entered by spending Dawn). Nothing read 807440 between the setup casts and the judged cast:
`after_start_reads` (ADR 1208) reads at the start of the after phase, before the setup casts, and Dawn can be
refused (Solar Power) or cancelled by a second cast.

## Options

- Extend `after_start_reads` with a read point: changes the meaning of an existing field and its documented place.
- A cost-gate style judged expectation: adds counted labels for a precondition.
- A sibling `metric_delta` option that reads after the last setup cast and voids the run on a mismatch.

## Decision

The `metric_delta` option `after_setup_reads` (`[{spell, expected}]`, expected 0 or 1) reads `aura_stacks` of each
spell on the caster after the last setup cast of every phase that makes the setup casts. A mismatch, or a missing
after-phase read, makes the run `unmeasured`; it never produces `ok` or `alert` and adds no counted label. Python
only, opt-in, default off; it uses the existing `setup_cast_steps` option point.

## Consequences

- Test: `AfterSetupReadsTests` (metric_delta_options/test_after_setup_reads.py), with the seeded mutant that still
  alerts when the read matches.
- Only entries that set the option change; finished-class scenario digests are unchanged.
- Documented in `apps/coa-gameplay-test/conformance/docs/metric_delta_options/after_setup_reads.md`.
