# 0533. Glacial Impact damage grows with the caster's Frost spell crit chance

- Status: accepted
- Date: 2026-11-13

## Context

The owner ruled (Q-a3-1, 09:0x go): Glacial Impact 707592 always deals damage x (1 + the caster's Frost spell crit
chance); the hit can still crit as usual, and crits as before under Glacier Lord 560852. No tooltip states a number:
the formula is the owner's. Fix note FN-own-7, approved by the mentor (09:3x): the factor reads the caster's
character-sheet Frost spell crit, floored at 0, with no upper cap; a per-spell guaranteed-crit modifier must not raise
it.

## Decision

- `Factor` (AscensionNecromancerContracts.cpp) multiplies 707592's damage by 1 + max(0, PLAYER_SPELL_CRIT_PERCENTAGE1 +
  SPELL_SCHOOL_FROST) / 100. `Factor` runs from `ModifySpellDamageTaken` after the crit roll, so crits and non-crits
  both carry it. The sheet value (`Player::UpdateSpellCritChance`: Intellect, aura 57 and 71, rating) excludes
  Glacier Lord's ASCENSION_STATE_MASKED_GUARANTEED_CRIT and the Frozen Bodies ten-stack hook.
- Conformance tools: a `hit_ratio` arm may set `aura_amounts` ([spell, effect, amount] of one of its own auras),
  applied with the harness `set_aura` amount before every trial, so a fixture aura holds an exact sheet value.

## Consequences

- Regression (class file 707402): control arms hold 984954 at its DBC -1000 (the floor: factor 1); treatment arms set
  984954 Effect[1] to +2 and +22, so the sheet is the reference's base 3.2817 (read in pair 20261113-043355) plus that:
  non-critical hits x 1.052817 (`crit_factor_5`) and x 1.252817 (`crit_factor_25`). `glacier_lord_factor`: with
  Glacier Lord learned in both arms every hit crits, and the crits are x 1.252817, not x 2. The `glacier_lord` rate
  entry stays +100 points (its arms hold the floored sheet).
- Entries holding 984954 keep their values because of the floor; an entry without it now carries x 1.03 at the
  reference's sheet. The field can exceed 100 with large ratings: no upper cap was ruled (observation for the balance
  pass, G-43). The Glacial Impact splash 707575 copies a share of the larger hit.
