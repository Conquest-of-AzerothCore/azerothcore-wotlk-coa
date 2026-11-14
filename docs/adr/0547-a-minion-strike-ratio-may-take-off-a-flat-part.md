# 0547. A minion strike ratio may take off its flat part

- Status: accepted
- Date: 2026-11-13
- Split before publication (mentor ruling 2, 2026-11-13): this ADR keeps the tool rule; the Skeletal Warriors fix it
  was written for is
  [Necromancer ADR 0029](conformance/necromancer/0029-command-skeletal-warriors-doubles-the-weapon-roll.md).

## Context

A minion command strike can carry a flat part next to its weapon multiple (Command: Skeletal Warriors 570042, fix note
FN-c1t-1, Necromancer ADR 0029: 2.0 times the swing plus the flat part of Effect[1] computed from spell power). The
`minion_swing_ratio` judge ([ADR 0541](0541-a-minion-strike-is-judged-against-its-own-swing.md)) compared the whole
strike with the swing.

## Decision

- `minion_swing_ratio` takes `strike_flat`: that amount is taken off every strike hit before the per-hit mean is
  divided by the per-swing mean (model `treatment_flat`, applied by the hit ratio judge to the treatment totals only).
- `minion_swing_ratio` takes `player_spell_power` (the harness spell-power fixture), so an arm can hold a spell power
  that separates a single flat part from a doubled one.
- Entries without `strike_flat` judge as before (Templar `generate --class 19` and `--stack` byte-identical).

## Consequences

- The flat amount is taken off unmitigated; on an armor-reduced Physical hit this may bias the ratio low (the
  Skeletal Warriors SP arm reads about 2.4% under 2.0, cause NOT measured, Necromancer ADR 0029). The judge is not
  changed.
- Tests: `MinionSwingRatioTests` (test_behaviours.py) with the flat part.
