# 0528. An owned creature's health modifiers are read unrounded

- Status: accepted
- Date: 2026-11-13

## Context

Hulking Hordes 300748 and 301326 raise the maximum health of summons by $s1% (5% and 10%). A Ghoul read 1380 before
and 1450 / 1519 after, one above the tooltip's 1449 / 1518 on the truncated 1380. The mentor ruled (2026-11-13) that
these may count as engine rounding (status 2, the Sturdy precedent) only after a read of the unrounded float base
reproduces 1450 and 1519 exactly. `owned_creature_max_health` reads only the truncated `GetMaxHealth()`.

## Decision

- Read-only harness metric `owned_creature_health_modifier` (G-39, a read): the owned creature's `UNIT_MOD_HEALTH`
  parts, `part` 0 base value, 1 base percent, 2 total value, 3 total percent, as floats
  (`GetFlatModifierValue` / `GetPctModifierValue`). `Creature::UpdateMaxHealth` truncates
  (base value x base percent + total value) x total percent (Unit::GetTotalAuraModValue).

## Consequences

- Runner validation requires `entry` and `part` 0..3 (test_runner.py).
- No gameplay path changes.
