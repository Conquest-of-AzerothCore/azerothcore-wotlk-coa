# 1173. A dummy power fixture after the trigger

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-22
- Builds on: ADR 0403

## Context

Mana Jinx 801925 "and preventing mana regeneration": Effect[1] aura 110 MOD_POWER_REGEN_PERCENT -100 acts on a
creature through `Creature::Regenerate` (Creature.cpp:1072), but the Jinx also drains 232 mana every 2000 ms, so a
read of the creature's mana cannot separate the two, and the harness `set_power` reached only the player and its pet
(tool note of cycle 10, author B20).

## Decision

- Harness: `set_power` takes an optional `target` unit (a creature or another player).
- metric_delta option `dummy_power_after_trigger` (`power`, `value`, `after_ms`): the dummy's power is set
  `after_ms` after each trigger cast (in an uncast before phase at the point of the cast) and read `wait_ms` later.

## Consequences

Opt-in only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical. Class 13
gains 801925 `jinx_no_regen` (the dummy emptied to 0 regains mana without the Jinx and none under it). The harness
change needs a build.
