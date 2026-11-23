# 1111. A summon-centred radius is bracketed from the summon, with the layout read back

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 1110 (placement at an owned creature), mentor ruling M-55 (summon-centred radii), G-29

## Context

`radius_edge` and `minion_range_arms` bracket a radius from the caster or the primary dummy. A field or pulse that a
summon searches around itself (an idol, an effigy) needs the bracket measured from the summon (tool note T-c8-2);
until now such entries kept a 2.5 yd margin and stayed reproduction only (M-55). Two Witch Doctor radius claims waited
on it: Spirit Idol 500961 (allies, an energize) and Shadow Effigy 505339 (enemies, an aura).

The search is `Cell::VisitObjects` over the cells of the radius square around the summon, then
`IsWithinDistInMap` (3D, both combat reaches). A unit inside the distance but in a cell the square does not touch is
not found, so a bracket point near a cell edge can be excluded for a reason other than the radius.

## Decision

- New kind `summon_edge`: a real cast of `summon_spell` summons `summon_entry`; two players (`role` `ally`, grouped,
  or `enemy`, PvP flagged at the PvP location) are placed at the summon (ADR 1110) on one line, `inside_yd` (-2 to
  -0.25) and `beyond_yd` (0.25 to 2) from the edge `radius` + both reaches.
- `role: "owner"` places the caster itself on the one side `owner_side` names, for a field that reaches only the
  summon's owner; `cell_search: false` drops the grid check for such a direct owner distance
  (`APPLY_AREA_AURA_PET`).
- It reads `spell_energize_count` (counted over `wait_ms`, the players' mana set to 1, an optional caster witness that
  must rise) or `aura` (at the end of the window) on each player, and the summon's and players' positions and reaches
  at the start and the end of the window.
- Verdict: unmeasured when a player stands less than 0.25 yd on its side of the edge, or in a cell the search does not
  visit (or within 0.05 yd of a cell edge), or when the witness did not rise; otherwise ok only when the inside
  player is reached and the beyond player is not.

## Consequences

- Witch Doctor: `500961 ally_edge` and `505339 enemy_edge` carry the radius claims of clauses 396 and 414, and
  `802719 field_owner_inside` and `field_owner_beyond` the 15 yd of clause 483.
- A grid cell edge between the radius and the edge point makes a run unmeasured (about one run in 25 for a 2.5 yd
  edge band on one axis), never a false ok or alert.
- New module only; classes 19 (with and without `--stack`) and 23 generate byte-identical output.
