# 1183. A hit ratio can narrow its band, and a cost gate aura can carry stacks

- Status: accepted
- Date: 2026-11-21
- Number: provisional, renumbered at merge (class-conformance guide 14.4)

## Context

Two needs came up in the Sun Cleric batch 2 (chunk 2, review fixes):

- Vindicator 704938 states "10% of the armor" ignored. The judged quantity is the damage ratio, and the G-19 band
  of the stated 10% (8% to 12%) maps, at 5528 armor and K 5500, to +4.18% to +6.40% of damage. That is tighter than
  the default two points of the ratio. With two points, a 5% or a 15% armor ignore would also pass.
- A cost gate whose cast needs an aura with several stacks, for example Solar Power 500149 at 20 stacks before
  Dawn 804584, had no way to state the stack count: `cast_auras` set one stack.

The fixer wrote both changes without the prior approval the dispatch rules require for a shared tool. The mentor
approved them after the fact (Sun Cleric mentor ruling D-32) because each rule only narrows a band or is opt-in. The
approval came on condition of this ADR.

## Decision

- `band_points` on a hit-ratio entry (`behaviours.hit_ratio_band_points`, `compare.py`): a number above 0 and below
  `POINT_BAND` (2). It replaces the judged band with that many points around the expected bonus. Any other value is
  refused at load. The verdict names "the band of the stated value", and the pilot sizes the trials to it.
- `stacks` on a `cost_gate` `cast_auras` item: a positive integer, default 1, written as the `stacks` of the
  `set_aura` precondition step. Any other value is refused at load.
- Both fields are opt-in. Without them, every generated scenario is unchanged. Templar (19), Necromancer (23) and
  Witch Hunter (15) regenerate byte-identical (re-review of the Sun Cleric chunk 2 fixes).
- Documented in `apps/coa-gameplay-test/conformance/docs/behaviour-scenarios.md`.

## Consequences

- A stated value mapped through a known formula is judged at its own band, which can only be narrower.
- `set_aura` remains a precondition fixture only (guide 3.4). The stacks are part of the fixture, never the subject.
- Process: an author who finds a tool need mid-work returns it to the controller instead of writing it.
