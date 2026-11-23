# 1110. A player can be placed at an owned creature, and creature casts can be untriggered

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 1027 (fixture creature casts), ADR 0221 (relocate)

## Context

Witch Doctor cycle 11 (author b) found three claims the harness could not reach:

- Summon-centred radii (tool note T-c8-2): Spirit Idol 500961 "Allies within $500958A1 yds" and Shadow Effigy 505339
  "Enemies within $504761a1 yds" search around the summon (`Nearby(me, 30)`), whose position is only known at run
  time. `relocate` moves a player by fixed offsets from where it stands, so no edge bracket could be placed from the
  code's centre, and nothing read the summon's position or combat reach.
- The idol's energize 805282 is cast by the idol, and `spell_energize_*` reads only logs whose caster is the player or
  its pet.
- Fool's Play 681007 "replicates their spells back on them" mirrors a cast through an `ALLSPELLHOOK_ON_CAST` hook that
  skips triggered casts. The harness creature `cast` always used `TRIGGERED_FULL_MASK`, so a fixture creature's cast
  could never be mirrored (tool note T-e).

## Decision

- `relocate` with `around_owner` (a player) and `around_entry` places the actor at that player's present owned
  creature of the entry: `radius` + the creature's combat reach + the actor's combat reach + `edge_offset` yd away
  along `bearing` (radians, world axes), at the creature's height. The record holds the distance. Plain `relocate`
  is unchanged, and the around fields are refused without `around_owner`.
- Reads `owned_creature_combat_reach` and `owned_creature_position_x`, `_y`, `_z` (owning player, present `entry`).
- `spell_energize_count` and `spell_energize_total` accept `caster_entry`: the logs of any creature of that entry.
- A creature `cast` accepts `triggered: false`, which casts with `TRIGGERED_NONE`.

## Consequences

- New fields and reads only; every existing step keeps its behaviour. Generated scenarios of classes 19 (with and
  without `--stack`) and 23 are byte-identical.
- The placement uses the engine's distance rule (both combat reaches); the conformance kind that uses it reads the
  layout back and does not trust the placement alone (ADR 1111).
- An untriggered creature cast runs the ordinary cast checks (range, line of sight, power, cooldown); a refused one
  fails the step as before unless `allowed_refusal` names its code.
