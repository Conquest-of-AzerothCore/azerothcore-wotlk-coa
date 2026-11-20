# 0771. A metric delta strike can name its striker entry

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 296.0 (Unbroken 707407, "Increased further against Demons and Undead.", part A under owner ruling
O-28) is the attack power gained per damage taken from a Demon, an Undead and any other attacker: 325, 150 and 75 per
1000 (707407 Spell.dbc EffectBasePoints[0..2], EffectDieSides 0). The `metric_delta` `strike` fixture always spawns
creature 36 (Harvest Golem, creature_template type 9, Mechanical), so only the "other" rate could be read. The c15
Unbroken author's design line was approved by the mentor (D-248 / D-249, item T8).

## Options

- An optional `striker_entry` in the `strike` object (dataclass field, allowed key, parser, the striker fixture).
- A per-class default striker: one striker per scenario cannot carry three creature types.
- Setting the striker's creature type by a harness fixture: a new server-side test action for a choice the
  creature_template already makes.

## Decision

The optional field, a positive integer (booleans, strings, floats and non-positive values are refused). Absent, the
striker stays creature 36 and the scenario is byte-identical; present, only the striker's `entry` changes and the
contract names it.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: the field parses and is refused outside positive integers; it changes only the striker entry and the
  contract sentence; the three Witch Hunter arms spawn their strikers. Mutant: each arm judged at a sibling arm's gain
  (325, 150, 75 swapped) alerts.
- Witch Hunter: `707407 behaviour_metric_delta demon_rate`, `undead_rate`, `other_rate` (strikers 418 Lesser
  Voidwalker type 3, 3 Flesh Eater type 6, 36 Harvest Golem type 9, read from acore_world creature_template, no AI or
  script), each one strike of 32247 (1000 Physical) and a gain within 1 point. Diagnostic run 20261116-104054: 325,
  150 and 75, ok.
- Counted pair 20261116-104601 / -104630 (worldserver sha256 c9a6ffd6e5a9...): the three arms ok in both runs, and the
  class-file entry `707407 behaviour_metric_delta versus_amount` (707487 Effect[1], the displayed $w2, after the Demon
  strike) read 162 against 162.5 +- 1 in both runs.
