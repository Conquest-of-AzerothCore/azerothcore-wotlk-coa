# 1257. A metric delta reads an exact stack count after the setup casts

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: controller go (Felsworn endgame tool group B-3, owner delegation O-12)

## Context

Bane of Chaos 706420 "Can only have 1 Bane active on a target at a time." The `one_bane` entry casts Bane of Fire
707901 at the dummy as a setup cast and reads it gone after Bane of Chaos; it flipped in two pairs because a run whose
Bane of Fire never landed read 0 before the learn, and nothing read the dummy between the setup cast and the trigger
cast. Demonic Embrace 520257 needs the same kind of read for a Felfury count of exactly five on the caster.
`after_setup_reads` (ADR 1227) reads caster auras only, as present or absent.

## Options

- Extend `after_setup_reads` with a unit and a count: changes a field a finished class (Sun Cleric) uses.
- Sized in-scenario trials of the whole entry: a new loop in `metric_delta_scenario` for a deterministic outcome.
- A sibling option that reads an exact stack count on the caster or the dummy at the same point, void on mismatch.

## Decision

The `metric_delta` option `after_setup_stacks` (`[{spell, actor, stacks}]`, actor `caster` or `dummy`) reads
`aura_stacks` of each spell on its unit after the last setup cast of every phase that makes the setup casts. A count
other than `stacks`, or a missing after-phase read, makes the run `unmeasured`; it never produces `ok` or `alert` and
adds no counted label, so it has no evidence row. It uses the existing `setup_cast_steps` option point. Python only,
opt-in, default off. Sized trials are not added: an entry that uses the read states in its source why no roll decides
the judged reading once the precondition holds.

## Consequences

- Test: `AfterSetupStacksTests` (metric_delta_options/test_after_setup_stacks.py), with the seeded mutant that still
  alerts when the count matches.
- Only entries that set the option change; finished-class scenario digests are unchanged.
- Documented in `apps/coa-gameplay-test/conformance/docs/metric_delta_options/after_setup_stacks.md`.
