# 0561. A metric delta may set the enemy player's class

- Status: accepted
- Date: 2026-11-13
- Split before publication (mentor ruling, 2026-11-13, local 14:26): this ADR keeps the tool field; the
  Necromancer mana drain fix it was written for is
  [Necromancer ADR 0030](conformance/necromancer/0030-mana-drains-and-burns-reach-a-necromancers-mana-pool.md).

## Context

A `metric_delta` entry's enemy player took the class file's class. The regression of Necromancer ADR 0030 (mana
drains and burns reach a Necromancer's mana pool) needs controls at an enemy player of another class: a Mage (mana
active) and a class with no mana pool. No field set the enemy's class.

## Decision

- `metric_delta` takes `enemy_player_class` (requires `enemy_player_race`; omitted, the enemy keeps the class file's
  class and the scenario is unchanged).

## Consequences

- Seeded tests (EnemyPlayerClassTests): the class is set on the enemy, kept without the field, refused without a race.
- Entries without the field generate unchanged scenarios.
