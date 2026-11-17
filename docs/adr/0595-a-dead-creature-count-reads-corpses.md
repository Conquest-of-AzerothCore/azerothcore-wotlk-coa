# 0595. A dead-creature count reads corpses

- Status: accepted
- Date: 2026-11-13

## Context

Graveyard 805197 "creating a corpse" (claim 356.1): every raised Risen Ghoul 542065 dies after 500 ms and stays as a
corpse (`TEMPSUMMON_CORPSE_TIMED_DESPAWN`). `nearby_creature_count` counts living creatures only (gap T4).

## Options

1. A `dead` flag on `nearby_creature_count` (G-39 pure read).
2. A separate corpse metric (duplicate filters).

## Decision

Option 1: with `dead: true` the metric counts dead creatures of the entry in the player's phase (parallel scenarios
share a location in other phases). Kind `corpse_per_raise` polls the game time, the caster's `spell_cast_count` of the
raise spell and the dead count; the corpses that appear must equal the raises settled `death_ms` before the window ends.

## Consequences

- Living counts are unchanged (the phase check applies to `dead` only).
- Pilot 20261113-150027: 15 corpses for 15 settled raises (ok).
