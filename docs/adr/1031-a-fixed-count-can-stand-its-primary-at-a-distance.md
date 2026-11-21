# 1031. A fixed count can stand its primary at a distance

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21

## Context

`fixed_count` always placed its primary dummy 3 yd from the caster and the other dummies on the line beyond it. A
ranged-slot shot with a minimum range, such as Spirit Volley 504582, is refused there as SPELL_FAILED_TOO_CLOSE
(`Spell.cpp:7355-7359`), so its target count could not be read (tool notes T-b13-8, T-c9-B16-18). `metric_delta`,
`stack_chance_rate` and `procs` already take a `dummy_distance`.

The cycle 10 proposal also asked for a `forced_roll` on `fixed_count`, for a minion shot behind a roll (Voodoo Fire
500473 from the Serpent Ward). `fixed_count` judges the breadth of each player cast between two reads; a ward may
shoot several times inside one such window, so the per-cast breadth of a forced minion shot is not defined without a
per-shot read. That part is not built here.

## Decision

`fixed_count` takes `dummy_distance` (0 to 100 yd, `dummy_placement`): the primary stands that far from the caster and
every other dummy keeps its offset beyond it, the far dummy included. It is refused with a cast at the caster, a caster
layout, `behind_yd`, `swing_cleave` or `swing_ms`. The contract names the distance.

## Consequences

- No existing `fixed_count` entry sets it: generated scenarios of classes 19 (also `--stack`) and 23 are
  byte-identical (`diff -r`, 2026-11-21).
- Witch Doctor: 503712 `volley_targets` (the Volley at a primary 15 yd away, expected 3 extra dummies per cast, 30
  casts) links clause 68 "and up to $i enemies" and "within $a1 yds"; the damage formula claim keeps its tool gap.
- Seeded tests in `test_behaviours.py`: the shifted layout and the refused combinations.
