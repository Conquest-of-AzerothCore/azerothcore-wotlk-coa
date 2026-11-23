# 1172. A summon position is read against a reference before it exists

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-22
- Builds on: ADR 0860

## Context

Hexfire Adept 704500 "Spawns a Serpent Ward ... beneath your target": `owned_creature_distance_2d` needs the summon
present, and the control phase (no talent) has none, so metric_delta could not read a distance in both phases (tool
note of cycle 5, author B2).

## Decision

The metric_delta option `before_reference` replaces the before read of an `owned_creature_*` reading by a reference
read of the same unit (for a position claim, the caster's own distance to the dummy: where a summon placed at the
caster would stand), after a count of the owned entry that must read 0; the after read requires exactly one owned
creature. The verdict alerts on a nonzero count and is unmeasured without it.

## Consequences

Opt-in only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical. Class 13
gains 704500 `ward_beneath` (the ward 0 yd from a dummy 20 yd away).
