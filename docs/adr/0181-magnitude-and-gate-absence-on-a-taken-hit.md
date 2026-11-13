# 0181. Magnitude and gate-absence triggers on a taken hit

- Status: accepted
- Date: 2026-11-11
- Extends: the `taken_hit` trigger action of the trigger entries (docs `trigger-entries.md`)

## Context

Sacred Defense 705306: "When you take Physical damage you now strike back at enemies for $s1% of the damage dealt
as Holy damage. Can only occur once per sec. @ext:Does not work on Bosses.:ext@". Two of its claims had no
behaviour check:

- "for $s1% of the damage dealt as Holy damage": the strike-back amount was only an `effect_value` readback. The
  `magnitude_ratio` kind compares a copy with the hit that caused it, but only for a cast or an attack by the
  caster.
- "Does not work on Bosses": no check. `gate_absence` withholds a condition and requires zero events, but only for
  a cast trigger.

The `taken_hit` action already drives a striker creature for `trigger_count`. Its only fixture, Claw (Pet) 16827,
dealt 6 to 8 damage, so 15% truncated to 0 a third of the time. The internal-cooldown entry uses 32247, a flat 1000
physical hit that cannot miss.

## Options

1. A new behaviour kind with a striker, a damage read and a boss arm. It repeats the trigger scheduling.
2. Read the strike-back with `hit_ratio`. Its arms cast a player spell; the trigger here is a hit the caster takes.
3. Accept `taken_hit` in `magnitude_ratio` and `gate_absence`, with the striker reads `trigger_count` already uses.

## Decision

Option 3.

- `magnitude_ratio` with `taken_hit`: the striker casts the trigger spell at the caster on the usual schedule; the
  trigger side is the striker's `spell_damage_total` and `spell_damage_count` on the caster; the observed side is
  the caster's copy. A magic copy is judged after the striker's average partial resist (ADR 0092): `target_steps`
  takes the unit to read.
- `gate_absence` with `taken_hit`: the aura is learned, the trigger spell is not, and the striker is the creature
  whose kind withholds the gate.
- Every taken-hit attempt first restores the caster to its full fixture health, so 273 strikes of 1000 cannot kill
  it. No existing class-file entry used a live `taken_hit` trigger, so no scenario changes.

## Consequences

- Sacred Defense reads 0.1316 against 0.15 x 0.88 = 0.132, 273 strikes back in 273 hits, from Harvest Golem 36,
  and 0 strikes back in 273 hits from Heroic Training Dummy 31146 (a boss by `type_flags` 4). The magnitude entry
  is the control arm of the boss claim.
- The boss arm exercises `Creature::isWorldBoss` (`type_flags`). The other branch of the check,
  `Creature::IsDungeonBoss` (`flags_extra` `CREATURE_FLAG_EXTRA_DUNGEON_BOSS`), is not tested.
