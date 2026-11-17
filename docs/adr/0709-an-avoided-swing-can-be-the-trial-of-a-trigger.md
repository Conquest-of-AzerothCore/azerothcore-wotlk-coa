# 0709. An avoided swing can be the trial of a trigger

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Dark Intuition 806195 (Witch Hunter) casts 806194 whenever the caster parries or dodges (spell_proc HitMask 48,
AscensionWitchHunterEvents.cpp:198-199, 413-414). The trigger entries had no action whose trial is an avoided
attack (keys 396.0-398.0). Mentor decision D-158 (design D-5).

## Options

- A trigger action `avoided`, reusing the avoided setup of `cast_condition` (Evasion 26669, an aggressive attacker,
  `melee_attacks_taken` with a victim state).
- Count dodges only: a parry triggers the proc too (and 806194 raises the parry chance), so the ratio would read
  above one per trial.

## Decision

The `avoided` action. Each phase engages the striker once; each attempt sets the caster's health to full and
Evasion, then waits `swing_ms`. The trials are read twice, dodged and parried, and `compare.trigger_counts` sums the
parried reads when the model names them. The existing trigger judge applies.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry uses the action).
- Seeded mutant: a proc counted on dodges only alerts once parries are summed.
- Witch Hunter: `806195 trigger_count`, pair 20261115-210153 / -210225 ok, 269 / 269 and 281 / 281 events per
  avoided swing, none in the baseline.
