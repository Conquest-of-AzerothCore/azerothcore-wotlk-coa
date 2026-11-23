# 0703. A cooldown reset rate trigger can have its power refilled

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

`cooldown_reset_rate` refuses a trigger with a cost. Expulsion of Evil 139778 (Witch Hunter, 5% to reset
Houndmaster's Call on a direct ranged hit) has no free ranged trigger: Shadowblast costs 40 Rage (c10-hound). Mentor
decision D-158 (design D-8).

## Options

- An optional `cast_power` that sets the trigger's power before every cast.
- A free stand-in trigger: none exists in the class.

## Decision

`cast_power`, which must cover a flat cost; a percent or per-level cost is refused.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical.
- Each cast takes three steps, so the 10000-step limit caps an entry near 3300 casts.
- Witch Hunter use not proven: the 3152 trials of the 5% band with Shadowblast (1500 ms global cooldown) need about
  79 minutes of game time, past the one-hour accelerated case limit (cycle 11 tool report).
