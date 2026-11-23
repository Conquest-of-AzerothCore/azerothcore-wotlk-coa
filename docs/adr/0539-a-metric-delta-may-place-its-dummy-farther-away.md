# 0539. A metric_delta entry may place its dummy farther away

- Status: accepted
- Date: 2026-11-13

## Context

Curse of the Lich 300240: "Increases the range of your Rime spells by $s1 yds" (claim 8.0) needs a Lichfrost cast at
a dummy beyond Lichfrost's 30 yd. metric_delta could only relocate the caster within 20 yd (the scenario validator's
relocate bound), so the claim was a named tool gap. The scenario format already accepts a creature `distance` up to
100 yd.

## Decision

- metric_delta takes `dummy_distance` (yd, in (0, 100]): the dummy fixture is spawned that far from the caster, and
  the contract says so. Entries without the field generate the same scenarios.

## Consequences

- 300240 `range_extended` (35 yd: refused 97 without the talent, cast with it), `range_extended_hit` (the cast lands)
  and `range_capped` (41 yd: refused both ways) bracket the +6 yd.
- Tests: `MetricDeltaDummyDistanceTests` (test_behaviours.py), with a still-refused cast that must alert. Templar
  `generate --class 19` and `--stack` unchanged (no Templar entry sets the field).
