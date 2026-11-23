# 1102. A metric delta can set the caster's specialization or the enemy player's spell power

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582 (metric_delta option modules)

## Context

- Mixologist 561069 teaches Ingredient: Fish Oil through `SynchronizeTaughtAbilities`, which teaches it only in
  specialization 6 (`AscensionTaughtAbilityData.h:27`); the harness learn runs the sync, but the reference caster is in
  another specialization, so the `fish_taught` entry alerted (an incorrect test).
- Shrinking Jinx 807833 lowers an enemy's spell power by 85. `spell_power` clamps at 0 and the enemy player has none.

## Decision

Two `metric_delta` option modules: `specialization` (an id; the harness `specialization` step at the start of the
before phase, a precondition fixture) and `enemy_spell_power` (a positive amount set as the `spell_power` fixture of
the enemy player of `enemy_player_race`).

## Consequences

New modules only; classes 19 and 23 generate unchanged.
