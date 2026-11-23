# 0011. Cursed Effigy, Unstable Concoction and Godslayer read their spells' radii

- Status: accepted
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Three class searches used a literal 10 yd where the spell they apply has its own radius:
- Cursed Effigy 706542: its field 506820 is 15 yd;
- Unstable Concoction 802487: "healing nearby allies within $802489a1 yds"; 802489 has EffectRadiusIndex 9 (20 yd) and
  MaxAffectedTargets 5 ("Heals up to $i allies"). The script search `Allies(player, target, 10.0f, 5)` keeps both
  object sizes (1.5 yd per player), which reaches 13 yd centre to centre, against 23 yd under the tooltip;
- Godslayer 802714: the explosion 806616 is 8 yd.

## Decision

- A `Radius(id, effect)` helper reads `CalcRadius()` of the spell. Cursed Effigy scans `Radius(CursedField)`,
  Unstable Concoction `Radius(UnstableHeal)` with the cap from the spell's MaxAffectedTargets, and Godslayer
  `Radius(GlaiveExplosion)`.

## Consequences

- Regression: catalog `witch-doctor-unstable-concoction-radius`: the doctor is the marked target, with grouped allies
  at 3 yd (healed in every build), 22.5 yd (healed only after the fix) and 23.5 yd (never). It failed before the fix:
  the ally inside 20 yd was not healed. It passed in 20261121-012010.
- The Cursed Effigy and Godslayer class-file brackets read the bug before the fix and pass after it (20261121-012010).
