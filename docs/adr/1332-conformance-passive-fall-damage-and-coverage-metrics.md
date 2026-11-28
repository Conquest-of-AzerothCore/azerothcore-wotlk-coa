# 1332. Passive `fall_damage` scenarios and teleport/viewpoint coverage metrics

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-27
- Rulings: Felsworn (class 14) extra-spell catch-up (`520591` *Fel Finesse*, `532229` *Twisted Sight*, `535595..535605` *Fel Rifts*)

## Context

Integrating Felsworn's extra-spell conformance fragments surfaced two small shared gaps:

1. **Passive `fall_damage` spells (`520591` *Fel Finesse*)**: `behaviours.fall_damage_scenario` previously learned
   `spec.cast_spell` before the `without` landing and cast it between `without` and `with`. For a passive
   `SPELL_AURA_SAFE_FALL` spell, learning it before `without` applies Safe Fall to both landings and casting a passive
   is invalid.
2. **Teleport and viewpoint metrics in `coverage.py`**: `CoAGameplayTest.cpp`, `behaviours.py`, and `run.validate`
   already support `map_id`, `position_y`, `position_z`, and `viewpoint_entry`, but `coverage.METRIC_EVIDENCE` and
   `coverage.STATE_PROMISES` lacked rows for those four metrics, causing `coverage.clause_coverage()` to raise
   `EvidenceError` on Fel Rift (`535595..535605`) and *Twisted Sight* (`532229`) scenarios.

## Options

- Duplicate `fall_damage` into a separate `passive_fall_damage` kind: rejected; the judgement and measurements are
  identical, only the setup step order differs when `facts.passive` is true.
- Add a passive branch inside `fall_damage_scenario` (preserving active-spell output byte-for-byte) and register
  `map_id`, `position_y`, `position_z`, and `viewpoint_entry` as `STATE` metrics with matching `STATE_PROMISES` in
  `coverage.py`. Chosen.

## Decision

1. **Passive branch in `apps/coa-gameplay-test/conformance/behaviours.py` (`fall_damage_scenario`)**:
   - When `facts.passive` is `True`: run `landing('without')` first, then `learn spec.cast_spell`, wait
     `FALL_DAMAGE_AURA_SETTLE_MS`, measure `aura` on `spec.receiver`, and run `landing('with')` (omitting
     `cast_gate_power_step`, `required_aura_steps`, and `cast`).
   - When `facts.passive` is `False`: preserve steps and contract text byte-for-byte.
2. **Register 4 `STATE` metrics in `apps/coa-gameplay-test/conformance/coverage.py`**:
   - Add `map_id`, `position_y`, `position_z`, and `viewpoint_entry` to `METRIC_EVIDENCE` as `STATE`.
   - Add `STATE_PROMISES` patterns: `'map_id'`, `'position_y'`, `'position_z'` -> `r'teleport\w*'`; `'viewpoint_entry'`
     -> `r'vision|sight|eye'`.

## Consequences

- Zero diff on all other class snapshots (`13, 15, 19, 23, 25, 27`).
- Passive safe-fall spells like `520591` (*Fel Finesse*) measure fall damage cleanly before vs after learning the
  passive.
- Teleport destination and viewpoint-binding claims are classified as `behaviour` evidence when their clauses promise
  teleportation or vision/sight/eye binding, and `data` otherwise.
- Unit tests in `test_behaviours.py` and `test_coverage.py` cover both additions.
