# 0700. A proc-rate attempt can refill base mana

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

`hits.cast_steps` sets the power of a flat-cost trigger before every cast, but not of a trigger that costs a
percentage of base mana. Expert Killer 804404 (Witch Hunter, 8% chance, 5000 ms internal cooldown) needs a ranged
direct-damage trigger; Heartseeking Bolt 805754 costs 15% of base mana, and the 782 trials outlast the pool (c10-bolt).
Mentor decision D-158 (design D-4).

## Options

- Add `hits.base_mana_steps` before every attempt whenever the trigger costs a percentage of base mana.
- The same, opt-in per entry (`base_mana_per_attempt`).

## Decision

The opt-in field, as D-158 requires opt-in or new keys only. `procs.attempt_power_steps` adds the class file's
`base_mana` set before every attempt of the entry (the cast baseline included); the field on a trigger without a
percent cost, or on a class file without `base_mana`, is refused. An optional `dummy_distance` places the dummy for a
ranged trigger: the first pair at the melee default read SPELL_FAILED_TOO_CLOSE (128) on all 1256 casts.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry states the field; neither class file has
  `base_mana`).
- Witch Hunter: `804404 proc_rate` (Slinging Bolts, 30 parts of 40 Heartseeking Bolts, 5000 ms apart, dummy at
  17.5 yd): pair 20261115-203840 / -203917 ok, 81 and 107 procs in 1200 trials, none in 56 baseline trials.
