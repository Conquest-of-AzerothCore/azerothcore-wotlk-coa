# 0014. Arbiter of Light adds its Gavel of Light heal share while Vow of Light is active

- Status: accepted
- Date: 2026-11-22

## Context

Arbiter of Light 302914, Spell.dbc text: "While Vow of Light is active, your Gavel of Light now restores an additional
$807549s3% health equal to the damage dealt." `$807549s3` is 100 (Vow of Light 807549 effect 2, BasePoints 99).

Gavel of Light 800611 copies a share of its damage to the caster as 707522 (`AscensionSunClericAbilities.cpp`,
`OnSpellHitResult`). The share is `Amount(707521)`, read without a caster, plus Solemn Priest's own value while the
caster has 804269 ([Sun Cleric ADR 0004](0004-solemn-priest-adds-its-own-share-to-the-gavel-heal.md)). Arbiter of
Light's `SPELLMOD_EFFECT1` on 707521 (raised to +100 by `AscensionSunClericValkyrie.cpp`, merged #4516) never reaches
that read, and nothing applies 807549, whose effect 2 carries the tooltip's gate in the DBC: no incoming trigger, not
obtainable, no reference in `src/` or `data/sql/updates`, 0 events in 186 combat logs. The live Vow of Light is
807547 (trainer-taught, cast and applied in 5 logs each).

Measured on batch 5b (review report L1): `gavel_heal_vow` ratio 1.9959 / 2.0025 against 4.0, the control
`gavel_heal_no_vow` 2.0005 / 1.9977, with 807547 up in both phases (`vow_aura_active` 1 / 1).

Spell modifiers of family 33 that reach 707521 in the server Spell.dbc: Arbiter of Light 302914 (`SPELLMOD_EFFECT1`),
Solemn Priest 804269 (`SPELLMOD_EFFECT1` +50), Last Wish 704940 (`SPELLMOD_JUMP_TARGETS`) and Blade of The Sun 805632
(`SPELLMOD_DURATION`). None reaches the share, which is still read without a caster.

## Options

- Pass the caster to `Amount(707521)`. Arbiter of Light's +100 would apply at all times, and Solemn Priest's +50 would
  be counted twice beside its own share (ADR 0004).
- Add 807549 effect 2 to the share while the caster has both Arbiter of Light 302914 and the Vow of Light aura
  807547, and keep the read without a caster.

## Decision

The second option (mentor decision D-71, 2026-11-22; "While Vow of Light is active" is read as aura 807547 present).
The share is `Amount(707521)`, plus `Amount(804269, 1)` with Solemn Priest, plus `Amount(807549, 2)` with Arbiter of
Light and Vow of Light. The value comes from the data, not a literal.

## Consequences

- With Arbiter of Light and Vow of Light the Gavel heal is 150% of its damage dealt (200% with Solemn Priest);
  without Vow of Light, Arbiter of Light adds nothing.
- This narrows #4516's ungated +100 to the tooltip's gate. The Valkyrie script's BasePoints correction stays; its
  scenario `sun-cleric-arbiter-of-light.json` reads 707521's modified value, which no heal uses.
- No other class reads 302914, 807547, 807549, 707521 or 707522.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-arbiter-of-light-vow-gate.json`, three arms: a control
  with Vow of Light and without Arbiter of Light (ratio 1), Arbiter of Light without Vow of Light (ratio 1) and both
  (ratio 3). `sun-cleric-solemn-priest-gavel-heal.json` keeps its four arms, none of which casts Vow of Light.
