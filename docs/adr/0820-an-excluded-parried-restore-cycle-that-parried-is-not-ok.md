# 0820. An excluded parried restore cycle that parried is not ok

- Status: proposed (amended by ADR 0850)
- Date: 2026-11-16
- Amends: [ADR 0801](0801-a-parried-swing-restore-is-judged-per-cycle-at-a-set-state.md)

## Context

ADR 0801 leaves out a treatment cycle whose health (or Rage) at its end is not its start plus its events, and only
counts it. The c15 review (I-3) showed that this hides a failed restore: a parried swing that restores nothing, in a
cycle that also takes the foreign loss, reads as a foreign change and is dropped, and the verdict still passes while
`min_parried` parried swings stay judged. The seeded test placed the foreign change on a cycle with a parried swing
and expected `ok`.

## Options

- Leave the verdict unmeasured when an excluded cycle holds a parried swing.
- Alert when an excluded cycle holds a parried swing, and name the cycles and their parried swings.

## Decision

Only a cycle without a parried swing may be left out. An excluded treatment cycle with `parried > 0` adds a failure
that names the cycles and their parried swings, so the verdict alerts; when too few parried swings stay judged the
verdict stays unmeasured and its reason names the same cycles. The explanation always states the parried swings held
by the excluded cycles. An alert rather than unmeasured: the restore's own failure is one cause of the mismatch, and
it must not read as a measurement gap.

## Consequences

- Tests (`kinds/test_parried_restore.py`): a foreign change in a cycle without a swing is left out and counted
  (`ok`, measured 90000); one in a parried cycle alerts both labels; mutant "no restore on a parried swing in a
  foreign-change cycle" alerts; the unmeasured reason names the hidden cycles.
- Generation is untouched (judge only): scenario files and the finished-class digests do not move.
- Number provisional: shared ADRs are numbered at merge.
