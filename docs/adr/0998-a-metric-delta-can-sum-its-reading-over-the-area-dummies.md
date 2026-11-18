# 0998. A metric delta can sum its reading over the area dummies

- Status: draft
- Date: 2026-11-17
- Builds on: ADR 0711, ADR 0995

## Context

Shadow Trap 680238 states "the first enemy to approach it and up to $681179i enemies" ($681179i = 5). The server
stops its victim loop at 5 (`AscensionWitchHunterSummons.cpp:400-428`), and the order of the victims is a grid visit,
so which five enemies are struck is not fixed. A count claim needs the number of struck creatures among more than five,
in one reading. `area_dummies` (ADR 0995) places the creatures and reads one of them; `fields_sum` (ADR 0711) sums two
reads of different fields on one target. No option sums one read over several creatures.

## Decision

A `metric_delta` option module `area_sum` (ADR 0582 option, opt-in, mentor D-459): with `area_dummies` and the dummy
named once in the read (`measure_actor` for a read on the creature, `fields.target` for a read about it), each
judged reading is followed by the same read with every area dummy in the dummy's place, and `run_values` replaces the
reading with the sum, as `fields_sum` does for its second read. The plain judge is unchanged; a missing part leaves
the reading missing. Combining it with `fields_sum` is refused. Provisional number, renumbered at merge (14.4).

## Consequences

- Seeded tests in `metric_delta_options/test_area_sum.py`: one read per area dummy after each judged reading, no read
  without the option, refused inputs, and alerting mutants (one creature too many, one too few, a struck creature in
  the before reading, a missing part).
- No class file other than the Witch Hunter's sets the option, so the finished classes' digests do not move.
- The first users (Shadow Trap `count_stun`, `count_dot`) are provisional: the owner reads whether the tooltip's count
  is 5 in total or 1 + 5.
