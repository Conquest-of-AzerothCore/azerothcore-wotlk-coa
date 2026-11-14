# 0530. A strike may target an owned creature

- Status: accepted
- Date: 2026-11-13
- Split before publication (mentor ruling 2, 2026-11-13): this ADR keeps the harness and tool rules; the Abomination fix
  they were written for is [Necromancer ADR
  0023](conformance/necromancer/0023-the-abomination-disease-cloud-fires-when-the-abomination-takes-damage.md).

## Context

A minion effect triggered by damage the minion takes (the Abomination's disease cloud, Necromancer ADR 0023) needs an
enemy that strikes the caster's minion, not the caster or a dummy. The mentor approved the harness part on the
condition that it is test-only (G-39). The `metric_delta` and `script_hit` strikes could only hit the entry's target,
and `coverage.py` classed `owned_creature_spell_cast_count` (ADR 0485) as no event read.

## Decision

- Harness (test-only, no gameplay path): a creature actor's `cast` step may name `target_owner` and
  `target_owned_entry`, and then casts at that player's living owned creature of the entry (`GetOwnedCreature`).
- Conformance tools: a `metric_delta` `strike` may name `owned_entry`: the striker casts at the caster's owned
  creature of that entry, in the after phase only. A `script_hit` entry may name `strike_owned_entry`: the striker
  casts `strike_spell` at that owned creature in the treatment arm only, both arms waiting the same time, so
  `control_casts` may repeat the casts. `coverage.py` classes the `owned_creature_spell_cast_count` metric (ADR 0485)
  as an event, like `spell_cast_count`, now that a metric_delta entry reads it.

## Consequences

- No metric reads damage taken by an owned creature, so a cast count after owned strikes is not judged equal to
  damage-taken events.
- Templar `generate --class 19` and `--stack` are unchanged by the tool fields (absent fields generate the same steps).
