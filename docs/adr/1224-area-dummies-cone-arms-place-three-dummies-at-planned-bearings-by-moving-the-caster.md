# 1224. `area_dummies` cone arms place three dummies at planned bearings by moving the caster

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Shield Radiance 504580 ("on enemies in front of you", TargetA 24, a cone, radius 12 yd). Fixture creatures
stand only on the +x line from the spawn (`area_dummies` takes distances), so no existing option could put a dummy off
the facing axis: neither the angular edge nor a dummy behind the caster could be built. Mentor ruling D-223.

## Options

- A harness change that spawns a creature at a bearing: a C++ change, more than the claim needs.
- Move the caster instead, with the existing `relocate` step (the player's orientation is unchanged and readable): the
  dummies stay on the line and their bearings from the caster change. Python only.

## Decision

`area_dummies` also takes `{"cone": {"angle", "radius", "source", optional "offset", "margin_pct", "behind"}}`. The
angle comes from the data or the code line named in `source` (never from a reading). The caster is relocated
`offset` yd along -y and far enough along x that three dummies on the line stand at the half angle less and plus
`margin_pct` percent (the primary, struck, and area1, not struck) and at `behind` degrees (area2). After the cast the
entry reads the caster's and the dummies' positions, the caster's orientation and the two off-cone hit counts; the
option verdict recomputes every bearing from the positions and voids the trial (`unmeasured`) when a bearing is more
than 1 degree off its plan, a height more than 1 yd off the caster's, or a distance outside 4 yd and the radius. It
alerts when a dummy outside the cone is struck.

## Consequences

- Opt-in: the list form is unchanged and the finished classes (15, 19, 19 with `--stack`, 23) regenerate byte-identical
  (4215, 2301, 40 and 3734 scenarios, manifests equal after path normalisation).
- The entry judges the primary's `spell_damage_count` and refuses a setup cast, `area_sum`, `relocate_before_trigger`
  and a trigger cast in the before phase.
- Seeded tests: the generated layout, the refusals, a held layout judged `ok`, a struck outside or behind dummy
  `alert`, a misplaced orientation or dummy `unmeasured`.
- Measured on Shield Radiance 504580 (90 degrees, `spell_cone` 800654): bearings 40.5, 49.5 and 135 read back as planned
  and only the inside dummy was struck, in both runs of the counted pair.

## Addendum (mentor D-259, 2026-11-23): the edge form

Hope 680637 ("split between enemies within $570187a1 yds") needed the radius edge of a triggered explosion: the
`radius_edge` kind casts its spell directly and cannot deplete The Chosen's shield, and a first design with an outside
dummy at 11 yd was struck, consistent with the 8 yd radius plus the target's combat reach (Spell.cpp:9437-9442) and
the player's area leeway (Spell.cpp:1388-1394, Object.cpp:1787-1808, as in ADR 1190). `area_dummies` also takes
`{"edge": {"radius", "source", "reach", "reach_source", "leeway", optional "margin_pct"}}`: the reach and the leeway
are inputs from the data and the code, the in-run reads of positions, reaches and run speed rate only check them
(off -> `unmeasured`), `area1` and `area2` stand `margin_pct` (default 10) percent either side of the edge, and a
struck `area2` or an unstruck `area1` alerts. Opt-in: the list and cone forms are unchanged and the finished classes
regenerate byte-identical. Tests: `AreaDummiesEdgeTests` (test_area_dummies_edge.py).
