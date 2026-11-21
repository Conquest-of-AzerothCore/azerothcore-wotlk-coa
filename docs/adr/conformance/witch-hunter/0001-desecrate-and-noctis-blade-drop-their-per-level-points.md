# 0001. Desecrate and Noctis Blade drop their per-level points

- Status: accepted
- Date: 2026-11-15

## Context

`SpellEffectInfo::CalcValue` adds `int32(level x RealPointsPerLevel)` for every effect whose DBC carries a non-zero
`RealPointsPerLevel` (SpellInfo.cpp:487-497; the level is clamped to `MaxLevel`, minus the larger of `BaseLevel` and
`SpellLevel`). Two Witch Hunter values carry such a part that their tooltips do not show:

- Dark Juggernaut 560208 restores `${$680519m2+$sps*.2+$AP*.1}` health through Desecrate 680519 effect 2 (index 1,
  `SPELL_EFFECT_HEAL`, BasePoints 9, DieSides 1, RealPointsPerLevel 1.1, levels 0): at level 60 the server added 66, so
  the reference character read 104 against the tooltip's 38.2.
- Noctis Blade 802280, 680612, 680613, 680614 and 680615 deal `${$m1+0}` through effect 1 (index 0,
  `SPELL_EFFECT_SCHOOL_DAMAGE`, RealPointsPerLevel 0.95, 1.9, 2.1, 4.1 and 4.0): the reads at level 60 were 8, 15, 16,
  32 and 16 above the die ranges (count of record final06, pair 130549 / 131126).

The owner ruled to cancel both per-level parts in Witch Hunter code (O-16: "cancel the per-level part of the heal
(680519 effect 2)"; O-17: "cancel the per-level part on each rank that has one"), recorded in
[rulings.md](rulings.md) section 2. The mentor approved the fix note (D-81).

## Options

- Cancel the part at run time in the Witch Hunter value hook, as a copy of the Templar arithmetic.
- Zero `RealPointsPerLevel` at load in the Witch Hunter `ApplyContracts`, through a table of its own, guarded on the
  DBC fields.
- Call or share the Templar's `CancelStockEffectRealPointsPerLevel`.

## Decision

- `AscensionWitchHunterCompletion.cpp`: `CancelLevelScaling`, called first in `ApplyContracts` after the family check,
  zeroes `RealPointsPerLevel` on the six effects of `WitchUnscaledByLevelEffects` when Effect, BasePoints, DieSides and
  RealPointsPerLevel all match the DBC values above. A DBC already at 0 per level is skipped silently; a record that
  differs in any other guarded field is left alone and logged (`coa`, "Skipped unexpected Witch Hunter per-level
  record"). The 1% maximum health clause of 680519 (effect index 0, disabled at load) is untouched.
- No Templar code is called or shared (no cross-class effect links); the load-time zero covers every `CalcValue` read
  with less code than the run-time cancel.

## Consequences

- Fix 027d4648b9. Regressions at level 60 on the reference character, counted pair 20261115-135058 / -135217
  (worldserver a21e26f0237e, built from the working tree later committed as 027d4648b9; the verdicts record
  server_commit `df2ec5d9e5c4+`): 560208 `effect_value 680519e1 #0` ok 38.0 / 38.0
  (band 37.2-39.2, was 104); `effect_value e0 #1` ok on every rank: 802280 26.87 / 27.02 (roll 26..28), 680612
  48.45 / 48.52, 680613 82.10 / 82.63, 680614 180.37 / 181.32, 680615 264.38 / 266.04.
- The regression lives in the conformance labels above (generated value scenarios of the class convention); no
  committed gameplay scenario asserts 38 or the roll ranges.
- The Noctis Blade hit entries are ratios of arms that share the base, so their expectations do not change: the
  Guardbreaker 681493 negative arm `noctis_blade_control` stays ok (-0.46 / +0.12 points, band 2).
- Gameplay change: Dark Juggernaut's heal drops from 104 to 38 on the reference character; each Noctis Blade rank
  loses its per-level part (rank 5: -16 at level 60). Only six SpellFamilyName 21 effects change; no finished class is
  touched.
