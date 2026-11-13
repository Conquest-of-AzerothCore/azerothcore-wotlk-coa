# 0184. Gate-absence label suffix

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0181 (gate absence on a taken hit)

## Context

Sacred Defense 705306: "@ext:Does not work on Bosses.:ext@". Its check refuses an attacker that is a dungeon boss
(`Creature::IsDungeonBoss`, the `CREATURE_FLAG_EXTRA_DUNGEON_BOSS` that `ObjectMgr::LoadInstanceEncounters` sets on a
5-man encounter's kill credit) or a world boss (`Creature::isWorldBoss`, `type_flags` `CREATURE_TYPE_FLAG_BOSS_MOB`)
(`AscensionTemplarEvents.cpp:46-49`). The tooltip names bosses without a kind, so both branches are its claim. The
first `gate_absence` arm struck from Heroic Training Dummy 31146, a world boss only. A second entry for the same aura
collided with the first: label `<aura> gate_absence_count`, scenario key `(<aura>, "gate")`.

## Options

1. Move the dungeon boss into a second part of the same entry. Parts share one striker entry.
2. A `trigger.striker_entries` list. It changes the striker fixture of every taken-hit kind.
3. An optional `label_suffix` on `gate_absence`, carried into the label and the scenario key.

## Decision

Option 3. Without the field, the label and key are unchanged, so existing scenarios regenerate byte-identical.

## Consequences

- Sacred Defense reads 0 strike-backs in 273 hits from Sneed 643 (Deadmines encounter 162, `type_flags` 0, so a
  dungeon boss and not a world boss), against 273 in 273 from Harvest Golem 36. The harness's summoned striker does
  not carry the player as its owner GUID, or `IsDungeonBoss` would have read false and the strikes would have come back.
