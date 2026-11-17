# 0718. An attack proc can count off-hand trials

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Brushin' Off The Dusk 681329 and 681488 (Witch Hunter): "Your off-hand auto attacks now have a $h% chance to strike
additional times". `procs` attack trials were main-hand hits only (`melee_damage_count` hand 0), so an off-hand
chance could not be judged; the extra_strikes kind reports the share without judging it (c11-inq stop on claims 214.0
and 228.0). Mentor decision D-160 (c12 tool batch item 8).

## Options

- A `trial_hand` field on attack procs: hand 1 reads the off-hand trials and attempts and spaces swings by the
  off-hand speed.
- Summing both hands: the handler accepts off-hand swings only, so main-hand trials would dilute the rate.

## Decision

`procs.trial_hand` (0 or 1, attack triggers without `most_procs_per_trigger`); `hand_swing_interval` reads the off-hand
weapon of the entry's weapon set and refuses a set without one. The rule names off-hand trials.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry states the field).
- Witch Hunter: `681329 proc_rate` and `681488 proc_rate` (events: Replenishment 1257670 casts, one per proc).
