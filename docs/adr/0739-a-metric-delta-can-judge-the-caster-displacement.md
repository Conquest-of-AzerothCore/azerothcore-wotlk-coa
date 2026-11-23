# 0739. A metric delta can judge the caster's displacement

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 308.0 (Night Walker 789256, "Increases the base range of Vault by $s1 yds.") needs the Vault leap
measured from where it starts. Design D-9 (approved for 308.0) classed `point_distance_2d` as a state (built in cycle
11), but a fixed point cannot serve both phases: the treatment Vault starts where the control one landed (c12 tool,
item 12, stopped as larger than M). Gap design A2 depends on it (c13 gap designs, mentor ruling D-201: build the
dependency first).

## Options

- A `metric_delta` option that reads the caster's position right before each phase's trigger cast and before its
  judged reading, and replaces the judged readings with the distance between the two (`run_values`), so every plain
  judge applies to the displacement.
- Static `point_distance_2d` points with a return to the start between phases: a teleport is asynchronous.

## Decision

The option, with its own evidence metric `displacement_2d` (a state, promised by `leap\w*|range|yds?`), declared by
the module and merged by `coverage` through `option_rows` (ADR 0732); the global `point_distance_2d` row is unchanged.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`); no base
  coverage row changes.
- Seeded tests: the start reads sit right before each trigger cast and the end reads right before each reading; an
  uncast phase reads both right before its reading; the gain is judged on the displacements (3 yd passes; 0, 4 and a
  short base alert; a missing read is not ok); the state is promised by "range" and not by "haste"; an entry that is
  not the caster's `position_x` is refused.
- Witch Hunter: `789256 behaviour_metric_delta vault_range`. Pilot 20261116-064140: 15.0 yd without the talent,
  18.0 yd with it.
