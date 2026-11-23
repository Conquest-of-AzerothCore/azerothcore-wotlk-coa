# 0043. Valkyr's Calling's charge-back lands on its stored victim, whatever the selection

- Status: accepted (owner ruling O-32, mentor D-302, 2026-11-23)
- Date: 2026-11-23

## Context

Valkyr's Calling 520024: "Target an enemy and leap into the air, becoming immune to all physical attacks and spells
for $d. At the end of the duration, you charge back down, dealing ${$570034m1+$570034ppl1+$AP*1+$SP*.225} Holy damage
to all enemies within $570034a1 yds."

The flight and the landing are scripted (`AscensionSunClericSummons.cpp`, `Valkyr`, since e36bc50aad): the cast stores
the victim's GUID, the flight aura 520025 runs, then the caster charges to the victim's position and, once within 3 yd
of it, casts the landing spell 570034. That cast passed only a position (`CastSpell(x, y, z, 570034, true)`).

570034 in the server Spell.dbc: Effect[0] 2 SCHOOL_DAMAGE, EffectImplicitTargetA[0] 53 TARGET_DEST_TARGET_ENEMY,
EffectImplicitTargetB[0] 16 TARGET_UNIT_DEST_AREA_ENEMY, RadiusIndex 14 (8 yd), RangeIndex 13. TargetA 53 needs a unit
target and puts the destination on it (`Spell::SelectImplicitTargetDestTargets`). With no unit target given,
`Spell::InitExplicitTargets` takes the player's selection when it passes `CheckExplicitTarget`; otherwise the cast is
refused. So the landing depended on the selection at landing time (ledger 108, observation M1): no selection or a
friendly one refused 570034 (cast_failure 27, no damage), and another enemy selected moved the 8 yd area onto that
enemy.

Owner ruling O-32 (mentor D-302): the charge-back lands on the stored original victim, or the landing point, whatever
the player's selection, with the distance behaviour unchanged.

## Options

- Cast 570034 at the stored victim: TargetA 53 then takes the victim, whatever is selected.
- Keep the position cast and add a destination handler that sets 570034's destination to the landing point: a second
  hook for what the unit target already gives.

## Decision

The first option. At landing, the victim stored at the cast is looked up again; when it exists and is still a valid
attack target, and the caster ended within 3 yd of the charge destination, 570034 is cast at it.

## Consequences

- The landing no longer reads the player's selection: no selection, a friendly selection and another enemy selected
  all land on the victim. The 8 yd area is centred on the victim's position at landing.
- Unchanged: the 20 yd cast range, the fall without damage when at the end of the flight the victim is gone, dead,
  not a valid attack target or farther than 50 yd plus both sizes, nothing when the caster is dead or on another map,
  and no damage when the caster ends more than 3 yd from the charge destination.
- Changed, owner ruling O-39: a victim that dies or becomes invalid during the charge itself (after the flight) gives
  no damage, as at the end of the flight. Before, the landing then used whatever enemy was selected, so another
  selected enemy took the 8 yd area; that fallback is dropped. Unchanged for the cases with no selection or a
  friendly one (refused before, no cast now). No arm reads this case: `metric_delta` has no option that kills the
  victim during the flight with a second enemy selected, and building one is a tool addition awaiting approval.
- Readers: 570034 is read by id only in Sun Cleric code (`AscensionSunClericSummons.cpp`, the Dawn script values in
  `AscensionSunClericAbilities.cpp`, the coefficient row in `AscensionSunClericData.h`) and the Sun Cleric SQL;
  520024 and 520025 as in [Sun Cleric ADR 0010](0010-valkyrs-calling-landing-follows-the-flight-aura.md). No other
  class file or class code reads 520024, 520025 or 570034.
- Regression: the gameplay scenario
  `apps/coa-gameplay-test/scenarios/sun-cleric-valkyrs-calling-lands-on-its-target-whatever-the-selection.json`
  (no selection, the caster itself selected, a second enemy 17 yd from the victim selected, and the control with the
  victim selected), and the class-file entry `520024 behaviour_metric_delta charge_hit_unselected` (charge_hit without
  `select_dummy`, with `void_on_cast_failure`).
- Measured, entry `charge_hit_unselected` on counted pairs at level 60: before the change 20261123-075832 /
  20261123-080115 (build ac0f574d6fa0), unmeasured in both runs with 0 damage and 570034 refused (27); after it
  20261123-080405 / 20261123-080548 (build 302047965b98), ok in both runs, 497 against 497.6, the other 22 entries of
  520024 ok in all four runs, no flip. The regression scenario failed before the change on its no-selection arm
  (570034 refused, 27, for the no-selection and friendly-selection casters) and passed after it (20261123-080701).
