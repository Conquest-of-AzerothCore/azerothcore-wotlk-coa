# 0214. A PvP-flagged enemy player as a metric_delta target

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0191 (the player striker of taken_hit)

## Context

Tranquil Circle 801205, claim 294: "falling asleep for $850010d (8 sec vs players)". templar_scaling::OnAuraApply
(AscensionTemplarContracts.cpp:313-320) caps Tranquil State 850010 at 8000 ms on a player. A metric_delta reads a unit
around a cast, but its only units were the caster and the dummy.

## Options

1. A hand-written scenario outside the class file. The ledger cannot label it.
2. A taken_hit-like kind for a cast at a player. It repeats the metric_delta phases.
3. `enemy_player_race` on `metric_delta`: a PvP-flagged player of that race and the caster's class, `enemy`, which the
   entry's `target` and `measure_actor` may name.

## Decision

Option 3. With `enemy_player_race` the scenario adds the `enemy` player, moves to `TAKEN_HIT_PVP_LOCATION` (Elwynn
Forest) and flags both players for PvP after the base steps, with a 500 ms settle. The race is refused unless the
target or the measured unit is `enemy`, and `enemy` is refused without the race. Entries without it regenerate
byte-identical.

## Consequences

- Tranquil Circle on build 861e0e1e6bee (counted 20261112-015203 / -015316): an orc in the circle has no 850010 before
  the cast, has it 9800 ms after the cast and not 10200 ms after it (applied at about 2000 ms: 8000 ms); the dummy in the
  same cast keeps it 40000 ms (the `sleep` entry, 41800 / 42200 ms).
- Seeded tests: the enemy is PvP-flagged before the cast and measured; an enemy target without a race is refused; a
  creature-length sleep on the player alerts.
