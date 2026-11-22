# 0011. Luminary Mendicant raises the Vow of Grace mana once

- Status: accepted
- Date: 2026-11-22

## Context

Luminary Mendicant 547214, Spell.dbc text: "Increases the mana restored by Vow of Grace by $s1% ...". Its effect 0 is
`SPELL_AURA_ADD_PCT_MODIFIER`, `SPELLMOD_ALL_EFFECTS`, BasePoints 99 (+100%), on class mask word 1 `0x100000`. In
family 33 of the server Spell.dbc that flag is carried by Vow of Grace 504775 and 504877, and Luminary Mendicant is
the only modifier that reaches 504877.

Vow of Grace 803719 restores `CalculatePct(missing mana, Amount(504775))` plus `Amount(504877, 0, player)` on a direct
ability hit (`AscensionSunClericEvents.cpp`). The caster argument applies every spell modifier on 504877, Luminary
Mendicant's +100% included, and the script then added `AddPct(mana, Amount(547214))` while the caster had 547214, so
the 504877 part was doubled twice. Measured on batch 5b (review report L2): the first restore 285 (107 + 178), the
second 926 = (107 + 2 x 178) x 2, a cumulative ratio of 4.249 against 3.0, both runs.

## Options

- Drop the script's `AddPct` and keep the caster argument: the spell modifier raises 504877 once.
- Keep the `AddPct` and read 504877 without the caster: the modifier would no longer apply, and the script's own
  +100% would carry the tooltip alone.

## Decision

The first option (mentor decision D-72, 2026-11-22). The restore is `CalculatePct(missing, Amount(504775)) +
Amount(504877, 0, player)`.

## Consequences

- The 5% of missing mana (504775, read without a caster) is not raised by Luminary Mendicant: with it, the restore at
  the measured state is 107 + 356 = 463 by this arithmetic, where the tooltip's +100% on the whole restore gives 570.
  The counted pair after the fix states the measured value.
- No other class reads 547214, 504775, 504877 or 803719's restore.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-luminary-mendicant-vow-of-grace-mana.json`, a control that
  learns nothing between two Horusath Blasts (ratio 1) and a Luminary Mendicant arm (ratio 2 by the tooltip).
