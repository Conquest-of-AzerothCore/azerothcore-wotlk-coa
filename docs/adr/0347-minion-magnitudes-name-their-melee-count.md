# 0347. Minion magnitudes name their melee count

- Status: accepted
- Date: 2026-11-13

## Context

Both Necromancer B1 sides let a minion `magnitude_ratio` entry measure `trigger_metric: "pet_melee_damage"`. Side a
(ADR 0321) counts it with `pet_melee_hits`, since Putrid Claws 570050 follows every hit of Animate: Tomb King 805044,
and reads the observed spell with `caster_entry`. Side b (ADR 0346's commit) counts it with `pet_melee_crits`, since
Bone Club 801241 follows Depravity 638403's forced crits, and reads the observed spell with `entry` and `target`. One
mapping from `pet_melee_damage` to its count cannot serve both claims, and the presence aura read had two forms
(`presence_aura` on the caster, `aura_on_minion` on the minion).

## Considered options

1. Count crits for every `pet_melee_damage` entry. Rejected: a Tomb King part would count only its crits against the
   damage of all its hits.
2. Count hits for every entry. Rejected: Depravity's claim is per crit, and any swing that hits without a crit
   despite the forced crit chance would join its trigger side without a Bone Club roll.
3. Let the entry name its count, hits by default. Chosen.

## Decision

- `trigger_count_metric` names the minion count of a `magnitude_ratio` trigger metric: `pet_melee_hits` (default) or
  `pet_melee_crits` for `pet_melee_damage`, `owned_creature_damage_count` for `owned_creature_damage_total`.
  `checked_magnitude_entry` rejects any other value. Depravity 638403's magnitude entry sets `pet_melee_crits`.
- `observe_actor: "minion"` reads the observed spell by `caster_entry` of the minion entry (ADR 0321).
- The aura read is `presence_aura` on the caster when set, otherwise `aura_measurement` (the minion's copy with
  `aura_on_minion`).

## Consequences

- Tomb King's magnitude scenario is generated as side a ran it. Depravity's magnitude scenario keeps its crit count
  and aura read, but its observed spell is now read by `caster_entry` instead of `entry` and `target`, so its part
  must run again before its verdict counts.
