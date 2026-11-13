# 0149. Cancel the truncated per-level term for every unscaled Templar effect

- Status: accepted (mentor approval, 2026-11-11)
- Date: 2026-11-11
- Extends: ADR 0045 (cancel list) and ADR 0148

## Context

Some Templar tooltips show an effect's amount without its per-level term; the server takes the term back out in
`ModifySpellEffectBaseValue` (`src/server/coa/AscensionTemplarContracts.cpp`). ADR 0045 made the shared cancel step
subtract `float(int32(term))`, the amount stock `SpellEffectInfo::CalcValue` actually added (SpellInfo.cpp:497),
for the spells of `TEMPLAR_TOOLTIP_UNSCALED_BY_LEVEL_SPELLS`. Two effects kept their own cancel lines with the
continuous term:
- Chakra of Light 803844 e0: `value -= 2.65f * level`;
- Scarlet Hammer 807035 e1: `value -= 9.76f * max(0, level - 30)`.

At level 60, stock adds `int32(30 x 9.76) = 292` to Scarlet Hammer and the hook takes 292.8 away. Warrior of Dawn
301065's Scarlet Hammer reads 41 against its tooltip's `${$m2+0}` = 42 (`.cache/ppl2`, both runs); ADR 0147's fixed
rule now reports it. The mentor approved the fix (2026-11-11).

## Decision

- Add `TEMPLAR_TOOLTIP_UNSCALED_BY_LEVEL_EFFECTS` = {803844 effect 0, 807035 effect 1}.
  `CancelStockEffectRealPointsPerLevel` cancels a listed spell or a listed (spell, effect) pair the same way: it
  subtracts the truncated amount from the shared helper `StockEffectRealPointsPerLevelAmount`.
- Remove the two bespoke lines. The helper computes the same term with stock's clamp: 803844 has BaseLevel,
  SpellLevel and MaxLevel 0, so `60 x 2.65`; 807035 has BaseLevel 30 and no MaxLevel, so `(level - 30) x 9.76`.

## Consequences

- Scarlet Hammer 807035 e1 reads its tooltip's 42 at level 60 (claim 41's label `301065 effect_value 807035e1`).
- Chakra of Light 803844 e0 is unchanged at level 60: `60 x 2.65f` rounds to 159.0 in float, so the continuous and
  truncated terms are equal there.
- The 15 spells of the cancel list keep the arithmetic they already had.
