# 0016. Empowered Holy Form shortens every rank of Ancient Rites

- Status: accepted
- Date: 2026-11-22

## Context

Empowered Holy Form 800602, Spell.dbc text: "Doubles the effectiveness of your Holy Form and reduces the tick rate of
Ancient Rites by $/1000;s2 sec." `$s2` is -5000 ms. Its own effect 1 (`SPELLMOD_ACTIVATION_TIME` on 301368's flags)
targets the non-periodic energize and is turned into a dummy (`AscensionSunClericContracts.cpp`); the class aura script
lowers the period instead (`AscensionSunClericAuras.cpp`, `Period`).

Ancient Rites has three ranks, 300351, 301345 and 301817, each "Ancient Rites" with effect 0 aura 227,
EffectAmplitude 15000, triggering the energize 301368, and all three are obtainable (CharacterAdvancement.dbc). All
three carry `aura_ascension_sun_cleric_lifecycle`. The script tested `Named(GetSpellInfo(), 300351)`, a first-in-chain
equality; no `spell_ranks` row links the three ids, so only rank 1 was shortened. Measured on batch 5b (review report
L3): `period_upper_301345` and `period_upper_301817` 0 energize by 10.8 s against 1, both runs; rank 1 `period_upper`
1 and `period_lower` 0.

## Options

- Test the three rank ids in the script.
- Add a `spell_ranks` chain for the three ids. Every other `Named` test on those ids and every rank-aware engine path
  would then treat them as one chain, a wider change than the clause.

## Decision

The first option (mentor decision D-73, 2026-11-22). The script lowers the period of 300351, 301345 and 301817 by
`Amount(800602, 1)` while the caster has 800602.

## Consequences

- Every rank of Ancient Rites ticks every 10 s with Empowered Holy Form, 15 s without it.
- No other class reads 800602, 300351, 301345, 301817 or 301368. `AscensionStockCoefficientData.h` lists the three
  ranks for coefficients only.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-empowered-holy-form-ancient-rites-ranks.json`, one arm per
  rank with Empowered Holy Form (0 ticks by 8 s, 1 by 10.8 s) and one control per rank without it (0 and 0).
