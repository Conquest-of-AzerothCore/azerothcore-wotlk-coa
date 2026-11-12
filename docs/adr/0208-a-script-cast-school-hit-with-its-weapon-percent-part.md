# 0208. A script-cast school hit with its weapon percent part, and a value read from another spell

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0160 (script-cast hits), ADR 0172 (a learned weapon part)

## Context

The Scourgebane strike 801832 has a school damage effect and a WEAPON_PERCENT_DAMAGE effect (50%). Scourgebane 92111's
tooltip states both (claims 4 and 5); the script-hit model refused a hit of two models. Divine Charge's trample 527269
takes its value from 527270's Effect[2] (AscensionTemplarContracts.cpp:331-332), which the tooltip shows as
`$527270m3`; the model kept only tokens of the hit spell itself.

## Considered options

1. Judge only the school part. A strike with its weapon part read 25 points above it.
2. Add the weapon part through `expected_hit`'s existing `weapon_part` (ADR 0172), and map another spell's token onto
   the hit's school effect. Chosen.

## Decision

- `hits.script_hit_model`: when the tooltip shows the hit's weapon effect, the hit must be one school damage effect and
  one weapon percent effect; the weapon part (`weapon_hit` with the class weapon) is added to the school part.
- `script_hit` takes `value_spell` and `value_effect`: the tooltip token of that spell's effect is read as the hit's
  school effect. Both reach the compare-time model through the expectation record.

## Consequences

- 4 and 5: 260.6 / 259.5 against 258.0 (school only would be 236.4). With the dummy's resistance removed (823764,
  unresisted model), the strike reads 292.8 against 292.8 (school part 268.0), which bounds the weapon percent to
  about 49.5-50.5 (review I1).
- 387 (Argent Blade's text states the school part only) and 102 (the trample) alert; see the r2-a question and fix note.
- Other script hits regenerate byte-identical (1693 of 1693 for ADRs 0204-0208 together, 11 new scenarios).
- Tests: `test_behaviours.ScriptHitWeaponAndValueTests`.
