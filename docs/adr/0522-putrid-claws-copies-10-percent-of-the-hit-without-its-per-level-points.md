# 0522. Putrid Claws copies 10% of the hit without its per-level points

- Status: accepted
- Date: 2026-11-13

## Context

Animate: Tomb King 805044: "all of your Undead minion's attacks deal an additional $800027s1% of the damage dealt as
Plague damage." The owner ruled (Q-a1-5, option (b)) that the claw is 10% of the logged post-mitigation hit, then
resisted as a Plague hit (0.088 of the hit on the dummy). The server gave 0.1174 of the hit. The proc's damage is
already post-mitigation (fix note FN-own-3). The extra comes from the cast: `Copy` passes 10% of the hit as
SPELLVALUE_BASE_POINT0 and `SpellEffectInfo::CalcValue` still adds 570050's per-level part to a custom base point
(SpellInfo.cpp:479-498): Spell.dbc 570050 EffectRealPointsPerLevel[0] 0.15, SpellLevel 25, so about +5 per claw at
level 60. The mentor approved FN-own-3 with FN-mc-2 (ADR 0486).

## Decision

- The Necromancer contract sets 570050 Effects[0].RealPointsPerLevel to 0. `Copy` (shared by every Necromancer copy)
  and `CalcValue` (shared engine) are not changed.

## Consequences

- Regression (class file): the `Animate: Tomb King (Putrid Claws)` magnitude_ratio trigger, expected 0.1 of the hit,
  0.088 on the dummy, counted only inside the G-19 band around 0.088; putrid_with / putrid_without stay its presence
  control.
- The computed +5 per claw explains the measured 0.1174 to within about 2.5% (0.1172 computed); the residual is
  unexplained and not traced per event (mentor condition: no residual hunt before the count).
- Diabolical's 570050 copy also loses the per-level part; that branch looks unreachable (code read, not run). Live
  claws have a base of 51-97 (Q-a1-5b, ruled "no base"): this moves the server further from live, as ruled.
