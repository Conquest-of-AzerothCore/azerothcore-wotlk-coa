# 0698. A cast gate can place its dummy at a stated distance

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

`cast_gate_scenario` keeps the dummy at the melee default. Damnation 520217 (Witch Hunter, TargetAuraState 13,
RangeIndex 114, 0-35 yd ranged) read `blocked` ok (111) but `allowed` and `bypassed` 128 SPELL_FAILED_TOO_CLOSE in
cycle 10 (c10-bolt): the gate was never reached for the two arms that must pass. Mentor decision D-158 (design D-1).

## Options

- An optional `dummy_distance` on the cast-gate entry, placed through `dummy_placement` as `cost_gate` does.
- Always place the dummy at the gated spell's cast distance: moves every existing cast-gate scenario.

## Decision

The first option. `CastGateSpec.dummy_distance` (absent by default) places the creature fixture through
`dummy_placement` (0 < distance <= 100 yd) and names the distance in the contract. Absent, the scenario is unchanged.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry states the field).
- Witch Hunter: `520217 cast_gate` with Slinging Bolts 500161 as the bypass, dummy at 17.5 yd (the range midpoint);
  counted pair in the cycle 11 tool report.
