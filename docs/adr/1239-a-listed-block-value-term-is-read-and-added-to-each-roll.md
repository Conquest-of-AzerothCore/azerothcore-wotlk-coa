# 1239. A listed block value term is read and added to each roll

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-289 (Sun Cleric 27, Dawnbreak 800654 chain)
- Related: ADR 1238 (rank hit per-level truncation)

## Context

`sun_cleric_scaling::ModifySpellEffectBaseValue` adds `Player::GetShieldBlockValue()` to effect 0 of every spell
named 800654 (AscensionSunClericContracts.cpp:324-325), before the int32 truncation of `CalcValue`
(SpellInfo.cpp:592). `GetShieldBlockValue` is `(flat + Strength x 0.5 - 10) x percent` (Player.cpp:5611-5618).
The tooltip gives the term only in words ("scaling with your block value"). Pair 13 read every Dawnbreak rank's
`effect_value` and the 504580 `hit_mean` about one block value (11 with shield 2129, block 1, and Strength 40) above
the formula, as alerts.

## Considered options

1. Add a reference block value from the item and Strength to the expectation. Rejected: the percent and other flat
   sources would be assumed, not read.
2. Read the block value in the run and add it to each per-roll value. Chosen.

## Decision

- Class-file entry `block_value_terms`: `{spell, effect, source}`, matched on the class spell (the chain the code
  names) and opt-in per class. The source cites the code.
- The value and hit scenarios of a listed spell read the harness metric `block_value` (CoAGameplayTest.cpp:5152-5153,
  the same `GetShieldBlockValue`, percent included) after the base steps (`block_value.block_value_steps`).
- `compare.judge_roll` adds the read to each per-roll value of the rank's own token on that effect, before the
  truncation and per-level rules; without the read it is `unmeasured`. `hits.rank_hit` adds it to the rolled values
  of that effect (`flat`), so the hit model floors `roll + bonus + block` as the engine does; without the read the hit
  judge reports the missing measurement.
- These are data-level records with the code as their source. They do not lift a tooltip claim on the amount: the
  ledger's "scaling with your block value" claim stays on its behaviour rows (`damage_block`, `damage_block_only`).

## Consequences

- Only the Dawnbreak chain's scenarios change (seven value scenarios, four hit parts, the manifest); finished
  classes have no entry and regenerate byte-identical.
- Seeded tests: `test_compare` (reads with the block value `ok`, the same reads without it `alert`, no read
  `unmeasured`) and `test_hits` (a listed Templar rank reads `block_value`, its hit mean rises, the unraised mean
  alerts, no read raises the missing measurement).
- A fixed (`EffectDieSides` 0 or 1) effect with a listed term is not handled; no listed effect is fixed.
