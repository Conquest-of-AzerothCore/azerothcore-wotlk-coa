# 0087. Gap-closer distance check for charge/leap effects

## Context

Several Templar actives state a gap-closing movement in prose ("Charge towards an ally", "charging you to
them", "Leap at an enemy with divine force") on top of their own damage/heal effect. `hits.py`'s
`closes_distance(facts)` already detected `SPELL_EFFECT_CHARGE`/`SPELL_EFFECT_CHARGE_DEST` (96/149) to
relocate the caster before a repeat cast of an ally-targeted charge (Temple Guardian), but nothing measured
whether the charge/leap effect itself actually moved the caster, and `SPELL_EFFECT_JUMP_DEST` (42, the effect
Divine Force and Silverhand Incantation's own charge step use) was not recognised as a gap-closer at all.

## Decision

- `values.CHARGE_EFFECTS` gains effect code 42 (`SPELL_EFFECT_JUMP_DEST`), alongside 96/149, since
  `Spell::EffectJumpDest` relocates the caster via `MotionMaster::MoveJump` exactly as `EffectCharge`/
  `EffectChargeDest` do (`SpellEffects.cpp`).
- `hits.py`'s existing before-cast relocate fixture (`CHARGE_OFFSET_YD` yd away from the target along the
  caster's spawn axis) now applies to any `closes_distance` rank with a resolvable cast target, hostile or
  ally, not only an ally charge: the fixture already proved itself safe for a stationary ally target (Temple
  Guardian) and the same reasoning (a fixed-position target, re-approached every repeat cast) holds for a
  stationary hostile dummy.
- A new check, `gap_closer_distance`, measures `distance_2d` from the caster to the cast target right after
  the (first) cast and judges it against `NOMINAL_MELEE_RANGE_YD` (5.0, `ObjectDefines.h`'s
  `NOMINAL_MELEE_RANGE`) plus a `GAP_CLOSER_MARGIN_YD` (2.0) margin for missile travel/positioning slop: `ok`
  when the caster ends up within that margin of melee range, `alert` otherwise. It is added once per
  `hit_parts` call (`part == 0`), alongside whatever `hit_mean`/`unmodelled` expectation the rank already
  gets, never replacing it.
- A charge/leap rank whose own damage/heal effect has no `hit_kind` model (Silverhand Incantation's
  `TRIGGER_MISSILE_SPELL_WITH_VALUE` effect) still gets its own one-cast gap-closer scenario in the
  `Unmodelled` branch of `hit_parts`, built from the same `facts_of` reading `rank_hit` could not model,
  since the gap-closer claim is independent of whether the rank's own hit is measurable.

## Consequences

- Temple Guardian 803792, Silverhand Incantation 801465 and Divine Force 806153/807805 each gain a
  `gap_closer_distance` expectation proving the caster actually closes to melee range, not just that the
  tooltip's own damage/heal numbers check out.
- `CAST_DEPENDENT_CHECKS` includes `gap_closer_distance`, so a silenced/interrupted cast reports
  `unmeasured` rather than a false `alert`.
- Any other class's charge/leap active gets the same scenario for free, since `closes_distance`/
  `gap_closer_target` read only the DBC effect/target fields, no class-specific code.
- `NOMINAL_MELEE_RANGE_YD` departs from the project's "expected values come from the DBC or tooltip" rule:
  none of the three gap-closer clauses carries a literal number, so the pass/fail boundary is read from the
  C++ engine constant `NOMINAL_MELEE_RANGE` instead, acknowledged here as a deliberate exception for a
  qualitative ("close enough to melee") claim with nothing else to anchor it to.
