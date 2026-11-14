# 0534. An item cooldown gate may read a pool held through combat

- Status: accepted
- Date: 2026-11-13
- Split before publication (mentor ruling 2, 2026-11-13): this ADR keeps the tool rule; the reliquary fix it was written
  for is [Necromancer ADR
  0027](conformance/necromancer/0027-the-bone-and-frozen-reliquaries-share-the-potion-cooldown-pool.md).

## Context

A pooled item cooldown (category 5004, SPELL_CATEGORY_SHARED_POTION_COOLDOWN) allows one pooled use per combat, then
the cooldown after combat ends (Necromancer ADR 0027, the Bone and Frozen Reliquaries). An `item_cooldown_gate` entry
read one gate per item, out of combat only.

## Decision

- Conformance tools: an `item_cooldown_gate` entry may set `label_suffix` (several entries per item) and
  `combat_kill_spell` (the in-combat arm: the ally attacks the dummy, uses `item`, is refused `shared_item` past the
  cooldown while in combat, the caster kills the dummy with that spell, and `shared_item` is refused after the combat
  end, still refused just before the cooldown from the combat end and accepted just after it).

## Consequences

- One item may carry several gate entries (one per shared item and one in-combat arm); the reliquary regression uses
  this (Necromancer ADR 0027, `pool_combat`).
<!-- Draft note: the original ADR 0534 states no tool-only consequence (no Templar byte-identity line); add one only if
     measured. -->
