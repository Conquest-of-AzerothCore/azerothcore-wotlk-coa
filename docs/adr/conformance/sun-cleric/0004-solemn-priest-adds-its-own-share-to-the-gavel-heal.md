# 0004. Solemn Priest adds its own share to the Gavel of Light heal

- Status: accepted
- Date: 2026-11-21

## Context

Solemn Priest 804269, Spell.dbc text: "Increases your melee attack power by $s1% of your Intellect and causes Gavel of
Light to heal you for an additional $s2% of its damage dealt." $s2 is 50 (effect 1, BasePoints 49).

Gavel of Light 800611 copies a share of its damage to the caster as 707522
(`AscensionSunClericAbilities.cpp`, `OnSpellHitResult`). The share was `Amount(707521)`, the 50 of 707521 effect 0,
read without a caster, so no spell modifier reaches it. Solemn Priest's effect 1 is such a modifier
(`SPELL_AURA_ADD_FLAT_MODIFIER`, `SPELLMOD_EFFECT1`, class mask 2097152 = 707521's SpellFamilyFlags[0]) and never
applied. Measured on the counted pair verify-all 20261120-220240 / -220327 (server 6b19c29902): the cumulative Gavel
heal went from 3177 to 6374 when the passive was learned (ratio 2.006, expected 3.0).

Spell modifiers of family 33 on that mask in the server Spell.dbc: Solemn Priest 804269 (`SPELLMOD_EFFECT1` +50),
Arbiter of Light 302914 (`SPELLMOD_EFFECT1`, raised to +100 by `AscensionSunClericValkyrie.cpp`), Last Wish 704940
(`SPELLMOD_JUMP_TARGETS`) and Blade of The Sun 805632 (`SPELLMOD_DURATION`). Arbiter of Light's text reads "While Vow
of Light is active, your Gavel of Light now restores an additional $807549s3% health equal to the damage dealt.", but
302914 is a passive that nothing gates on Vow of Light.

## Options

- Pass the caster to `Amount(707521)`, so every spell modifier on 707521 applies. Arbiter of Light's +100 would then
  apply at all times, a second behaviour change that no claim or ruling covers.
- Add Solemn Priest's own value, `Amount(804269, 1)`, while the caster has 804269, and leave the caster out.

## Decision

The second option (mentor decisions D-34 and D-36, 2026-11-21). The share is
`Amount(707521) + Amount(804269, 1)` while the caster has the 804269 aura, `Amount(707521)` otherwise.

## Consequences

- With Solemn Priest, the Gavel heal is 100% of its damage dealt; without it, 50%.
- Arbiter of Light still adds nothing to the heal. Its missing Vow of Light gate is a separate lead.
- No other class reads 707521, 707522, 804269 or 302914.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-solemn-priest-gavel-heal.json`, four arms: a control that
  learns nothing between two casts (ratio 1), Solemn Priest (ratio 2), Arbiter of Light alone (ratio 1) and both
  (ratio 2).
