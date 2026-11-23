# 0034. Mojo Beam grows one branch per tick, with no cap of 8

- Status: accepted (contributor decision 2026-11-23)
- Date: 2026-11-23

## Context

Mojo Beam 500950-501118 and 572577: "Each time Mojo Beam heals a target it will grow a new branch. Each new branch
immediately heals and continues healing." Its aura text: "Each heal has a 100% chance to grow a vine to the
lowest-health nearby ally not already targeted." The 2026-09-09 reconstruction let every branch grow one per 500 ms
tick, so the healed allies doubled (1, 2, 4, 8) and stopped at 8 (`AscensionWitchDoctorBrewing.cpp`). Reproduced
20261123-004420 with seven grouped Warlocks and their Imps: 2, 4 and 8 heals on ticks 1 to 3, and one of the 14
units (the first one read) was never healed.

The contributor's live combat log of 2026-08-31 (one raid Witch Doctor, 32 beams of 501117, aggregates) shows the
healed targets growing by about one per tick: a median of 2, 3, 4, 5, 6 and 7 targets at 0.5 to 3 s, 9 at 4 s, 13 at
6 s and 15 at 8 s, up to 17, with no cap of 8.

## Decision

- Every tick, every branch heals, then one new branch grows: the lowest-health ally (the existing `Allies` order)
  within 15 yd of the first branch that has one, within 40 yd of the Witch Doctor and not yet a branch. It heals at
  once.
- No cap on the number of branches.

## Consequences

- Regression `witch-doctor-mojo-beam-branch-per-tick-12847`: 9 heals over three ticks, 14 over four, the channel
  still running, all 14 units healed and 146 heals over 16 ticks.
- The conformance entries `branch_grow`, `branch_heals` and `beam_lasts` judge the same layouts unchanged.
