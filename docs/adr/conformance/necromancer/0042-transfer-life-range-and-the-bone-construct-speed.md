# 0042. Transfer Life's range and the Bone Construct's speed

- Status: accepted
- Date: 2026-11-13

## Context

Claims 376.1 (Transfer Life 801530 "within $a1 yds", EffectRadiusIndex 9 = 20 yd) and 101.1 (Animate: Bone Construct
531130 "It moves at a slow speed": Bone Construct Hidden 531133 aura 33 -50%, creature_template speed_run 1.14286 for
both 503200 and the Ghoul 50073) (shared ADR 0594).

## Decision

- `801530 minion_range` (kind `minion_range_arms`): a Ghoul sent onto the dummy, the caster 12 yd (healed) then 28 yd
  (control, not healed) from it.
- `531130 travel_ratio` (kind `minion_travel_ratio`): the Construct against a Ghoul (control, no slow) sent at a dummy
  25 yd out; expected speed ratio 0.5, band 0.475 to 0.525. The Construct's cast gets 1000 Runic Power (300 set before
  the 3 s cast was refused with 85 in the first pilot, as in the lifetime entry).

## Consequences

- The "piercing" part of 101.1 is untouched (owner question O-3).
