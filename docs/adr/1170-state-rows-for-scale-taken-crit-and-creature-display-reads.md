# 1170. State rows for scale, taken crit chance and a creature display read

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-22
- Builds on: ADR 0036, ADR 1029

## Context

Four Witch Doctor claims had a harness read but no countable evidence: Shrinking Jinx 807833 "reducing their size"
(`unit_scale` had no `coverage.METRIC_EVIDENCE` row, pitfall 5), Cursed Effigy 706542 "are unable to critically
strike" (`melee_crit_taken_chance`, the enemy's `Unit::GetUnitCriticalChance` against the player, had no row),
Hexed 504762 "unable to move" (`rooted` is promised by `root\w*` only) and Brew Cocktail 807076 "Conjured items
disappear ..." (`item_count` is promised by `creat\w*|brew\w*`). Slither 500947 "Transform into a serpent" sets a
display chosen at random among the four models of creature template 2914 (`ObjectMgr::ChooseDisplayId`,
SpellAuraEffects.cpp:3034), so `display_id` has no single expected value.

## Decision

- Harness read `display_of_creature` (`entry`): 1 when the unit's display is one of the models of that creature
  template (`CreatureTemplate::GetModelWithDisplayId`), else 0.
- `coverage.METRIC_EVIDENCE` STATE rows for `unit_scale`, `melee_crit_taken_chance` and `display_of_creature`, with
  the promises `size|scale`, the crit words plus `critically strike`, and `transform\w*`.
- `rooted` is also promised by `unable to move`; `item_count` also by `conjur\w*`.

## Consequences

Coverage only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical. Class 13
gains 500947 `slither_form`, 807833 `jinx_size`, 706542 `effigy_no_crit`, 506634 `hexed_rooted` and 807076
`logout_expiry`. The harness read needs a build.
