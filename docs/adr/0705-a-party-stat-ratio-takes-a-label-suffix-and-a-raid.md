# 0705. A party stat ratio takes a label suffix and a raid

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Monster Hunting 300872 (Witch Hunter): "Increases melee and ranged haste of party and raid members". The entry read
the ally's melee attack time only (review I-1), and a second entry of the spell would collide on its label; the raid
half was not read. Mentor decision D-158 (design D-11).

## Decision

`label_suffix` is appended to the label (`passives.BEHAVIOUR_LABELS` too). `raid: true` groups four filler players
before the measured ally, so the harness converts the full party to a raid when the ally joins
(`CoAGameplayTest.cpp`, `group` action), as `group_target` does.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry states either field).
- Witch Hunter: `300872 behaviour_party_stat_ratio ranged` (`hand: 2`) and `raid`.
