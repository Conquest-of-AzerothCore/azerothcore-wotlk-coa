# 0592. An area radius is bracketed by dummies at its edge

- Status: accepted
- Date: 2026-11-13

## Context

`fixed_count` spreads its dummies inside the radius and puts the far one 5 yd beyond it, so a radius 1 yd wider or
narrower passes (gap 47.1 "explicit dummy offsets", design T3 for 187.1). Fixture creatures are placed along +X from
their owner (`CreateTargets`, `distance`), so one line gives explicit offsets from the primary without harness changes.
The engine keeps a unit in an area when its 3D distance is under the radius plus the unit's object size
(`WorldObject::IsWithinDist3d`, `GetObjectSize` = combat reach); entry 36 reads 1.275 yd.

## Options

1. Extend `fixed_count` with offsets (central dataclass and chain, ADR 0581 says no).
2. A harness placement action with angles (C++ beyond a read, G-39).
3. A kind module that places three dummies on the caster's line around the edge and reads their geometry.

## Decision

Option 3, kind `radius_edge` (`kinds/radius_edge.py`): the primary at 3 yd, dummies `margin_yd` (0.5) inside and
beyond `radius` + `dummy_reach`. Combat reach, height and distance to the primary are read; the judge refuses a layout
the read values do not bracket. Control arm before `gate_spell` is learned, treatment after it; the inside dummy must be
struck, the outside one never, the control none.

## Consequences

- One kind serves 47.1 (801513, 6 yd) and 187.1 (707575, 6 yd); pilot 20261113-150027 read both ok.
- The bracket is 1 yd wide around the edge (G-19 is not stated for yards; the tooltip value is whole).
- Templar `generate --class 19` and `--stack` byte-identical (no Templar entry has the kind).
