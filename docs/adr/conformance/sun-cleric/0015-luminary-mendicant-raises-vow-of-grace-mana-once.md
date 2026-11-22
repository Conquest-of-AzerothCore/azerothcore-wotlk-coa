# 0015. Luminary Mendicant raises the Vow of Grace mana once

- Status: accepted
- Date: 2026-11-22

## Context

Luminary Mendicant 547214, Spell.dbc text: "Increases the mana restored by Vow of Grace by $s1% ...". Its effect 0 is
`SPELL_AURA_ADD_PCT_MODIFIER`, `SPELLMOD_ALL_EFFECTS`, BasePoints 99 (+100%), on class mask word 1 `0x100000`. Vow of
Grace 803719 text: "direct ability damage or healing now regenerates $504775s1% of your missing mana plus
${$504877m1+$504877ppl1}." Both 504775 and 504877 carry SpellFamilyFlags[1] `0x100000`.

Vow of Grace restored `CalculatePct(missing mana, Amount(504775))` plus `Amount(504877, 0, player)` on a direct ability
hit (`AscensionSunClericEvents.cpp`), then `AddPct(mana, Amount(547214))` while the caster had 547214. The caster
argument already applies Luminary Mendicant's +100% to 504877, so that part was doubled twice. Measured on batch 5b
(review report L2): the first restore 285 (107 + 178), the second 926 = (107 + 2 x 178) x 2, a cumulative ratio of
4.249 against 3.0, both runs.

Spell modifiers (aura 107 or 108, server Spell.dbc) whose mask matches word 1 `0x100000`: Luminary Mendicant 547214
only, so it is the only modifier that reaches 504775 or 504877. 504775 has no per-level points (RealPointsPerLevel 0,
SpellLevel and BaseLevel 0); 504877 has 3.5 per level from level 12, which `SpellEffectInfo::CalcValue` adds only with a
caster (178 at level 60, 10 without).

## Options

- (a) Drop the script's `AddPct` and read both 504775 and 504877 with the caster: the modifier raises the whole restore
  once, 2 x (107 + 178) = 570 at the measured state.
- (b) Keep the `AddPct` and read 504877 without the caster. That also drops 504877's per-level points: 117 without the
  passive and 234 with it, against the tooltip's 285 and 570.
- (c) Drop the `AddPct` and keep 504775 read without the caster: the 5% of missing mana is not raised, 107 + 356 = 463.
  Built first (mentor decision D-72) and measured at 463 on the pair 20261122-034040 / -034113, build df2938ad58ac.

## Decision

Option (a) (mentor decisions D-72 and D-79, 2026-11-22). The restore is `CalculatePct(missing, Amount(504775, 0,
player)) + Amount(504877, 0, player)`, with no script multiplier.

## Consequences

- With Luminary Mendicant the restore is twice the restore without it, both parts included.
- No other class reads 547214, 504775, 504877 or 803719's restore.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-luminary-mendicant-vow-of-grace-mana.json`, a control that
  learns nothing between two Horusath Blasts (ratio 1) and a Luminary Mendicant arm (ratio 2).
