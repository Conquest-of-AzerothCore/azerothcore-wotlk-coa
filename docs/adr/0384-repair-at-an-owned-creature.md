# 0384. Repair at an owned creature

- Status: accepted
- Date: 2026-11-13

## Context

Animate: Skeletal Smith 804681: "Animate a Skeletal Smith that can repair the equipment of allies for $d." The Smith
50261 carries the repairer NPC flag and takes its owner's faction at its summon. The harness had no repair action and
no durability read. The mentor approved a harness action under G-39 (Q-b2b-1): drive the real repair opcode handler
with the Smith as the NPC, never repair or write durability directly, wear the gear by a durability-loss call as a
named precondition fixture.

## Considered options

1. Call `Player::DurabilityRepairAll`. Rejected: it skips the NPC flag, distance and reaction checks.
2. Send `CMSG_REPAIR_ITEM` through `WorldSession::HandleRepairItemOpcode` with the owned creature's guid. Chosen.

## Decision

- Harness: `repair_at` (`owner`, `entry`) builds `CMSG_REPAIR_ITEM` (the owned creature's guid, or none when the owner
  has none out; repair all; no guild bank) and calls the handler; `durability_loss` (`percent`) calls
  `Player::DurabilityLossAll` (a precondition fixture); `equipped_durability` reads the current durability of the
  equipped items, or of one item entry (read only).
- Conformance kind `npc_repair`: the caster, a grouped ally and an enemy-faction player wear one item, worn before each
  request, and ask the caster's creature to repair it: before the summon (refused), then the caster and the ally
  (repaired to the item's maximum) and the enemy (refused). Each reading is a `behaviour_cast_condition` exact check.
- Templar `generate --class 19` and `--stack` byte-identical.
