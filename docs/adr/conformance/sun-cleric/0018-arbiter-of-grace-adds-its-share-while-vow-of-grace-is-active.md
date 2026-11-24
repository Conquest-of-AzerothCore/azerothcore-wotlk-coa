# 0018. Arbiter of Grace adds its Glorious Execution mana share while Vow of Grace is active

- Status: accepted
- Date: 2026-11-22

## Context

Arbiter of Grace 301313, Spell.dbc text: "While Vow of Grace is active, your Glorious Execution now regenerates an
additional $807446s3% mana equal to the damage dealt." `$807446s3` is 15 (Vow of Grace 807446 effect 2, BasePoints 14,
DieSides 1, no per-level points).

Glorious Execution's hits 800691 and 802566 restore mana as 807552 (`AscensionSunClericAbilities.cpp`,
`OnSpellHitResult`): `CalculatePct(dealt, Amount(807451))`, read without a caster. Arbiter of Grace's
`SPELLMOD_EFFECT1` on 807451 (BasePoints raised to 14 by `AscensionSunClericValkyrie.cpp`, merged #4516 for #1818)
never reaches that read. 807446 effect 2 carries the tooltip's gate in the DBC (aura 107, `SPELLMOD_EFFECT1`, class
mask word 2 `0x01000000`, which is 301313's SpellFamilyFlags[2]), but CoA code makes every effect of 807446 a dummy
(`AscensionSunClericContracts.cpp`) and removes the 807446 aura at every refresh (`AscensionSunCleric.cpp`), so its
presence cannot gate anything. The Vow of Grace the class casts is 803719: a class spell of class 27
(`AscensionCustomClassData.h`, `ClassSpells`), one of the class's vows (`SunClericVows`, `AscensionSunClericData.h`)
whose restore is scripted in `AscensionSunClericEvents.cpp` ([Sun Cleric ADR 0015](0015-luminary-mendicant-raises-vow-of-grace-mana-once.md)),
and applied on live 54 times in the combat logs of 2026-07-12 to 2026-08-23 (coa-history).

Measured on batch 6b (review report I-1): `ge_mana_vow` ratio 1.9985 / 2.0015 against 5.0, the control
`ge_mana_no_vow` 2.0045 / 2.0015, with 803719 cast before both phases of the Vow arm.

Spell modifiers of the server Spell.dbc (aura 107 or 108):
- On 807451, family 33: Arbiter of Grace 301313 (`SPELLMOD_EFFECT1`), and 300358, 504734, 560696, 560859, 561329,
  578294 and 802599, none of which modifies an effect value. Family-0 auras with a zero mask: 280135, 281131, 281181,
  965588 (`SPELLMOD_EFFECT1`) and 281182 (`SPELLMOD_ALL_EFFECTS`); none is a Sun Cleric aura.
- On 807446, family 33: 570045 (`SPELLMOD_CRITICAL_CHANCE`) and 707528 (`SPELLMOD_EFFECT2`), neither of which
  modifies effect 2. Family-0 auras with a zero mask: 281181 (`SPELLMOD_EFFECT3`) and 281182 (`SPELLMOD_ALL_EFFECTS`).

## Options

- Pass the caster to `Amount(807451)`. Arbiter of Grace's +15 would apply at all times, with or without Vow of Grace.
- Add 807446 effect 2 to the share while the caster has both Arbiter of Grace 301313 and the Vow of Grace aura
  803719, and keep the read without a caster (the shape of [Sun Cleric ADR 0014](0014-arbiter-of-light-adds-its-share-while-vow-of-light-is-active.md)).

## Decision

The second option (mentor decision D-84, 2026-11-22, on the design of D-71; "While Vow of Grace is active" is read as
aura 803719 present). The share is `Amount(807451)`, plus `Amount(807446, 2)` with Arbiter of Grace and Vow of Grace.
The value comes from the data, not a literal.

Both reads stay without a caster. `Amount(807451)` keeps dropping every spell modifier and the script hook, as before
this change; its level scaling is dropped too and is zero (`EffectRealPointsPerLevel[0]` 0.0). `Amount(807446, 2)`
drops the modifiers listed above, none of which is a Sun Cleric aura, and its level scaling, which is zero
(`EffectRealPointsPerLevel[2]` 0.0).

## Consequences

- With Arbiter of Grace and Vow of Grace, Glorious Execution restores 20% of its damage dealt as mana; without Vow of
  Grace, Arbiter of Grace adds nothing.
- This replaces #4516's intent of an ungated +15 with the tooltip's gate. The Valkyrie script's BasePoints correction
  stays; its scenario `sun-cleric-arbiter-of-grace.json` reads 807451's modified value, which no mana restore uses.
- No other class reads 301313, 803719, 807446, 807451 or 807552.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-arbiter-of-grace-vow-gate.json`, three arms: a control
  with Vow of Grace and without Arbiter of Grace (ratio 1), Arbiter of Grace without Vow of Grace (ratio 1) and both
  (ratio 4).
